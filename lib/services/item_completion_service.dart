import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class ItemCompletionService {
  static const String _keyPrefix = 'item_completion_';

  // Save item completion state for a specific post
  static Future<void> saveItemCompletion(
    String postId,
    int itemId,
    bool isCompleted,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$postId';

      // Get existing completion data
      final existingData = prefs.getString(key) ?? '{}';
      final Map<String, dynamic> completionData = json.decode(existingData);

      // Update the specific item
      completionData[itemId.toString()] = isCompleted;

      // Save back to preferences
      await prefs.setString(key, json.encode(completionData));
    } catch (e) {
      debugPrint('Error saving item completion: $e');
    }
  }

  // Get item completion state for a specific post
  static Future<Map<int, bool>> getItemCompletions(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$postId';

      final data = prefs.getString(key);
      if (data == null) return {};

      final Map<String, dynamic> completionData = json.decode(data);

      // Convert string keys back to integers
      return completionData.map(
        (key, value) => MapEntry(int.parse(key), value as bool),
      );
    } catch (e) {
      debugPrint('Error getting item completions: $e');
      return {};
    }
  }

  // Check if a specific item is completed
  static Future<bool> isItemCompleted(String postId, int itemId) async {
    try {
      final completions = await getItemCompletions(postId);
      return completions[itemId] ?? false;
    } catch (e) {
      debugPrint('Error checking item completion: $e');
      return false;
    }
  }

  // Clear all completion data for a post (useful for testing)
  static Future<void> clearPostCompletions(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$postId';
      await prefs.remove(key);
    } catch (e) {
      debugPrint('Error clearing post completions: $e');
    }
  }

  // Get completion count for a post
  static Future<int> getCompletionCount(String postId) async {
    try {
      final completions = await getItemCompletions(postId);
      return completions.values.where((completed) => completed).length;
    } catch (e) {
      debugPrint('Error getting completion count: $e');
      return 0;
    }
  }
}
