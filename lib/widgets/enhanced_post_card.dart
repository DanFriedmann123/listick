import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/list_item.dart';
import '../services/database_interaction_service.dart';
import '../services/image_preload_service.dart';
import '../services/link_click_service.dart';
import '../screens/image_viewer_screen.dart';
import '../screens/user_profile_screen.dart';
import 'comment_dialog.dart';

class EnhancedPostCard extends StatefulWidget {
  final String postId; // Add unique identifier for the post
  final String title;
  final String description;
  final List<ListItem> items;
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final bool isTrending;
  final bool isBookmarked;
  final List<String> imageUrls;
  final String? videoUrl;
  final String? category;
  final DateTime? createdAt;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onBookmark;
  final VoidCallback? onShare;
  final VoidCallback? onComment;
  final VoidCallback? onEdit;
  final Function(int, bool)? onItemToggle;
  final Map<int, bool>? itemCompletions;
  final VoidCallback? onRefresh;

  const EnhancedPostCard({
    super.key,
    required this.postId,
    required this.title,
    required this.description,
    required this.items,
    required this.likeCount,
    this.commentCount = 0,
    this.viewCount = 0,
    this.isTrending = false,
    this.isBookmarked = false,
    this.imageUrls = const [],
    this.videoUrl,
    this.category,
    this.createdAt,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    this.onTap,
    this.onLike,
    this.onBookmark,
    this.onShare,
    this.onComment,
    this.onEdit,
    this.onItemToggle,
    this.itemCompletions,
    this.onRefresh,
  });

  @override
  State<EnhancedPostCard> createState() => _EnhancedPostCardState();
}

class _EnhancedPostCardState extends State<EnhancedPostCard> {
  bool _isLiked = false;
  bool _isBookmarked = false;
  bool _showAllItems = false;
  late PageController _pageController;
  int _currentPage = 0;
  int _actualCommentCount = 0;
  bool _isLoadingLikeState = true;
  bool _isCommentDialogOpen = false;
  Map<int, int> _linkClickCounts = {};
  Map<int, bool> _showClickCounts = {};

  @override
  void initState() {
    super.initState();
    _isBookmarked = widget.isBookmarked;
    _pageController = PageController();
    _actualCommentCount = widget.commentCount;
    _loadInteractionState();
    _loadLinkClickCounts();
  }

  Future<void> _loadInteractionState() async {
    try {
      final isLiked = await DatabaseInteractionService.isPostLiked(
        widget.postId,
      );
      final commentCount = await DatabaseInteractionService.getCommentCount(
        widget.postId,
      );

      if (mounted) {
        setState(() {
          _isLiked = isLiked;
          _actualCommentCount = widget.commentCount + commentCount;
          _isLoadingLikeState = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLikeState = false;
        });
      }
    }
  }

  Future<void> _loadLinkClickCounts() async {
    try {
      final clickCounts = await LinkClickService.getLinkClickCounts(
        widget.postId,
      );
      if (mounted) {
        setState(() {
          _linkClickCounts = clickCounts;
        });
      }
    } catch (e) {
      debugPrint('Error loading link click counts: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    final newLikeState = !_isLiked;

    // Update UI immediately for responsiveness
    setState(() {
      _isLiked = newLikeState;
    });

    try {
      // Save to persistent storage
      await DatabaseInteractionService.toggleLike(widget.postId, newLikeState);

      // Call the original callback if provided
      widget.onLike?.call();
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _isLiked = !newLikeState;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating like: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _toggleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    widget.onBookmark?.call();
  }

  void _sharePost() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
    widget.onShare?.call();
  }

  Future<void> _showCommentDialog() async {
    if (_isCommentDialogOpen) {
      debugPrint('Comment dialog already open, ignoring tap');
      return;
    }

    debugPrint('Opening comment dialog for post: ${widget.postId}');
    setState(() {
      _isCommentDialogOpen = true;
    });

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => CommentDialog(
            postId: widget.postId,
            postTitle: widget.title,
            initialCommentCount: _actualCommentCount,
          ),
    );

    debugPrint('Comment dialog closed with result: $result');

    if (mounted) {
      setState(() {
        _isCommentDialogOpen = false;
      });

      // Refresh comment count after dialog closes
      try {
        final commentCount = await DatabaseInteractionService.getCommentCount(
          widget.postId,
        );
        if (mounted) {
          setState(() {
            _actualCommentCount = widget.commentCount + commentCount;
          });
        }
      } catch (e) {
        debugPrint('Error refreshing comment count: $e');
      }

      // Call the original callback if provided
      widget.onComment?.call();
    }
  }

  void _toggleItems() {
    setState(() {
      _showAllItems = !_showAllItems;
    });
  }

  String _getTimeAgo() {
    if (widget.createdAt == null) return '';

    final now = DateTime.now();
    final difference = now.difference(widget.createdAt!);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _launchUrl(String url, int itemId) async {
    try {
      print('Attempting to launch URL: $url'); // Debug log

      // Track the link click
      await LinkClickService.trackLinkClick(widget.postId, itemId);

      // Check if this is the first click for this item
      final isFirstClick = (_linkClickCounts[itemId] ?? 0) == 0;

      // Update local state to show the new count
      setState(() {
        _linkClickCounts[itemId] = (_linkClickCounts[itemId] ?? 0) + 1;
      });

      // If this is the first click, show counter with fade-in animation
      if (isFirstClick) {
        setState(() {
          _showClickCounts[itemId] = false;
        });

        // Trigger fade-in animation after a short delay
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {
              _showClickCounts[itemId] = true;
            });
          }
        });
      }

