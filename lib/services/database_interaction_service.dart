import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DatabaseInteractionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  // Check if user is authenticated
  static bool get isAuthenticated => _auth.currentUser != null;

  // Toggle like for a post (real or demo)
  static Future<void> toggleLike(
    String postId,
    bool isLiked, {
    bool isDemoPost = false,
  }) async {
    if (!isAuthenticated) {
      throw Exception('User must be authenticated to like posts');
    }

    try {
      final userId = currentUserId!;
      final collectionPath = isDemoPost ? 'demo_posts' : 'posts';
      final likeRef = _firestore
          .collection(collectionPath)
          .doc(postId)
          .collection('likes')
          .doc(userId);

      if (isLiked) {
        // Add like
        await likeRef.set({
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        // Remove like
        await likeRef.delete();
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
      throw Exception('Failed to update like: $e');
    }
  }

  // Check if user has liked a post
  static Future<bool> isPostLiked(
    String postId, {
    bool isDemoPost = false,
  }) async {
    if (!isAuthenticated) return false;

    try {
      final userId = currentUserId!;
      final collectionPath = isDemoPost ? 'demo_posts' : 'posts';
      final likeDoc =
          await _firestore
              .collection(collectionPath)
              .doc(postId)
              .collection('likes')
              .doc(userId)
              .get();

      return likeDoc.exists;
    } catch (e) {
      debugPrint('Error checking like status: $e');
      return false;
    }
  }

  // Get like count for a post
  static Future<int> getLikeCount(
    String postId, {
    bool isDemoPost = false,
  }) async {
    try {
      final collectionPath = isDemoPost ? 'demo_posts' : 'posts';
      final likesSnapshot =
          await _firestore
              .collection(collectionPath)
              .doc(postId)
              .collection('likes')
              .get();

      return likesSnapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting like count: $e');
      return 0;
    }
  }

  // Add comment to a post
  static Future<void> addComment(
    String postId,
    String commentText, {
    bool isDemoPost = false,
  }) async {
    if (!isAuthenticated) {
      throw Exception('User must be authenticated to comment');
    }

    try {
      final userId = currentUserId!;
      final user = _auth.currentUser;
      final authorName = user?.displayName ?? user?.email ?? 'Anonymous';

      final collectionPath = isDemoPost ? 'demo_posts' : 'posts';
      final commentRef =
          _firestore
              .collection(collectionPath)
              .doc(postId)
              .collection('comments')
              .doc();

      await commentRef.set({
        'id': commentRef.id,
        'text': commentText,
        'authorId': userId,
        'authorName': authorName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding comment: $e');
      throw Exception('Failed to add comment: $e');
    }
  }

  // Get comments for a post
  static Future<List<Map<String, dynamic>>> getComments(
    String postId, {
    bool isDemoPost = false,
  }) async {
    try {
      final collectionPath = isDemoPost ? 'demo_posts' : 'posts';
      final commentsSnapshot =
          await _firestore
              .collection(collectionPath)
              .doc(postId)
              .collection('comments')
              .orderBy('timestamp', descending: true)
              .get();

      return commentsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'text': data['text'] ?? '',
          'authorId': data['authorId'] ?? '',
          'authorName': data['authorName'] ?? 'Anonymous',
          'timestamp': data['timestamp'] ?? Timestamp.now(),
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting comments: $e');
      return [];
    }
  }

  // Get comment count for a post
  static Future<int> getCommentCount(
    String postId, {
    bool isDemoPost = false,
  }) async {
    try {
      final collectionPath = isDemoPost ? 'demo_posts' : 'posts';
      final commentsSnapshot =
          await _firestore
              .collection(collectionPath)
              .doc(postId)
              .collection('comments')
              .get();

      return commentsSnapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting comment count: $e');
      return 0;
    }
  }

  // Delete a comment (only by the author)
  static Future<void> deleteComment(
    String postId,
    String commentId, {
    bool isDemoPost = false,
  }) async {
    if (!isAuthenticated) {
      throw Exception('User must be authenticated to delete comments');
    }

    try {
      final userId = currentUserId!;
      final collectionPath = isDemoPost ? 'demo_posts' : 'posts';
      final commentRef = _firestore
          .collection(collectionPath)
          .doc(postId)
          .collection('comments')
          .doc(commentId);

      // Check if user is the author
      final commentDoc = await commentRef.get();
      if (!commentDoc.exists) {
        throw Exception('Comment not found');
      }

      final commentData = commentDoc.data();
      if (commentData?['authorId'] != userId) {
        throw Exception('Only comment author can delete comments');
      }

      await commentRef.delete();
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      throw Exception('Failed to delete comment: $e');
    }
  }

  // Get real-time stream of comments for a post
  static Stream<List<Map<String, dynamic>>> getCommentsStream(
    String postId, {
    bool isDemoPost = false,
  }) {
    final collectionPath = isDemoPost ? 'demo_posts' : 'posts';
    return _firestore
        .collection(collectionPath)
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();
                return {
                  'id': doc.id,
                  'text': data['text'] ?? '',
                  'authorId': data['authorId'] ?? '',
                  'authorName': data['authorName'] ?? 'Anonymous',
                  'timestamp': data['timestamp'] ?? Timestamp.now(),
                };
              }).toList(),
        );
  }

  // Get real-time stream of like count for a post
  static Stream<int> getLikeCountStream(
    String postId, {
    bool isDemoPost = false,
  }) {
    final collectionPath = isDemoPost ? 'demo_posts' : 'posts';
    return _firestore
        .collection(collectionPath)
        .doc(postId)
        .collection('likes')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
