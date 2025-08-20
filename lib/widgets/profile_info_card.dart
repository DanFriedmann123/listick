import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../services/avatar_upload_service.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/settings_screen.dart';

class ProfileInfoCard extends StatefulWidget {
  final User user;
  final Map<String, dynamic>? userProfile;
  final bool isOwnProfile;
  final VoidCallback? onAvatarUpdated;

  const ProfileInfoCard({
    super.key,
    required this.user,
    this.userProfile,
    required this.isOwnProfile,
    this.onAvatarUpdated,
  });

  @override
  State<ProfileInfoCard> createState() => _ProfileInfoCardState();
}

class _ProfileInfoCardState extends State<ProfileInfoCard> {
  final UserService _userService = UserService();
  final AvatarUploadService _avatarService = AvatarUploadService();
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar Section
            _buildAvatarSection(),

            const SizedBox(height: 24),

            // User Info Section
            _buildUserInfoSection(),

            const SizedBox(height: 24),

            // Edit Profile Button (only for own profile)
            if (widget.isOwnProfile) _buildEditProfileButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Row(
      children: [
        // Avatar (centered)
        Expanded(
          child: Center(
            child: Stack(
              children: [
                // Avatar
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE91E63).withValues(alpha: 0.3),
                      width: 4,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: const Color(
                      0xFFE91E63,
                    ).withValues(alpha: 0.1),
                    child:
                        _isUploading
                            ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFE91E63),
                              ),
                            )
                            : (widget.userProfile?['avatarUrl'] != null &&
                                    widget
                                        .userProfile!['avatarUrl']
                                        .isNotEmpty) ||
                                (widget.user.photoURL != null &&
                                    widget.user.photoURL!.isNotEmpty)
                            ? ClipOval(
                              child: Image.network(
                                widget.userProfile?['avatarUrl'] ??
                                    widget.user.photoURL!,
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildAvatarFallback();
                                },
                              ),
                            )
                            : _buildAvatarFallback(),
                  ),
                ),

                // Camera Icon (only for own profile)
                if (widget.isOwnProfile)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _handleAvatarTap,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE91E63),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF0A0A0A),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFE91E63,
                              ).withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Settings Button (only for own profile, positioned to the far right)
        if (widget.isOwnProfile)
          Container(
            margin: const EdgeInsets.only(left: 16),
            child: IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.settings, color: Colors.white, size: 24),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarFallback() {
    final displayName =
        widget.user.displayName ?? widget.user.email?.split('@')[0] ?? 'U';
    return Text(
      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
      style: const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: Color(0xFFE91E63),
      ),
    );
  }

  Widget _buildUserInfoSection() {
    final displayName =
        widget.userProfile?['displayName'] ?? widget.user.displayName ?? 'User';
    final username =
        widget.userProfile?['username'] ??
        widget.user.email?.split('@')[0] ??
        'user';

    return Column(
      children: [
        // Display Name
        Text(
          displayName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // Username
        Text(
          '@$username',
          style: TextStyle(fontSize: 16, color: Colors.grey[400]),
          textAlign: TextAlign.center,
        ),

        // Bio section
        const SizedBox(height: 16),
        if (widget.userProfile?['bio'] != null &&
            widget.userProfile!['bio'].isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: (Colors.grey[800] ?? Colors.grey).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.userProfile!['bio'],
              style: const TextStyle(fontSize: 14, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: (Colors.grey[800] ?? Colors.grey).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'No bio yet',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEditProfileButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (context) => EditProfileScreen(
                    user: widget.user,
                    userProfile: widget.userProfile,
                    onProfileUpdated: widget.onAvatarUpdated ?? () {},
                  ),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFE91E63)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Edit Profile',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // Handle avatar tap for image upload
  Future<void> _handleAvatarTap() async {
    if (_isUploading) return;

    // Early context check
    if (!mounted || !context.mounted) {
      return;
    }

    // Validate user object
    if (widget.user.uid.isEmpty) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Invalid user data'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      if (mounted) {
        setState(() {
          _isUploading = true;
        });
      }

      // Show image source picker dialog
      if (!mounted || !context.mounted) {
        return;
      }

      final imageFile = await _avatarService.showImageSourceDialog(context);

      if (imageFile != null && mounted && context.mounted) {
        // Upload avatar
        final avatarUrl = await _avatarService.uploadAvatar(
          imageFile,
          widget.user.uid,
        );

        if (mounted && context.mounted) {
          // Update user profile with new avatar URL
          await _userService.updateUserProfile(avatarUrl: avatarUrl);

          // Update Firebase Auth user photoURL
          await widget.user.updatePhotoURL(avatarUrl);

          // Update Firebase Auth user display name if needed
          if (widget.user.displayName == null ||
              widget.user.displayName!.isEmpty) {
            await widget.user.updateDisplayName(
              widget.user.email?.split('@')[0] ?? 'User',
            );
          }

          // Force rebuild to show new avatar
          if (mounted) {
            setState(() {});
          }

          // Call callback to refresh parent widget
          if (widget.onAvatarUpdated != null) {
            widget.onAvatarUpdated!();
          }

          // Show success message
          if (mounted && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Avatar updated successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating avatar: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }
}
