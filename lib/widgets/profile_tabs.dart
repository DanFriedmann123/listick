import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post.dart';
import '../models/list_item.dart';
import '../services/post_service.dart';
import '../services/image_preload_service.dart';
import '../widgets/enhanced_post_card.dart';
import '../screens/edit_post_screen.dart';

class ProfileTabs extends StatelessWidget {
  final TabController tabController;
  final bool isOwnProfile;
  final String? userId; // Add userId parameter
  final Function(String)? onPostClick;

  const ProfileTabs({
    super.key,
    required this.tabController,
    required this.isOwnProfile,
    this.userId,
    this.onPostClick,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Column(
        children: [
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
            child: TabBar(
              controller: tabController,
              indicator: BoxDecoration(
                color: const Color(0xFFE91E63),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE91E63).withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade400,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Lists'),
                Tab(text: 'Tagged'),
                Tab(text: 'Activity'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tab Content
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: tabController,
              children: [
                _buildListsTab(),
                _buildTaggedTab(),
                _buildActivityTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListsTab() {
    // Use the provided userId or fall back to current user's ID
    final targetUserId = userId ?? FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<List<Post>>(
      stream: PostService().getPostsByUserStream(targetUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading posts: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final posts = snapshot.data ?? [];

        // Preload images for user's posts
        if (posts.isNotEmpty) {
          _preloadPostImages(posts);
        }

        if (posts.isEmpty) {
          return _buildEmptyState(
            icon: Icons.list_alt,
            title: 'No lists yet',
            subtitle: 'Start creating some amazing lists!',
          );
        }

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return _buildEditablePostCard(context, post);
          },
        );
      },
    );
  }

  Widget _buildTaggedTab() {
    // Replace with actual tagged lists data
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: _buildEmptyState(
        icon: Icons.tag,
        title: 'No tagged lists yet',
        subtitle: 'Lists you\'re tagged in will appear here',
      ),
    );
  }

  Widget _buildActivityTab(BuildContext context) {
    // Show activity for all users, not just own profile

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // Recent Activity
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _buildActivityItem(
                  icon: Icons.favorite,
                  text: 'Liked "Travel Packing List"',
                  time: '2h ago',
                  color: Colors.red,
                ),
                const SizedBox(height: 8),
                _buildActivityItem(
                  icon: Icons.bookmark,
                  text: 'Saved "Gaming Setup"',
                  time: '1d ago',
                  color: Colors.purple,
                ),
                const SizedBox(height: 8),
                _buildActivityItem(
                  icon: Icons.person_add,
                  text: 'Started following @FoodieChef',
                  time: '2d ago',
                  color: Colors.green,
                ),
                const SizedBox(height: 8),
                _buildActivityItem(
                  icon: Icons.create,
                  text: 'Created "Weekend Shopping List"',
                  time: '3d ago',
                  color: Colors.blue,
                ),
                const SizedBox(height: 8),
                _buildActivityItem(
                  icon: Icons.share,
                  text: 'Shared "Movie Watchlist"',
                  time: '4d ago',
                  color: Colors.orange,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Activity Stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This Week',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildActivityStat(
                        icon: Icons.favorite,
                        label: 'Likes',
                        count: '12',
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActivityStat(
                        icon: Icons.bookmark,
                        label: 'Saved',
                        count: '8',
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActivityStat(
                        icon: Icons.create,
                        label: 'Created',
                        count: '3',
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String text,
    required String time,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                time,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityStat({
    required IconData icon,
    required String label,
    required String count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEditablePostCard(BuildContext context, Post post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: EnhancedPostCard(
        postId: post.id,
        title: post.title,
        description: post.description,
        items:
            post.items
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
        likeCount: post.likeCount,
        commentCount: post.commentCount,
        viewCount: post.viewCount,
        isTrending: post.isTrending,
        isBookmarked: false,
        imageUrls: post.imageUrls,
        videoUrl: post.videoUrl,
        category: post.category,
        createdAt: post.createdAt,
        authorId: post.authorId,
        authorName: post.authorName,
        authorAvatar: post.authorAvatar, // Always show avatar
        itemCompletions: null,
        onTap: () {
          if (onPostClick != null) {
            onPostClick!(post.id);
          }
        },
        onLike: () {
          // Handle like
        },
        onBookmark: () {
          // Handle bookmark
        },
        onShare: () {
          // Handle share
        },
        onComment: () {
          // Handle comment
        },
        onItemToggle: (itemId, isCompleted) {
          // Handle item toggle
        },
        // Add edit callback for own profile
        onEdit: isOwnProfile ? () => _editPost(context, post) : null,
      ),
    );
  }

  Future<void> _editPost(BuildContext context, Post post) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => EditPostScreen(post: post)),
    );

    if (result == true && context.mounted) {
      // Post was updated successfully, show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
      ImagePreloadService().preloadImages(uniqueImageUrls).catchError((error) {
        print('Error preloading images: $error');
      });
    }
  }
}