      // Ensure URL has a protocol
      String processedUrl = url.trim();
      if (!processedUrl.startsWith('http://') &&
          !processedUrl.startsWith('https://')) {
        processedUrl = 'https://$processedUrl';
      }

      print('Processed URL: $processedUrl'); // Debug log

      final Uri uri = Uri.parse(processedUrl);

      print('Checking if URL can be launched...'); // Debug log
      final canLaunch = await canLaunchUrl(uri);
      print('Can launch URL: $canLaunch'); // Debug log

      if (canLaunch) {
        print('Launching URL: $processedUrl'); // Debug log
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('URL launched successfully'); // Debug log
      } else {
        print('Cannot launch URL: $processedUrl'); // Debug log
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open $processedUrl'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error launching URL: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openImageViewer(int initialIndex) async {
    if (widget.imageUrls.isNotEmpty) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => ImageViewerScreen(
                imageUrls: widget.imageUrls,
                initialIndex: initialIndex,
                title: widget.title,
                description: widget.description,
                items: widget.items,
                authorName: widget.authorName,
                authorAvatar: widget.authorAvatar,
                createdAt: widget.createdAt,
                postId: widget.postId,
              ),
        ),
      );

      // Trigger a refresh to reload completion states
      if (mounted) {
        widget.onRefresh?.call();
      }
    }
  }

  void _navigateToUserProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => UserProfileScreen(
              userId: widget.authorId,
              userName: widget.authorName,
              userAvatar: widget.authorAvatar,
              onBack: () => Navigator.of(context).pop(),
            ),
      ),
    );
  }

  ImageProvider _getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('assets/')) {
      return AssetImage(imageUrl);
    } else {
      // Check if image is preloaded first
      final preloadedImage = ImagePreloadService().getPreloadedImage(imageUrl);
      if (preloadedImage != null) {
        return preloadedImage;
      }

      // Fallback to CachedNetworkImageProvider for better caching
      return CachedNetworkImageProvider(imageUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayedItems =
        _showAllItems ? widget.items : widget.items.take(3).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with author info
            Row(
              children: [
                // Show edit button if onEdit is provided, otherwise show avatar
                widget.onEdit != null
                    ? GestureDetector(
                      onTap: widget.onEdit,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.2,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.edit,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    )
                    : GestureDetector(
                      onTap: _navigateToUserProfile,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: theme.colorScheme.primary.withValues(
                          alpha: 0.2,
                        ),
                        backgroundImage:
                            widget.authorAvatar != null
                                ? _getImageProvider(widget.authorAvatar!)
                                : null,
                        child:
                            widget.authorAvatar == null
                                ? Text(
                                  widget.authorName.isNotEmpty
                                      ? widget.authorName[0].toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                                : null,
                      ),
                    ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _navigateToUserProfile,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.authorName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.createdAt != null)
                          Text(
                            _getTimeAgo(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (widget.category != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.category!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Trending badge
            if (widget.isTrending)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.trending_up,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Trending',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            // Title
            GestureDetector(
              onTap: widget.onTap,
              child: Text(
                widget.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 8),

            // Description
            if (widget.description.isNotEmpty) ...[
              Text(
                widget.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
            ],

            // Media (images or video)
            if (widget.imageUrls.isNotEmpty || widget.videoUrl != null) ...[
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[800],
                ),
                child: Stack(
                  children: [
                    if (widget.imageUrls.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildImageGallery(),
                      ),
                    if (widget.videoUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          color: Colors.black,
                          child: const Center(
                            child: Icon(
                              Icons.play_circle_outline,
                              size: 64,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    if (widget.videoUrl != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_arrow,
                                size: 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'VIDEO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Image counter badge
                    if (widget.imageUrls.length > 1)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${widget.imageUrls.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            if (widget.imageUrls.isNotEmpty || widget.videoUrl != null)
              const SizedBox(height: 16),

            // List items
            Column(
              children:
                  displayedItems
                      .map((item) => _buildListItem(item, theme))
                      .toList(),
            ),

            // Show more/less button
            if (widget.items.length > 3)
              TextButton(
                onPressed: _toggleItems,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                ),
                child: Text(
                  _showAllItems
                      ? 'Show less'
                      : 'Show ${widget.items.length - 3} more',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Stats row
            Row(
              children: [
                Icon(
                  Icons.list_alt,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.items.length} items',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (widget.viewCount > 0) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.visibility,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.viewCount}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                // Like button
                Expanded(
                  child: GestureDetector(
                    onTap: _toggleLike,
                    child: Row(
                      children: [
                        Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 24,
                          color:
                              _isLiked
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                        ),
                        const SizedBox(width: 8),
                        _isLoadingLikeState
                            ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 1),
                            )
                            : Text(
                              '${widget.likeCount + (_isLiked ? 1 : 0)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color:
                                    _isLiked
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                fontWeight:
                                    _isLiked
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                              ),
                            ),
                      ],
                    ),
                  ),
                ),

                // Comment button
                Expanded(
                  child: GestureDetector(
                    onTap: _showCommentDialog,
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 24,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_actualCommentCount',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bookmark button
                Expanded(
                  child: GestureDetector(
                    onTap: _toggleBookmark,
                    child: Icon(
                      _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      size: 24,
                      color:
                          _isBookmarked
                              ? theme.colorScheme.secondary
                              : theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                    ),
                  ),
                ),

                // Share button
                Expanded(
                  child: GestureDetector(
                    onTap: _sharePost,
                    child: Icon(
                      Icons.share,
                      size: 24,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(ListItem item, ThemeData theme) {
    final isCompleted = widget.itemCompletions?[item.id] ?? item.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isCompleted
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isCompleted
                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: () {
              widget.onItemToggle?.call(item.id, !isCompleted);
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color:
                    isCompleted
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                border: Border.all(
                  color:
                      isCompleted
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child:
                  isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
            ),
          ),
          const SizedBox(width: 12),
          // Item content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color:
                        isCompleted
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                            : null,
                  ),
                ),
                if (item.url != null && item.url!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _launchUrl(item.url!, item.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.link,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              item.url!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Click count badge with fade-in animation
                          if (_linkClickCounts[item.id] != null &&
                              _linkClickCounts[item.id]! > 0) ...[
                            AnimatedOpacity(
                              opacity:
                                  _showClickCounts[item.id] == true ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_linkClickCounts[item.id]}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Completion count
          if (item.completionCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${item.completionCount}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    if (widget.imageUrls.isEmpty) {
      return Container(
        width: double.infinity,
        height: 200,
        color: Colors.grey[800],
        child: const Icon(
          Icons.image_not_supported,
          size: 48,
          color: Colors.grey,
        ),
      );
    }

    if (widget.imageUrls.length == 1) {
      final imageUrl = widget.imageUrls.first;

      return GestureDetector(
        onTap: () => _openImageViewer(0),
        child: Container(
          width: double.infinity,
          height: 200,
          child:
              imageUrl.startsWith('assets/')
                  ? Image(
                    image: AssetImage(imageUrl),
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: Colors.grey,
                        ),
                      );
                    },
                  )
                  : CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          color: Colors.grey[800],
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFE91E63),
                              ),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                  ),
        ),
      );
    }

    // Multiple images - show horizontal scrollable gallery
    return GestureDetector(
      onTap: () => _openImageViewer(_currentPage),
      child: Stack(
        children: [
          // Horizontal scrollable image gallery
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            physics: const PageScrollPhysics(),
            allowImplicitScrolling: true,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final imageUrl = widget.imageUrls[index];

              if (imageUrl.startsWith('assets/')) {
                return Image(
                  image: AssetImage(imageUrl),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: Colors.grey,
                      ),
                    );
                  },
                );
              } else {
                return CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFE91E63),
                            ),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                );
              }
            },
          ),
          // Gradient overlay to make text readable (positioned above images but below UI elements)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
          ),
          // Page indicator dots
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.imageUrls.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        index == _currentPage
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
          // Page indicators (dots) at the bottom
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _currentPage == index
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ),
          // Navigation buttons (only show if there are multiple images) - positioned on top
          if (widget.imageUrls.length > 1) ...[
            // Previous button (<<)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_currentPage > 0) {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_left,
                      color:
                          _currentPage > 0
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.3),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
            // Next button (>>)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_currentPage < widget.imageUrls.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      color:
                          _currentPage < widget.imageUrls.length - 1
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.3),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
