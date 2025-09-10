import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ImagePreloadService {
  static final ImagePreloadService _instance = ImagePreloadService._internal();
  factory ImagePreloadService() => _instance;
  ImagePreloadService._internal();

  final Map<String, ImageProvider> _preloadedImages = {};
  final Set<String> _preloadingImages = {};

  /// Preload images from a list of URLs
  Future<void> preloadImages(List<String> imageUrls) async {
    final List<Future<void>> preloadTasks = [];

    for (String imageUrl in imageUrls) {
      if (imageUrl.isNotEmpty &&
          !_preloadedImages.containsKey(imageUrl) &&
          !_preloadingImages.contains(imageUrl)) {
        preloadTasks.add(_preloadSingleImage(imageUrl));
      }
    }

    // Preload all images concurrently
    await Future.wait(preloadTasks);
  }

  /// Preload a single image
  Future<void> _preloadSingleImage(String imageUrl) async {
    if (_preloadedImages.containsKey(imageUrl) ||
        _preloadingImages.contains(imageUrl)) {
      return;
    }

    _preloadingImages.add(imageUrl);

    try {
      ImageProvider imageProvider;

      if (imageUrl.startsWith('assets/')) {
        // Asset images don't need preloading
        imageProvider = AssetImage(imageUrl);
      } else {
        // Network images - preload and cache
        imageProvider = CachedNetworkImageProvider(
          imageUrl,
          cacheManager: DefaultCacheManager(),
        );

        // Preload the image into cache
        await precacheImage(
          imageProvider,
          NavigationService.navigatorKey.currentContext!,
        );
      }

      _preloadedImages[imageUrl] = imageProvider;
      print('Preloaded image: $imageUrl');
    } catch (e) {
      print('Failed to preload image $imageUrl: $e');
    } finally {
      _preloadingImages.remove(imageUrl);
    }
  }

  /// Get preloaded image provider
  ImageProvider? getPreloadedImage(String imageUrl) {
    return _preloadedImages[imageUrl];
  }

  /// Check if image is preloaded
  bool isImagePreloaded(String imageUrl) {
    return _preloadedImages.containsKey(imageUrl);
  }

  /// Clear all preloaded images (useful for memory management)
  void clearPreloadedImages() {
    _preloadedImages.clear();
    _preloadingImages.clear();
  }

  /// Get memory usage info
  Map<String, dynamic> getMemoryInfo() {
    return {
      'preloadedCount': _preloadedImages.length,
      'preloadingCount': _preloadingImages.length,
      'preloadedUrls': _preloadedImages.keys.toList(),
    };
  }
}

/// Navigation service to access navigator context
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
}
