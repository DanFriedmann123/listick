import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationService = NotificationService();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Section
            _buildSectionHeader('Account', theme),
            const SizedBox(height: 12),
            _buildSettingsTile(
              icon: Icons.person,
              title: 'Edit Profile',
              subtitle: 'Update your profile information',
              onTap: () {
                // Navigate to edit profile
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Edit Profile - Coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              theme: theme,
            ),
            _buildSettingsTile(
              icon: Icons.lock,
              title: 'Privacy',
              subtitle: 'Manage your privacy settings',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Privacy Settings - Coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              theme: theme,
            ),
            _buildSettingsTile(
              icon: Icons.security,
              title: 'Security',
              subtitle: 'Two-factor authentication and more',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Security Settings - Coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              theme: theme,
            ),

            const SizedBox(height: 32),

            // Notifications Section
            _buildSectionHeader('Notifications', theme),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: notificationService.buildNotificationSettingsUI(),
            ),

            const SizedBox(height: 32),

            // Content Section
            _buildSectionHeader('Content', theme),
            const SizedBox(height: 12),
            _buildSettingsTile(
              icon: Icons.content_copy,
              title: 'Content Preferences',
              subtitle: 'Customize your feed and recommendations',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Content Preferences - Coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              theme: theme,
            ),
            _buildSettingsTile(
              icon: Icons.block,
              title: 'Blocked Users',
              subtitle: 'Manage blocked users and content',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Blocked Users - Coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              theme: theme,
            ),
            _buildSettingsTile(
              icon: Icons.report,
              title: 'Report Issues',
              subtitle: 'Report bugs or inappropriate content',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Report Issues - Coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              theme: theme,
            ),

            const SizedBox(height: 32),

            // App Section
            _buildSectionHeader('App', theme),
            const SizedBox(height: 12),
            _buildSettingsTile(
              icon: Icons.info,
              title: 'About Listick',
              subtitle: 'Version 0.1.0 - MVP',
              onTap: () {
                _showAboutDialog(context, theme);
              },
              theme: theme,
            ),
            _buildSettingsTile(
              icon: Icons.help,
              title: 'Help & Support',
              subtitle: 'Get help and contact support',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Help & Support - Coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              theme: theme,
            ),
            _buildSettingsTile(
              icon: Icons.description,
              title: 'Terms of Service',
              subtitle: 'Read our terms and conditions',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Terms of Service - Coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              theme: theme,
            ),
            _buildSettingsTile(
              icon: Icons.privacy_tip,
              title: 'Privacy Policy',
              subtitle: 'Read our privacy policy',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Privacy Policy - Coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              theme: theme,
            ),

            const SizedBox(height: 32),

            // Danger Zone
            _buildSectionHeader('Danger Zone', theme),
            const SizedBox(height: 12),
            _buildSettingsTile(
              icon: Icons.delete_forever,
              title: 'Delete Account',
              subtitle: 'Permanently delete your account and data',
              onTap: () {
                _showDeleteAccountDialog(context, theme);
              },
              theme: theme,
              isDestructive: true,
            ),

            const SizedBox(height: 32),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _signOut(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Sign Out',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeData theme,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color:
              isDestructive
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: isDestructive ? theme.colorScheme.error : null,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showAboutDialog(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            title: const Text('About Listick'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Listick is a social platform for creating, sharing, and discovering interactive lists.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Version: 0.1.0 (MVP)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Build: 2024.12.19',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            title: const Text('Delete Account'),
            content: const Text(
              'Are you sure you want to delete your account? This action cannot be undone and will permanently remove all your data.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Delete Account - Coming soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await AuthService().signOut();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
