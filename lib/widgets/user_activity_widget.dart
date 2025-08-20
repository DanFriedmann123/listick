import 'package:flutter/material.dart';

class UserActivityWidget extends StatelessWidget {
  final VoidCallback? onViewAllActivity;
  final VoidCallback? onViewAchievements;

  const UserActivityWidget({
    super.key,
    this.onViewAllActivity,
    this.onViewAchievements,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Activity',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: onViewAllActivity,
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
        ),

        const SizedBox(height: 12),

        // Activity feed
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: _buildActivityItems(theme),
          ),
        ),

        const SizedBox(height: 24),

        // Achievements section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Achievements',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: onViewAchievements,
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
              const SizedBox(height: 12),
              Row(children: _buildAchievementBadges(theme)),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Statistics
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This Week',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(children: _buildStatCards(theme)),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActivityItems(ThemeData theme) {
    final activities = [
      {
        'type': 'like',
        'text': 'Liked "Travel Packing List"',
        'time': '2h ago',
        'icon': Icons.favorite,
        'color': Colors.red,
      },
      {
        'type': 'comment',
        'text': 'Commented on "Study Tips"',
        'time': '4h ago',
        'icon': Icons.chat_bubble,
        'color': Colors.blue,
      },
      {
        'type': 'save',
        'text': 'Saved "Gaming Setup"',
        'time': '1d ago',
        'icon': Icons.bookmark,
        'color': Colors.purple,
      },
      {
        'type': 'follow',
        'text': 'Started following @TravelGuru',
        'time': '2d ago',
        'icon': Icons.person_add,
        'color': Colors.green,
      },
      {
        'type': 'create',
        'text': 'Created "My Reading List"',
        'time': '3d ago',
        'icon': Icons.add_circle,
        'color': Colors.orange,
      },
    ];

    return activities.map((activity) {
      return Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (activity['color'] as Color).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    activity['icon'] as IconData,
                    size: 16,
                    color: activity['color'] as Color,
                  ),
                ),
                const Spacer(),
                Text(
                  activity['time'] as String,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                activity['text'] as String,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildAchievementBadges(ThemeData theme) {
    final achievements = [
      {
        'name': 'First List',
        'icon': Icons.list_alt,
        'unlocked': true,
        'description': 'Created your first list',
      },
      {
        'name': 'Social Butterfly',
        'icon': Icons.people,
        'unlocked': true,
        'description': 'Followed 10 users',
      },
      {
        'name': 'Trendsetter',
        'icon': Icons.trending_up,
        'unlocked': false,
        'description': 'Get 100 likes on a list',
      },
      {
        'name': 'Creator',
        'icon': Icons.create,
        'unlocked': true,
        'description': 'Created 5 lists',
      },
    ];

    return achievements.map((achievement) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                achievement['unlocked'] as bool
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : theme.colorScheme.surface.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  achievement['unlocked'] as bool
                      ? theme.colorScheme.primary.withValues(alpha: 0.3)
                      : theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(
                achievement['icon'] as IconData,
                size: 24,
                color:
                    achievement['unlocked'] as bool
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 8),
              Text(
                achievement['name'] as String,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color:
                      achievement['unlocked'] as bool
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                achievement['description'] as String,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildStatCards(ThemeData theme) {
    final stats = [
      {
        'label': 'Lists Created',
        'value': '3',
        'icon': Icons.create,
        'color': Colors.blue,
      },
      {
        'label': 'Items Completed',
        'value': '12',
        'icon': Icons.check_circle,
        'color': Colors.green,
      },
      {
        'label': 'Likes Given',
        'value': '8',
        'icon': Icons.favorite,
        'color': Colors.red,
      },
      {
        'label': 'Lists Saved',
        'value': '5',
        'icon': Icons.bookmark,
        'color': Colors.purple,
      },
    ];

    return stats.map((stat) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                stat['icon'] as IconData,
                size: 20,
                color: stat['color'] as Color,
              ),
              const SizedBox(height: 8),
              Text(
                stat['value'] as String,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: stat['color'] as Color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stat['label'] as String,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
