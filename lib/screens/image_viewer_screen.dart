import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/list_item.dart';
import '../services/item_completion_service.dart';
import '../services/link_click_service.dart';

class ImageViewerScreen extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String title;
  final String description;
  final List<ListItem> items;
  final String authorName;
  final String? authorAvatar;
  final DateTime? createdAt;
  final String postId;

  const ImageViewerScreen({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    required this.title,
    required this.description,
    required this.items,
    required this.authorName,
    this.authorAvatar,
    this.createdAt,
    required this.postId,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  Map<int, bool> _itemCompletions = {};
  Map<int, int> _linkClickCounts = {};
  Map<int, bool> _showClickCounts = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _loadItemCompletions();
    _loadLinkClickCounts();
  }

  Future<void> _loadItemCompletions() async {
    try {
      final completions = await ItemCompletionService.getItemCompletions(
        widget.postId,
      );
      setState(() {
        _itemCompletions = completions;
      });
    } catch (e) {
      debugPrint('Error loading item completions: $e');
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

  void _previousImage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextImage() {
    if (_currentIndex < widget.imageUrls.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _toggleItemCompletion(int itemId) async {
    try {
      final isCompleted = _itemCompletions[itemId] ?? false;
      final newCompletionState = !isCompleted;

      // Save to service
      await ItemCompletionService.saveItemCompletion(
        widget.postId,
        itemId,
        newCompletionState,
      );

      // Update local state
      setState(() {
        _itemCompletions[itemId] = newCompletionState;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving completion: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.surface),
            iconSize: 20,
          ),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              backgroundImage:
                  widget.authorAvatar != null
                      ? CachedNetworkImageProvider(widget.authorAvatar!)
                      : null,
              child:
                  widget.authorAvatar == null
                      ? Text(
                        widget.authorName.isNotEmpty
                            ? widget.authorName[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.authorName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.createdAt != null)
                    Text(
                      _formatDate(widget.createdAt!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Title and description section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // List title
                Text(
                  widget.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                // Description
                if (widget.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Image gallery
          Expanded(flex: 4, child: _buildImageGallery()),

          // List items at the bottom
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // List items
                  if (widget.items.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: widget.items.length,
                        itemBuilder: (context, index) {
                          return _buildListItem(widget.items[index], theme);
                        },
                      ),
                    )
                  else
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.list_alt_outlined,
                              size: 48,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No items in this list',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
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
        color: Colors.grey[800],
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemCount: widget.imageUrls.length,
          itemBuilder: (context, index) {
            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: Center(child: _buildImage(widget.imageUrls[index])),
            );
          },
        ),

        // Image counter and navigation (only show if multiple images)
        if (widget.imageUrls.length > 1) ...[
          // Page indicator dots
          Positioned(
            bottom: 16,
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
                        index == _currentIndex
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),

          // Navigation buttons
          Positioned(
            left: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: _currentIndex > 0 ? _previousImage : null,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        _currentIndex > 0
                            ? Colors.black.withValues(alpha: 0.5)
                            : Colors.black.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_left,
                    color:
                        _currentIndex > 0
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap:
                    _currentIndex < widget.imageUrls.length - 1
                        ? _nextImage
                        : null,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        _currentIndex < widget.imageUrls.length - 1
                            ? Colors.black.withValues(alpha: 0.5)
                            : Colors.black.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    color:
                        _currentIndex < widget.imageUrls.length - 1
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.image_not_supported,
            size: 64,
            color: Colors.grey,
          );
        },
      );
    } else {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder:
            (context, url) => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
                strokeWidth: 2,
              ),
            ),
        errorWidget:
            (context, url, error) => const Icon(
              Icons.image_not_supported,
              size: 64,
              color: Colors.grey,
            ),
      );
    }
  }

  Widget _buildListItem(ListItem item, ThemeData theme) {
    final isCompleted = _itemCompletions[item.id] ?? item.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleItemCompletion(item.id),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Interactive checkbox
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isCompleted
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                    border: Border.all(
                      color:
                          isCompleted
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withValues(
                                alpha: 0.4,
                              ),
                      width: 2,
                    ),
                    boxShadow:
                        isCompleted
                            ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                            : null,
                  ),
                  child:
                      isCompleted
                          ? const Icon(
                            Icons.check,
                            size: 18,
                            color: Colors.white,
                          )
                          : null,
                ),
                const SizedBox(width: 16),

                // Item content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.text,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : null,
                          color:
                              isCompleted
                                  ? theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  )
                                  : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),

                      // URL link if available
                      if (item.url?.isNotEmpty == true) ...[
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => _launchUrl(item.url!, item.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(10),
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
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.url!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Click count badge with fade-in animation
                                if (_linkClickCounts[item.id] != null &&
                                    _linkClickCounts[item.id]! > 0) ...[
                                  AnimatedOpacity(
                                    opacity:
                                        _showClickCounts[item.id] == true
                                            ? 1.0
                                            : 0.0,
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
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Icon(
                                  Icons.open_in_new,
                                  size: 14,
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Completion count
                if (item.completionCount > 0) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.completionCount}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url, int itemId) async {
    try {
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

      String processedUrl = url.trim();
      if (!processedUrl.startsWith('http://') &&
          !processedUrl.startsWith('https://')) {
        processedUrl = 'https://$processedUrl';
      }

      final Uri uri = Uri.parse(processedUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
