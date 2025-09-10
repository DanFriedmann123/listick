import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:developer' as developer;

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _users => _firestore.collection('users');

  // Get current user document reference
  DocumentReference? get currentUserRef {
    final user = _auth.currentUser;
    return user != null ? _users.doc(user.uid) : null;
  }

  // Create or update user profile
  Future<void> createOrUpdateUser({
    required String uid,
    required String email,
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      await _users.doc(uid).set({
        'uid': uid,
        'email': email,
        'displayName': displayName ?? email.split('@')[0],
        'username': username ?? email.split('@')[0],
        'bio': bio ?? '',
        'avatarUrl': avatarUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'followers': [],
        'following': [],
        'followersCount': 0,
        'followingCount': 0,
        'listsCount': 0,
      }, SetOptions(merge: true));

      developer.log('User profile created/updated successfully');
    } catch (e) {
      developer.log('Error creating/updating user profile: ${e.toString()}');
      throw 'Failed to create/update user profile: ${e.toString()}';
    }
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _users
          .doc(uid)
          .get()
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw 'Timeout getting user profile',
          );
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      developer.log('Error getting user profile: ${e.toString()}');
      throw 'Failed to get user profile: ${e.toString()}';
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'No authenticated user';

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (displayName != null) updates['displayName'] = displayName;
      if (username != null) updates['username'] = username;
      if (bio != null) updates['bio'] = bio;
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;

      await _users
          .doc(user.uid)
          .update(updates)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw 'Timeout updating user profile',
          );
      developer.log('User profile updated successfully');
    } catch (e) {
      developer.log('Error updating user profile: ${e.toString()}');
      throw 'Failed to update user profile: ${e.toString()}';
    }
  }

  // Delete user profile
  Future<void> deleteUserProfile(String uid) async {
    try {
      // Delete user document from Firestore
      await _users.doc(uid).delete();

      // Delete user's avatar from Storage if it exists
      try {
        final avatarRef = _storage.ref().child('avatars/$uid');
        await avatarRef.delete();
      } catch (e) {
        // Avatar might not exist, ignore error
        developer.log('No avatar to delete or error deleting avatar: $e');
      }

      developer.log('User profile deleted successfully');
    } catch (e) {
      developer.log('Error deleting user profile: ${e.toString()}');
      throw 'Failed to delete user profile: ${e.toString()}';
    }
  }

  // Upload user avatar
  Future<String> uploadUserAvatar(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'No authenticated user';

      // Create unique filename
      final fileName =
          'avatars/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload to Firebase Storage
      final ref = _storage.ref().child(fileName);
      final uploadTask = ref.putFile(imageFile);

      // Wait for upload to complete with timeout
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw 'Timeout uploading avatar',
      );

      // Get download URL with timeout
      final downloadUrl = await snapshot.ref.getDownloadURL().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw 'Timeout getting avatar download URL',
      );

      // Update user profile with new avatar URL
      await updateUserProfile(avatarUrl: downloadUrl);

      developer.log('Avatar uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      developer.log('Error uploading avatar: ${e.toString()}');
      throw 'Failed to upload avatar: ${e.toString()}';
    }
  }

  // Delete user avatar
  Future<void> deleteUserAvatar() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'No authenticated user';

      // Get current avatar URL
      final userData = await getUserProfile(user.uid);
      final currentAvatarUrl = userData?['avatarUrl'] as String?;

      if (currentAvatarUrl != null) {
        // Delete from Storage
        try {
          final ref = _storage.refFromURL(currentAvatarUrl);
          await ref.delete();
        } catch (e) {
          developer.log('Error deleting from storage: ${e.toString()}');
          // Continue even if storage deletion fails
        }
      }

      // Update profile to remove avatar URL
      await updateUserProfile(avatarUrl: '');
      developer.log('Avatar deleted successfully');
    } catch (e) {
      developer.log('Error deleting avatar: ${e.toString()}');
      throw 'Failed to delete avatar: ${e.toString()}';
    }
  }

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      if (username.length < 3 || username.length > 20) {
        return false;
      }

      // Check Firestore for username availability
      final query =
          await _users
              .where('username', isEqualTo: username.toLowerCase())
              .limit(1)
              .get();

      return query.docs.isEmpty;
    } catch (e) {
      developer.log('Error checking username availability: ${e.toString()}');
      return false;
    }
  }

  // Get user by username
  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    try {
      final query =
          await _users
              .where('username', isEqualTo: username.toLowerCase())
              .limit(1)
              .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      developer.log('Error getting user by username: ${e.toString()}');
      throw 'Failed to get user by username: ${e.toString()}';
    }
  }

  // Stream user profile changes
  Stream<Map<String, dynamic>?> getUserProfileStream(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    });
  }

  // Update user counts
  Future<void> updateUserCounts({
    String? uid,
    int? followersCount,
    int? followingCount,
    int? listsCount,
  }) async {
    try {
      final userId = uid ?? _auth.currentUser?.uid;
      if (userId == null) throw 'No user ID provided';

      final updates = <String, dynamic>{};
      if (followersCount != null) updates['followersCount'] = followersCount;
      if (followingCount != null) updates['followingCount'] = followingCount;
      if (listsCount != null) updates['listsCount'] = listsCount;

      await _users.doc(userId).update(updates);
    } catch (e) {
      developer.log('Error updating user counts: ${e.toString()}');
      throw 'Failed to update user counts: ${e.toString()}';
    }
  }

  // Follow a user
  Future<void> followUser(String currentUserId, String targetUserId) async {
    try {
      final batch = _firestore.batch();

      // Add targetUserId to current user's following array
      final currentUserRef = _users.doc(currentUserId);
      batch.update(currentUserRef, {
        'following': FieldValue.arrayUnion([targetUserId]),
        'followingCount': FieldValue.increment(1),
      });

      // Add currentUserId to target user's followers array
      final targetUserRef = _users.doc(targetUserId);
      batch.update(targetUserRef, {
        'followers': FieldValue.arrayUnion([currentUserId]),
        'followersCount': FieldValue.increment(1),
      });

      await batch.commit();
      developer.log('Successfully followed user: $targetUserId');
    } catch (e) {
      developer.log('Error following user: ${e.toString()}');
      throw 'Failed to follow user: ${e.toString()}';
    }
  }

  // Unfollow a user
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      final batch = _firestore.batch();

      // Remove targetUserId from current user's following array
      final currentUserRef = _users.doc(currentUserId);
      batch.update(currentUserRef, {
        'following': FieldValue.arrayRemove([targetUserId]),
        'followingCount': FieldValue.increment(-1),
      });

      // Remove currentUserId from target user's followers array
      final targetUserRef = _users.doc(targetUserId);
      batch.update(targetUserRef, {
        'followers': FieldValue.arrayRemove([currentUserId]),
        'followersCount': FieldValue.increment(-1),
      });

      await batch.commit();
      developer.log('Successfully unfollowed user: $targetUserId');
    } catch (e) {
      developer.log('Error unfollowing user: ${e.toString()}');
      throw 'Failed to unfollow user: ${e.toString()}';
    }
  }

  // Check if current user is following target user
  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    try {
      final doc = await _users.doc(currentUserId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final following = List<String>.from(data['following'] ?? []);
        return following.contains(targetUserId);
      }
      return false;
    } catch (e) {
      developer.log('Error checking follow status: ${e.toString()}');
      return false;
    }
  }

  // Get followers list
  Future<List<String>> getFollowers(String userId) async {
    try {
      final doc = await _users.doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return List<String>.from(data['followers'] ?? []);
      }
      return [];
    } catch (e) {
      developer.log('Error getting followers: ${e.toString()}');
      throw 'Failed to get followers: ${e.toString()}';
    }
  }

  // Get following list
  Future<List<String>> getFollowing(String userId) async {
    try {
      final doc = await _users.doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return List<String>.from(data['following'] ?? []);
      }
      return [];
    } catch (e) {
      developer.log('Error getting following: ${e.toString()}');
      throw 'Failed to get following: ${e.toString()}';
    }
  }
}
