import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:developer' as developer;
import '../models/post.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _posts => _firestore.collection('posts');
  CollectionReference get _users => _firestore.collection('users');

  // Create a new post
  Future<String> createPost({
    required String title,
    required String description,
    required List<File> images,
    String? category,
    required List<PostItem> items,
    List<String>? tags,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'User not authenticated';

      // Get user profile data with timeout
      final userDoc = await _users
          .doc(user.uid)
          .get()
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw 'Timeout getting user profile',
          );
      if (!userDoc.exists) throw 'User profile not found';

      final userData = userDoc.data() as Map<String, dynamic>;
      final authorName =
          userData['displayName'] ?? userData['username'] ?? 'Unknown User';
      final authorAvatar = userData['avatarUrl'];

      // Upload images to Firebase Storage with timeout
      final List<String> imageUrls = [];
      for (int i = 0; i < images.length; i++) {
        final imageFile = images[i];
        final fileName =
            'posts/${user.uid}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final ref = _storage.ref().child(fileName);

        final uploadTask = ref.putFile(imageFile);
        final snapshot = await uploadTask.timeout(
          const Duration(seconds: 60),
          onTimeout: () => throw 'Timeout uploading image ${i + 1}',
        );
        final downloadUrl = await snapshot.ref.getDownloadURL().timeout(
          const Duration(seconds: 30),
          onTimeout:
              () => throw 'Timeout getting download URL for image ${i + 1}',
        );
        imageUrls.add(downloadUrl);
      }

      // Create post document
      final postData = {
        'title': title,
        'description': description,
        'authorId': user.uid,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'imageUrls': imageUrls,
        'videoUrl': null,
        'category': category,
        'items': items.map((item) => item.toMap()).toList(),
        'likeCount': 0,
        'commentCount': 0,
        'viewCount': 0,
        'isTrending': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'likedBy': [],
        'bookmarkedBy': [],
        'tags': tags ?? [],
      };

      final docRef = await _posts
          .add(postData)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw 'Timeout creating post document',
          );

      // Update user's post count
      await _users
          .doc(user.uid)
          .update({
            'listsCount': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw 'Timeout updating user post count',
          );

      developer.log('Post created successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      developer.log('Error creating post: $e');
      rethrow;
    }
  }

  // Get all posts with pagination
  Stream<List<Post>> getPostsStream({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) {
    Query query = _posts.orderBy('createdAt', descending: true).limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    });
  }

  // Get posts by user
  Stream<List<Post>> getPostsByUserStream(String userId) {
    return _posts.where('authorId', isEqualTo: userId).snapshots().map((
      snapshot,
    ) {
      final posts =
          snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
      // Sort posts by creation date in memory to avoid Firestore index requirement
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    });
  }

  // Get posts by category
  Stream<List<Post>> getPostsByCategoryStream(String category) {
    return _posts
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
        });
  }

  // Get trending posts (posts marked as trending)
  Stream<List<Post>> getTrendingPostsStream() {
    return _posts
        .where('isTrending', isEqualTo: true)
        .orderBy('likeCount', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
        });
  }

  // Get popular posts based on engagement (likes only for now to avoid index issues)
  Stream<List<Post>> getPopularPostsStream({int limit = 10}) {
    return _posts
        .orderBy('likeCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
        });
  }

  // Get single post by ID
  Future<Post?> getPostById(String postId) async {
    try {
      final doc = await _posts.doc(postId).get();
      if (doc.exists) {
        return Post.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      developer.log('Error getting post: $e');
      return null;
    }
  }

  // Like/unlike a post
  Future<void> toggleLike(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'User not authenticated';

      final postRef = _posts.doc(postId);
      final postDoc = await postRef.get();

      if (!postDoc.exists) throw 'Post not found';

      final postData = postDoc.data() as Map<String, dynamic>;
      final likedBy = List<String>.from(postData['likedBy'] ?? []);
      final likeCount = postData['likeCount'] ?? 0;

      if (likedBy.contains(user.uid)) {
        // Unlike
        likedBy.remove(user.uid);
        await postRef.update({
          'likedBy': likedBy,
          'likeCount': likeCount - 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Like
        likedBy.add(user.uid);
        await postRef.update({
          'likedBy': likedBy,
          'likeCount': likeCount + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      developer.log('Error toggling like: $e');
      rethrow;
    }
  }

  // Bookmark/unbookmark a post
  Future<void> toggleBookmark(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'User not authenticated';

      final postRef = _posts.doc(postId);
      final postDoc = await postRef.get();

      if (!postDoc.exists) throw 'Post not found';

      final postData = postDoc.data() as Map<String, dynamic>;
      final bookmarkedBy = List<String>.from(postData['bookmarkedBy'] ?? []);

      if (bookmarkedBy.contains(user.uid)) {
        // Remove bookmark
        bookmarkedBy.remove(user.uid);
      } else {
        // Add bookmark
        bookmarkedBy.add(user.uid);
      }

      await postRef.update({
        'bookmarkedBy': bookmarkedBy,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      developer.log('Error toggling bookmark: $e');
      rethrow;
    }
  }

  // Update post view count
  Future<void> incrementViewCount(String postId) async {
    try {
      await _posts.doc(postId).update({
        'viewCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      developer.log('Error incrementing view count: $e');
    }
  }

  // Update a post
  Future<void> updatePost({
    required String postId,
    required String title,
    required String description,
    List<File>? newImages,
    String? category,
    required List<PostItem> items,
    List<String>? tags,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'User not authenticated';

      final postRef = _posts.doc(postId);
      final postDoc = await postRef.get();

      if (!postDoc.exists) throw 'Post not found';

      final postData = postDoc.data() as Map<String, dynamic>;
      if (postData['authorId'] != user.uid) {
        throw 'Only the author can edit this post';
      }

      Map<String, dynamic> updateData = {
        'title': title,
        'description': description,
        'category': category,
        'items': items.map((item) => item.toMap()).toList(),
        'tags': tags ?? [],
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Handle new images if provided
      if (newImages != null && newImages.isNotEmpty) {
        // Delete old images from Storage
        final oldImageUrls = List<String>.from(postData['imageUrls'] ?? []);
        for (final imageUrl in oldImageUrls) {
          try {
            final ref = _storage.refFromURL(imageUrl);
            await ref.delete();
          } catch (e) {
            developer.log('Error deleting old image: $e');
          }
        }

        // Upload new images
        final List<String> imageUrls = [];
        for (int i = 0; i < newImages.length; i++) {
          final imageFile = newImages[i];
          final fileName =
              'posts/${user.uid}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          final ref = _storage.ref().child(fileName);

          final uploadTask = ref.putFile(imageFile);
          final snapshot = await uploadTask.timeout(
            const Duration(seconds: 60),
            onTimeout: () => throw 'Timeout uploading image ${i + 1}',
          );
          final downloadUrl = await snapshot.ref.getDownloadURL().timeout(
            const Duration(seconds: 30),
            onTimeout:
                () => throw 'Timeout getting download URL for image ${i + 1}',
          );
          imageUrls.add(downloadUrl);
        }

        updateData['imageUrls'] = imageUrls;
      }

      await postRef.update(updateData);
      developer.log('Post updated successfully');
    } catch (e) {
      developer.log('Error updating post: $e');
      rethrow;
    }
  }

  // Delete a post
  Future<void> deletePost(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'User not authenticated';

      final postDoc = await _posts.doc(postId).get();
      if (!postDoc.exists) throw 'Post not found';

      final postData = postDoc.data() as Map<String, dynamic>;
      if (postData['authorId'] != user.uid) {
        throw 'Only the author can delete this post';
      }

      // Delete images from Storage
      final imageUrls = List<String>.from(postData['imageUrls'] ?? []);
      for (final imageUrl in imageUrls) {
        try {
          final ref = _storage.refFromURL(imageUrl);
          await ref.delete();
        } catch (e) {
          developer.log('Error deleting image: $e');
        }
      }

      // Delete post document
      await _posts.doc(postId).delete();

      // Update user's post count
      await _users.doc(user.uid).update({
        'listsCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log('Post deleted successfully');
    } catch (e) {
      developer.log('Error deleting post: $e');
      rethrow;
    }
  }

  // Search posts
  Stream<List<Post>> searchPostsStream(String query) {
    if (query.trim().isEmpty) {
      return Stream.value([]);
    }

    return _posts
        .orderBy('title')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .limit(20)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
        });
  }

  // Get categories
  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _posts.where('category', isNull: false).get();

      final categories =
          snapshot.docs
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>?;
                return data?['category'] as String?;
              })
              .where((category) => category != null && category.isNotEmpty)
              .map((category) => category!)
              .toSet()
              .toList();

      return categories;
    } catch (e) {
      developer.log('Error getting categories: $e');
      return [];
    }
  }

  // Check if user has liked a post
  Future<bool> hasUserLikedPost(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final postDoc = await _posts.doc(postId).get();
      if (!postDoc.exists) return false;

      final postData = postDoc.data() as Map<String, dynamic>;
      final likedBy = List<String>.from(postData['likedBy'] ?? []);

      return likedBy.contains(user.uid);
    } catch (e) {
      developer.log('Error checking if user liked post: $e');
      return false;
    }
  }

  // Check if user has bookmarked a post
  Future<bool> hasUserBookmarkedPost(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final postDoc = await _posts.doc(postId).get();
      if (!postDoc.exists) return false;

      final postData = postDoc.data() as Map<String, dynamic>;
      final bookmarkedBy = List<String>.from(postData['bookmarkedBy'] ?? []);

      return bookmarkedBy.contains(user.uid);
    } catch (e) {
      developer.log('Error checking if user bookmarked post: $e');
      return false;
    }
  }

  // Get posts from users that the current user follows
  Stream<List<Post>> getFollowingPostsStream({int limit = 10}) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _users.doc(user.uid).snapshots().asyncExpand((userDoc) {
      if (!userDoc.exists) {
        return Stream.value(<Post>[]);
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final following = List<String>.from(userData['following'] ?? []);

      if (following.isEmpty) {
        return Stream.value(<Post>[]);
      }

      // Get posts from followed users (without orderBy to avoid index requirement)
      return _posts.where('authorId', whereIn: following).snapshots().map((
        snapshot,
      ) {
        final posts =
            snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
        // Sort by createdAt in memory (descending)
        posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        // Return limited results
        return posts.take(limit).toList();
      });
    });
  }
}
