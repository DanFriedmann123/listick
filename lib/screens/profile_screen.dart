import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/post_service.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_info_card.dart';
import '../widgets/profile_stats.dart';
import '../widgets/profile_tabs.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onBack;
  final bool isOwnProfile;
  final Function(String)? onPostClick;

  const ProfileScreen({
    super.key,
    required this.onBack,
    this.isOwnProfile = true,
    this.onPostClick,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _authService = AuthService();
  final _userService = UserService();
  User? _currentUser;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

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
      final user = _authService.currentUser;
      if (user != null) {
        // Load both Firebase Auth user and Firestore profile data
        final profile = await _userService.getUserProfile(user.uid);

        setState(() {
          _currentUser = user;
          _userProfile = profile;
        });
      }
    } catch (e) {
      // Handle error silently
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to refresh user data (called after avatar upload)
  Future<void> _refreshUserData() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        // Refresh both Firebase Auth user and Firestore profile data
        final profile = await _userService.getUserProfile(user.uid);

        setState(() {
          _currentUser = user;
          _userProfile = profile;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_currentUser == null) {
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
              isOwnProfile: widget.isOwnProfile,
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
                      isOwnProfile: widget.isOwnProfile,
                      onAvatarUpdated: _refreshUserData,
                    ),

                    const SizedBox(height: 24),

                    // Profile Stats
                    StreamBuilder<int>(
                      stream: PostService().getPostsByUserStream(FirebaseAuth.instance.currentUser?.uid ?? '').map((posts) => posts.length),
                      builder: (context, snapshot) {
                        final postsCount = snapshot.data ?? 0;
                        return ProfileStats(
                          postsCount: postsCount,
                          followersCount: 0, // Get from saved lists service
                          followingCount: 0, // Get from settings service
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
                      isOwnProfile: widget.isOwnProfile,
                      onPostClick: widget.onPostClick,
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

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            ProfileHeader(
              onBack: widget.onBack,
              isOwnProfile: widget.isOwnProfile,
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
              isOwnProfile: widget.isOwnProfile,
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
                      'There was an issue loading your profile data.',
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
