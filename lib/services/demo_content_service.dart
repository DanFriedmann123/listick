import 'package:flutter/material.dart';
import '../widgets/enhanced_post_card.dart';
import '../models/list_item.dart';
import 'item_completion_service.dart';
import 'database_interaction_service.dart';
import '../widgets/comment_dialog.dart';

class DemoContentService {
  static final DemoContentService _instance = DemoContentService._internal();
  factory DemoContentService() => _instance;
  DemoContentService._internal();

  // Demo users
  final List<Map<String, dynamic>> _demoUsers = [
    {
      'id': '1',
      'name': 'TravelGuru',
      'avatar': 'https://picsum.photos/200/200?random=1',
      'bio': 'Exploring the world, one list at a time ✈️',
      'followers': 1247,
      'following': 89,
      'posts': 23,
    },
    {
      'id': '2',
      'name': 'FoodieChef',
      'avatar': 'https://picsum.photos/200/200?random=2',
      'bio': 'Culinary adventures and recipe collections 🍳',
      'followers': 892,
      'following': 156,
      'posts': 45,
    },
    {
      'id': '3',
      'name': 'TechGeek',
      'avatar': 'https://picsum.photos/200/200?random=3',
      'bio': 'Gadgets, gaming, and tech reviews 🎮',
      'followers': 567,
      'following': 78,
      'posts': 31,
    },
    {
      'id': '4',
      'name': 'StudyBuddy',
      'avatar': 'https://picsum.photos/200/200?random=4',
      'bio': 'Academic tips and study resources 📚',
      'followers': 445,
      'following': 92,
      'posts': 18,
    },
    {
      'id': '5',
      'name': 'FitnessPro',
      'avatar': 'https://picsum.photos/200/200?random=5',
      'bio': 'Workout routines and healthy living 💪',
      'followers': 678,
      'following': 134,
      'posts': 27,
    },
  ];

