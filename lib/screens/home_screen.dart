import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../services/demo_content_service.dart';
import '../services/post_service.dart';
import '../services/image_preload_service.dart';
import '../models/post.dart';
import '../widgets/enhanced_post_card.dart';
import '../models/list_item.dart';
import '../services/item_completion_service.dart';
import '../widgets/profile_info_card.dart';
import '../widgets/profile_stats.dart';
import '../widgets/profile_tabs.dart';
import '../widgets/search_discovery_widget.dart';
import '../widgets/user_activity_widget.dart';
import 'create_post_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  final DemoContentService _demoContentService = DemoContentService();
  final PostService _postService = PostService();
  final ImagePreloadService _imagePreloadService = ImagePreloadService();
  final ScrollController _followingScrollController = ScrollController();
  final ScrollController _inspirationScrollController = ScrollController();
  Map<String, dynamic>? _userProfile;
  late TabController _tabController;
  bool _isProfileLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _followingScrollController.dispose();
    _inspirationScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final profile = await _userService.getUserProfile(user.uid);
        if (mounted) {
          setState(() {
            _userProfile = profile;
            _isProfileLoading = false;
          });
        }
      }
    } catch (e) {
      // Handle error silently
      if (mounted) {
        setState(() {
          _isProfileLoading = false;
        });
      }
    }
  }

  /// Preload images for a list of posts
  void _preloadPostImages(List<Post> posts) {
    // Collect all image URLs from all posts
    final List<String> allImageUrls = [];

    for (final post in posts) {
      // Add post images
      allImageUrls.addAll(post.imageUrls);

      // Add author avatar if it exists
      if (post.authorAvatar != null && post.authorAvatar!.isNotEmpty) {
        allImageUrls.add(post.authorAvatar!);
      }
    }

    // Remove duplicates and empty URLs
    final uniqueImageUrls =
        allImageUrls.where((url) => url.isNotEmpty).toSet().toList();

    if (uniqueImageUrls.isNotEmpty) {
      // Preload images asynchronously (don't wait for completion)
      _imagePreloadService.preloadImages(uniqueImageUrls).catchError((error) {
        print('Error preloading images: $error');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header with profile info and + button
            _buildProfileHeader(user, theme),

            // Divider
            Container(
              height: 0.5,
              color: Colors.white.withValues(alpha: 0.1),
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),

            // Content based on selected index
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildFollowingTab(theme), // Following feed
                  _buildInspirationTab(theme), // Inspiration feed
                  _buildProfileTab(theme), // Profile section
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildCustomBottomNavigation(),
    );
  }

  Widget _buildProfileHeader(User? user, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Profile avatar (clickable to go to profile tab)
          GestureDetector(
            onTap: () {
              setState(() => _selectedIndex = 2);
            },
            child: CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFE91E63).withValues(alpha: 0.2),
              backgroundImage:
                  _userProfile?['avatarUrl'] != null
                      ? NetworkImage(_userProfile!['avatarUrl'])
                      : null,
              child:
                  _userProfile?['avatarUrl'] == null
                      ? Text(
                        (_userProfile?['displayName']?.isNotEmpty == true
                            ? _userProfile!['displayName'][0].toUpperCase()
                            : user?.email?.isNotEmpty == true
                            ? user!.email![0].toUpperCase()
                            : 'U'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE91E63),
                        ),
                      )
                      : null,
            ),
          ),

          const SizedBox(width: 16),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userProfile?['displayName'] ?? user?.displayName ?? 'User',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // Username removed to avoid duplication with profile page
              ],
            ),
          ),

          // + Button (moved from floating action button)
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreatePostScreen(),
                  ),
                );
              },
              icon: Icon(Icons.add, color: theme.colorScheme.onPrimary),
              iconSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowingTab(ThemeData theme) {
    return SingleChildScrollView(
      controller: _followingScrollController,
      child: Column(
        children: [
          // Following Posts Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'From People You Follow',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                // Posts from users you follow
                StreamBuilder<List<Post>>(
                  stream: _postService.getFollowingPostsStream(limit: 20),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading following posts: ${snapshot.error}',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final followingPosts = snapshot.data ?? [];

                    // Preload images for following posts
                    if (followingPosts.isNotEmpty) {
                      _preloadPostImages(followingPosts);
                    }

                    if (followingPosts.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.people,
                              size: 64,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No posts from people you follow',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Follow some people to see their posts here!',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children:
                          followingPosts
                              .map((post) => _buildPostCard(post, theme))
                              .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspirationTab(ThemeData theme) {
    return SingleChildScrollView(
      controller: _inspirationScrollController,
      child: Column(
        children: [
          // Search and Discovery Widget
          SearchDiscoveryWidget(
            onSearch: (query) {
              // Handle search
              debugPrint('Searching for: $query');
            },
            onHashtagTap: (hashtag) {
              // Handle hashtag tap
              debugPrint('Tapped hashtag: $hashtag');
            },
            onTrendingTap: () {
              // Handle trending tap
              debugPrint('Tapped trending');
            },
          ),

          const SizedBox(height: 24),

          // User Activity Widget
          UserActivityWidget(
            onViewAllActivity: () {
              // Handle view all activity
              debugPrint('View all activity');
            },
            onViewAchievements: () {
              // Handle view achievements
              debugPrint('View achievements');
            },
          ),

          const SizedBox(height: 24),

          // Popular Now Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Popular Now',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () {
                        // Handle view all trending
                        debugPrint('View all trending');
                      },
                      child: Text(
                        'View all',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Popular posts from all users (based on engagement)
                StreamBuilder<List<Post>>(
                  stream: _postService.getPopularPostsStream(limit: 5),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading popular posts: ${snapshot.error}',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final popularPosts = snapshot.data ?? [];

                    // Preload images for popular posts
                    if (popularPosts.isNotEmpty) {
                      _preloadPostImages(popularPosts);
                    }

                    if (popularPosts.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              Icons.trending_up,
                              size: 48,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No posts yet',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Posts will appear here as users engage with content',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children:
                          popularPosts
                              .map((post) => _buildPostCard(post, theme))
                              .toList(),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Recent posts from all users
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Recent Posts from Everyone',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () {
                        // Handle view all recent posts
                        debugPrint('View all recent posts');
                      },
                      child: Text(
                        'View all',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Recent posts from all users
                StreamBuilder<List<Post>>(
                  stream: _postService.getPostsStream(limit: 5),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading recent posts: ${snapshot.error}',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final recentPosts = snapshot.data ?? [];

                    // Preload images for recent posts
                    if (recentPosts.isNotEmpty) {
                      _preloadPostImages(recentPosts);
                    }

                    if (recentPosts.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              Icons.post_add,
                              size: 48,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No posts yet',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Be the first to create a post!',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children:
                          recentPosts
                              .map((post) => _buildPostCard(post, theme))
                              .toList(),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Category-based recommendations
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommended for You',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                // Show posts from different categories
                ..._demoContentService.buildDemoPostWidgets(category: 'Travel'),
                const SizedBox(height: 16),
                ..._demoContentService.buildDemoPostWidgets(category: 'Food'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discover More',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.explore,
                        title: 'Explore Categories',
                        subtitle: 'Find content by topic',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Explore categories - Coming soon!',
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.trending_up,
                        title: 'Trending Lists',
                        subtitle: 'See what\'s popular',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Trending lists - Coming soon!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        theme: theme,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPostCard(Post post, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: _PostCardWithCompletions(post: post, theme: theme),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab(ThemeData theme) {
    if (_isProfileLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
        ),
      );
    }

    final user = _authService.currentUser;
    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Unable to load profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There was an issue loading your profile data.',
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadUserProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Info Card
          ProfileInfoCard(
            user: user,
            userProfile: _userProfile,
            isOwnProfile: true,
            onAvatarUpdated: _loadUserProfile,
          ),

          const SizedBox(height: 24),

          // Profile Stats
          ProfileStats(
            postsCount: 0, // Get from posts service
            followersCount: 0, // Get from saved lists service
            followingCount: 0, // Get from settings service
            onTabChange: (index) {
              _tabController.animateTo(index);
            },
          ),

          const SizedBox(height: 16),

          // Tabs Content
          ProfileTabs(
            tabController: _tabController,
            isOwnProfile: true,
            userId: user.uid,
            onPostClick: null,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Following Tab
              _buildNavItem(
                icon: Icons.people,
                label: 'Following',
                isSelected: _selectedIndex == 0,
                onTap: () => setState(() => _selectedIndex = 0),
              ),

              // Middle Circle Tab (Inspiration)
              _buildMiddleTab(),

              // Profile Tab
              _buildNavItem(
                icon: Icons.person,
                label: 'Profile',
                isSelected: _selectedIndex == 2,
                onTap: () => setState(() => _selectedIndex = 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFFE91E63) : Colors.grey[400],
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? const Color(0xFFE91E63) : Colors.grey[400],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiddleTab() {
    final isSelected = _selectedIndex == 1;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = 1),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient:
              isSelected
                  ? const LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                  )
                  : null,
          color: isSelected ? null : Colors.grey[800],
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[600]!,
            width: 2,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: const Color(0xFFE91E63).withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                  : null,
        ),
        child: Icon(
          Icons.lightbulb,
          color: isSelected ? Colors.white : Colors.grey[400],
          size: 28,
        ),
      ),
    );
  }
}

class _PostCardWithCompletions extends StatefulWidget {
  final Post post;
  final ThemeData theme;

  const _PostCardWithCompletions({required this.post, required this.theme});

  @override
  State<_PostCardWithCompletions> createState() =>
      _PostCardWithCompletionsState();
}

class _PostCardWithCompletionsState extends State<_PostCardWithCompletions> {
  Map<int, bool> _itemCompletions = {};
  bool _isLoadingCompletions = true;

  @override
  void initState() {
    super.initState();
    _loadItemCompletions();
  }

  Future<void> _loadItemCompletions() async {
    try {
      final completions = await ItemCompletionService.getItemCompletions(
        widget.post.id,
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

  void refreshCompletions() {
    _loadItemCompletions();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCompletions) {
      return const Center(child: CircularProgressIndicator());
    }

    return EnhancedPostCard(
      key: ValueKey(widget.post.id),
      postId: widget.post.id,
      title: widget.post.title,
      description: widget.post.description,
      items:
          widget.post.items
              .map(
                (item) => ListItem(
                  id: item.id,
                  text: item.text,
                  url: item.url,
                  isCompleted: item.isCompleted,
                  completionCount: item.completionCount,
                ),
              )
              .toList(),
      likeCount: widget.post.likeCount,
      commentCount: widget.post.commentCount,
      viewCount: widget.post.viewCount,
      isTrending: widget.post.isTrending,
      isBookmarked: widget.post.bookmarkedBy.contains(
        FirebaseAuth.instance.currentUser?.uid ?? '',
      ),
      imageUrls: widget.post.imageUrls,
      videoUrl: widget.post.videoUrl,
      category: widget.post.category,
      createdAt: widget.post.createdAt,
      authorId: widget.post.authorId,
      authorName: widget.post.authorName,
      authorAvatar: widget.post.authorAvatar,
      itemCompletions: _itemCompletions,
      onTap: () {
        // TODO: Navigate to post detail
        debugPrint('Tapped on post: ${widget.post.title}');
      },
      // onLike and onBookmark are handled internally by EnhancedPostCard
      onShare: () {
        // TODO: Implement share functionality
        debugPrint('Share post: ${widget.post.title}');
      },
      onComment: () {
        // TODO: Navigate to comments
        debugPrint('Comment on post: ${widget.post.title}');
      },
      onItemToggle: (itemId, isCompleted) async {
        try {
          // Save completion state to local storage
          await ItemCompletionService.saveItemCompletion(
            widget.post.id,
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
      onRefresh: refreshCompletions,
    );
  }
}
