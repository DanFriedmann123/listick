import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _likeNotificationsKey = 'like_notifications';
  static const String _commentNotificationsKey = 'comment_notifications';
  static const String _followNotificationsKey = 'follow_notifications';
  static const String _trendingNotificationsKey = 'trending_notifications';

  // Default notification preferences
  static const Map<String, bool> _defaultPreferences = {
    _notificationsEnabledKey: true,
    _likeNotificationsKey: true,
    _commentNotificationsKey: true,
    _followNotificationsKey: true,
    _trendingNotificationsKey: false,
  };

  // Get notification preferences
  Future<Map<String, bool>> getNotificationPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferences = <String, bool>{};

      for (final key in _defaultPreferences.keys) {
        preferences[key] = prefs.getBool(key) ?? _defaultPreferences[key]!;
      }

      return preferences;
    } catch (e) {
      debugPrint('Error getting notification preferences: $e');
      return Map.from(_defaultPreferences);
    }
  }

  // Update notification preference
  Future<bool> updateNotificationPreference(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('Error updating notification preference: $e');
      return false;
    }
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final preferences = await getNotificationPreferences();
    return preferences[_notificationsEnabledKey] ?? false;
  }

  // Check if specific notification type is enabled
  Future<bool> isNotificationTypeEnabled(String type) async {
    final notificationsEnabled = await areNotificationsEnabled();
    if (!notificationsEnabled) return false;

    final preferences = await getNotificationPreferences();
    return preferences[type] ?? false;
  }

  // Show local notification (placeholder for now)
  void showLocalNotification({
    required String title,
    required String body,
    String? type,
  }) {
    // Placeholder: In a real app, this would use a local notification plugin
    // For now, we'll just print to console
    debugPrint('Notification: $title - $body (Type: $type)');

    // You could also show a snackbar or toast here
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('$title: $body')),
    // );
  }

  // Handle like notification
  Future<void> handleLikeNotification({
    required String postTitle,
    required String likerName,
  }) async {
    if (await isNotificationTypeEnabled(_likeNotificationsKey)) {
      showLocalNotification(
        title: 'New Like!',
        body: '$likerName liked your post "$postTitle"',
        type: 'like',
      );
    }
  }

  // Handle comment notification
  Future<void> handleCommentNotification({
    required String postTitle,
    required String commenterName,
  }) async {
    if (await isNotificationTypeEnabled(_commentNotificationsKey)) {
      showLocalNotification(
        title: 'New Comment!',
        body: '$commenterName commented on your post "$postTitle"',
        type: 'comment',
      );
    }
  }

  // Handle follow notification
  Future<void> handleFollowNotification({required String followerName}) async {
    if (await isNotificationTypeEnabled(_followNotificationsKey)) {
      showLocalNotification(
        title: 'New Follower!',
        body: '$followerName started following you',
        type: 'follow',
      );
    }
  }

  // Handle trending notification
  Future<void> handleTrendingNotification({
    required String postTitle,
    required String category,
  }) async {
    if (await isNotificationTypeEnabled(_trendingNotificationsKey)) {
      showLocalNotification(
        title: 'Trending Post!',
        body: 'Your post "$postTitle" is trending in $category',
        type: 'trending',
      );
    }
  }

  // Get notification settings UI
  Widget buildNotificationSettingsUI() {
    return FutureBuilder<Map<String, bool>>(
      future: getNotificationPreferences(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text('Error loading notification settings'),
          );
        }

        final preferences = snapshot.data!;

        return Column(
          children: [
            _buildNotificationSwitch(
              title: 'Enable Notifications',
              subtitle: 'Receive notifications about your activity',
              value: preferences[_notificationsEnabledKey] ?? false,
              onChanged: (value) async {
                await updateNotificationPreference(
                  _notificationsEnabledKey,
                  value,
                );
                // Refresh the UI
                if (context.mounted) {
                  (context as Element).markNeedsBuild();
                }
              },
            ),
            if (preferences[_notificationsEnabledKey] ?? false) ...[
              const SizedBox(height: 16),
              _buildNotificationSwitch(
                title: 'Like Notifications',
                subtitle: 'When someone likes your posts',
                value: preferences[_likeNotificationsKey] ?? false,
                onChanged: (value) async {
                  await updateNotificationPreference(
                    _likeNotificationsKey,
                    value,
                  );
                  if (context.mounted) {
                    (context as Element).markNeedsBuild();
                  }
                },
              ),
              const SizedBox(height: 8),
              _buildNotificationSwitch(
                title: 'Comment Notifications',
                subtitle: 'When someone comments on your posts',
                value: preferences[_commentNotificationsKey] ?? false,
                onChanged: (value) async {
                  await updateNotificationPreference(
                    _commentNotificationsKey,
                    value,
                  );
                  if (context.mounted) {
                    (context as Element).markNeedsBuild();
                  }
                },
              ),
              const SizedBox(height: 8),
              _buildNotificationSwitch(
                title: 'Follow Notifications',
                subtitle: 'When someone follows you',
                value: preferences[_followNotificationsKey] ?? false,
                onChanged: (value) async {
                  await updateNotificationPreference(
                    _followNotificationsKey,
                    value,
                  );
                  if (context.mounted) {
                    (context as Element).markNeedsBuild();
                  }
                },
              ),
              const SizedBox(height: 8),
              _buildNotificationSwitch(
                title: 'Trending Notifications',
                subtitle: 'When your posts become trending',
                value: preferences[_trendingNotificationsKey] ?? false,
                onChanged: (value) async {
                  await updateNotificationPreference(
                    _trendingNotificationsKey,
                    value,
                  );
                  if (context.mounted) {
                    (context as Element).markNeedsBuild();
                  }
                },
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildNotificationSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFFE91E63),
    );
  }

  // Reset notification preferences to defaults
  Future<void> resetToDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final entry in _defaultPreferences.entries) {
        await prefs.setBool(entry.key, entry.value);
      }
    } catch (e) {
      debugPrint('Error resetting notification preferences: $e');
    }
  }
}
