import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class OnboardingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // List of interests for user selection
  // In the future, we should:
  // 1. Make this list dynamic and fetch from Firestore
  // 2. Allow admins to add/remove interests
  // 3. Add interest categories and subcategories
  // 4. Implement interest-based content recommendations
  // 5. Add trending interests based on user activity
  static const List<String> availableInterests = [
    'Technology',
    'Music',
    'Sports',
    'Cooking',
    'Travel',
    'Reading',
    'Gaming',
    'Fitness',
    'Art',
    'Photography',
    'Fashion',
    'Food',
    'Movies',
    'Nature',
    'Science',
    'History',
    'Politics',
    'Business',
    'Education',
    'Health',
    'Fashion',
    'Beauty',
    'DIY',
    'Gardening',
    'Pets',
    'Cars',
    'Architecture',
    'Design',
    'Writing',
    'Dance',
    'Yoga',
    'Meditation',
    'Astronomy',
    'Psychology',
    'Philosophy',
    'Economics',
    'Environment',
    'Social Media',
    'Blogging',
    'Podcasting',
  ];

  // Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return data['username'] != null &&
            data['avatarUrl'] != null &&
            data['interests'] != null &&
            (data['interests'] as List).isNotEmpty;
      }
      return false;
    } catch (e) {
      developer.log('Error checking onboarding status: $e');
      return false;
    }
  }

  // Save username
  Future<bool> saveUsername(String userId, String username) async {
    try {
      // Check if username is available
      final isAvailable = await isUsernameAvailable(username);
      if (!isAvailable) {
        throw 'Username is already taken';
      }

      await _firestore.collection('users').doc(userId).set({
        'username': username.toLowerCase(),
        'displayName': username,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      developer.log('Error saving username: $e');
      rethrow;
    }
  }

  // Save profile image
  Future<bool> saveProfileImage(String userId, File imageFile) async {
    try {
      // Create unique filename
      final fileName =
          'avatars/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload to Firebase Storage
      final ref = _storage.ref().child(fileName);
      final uploadTask = ref.putFile(imageFile);

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update user profile
      await _firestore.collection('users').doc(userId).set({
        'avatarUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      developer.log('Error saving profile image: $e');
      rethrow;
    }
  }

  // Save user interests
  Future<bool> saveInterests(String userId, List<String> interests) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'interests': interests,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      developer.log('Error saving interests: $e');
      rethrow;
    }
  }

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));

      return query.docs.isEmpty;
    } catch (e) {
      developer.log('Error checking username availability: $e');
      // Return true to allow username selection when Firestore is unavailable
      return true;
    }
  }

  // Get user's current onboarding progress
  Future<Map<String, dynamic>> getOnboardingProgress(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return {
          'hasUsername': data['username'] != null,
          'hasAvatar': data['avatarUrl'] != null,
          'hasInterests':
              data['interests'] != null &&
              (data['interests'] as List).isNotEmpty,
          'username': data['username'],
          'avatarUrl': data['avatarUrl'],
          'interests': data['interests'] ?? [],
        };
      }
      return {
        'hasUsername': false,
        'hasAvatar': false,
        'hasInterests': false,
        'username': null,
        'avatarUrl': null,
        'interests': [],
      };
    } catch (e) {
      developer.log('Error getting onboarding progress: $e');
      return {
        'hasUsername': false,
        'hasAvatar': false,
        'hasInterests': false,
        'username': null,
        'avatarUrl': null,
        'interests': [],
      };
    }
  }

  // Complete onboarding and mark user as fully set up
  Future<bool> completeOnboarding(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'onboardingCompleted': true,
        'onboardingCompletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      developer.log('Error completing onboarding: $e');
      return false;
    }
  }
}
