import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/post_service.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_info_card.dart';
import '../widgets/profile_stats.dart';
import '../widgets/profile_tabs.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String? userName;
  final String? userAvatar;
  final VoidCallback onBack;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.userName,
    this.userAvatar,
    required this.onBack,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _authService = AuthService();
  final _userService = UserService();
  final _postService = PostService();
  User? _currentUser;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isFollowLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        // Load the target user's profile data
        final profile = await _userService.getUserProfile(widget.userId);

        // Check if current user is following this user
        final isFollowing = await _userService.isFollowing(
          currentUser.uid,
          widget.userId,
        );

        setState(() {
          _currentUser = currentUser;
          _userProfile = profile;
          _isFollowing = isFollowing;
        });
      }
    } catch (e) {
      // Handle error silently
      debugPrint('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_isFollowLoading) return;

    setState(() {
      _isFollowLoading = true;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        if (_isFollowing) {
          await _userService.unfollowUser(currentUser.uid, widget.userId);
        } else {
          await _userService.followUser(currentUser.uid, widget.userId);
        }

        setState(() {
          _isFollowing = !_isFollowing;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isFollowLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_userProfile == null) {
      return _buildErrorScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            ProfileHeader(
              onBack: widget.onBack,
              isOwnProfile: false,
              onSettings: null,
            ),

            // Profile Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile Info Card
                    ProfileInfoCard(
                      user: _currentUser!,
                      userProfile: _userProfile,
                      isOwnProfile: false,
                      onAvatarUpdated: null,
                    ),

                    const SizedBox(height: 16),

                    // Follow Button
                    _buildFollowButton(),

                    const SizedBox(height: 24),

                    // Profile Stats
                    StreamBuilder<int>(
                      stream: _postService
                          .getPostsByUserStream(widget.userId)
                          .map((posts) => posts.length),
                      builder: (context, snapshot) {
                        final postsCount = snapshot.data ?? 0;
                        return ProfileStats(
                          postsCount: postsCount,
                          followersCount: _userProfile?['followersCount'] ?? 0,
                          followingCount: _userProfile?['followingCount'] ?? 0,
                          onTabChange: (index) {
                            _tabController.animateTo(index);
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Tabs Content
                    ProfileTabs(
                      tabController: _tabController,
                      isOwnProfile: false,
                      userId: widget.userId,
                      onPostClick: null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowButton() {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isFollowLoading ? null : _toggleFollow,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _isFollowing ? Colors.grey[800] : theme.colorScheme.primary,
          foregroundColor: _isFollowing ? Colors.white : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child:
            _isFollowLoading
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : Text(
                  _isFollowing ? 'Following' : 'Follow',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            ProfileHeader(
              onBack: widget.onBack,
              isOwnProfile: false,
              onSettings: null,
            ),
            Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            ProfileHeader(
              onBack: widget.onBack,
              isOwnProfile: false,
              onSettings: null,
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
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
                      'There was an issue loading this user\'s profile.',
                      style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadUserData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
