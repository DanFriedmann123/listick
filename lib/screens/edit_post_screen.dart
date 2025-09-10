import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../models/post.dart';
import '../services/post_service.dart';

class EditPostScreen extends StatefulWidget {
  final Post post;

  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _tagController = TextEditingController();

  final List<File> _selectedImages = [];
  final List<PostItem> _items = [];
  final List<TextEditingController> _itemControllers = [];
  final List<TextEditingController> _urlControllers = [];
  final List<String> _tags = [];

  String? _selectedCategory;
  bool _isLoading = false;

  final List<String> _availableCategories = [
    'Travel',
    'Food',
    'Technology',
    'Fitness',
    'Fashion',
    'Home',
    'Education',
    'Entertainment',
    'Sports',
    'Health',
    'Business',
    'Art',
    'Music',
    'Gaming',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Initialize form fields with existing post data
    _titleController.text = widget.post.title;
    _descriptionController.text = widget.post.description;
    _selectedCategory = widget.post.category;
    _tags.addAll(widget.post.tags);

    // Initialize items
    for (final item in widget.post.items) {
      final textController = TextEditingController(text: item.text);
      final urlController = TextEditingController(text: item.url ?? '');
      _itemControllers.add(textController);
      _urlControllers.add(urlController);
      _items.add(item);
    }

    // If no items, add one empty item
    if (_items.isEmpty) {
      _addItem();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _tagController.dispose();
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    for (final controller in _urlControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      final itemId = _items.length + 1;
      final textController = TextEditingController();
      final urlController = TextEditingController();
      _itemControllers.add(textController);
      _urlControllers.add(urlController);
      _items.add(
        PostItem(
          id: itemId,
          text: '',
          url: '',
          isCompleted: false,
          completionCount: 0,
        ),
      );
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _itemControllers[index].dispose();
        _urlControllers[index].dispose();
        _itemControllers.removeAt(index);
        _urlControllers.removeAt(index);
        _items.removeAt(index);

        // Reorder IDs
        for (int i = 0; i < _items.length; i++) {
          _items[i] = _items[i].copyWith(id: i + 1);
        }
      });
    }
  }

  Future<void> _pickImages() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          final file = File(image.path);
          _selectedImages.add(file);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image selected successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (e.toString().contains('permission') ||
          e.toString().contains('denied')) {
        final status = await Permission.photos.status;
        if (status.isDenied || status.isPermanentlyDenied) {
          final result = await Permission.photos.request();
          if (!result.isGranted) {
            if (mounted) {
              final shouldOpenSettings = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Permission Required'),
                      content: const Text(
                        'Photo library access is required to select images. Please enable it in your device settings.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Open Settings'),
                        ),
                      ],
                    ),
              );

              if (shouldOpenSettings == true) {
                await openAppSettings();
              }
            }
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error picking image: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          final file = File(image.path);
          _selectedImages.add(file);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo taken successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (e.toString().contains('permission') ||
          e.toString().contains('denied')) {
        final status = await Permission.camera.status;
        if (status.isDenied || status.isPermanentlyDenied) {
          final result = await Permission.camera.request();
          if (!result.isGranted) {
            if (mounted) {
              final shouldOpenSettings = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Permission Required'),
                      content: const Text(
                        'Camera access is required to take photos. Please enable it in your device settings.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Open Settings'),
                        ),
                      ],
                    ),
              );

              if (shouldOpenSettings == true) {
                await openAppSettings();
              }
            }
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error taking photo: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _addTag() {
    final tagText = _tagController.text.trim();
    if (tagText.isNotEmpty && !_tags.contains(tagText)) {
      setState(() {
        _tags.add(tagText);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _updatePost() async {
    if (!_formKey.currentState!.validate()) return;

    // Update items with text and URLs from controllers
    for (int i = 0; i < _items.length; i++) {
      final text = _itemControllers[i].text.trim();
      final url = _urlControllers[i].text.trim();
      if (text.isNotEmpty) {
        _items[i] = _items[i].copyWith(
          text: text,
          url: url.isNotEmpty ? url : null,
        );
      }
    }

    // Filter out empty items
    final validItems = _items.where((item) => item.text.isNotEmpty).toList();
    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item to your list'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final postService = PostService();
      await postService.updatePost(
        postId: widget.post.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        newImages: _selectedImages.isNotEmpty ? _selectedImages : null,
        category: _selectedCategory,
        items: validItems,
        tags: _tags,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error updating post';
        if (e.toString().contains('Timeout')) {
          errorMessage =
              'Request timed out. Please check your internet connection and try again.';
        } else if (e.toString().contains('permission-denied')) {
          errorMessage = 'Permission denied. Please check your account status.';
        } else if (e.toString().contains('network')) {
          errorMessage =
              'Network error. Please check your internet connection.';
        } else {
          errorMessage = 'Error updating post: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Post'),
            content: Text(
              'Are you sure you want to delete "${widget.post.title}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _isLoading = true;
      });

      try {
        final postService = PostService();
        await postService.deletePost(widget.post.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate deletion
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting post: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: const Text('Edit Post'),
        actions: [
          // Delete button
          IconButton(
            onPressed: _isLoading ? null : _deletePost,
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Delete Post',
          ),
          // Update button
          TextButton(
            onPressed: _isLoading ? null : _updatePost,
            child:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Text(
                      'Update',
                      style: TextStyle(
                        color: Color(0xFFE91E63),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Selection Section
              _buildImageSection(theme),

              const SizedBox(height: 24),

              // Title Field
              _buildTitleField(theme),

              const SizedBox(height: 16),

              // Description Field
              _buildDescriptionField(theme),

              const SizedBox(height: 16),

              // Category Field
              _buildCategoryField(theme),

              const SizedBox(height: 16),

              // Tags Section
              _buildTagsSection(theme),

              const SizedBox(height: 24),

              // List Items Section
              _buildItemsSection(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Images',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Current images from post
        if (widget.post.imageUrls.isNotEmpty) ...[
          Text(
            'Current Images:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.post.imageUrls.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.post.imageUrls[index],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Selected new images
        if (_selectedImages.isNotEmpty) ...[
          Text(
            'New Images:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImages[index],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
        ],

        // Image Selection Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _pickImages,
                icon: const Icon(Icons.photo_library),
                label: const Text('Add from Gallery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTitleField(ThemeData theme) {
    return TextFormField(
      controller: _titleController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Title',
        labelStyle: TextStyle(color: Colors.grey[400]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE91E63)),
        ),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a title';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField(ThemeData theme) {
    return TextFormField(
      controller: _descriptionController,
      style: const TextStyle(color: Colors.white),
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Description',
        labelStyle: TextStyle(color: Colors.grey[400]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE91E63)),
        ),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a description';
        }
        return null;
      },
    );
  }

  Widget _buildCategoryField(ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Category',
        labelStyle: TextStyle(color: Colors.grey[400]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE91E63)),
        ),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
      ),
      dropdownColor: const Color(0xFF2A2A2A),
      items:
          _availableCategories.map((category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(
                category,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a category';
        }
        return null;
      },
    );
  }

  Widget _buildTagsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _tagController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Add a tag',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[600]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[600]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE91E63)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _addTag,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.2,
                    ),
                    labelStyle: TextStyle(color: theme.colorScheme.primary),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeTag(tag),
                  );
                }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildItemsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'List Items',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _addItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Item'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(_items.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                // Item text field
                TextFormField(
                  controller: _itemControllers[index],
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Item ${index + 1}',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[600]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[600]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE91E63)),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                  ),
                ),
                const SizedBox(height: 8),
                // URL field
                TextFormField(
                  controller: _urlControllers[index],
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Link (optional)',
                    hintText: 'https://example.com',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[600]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[600]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE91E63)),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    prefixIcon: const Icon(
                      Icons.link,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                ),
                if (_items.length > 1) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () => _removeItem(index),
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}