  // Demo posts
  final List<Map<String, dynamic>> _demoPosts = [
    {
      'id': '1',
      'title': 'Ultimate Travel Packing List',
      'description':
          'Everything you need for your next adventure, organized by category and priority.',
      'authorId': '1',
      'category': 'Travel',
      'isTrending': true,
      'likeCount': 156,
      'commentCount': 23,
      'viewCount': 1247,
      'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
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
          'url': null,
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
          'url': null,
          'isCompleted': false,
          'completionCount': 78,
        },
        {
          'id': 5,
          'text': 'Comfortable walking shoes',
          'url': null,
          'isCompleted': false,
          'completionCount': 92,
        },
        {
          'id': 6,
          'text': 'First aid kit',
          'url': null,
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
      'authorId': '2',
      'category': 'Food',
      'isTrending': true,
      'likeCount': 89,
      'commentCount': 12,
      'viewCount': 567,
      'createdAt': DateTime.now().subtract(const Duration(hours: 4)),
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
      'authorId': '3',
      'category': 'Gaming',
      'isTrending': false,
      'likeCount': 67,
      'commentCount': 8,
      'viewCount': 234,
      'createdAt': DateTime.now().subtract(const Duration(days: 1)),
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
      'authorId': '4',
      'category': 'Education',
      'isTrending': false,
      'likeCount': 45,
      'commentCount': 6,
      'viewCount': 189,
      'createdAt': DateTime.now().subtract(const Duration(days: 2)),
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
      'authorId': '5',
      'category': 'Fitness',
      'isTrending': false,
      'likeCount': 78,
      'commentCount': 14,
      'viewCount': 456,
      'createdAt': DateTime.now().subtract(const Duration(days: 3)),
      'imageUrls': [
        'https://picsum.photos/400/200?random=50',
        'https://picsum.photos/400/200?random=51',
        'https://picsum.photos/400/200?random=52',
        'https://picsum.photos/400/200?random=53',
        'https://picsum.photos/400/200?random=54',
        'https://picsum.photos/400/200?random=55',
        'https://picsum.photos/400/200?random=56',
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

  // Get demo users
  List<Map<String, dynamic>> getDemoUsers() {
    return List.from(_demoUsers);
  }

  // Get demo posts
  List<Map<String, dynamic>> getDemoPosts() {
    return List.from(_demoPosts);
  }

  // Get trending posts
  List<Map<String, dynamic>> getTrendingPosts() {
    return _demoPosts.where((post) => post['isTrending'] == true).toList();
  }

  // Get posts by category
  List<Map<String, dynamic>> getPostsByCategory(String category) {
    return _demoPosts.where((post) => post['category'] == category).toList();
  }

  // Get user by ID
  Map<String, dynamic>? getUserById(String id) {
    try {
      return _demoUsers.firstWhere((user) => user['id'] == id);
    } catch (e) {
      return null;
    }
  }

  // Get post by ID
  Map<String, dynamic>? getPostById(String id) {
    try {
      return _demoPosts.firstWhere((post) => post['id'] == id);
    } catch (e) {
      return null;
    }
  }

  // Search posts
  List<Map<String, dynamic>> searchPosts(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _demoPosts.where((post) {
      return post['title'].toLowerCase().contains(lowercaseQuery) ||
          post['description'].toLowerCase().contains(lowercaseQuery) ||
          post['category'].toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Get posts by user
  List<Map<String, dynamic>> getPostsByUser(String userId) {
    return _demoPosts.where((post) => post['authorId'] == userId).toList();
  }

  // Convert demo post to ListItem objects
  List<ListItem> _convertToListItemList(List<dynamic> items) {
    return items
        .map(
          (item) => ListItem(
            id: item['id'],
            text: item['text'],
            url: item['url'],
            isCompleted: item['isCompleted'] ?? false,
            completionCount: item['completionCount'] ?? 0,
          ),
        )
        .toList();
  }

  // Build demo post widgets
  List<Widget> buildDemoPostWidgets({
    String? category,
    bool trendingOnly = false,
    String? userId,
    String? searchQuery,
  }) {
    List<Map<String, dynamic>> posts = _demoPosts;

    // Apply filters
    if (category != null) {
      posts = posts.where((post) => post['category'] == category).toList();
    }
    if (trendingOnly) {
      posts = posts.where((post) => post['isTrending'] == true).toList();
    }
    if (userId != null) {
      posts = posts.where((post) => post['authorId'] == userId).toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      posts = searchPosts(searchQuery);
    }

    return posts.map((post) {
      final author = getUserById(post['authorId']);
      final items = _convertToListItemList(post['items']);

      return _DemoPostCardWrapper(
        key: ValueKey('demo_${post['id']}'),
        postData: post,
        author: author,
        items: items,
      );
    }).toList();
  }

  // Get categories
  List<String> getCategories() {
    return _demoPosts
        .map((post) => post['category'] as String)
        .toSet()
        .toList();
  }

  // Get trending hashtags
  List<String> getTrendingHashtags() {
    return [
      '#TravelGoals',
      '#FoodieLife',
      '#GamingSetup',
      '#StudyTips',
      '#FitnessRoutine',
      '#TechGadgets',
      '#BookClub',
      '#MovieNight',
      '#DIYProjects',
      '#PetCare',
    ];
  }
}

class _DemoPostCardWrapper extends StatefulWidget {
  final Map<String, dynamic> postData;
  final Map<String, dynamic>? author;
  final List<ListItem> items;

  const _DemoPostCardWrapper({
    super.key,
    required this.postData,
    required this.author,
    required this.items,
  });

  @override
  State<_DemoPostCardWrapper> createState() => _DemoPostCardWrapperState();
}

class _DemoPostCardWrapperState extends State<_DemoPostCardWrapper> {
  Map<int, bool> _itemCompletions = {};
  bool _isLoadingCompletions = true;
  bool _isLiked = false;
  int _actualCommentCount = 0;
  bool _isCommentDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _loadItemCompletions();
    _loadInteractionState();
  }

  Future<void> _loadItemCompletions() async {
    try {
      final completions = await ItemCompletionService.getItemCompletions(
        'demo_${widget.postData['id']}',
      );
      if (mounted) {
        setState(() {
          _itemCompletions = completions;
          _isLoadingCompletions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCompletions = false;
        });
      }
    }
  }

  Future<void> _loadInteractionState() async {
    try {
      final isLiked = await DatabaseInteractionService.isPostLiked(
        widget.postData['id'],
        isDemoPost: true,
      );
      final commentCount = await DatabaseInteractionService.getCommentCount(
        widget.postData['id'],
        isDemoPost: true,
      );

      if (mounted) {
        setState(() {
          _isLiked = isLiked;
          _actualCommentCount = widget.postData['commentCount'] + commentCount;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCompletions) {
      return const Center(child: CircularProgressIndicator());
    }

    return EnhancedPostCard(
      key: ValueKey('demo_${widget.postData['id']}'),
      postId: 'demo_${widget.postData['id']}',
      title: widget.postData['title'],
      description: widget.postData['description'],
      items: widget.items,
      likeCount: widget.postData['likeCount'],
      commentCount: widget.postData['commentCount'],
      viewCount: widget.postData['viewCount'],
      isTrending: widget.postData['isTrending'],
      isBookmarked: false,
      imageUrls: widget.postData['imageUrls'] ?? [],
      videoUrl: null,
      category: widget.postData['category'],
      createdAt: widget.postData['createdAt'],
      authorName: widget.author?['name'] ?? 'Unknown User',
      authorAvatar: widget.author?['avatar'],
      itemCompletions: _itemCompletions,
      onTap: () {
        debugPrint('Tapped on demo post: ${widget.postData['title']}');
      },
      onLike: () async {
        try {
          final newLikeState = !_isLiked;
          setState(() {
            _isLiked = newLikeState;
          });

          await DatabaseInteractionService.toggleLike(
            widget.postData['id'],
            newLikeState,
            isDemoPost: true,
          );
        } catch (e) {
          // Revert on error
          setState(() {
            _isLiked = !_isLiked;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error updating like: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      onBookmark: () {
        debugPrint('Bookmarked demo post: ${widget.postData['title']}');
      },
      onShare: () {
        debugPrint('Shared demo post: ${widget.postData['title']}');
      },
      onComment: () async {
        if (_isCommentDialogOpen) {
          debugPrint('Demo comment dialog already open, ignoring tap');
          return;
        }

        debugPrint(
          'Opening comment dialog for demo post: ${widget.postData['id']}',
        );
        setState(() {
          _isCommentDialogOpen = true;
        });

        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder:
              (context) => CommentDialog(
                postId: widget.postData['id'],
                postTitle: widget.postData['title'],
                initialCommentCount: _actualCommentCount,
                isDemoPost: true,
              ),
        );

        debugPrint('Demo comment dialog closed with result: $result');

        if (mounted) {
          setState(() {
            _isCommentDialogOpen = false;
          });

          // Refresh comment count after dialog closes
          try {
            final commentCount =
                await DatabaseInteractionService.getCommentCount(
                  widget.postData['id'],
                  isDemoPost: true,
                );
            if (mounted) {
              setState(() {
                _actualCommentCount =
                    widget.postData['commentCount'] + commentCount;
              });
            }
          } catch (e) {
            debugPrint('Error refreshing demo comment count: $e');
          }
        }
      },
      onItemToggle: (itemId, isCompleted) async {
        try {
          // Save completion state to local storage using demo post ID
          await ItemCompletionService.saveItemCompletion(
            'demo_${widget.postData['id']}',
            itemId,
            isCompleted,
          );

          // Update local state to reflect the change
          setState(() {
            _itemCompletions[itemId] = isCompleted;
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error saving completion: $e')),
            );
          }
        }
      },
    );
  }
}
