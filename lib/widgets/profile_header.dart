import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final VoidCallback onBack;
  final bool isOwnProfile;
  final VoidCallback? onSettings;

  const ProfileHeader({
    super.key,
    required this.onBack,
    required this.isOwnProfile,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A).withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Back Button
              IconButton(
                onPressed: onBack,
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                ),
              ),

              // Title
              Expanded(
                child: Center(
                  child: Text(
                    'Profile',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Settings Button (only for own profile)
              if (isOwnProfile && onSettings != null)
                IconButton(
                  onPressed: onSettings,
                  icon: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                  ),
                )
              else
                const SizedBox(width: 48), // Placeholder for consistent spacing
            ],
          ),
        ),
      ),
    );
  }
}
