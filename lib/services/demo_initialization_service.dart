import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DemoInitializationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize demo posts in the database
  static Future<void> initializeDemoPosts() async {
    try {
      final demoPosts = [
        {
          'id': '1',
          'title': 'Ultimate Travel Packing List',
          'description':
              'Everything you need for your next adventure, organized by category and priority.',
          'authorId': 'demo_user',
          'category': 'Travel',
          'isTrending': true,
          'likeCount': 156,
          'commentCount': 23,
          'viewCount': 1247,
          'createdAt': FieldValue.serverTimestamp(),
          'imageUrls': [
            'https://picsum.photos/400/200?random=10',
            'https://picsum.photos/400/200?random=11',
            'https://picsum.photos/400/200?random=12',
            'https://picsum.photos/400/200?random=13',
            'https://picsum.photos/400/200?random=14',
            'https://picsum.photos/400/200?random=15',
          ],
          'items': [
            {
              'id': 1,
              'text': 'Passport and travel documents',
              'url': null as String?,
              'isCompleted': false,
              'completionCount': 89,
            },
            {
              'id': 2,
              'text': 'Universal power adapter',
              'url': 'https://amazon.com/power-adapter',
              'isCompleted': false,
              'completionCount': 67,
            },
            {
              'id': 3,
              'text': 'Portable charger',
              'url': 'https://amazon.com/portable-charger',
              'isCompleted': false,
              'completionCount': 45,
            },
            {
              'id': 4,
              'text': 'Travel-size toiletries',
              'url': null as String?,
              'isCompleted': false,
              'completionCount': 78,
            },
            {
              'id': 5,
              'text': 'Comfortable walking shoes',
              'url': null as String?,
              'isCompleted': false,
              'completionCount': 92,
            },
            {
              'id': 6,
              'text': 'First aid kit',
              'url': null as String?,
              'isCompleted': false,
              'completionCount': 34,
            },
          ],
        },
        {
          'id': '2',
          'title': 'Quick Healthy Breakfast Ideas',
          'description':
              'Start your day right with these nutritious and delicious breakfast options.',
          'authorId': 'demo_user',
          'category': 'Food',
          'isTrending': true,
          'likeCount': 89,
          'commentCount': 12,
          'viewCount': 567,
          'createdAt': FieldValue.serverTimestamp(),
          'imageUrls': [
            'https://picsum.photos/400/200?random=20',
            'https://picsum.photos/400/200?random=21',
            'https://picsum.photos/400/200?random=22',
            'https://picsum.photos/400/200?random=23',
            'https://picsum.photos/400/200?random=24',
            'https://picsum.photos/400/200?random=25',
            'https://picsum.photos/400/200?random=26',
          ],
          'items': [
            {
              'id': 1,
              'text': 'Overnight oats with berries',
              'url': 'https://recipe-site.com/overnight-oats',
              'isCompleted': false,
              'completionCount': 23,
            },
            {
              'id': 2,
              'text': 'Greek yogurt parfait',
              'url': null,
              'isCompleted': false,
              'completionCount': 18,
            },
            {
              'id': 3,
              'text': 'Avocado toast with eggs',
              'url': 'https://recipe-site.com/avocado-toast',
              'isCompleted': false,
              'completionCount': 31,
            },
            {
              'id': 4,
              'text': 'Smoothie bowl',
              'url': null,
              'isCompleted': false,
              'completionCount': 15,
            },
          ],
        },
        {
          'id': '3',
          'title': 'Gaming Setup Essentials',
          'description':
              'Build the ultimate gaming station with these must-have components.',
          'authorId': 'demo_user',
          'category': 'Gaming',
          'isTrending': false,
          'likeCount': 67,
          'commentCount': 8,
          'viewCount': 234,
          'createdAt': FieldValue.serverTimestamp(),
          'imageUrls': [
            'https://picsum.photos/400/200?random=30',
            'https://picsum.photos/400/200?random=31',
            'https://picsum.photos/400/200?random=32',
            'https://picsum.photos/400/200?random=33',
            'https://picsum.photos/400/200?random=34',
            'https://picsum.photos/400/200?random=35',
            'https://picsum.photos/400/200?random=36',
            'https://picsum.photos/400/200?random=37',
          ],
          'items': [
            {
              'id': 1,
              'text': 'Gaming monitor (144Hz+)',
              'url': 'https://amazon.com/gaming-monitor',
              'isCompleted': false,
              'completionCount': 12,
            },
            {
              'id': 2,
              'text': 'Mechanical keyboard',
              'url': 'https://amazon.com/mechanical-keyboard',
              'isCompleted': false,
              'completionCount': 19,
            },
            {
              'id': 3,
              'text': 'Gaming mouse with RGB',
              'url': 'https://amazon.com/gaming-mouse',
              'isCompleted': false,
              'completionCount': 25,
            },
            {
              'id': 4,
              'text': 'Gaming headset',
              'url': null,
              'isCompleted': false,
              'completionCount': 16,
            },
            {
              'id': 5,
              'text': 'Streaming microphone',
              'url': 'https://amazon.com/streaming-mic',
              'isCompleted': false,
              'completionCount': 8,
            },
          ],
        },
        {
          'id': '4',
          'title': 'Study Techniques That Actually Work',
          'description':
              'Evidence-based study methods to improve your learning efficiency.',
          'authorId': 'demo_user',
          'category': 'Education',
          'isTrending': false,
          'likeCount': 45,
          'commentCount': 6,
          'viewCount': 189,
          'createdAt': FieldValue.serverTimestamp(),
          'imageUrls': [
            'https://picsum.photos/400/200?random=40',
            'https://picsum.photos/400/200?random=41',
            'https://picsum.photos/400/200?random=42',
            'https://picsum.photos/400/200?random=43',
            'https://picsum.photos/400/200?random=44',
            'https://picsum.photos/400/200?random=45',
            'https://picsum.photos/400/200?random=46',
            'https://picsum.photos/400/200?random=47',
          ],
          'items': [
            {
              'id': 1,
              'text': 'Pomodoro Technique (25/5)',
              'url': 'https://study-methods.com/pomodoro',
              'isCompleted': false,
              'completionCount': 34,
            },
            {
              'id': 2,
              'text': 'Active recall with flashcards',
              'url': null,
              'isCompleted': false,
              'completionCount': 28,
            },
            {
              'id': 3,
              'text': 'Spaced repetition',
              'url': 'https://study-methods.com/spaced-repetition',
              'isCompleted': false,
              'completionCount': 19,
            },
            {
              'id': 4,
              'text': 'Mind mapping',
              'url': null,
              'isCompleted': false,
              'completionCount': 22,
            },
            {
              'id': 5,
              'text': 'Teaching others (Feynman Technique)',
              'url': null,
              'isCompleted': false,
              'completionCount': 15,
            },
          ],
        },
        {
          'id': '5',
          'title': '30-Day Fitness Challenge',
          'description':
              'Transform your fitness routine with this progressive workout plan.',
          'authorId': 'demo_user',
          'category': 'Fitness',
          'isTrending': false,
          'likeCount': 78,
          'commentCount': 14,
          'viewCount': 456,
          'createdAt': FieldValue.serverTimestamp(),
          'imageUrls': [
            'https://picsum.photos/400/200?random=50',
            'https://picsum.photos/400/200?random=51',
            'https://picsum.photos/400/200?random=52',
            'https://picsum.photos/400/200?random=53',
            'https://picsum.photos/400/200?random=54',
            'https://picsum.photos/400/200?random=55',
          ],
          'items': [
            {
              'id': 1,
              'text': 'Week 1: Foundation building',
              'url': 'https://fitness-app.com/week1',
              'isCompleted': false,
              'completionCount': 67,
            },
            {
              'id': 2,
              'text': 'Week 2: Strength focus',
              'url': 'https://fitness-app.com/week2',
              'isCompleted': false,
              'completionCount': 45,
            },
            {
              'id': 3,
              'text': 'Week 3: Endurance training',
              'url': 'https://fitness-app.com/week3',
              'isCompleted': false,
              'completionCount': 38,
            },
            {
              'id': 4,
              'text': 'Week 4: Peak performance',
              'url': 'https://fitness-app.com/week4',
              'isCompleted': false,
              'completionCount': 29,
            },
          ],
        },
      ];

      // Check if demo posts already exist
      final existingDocs = await _firestore.collection('demo_posts').get();
      if (existingDocs.docs.isNotEmpty) {
        debugPrint('Demo posts already exist, skipping initialization');
        return;
      }

      // Add demo posts to database
      for (final post in demoPosts) {
        await _firestore
            .collection('demo_posts')
            .doc(post['id'] as String)
            .set(post);
        debugPrint('Added demo post: ${post['title']}');
      }

      debugPrint('Demo posts initialized successfully');
    } catch (e) {
      debugPrint('Error initializing demo posts: $e');
    }
  }

  // Check if demo posts exist in database
  static Future<bool> demoPostsExist() async {
    try {
      final snapshot = await _firestore.collection('demo_posts').limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking demo posts: $e');
      return false;
    }
  }
}
