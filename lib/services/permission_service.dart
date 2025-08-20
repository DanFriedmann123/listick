import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionService {
  // Check and request camera permission
  static Future<bool> requestCameraPermission(BuildContext context) async {
    try {
      final status = await Permission.camera.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.camera.request();
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        if (context.mounted) {
          _showPermissionDialog(
            context,
            'Camera Permission Required',
            'Camera permission is required to take photos. Please enable it in your device settings.',
          );
        }
        return false;
      }

      return false;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting camera permission: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  // Check and request photo library permission
  static Future<bool> requestPhotoLibraryPermission(
    BuildContext context,
  ) async {
    try {
      final status = await Permission.photos.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.photos.request();
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        if (context.mounted) {
          _showPermissionDialog(
            context,
            'Photo Library Permission Required',
            'Photo library permission is required to select images. Please enable it in your device settings.',
          );
        }
        return false;
      }

      return false;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting photo library permission: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  // Show permission dialog with option to open settings
  static void _showPermissionDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Text(title, style: const TextStyle(color: Colors.white)),
            content: Text(message, style: const TextStyle(color: Colors.white)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text(
                  'Open Settings',
                  style: TextStyle(color: Color(0xFFE91E63)),
                ),
              ),
            ],
          ),
    );
  }
}
