import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class LinkClickService {
  static const String _keyPrefix = 'link_clicks_';

  // Track a link click for a specific post and item
  static Future<void> trackLinkClick(String postId, int itemId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$postId';

      // Get existing click data
      final existingData = prefs.getString(key) ?? '{}';
      final Map<String, dynamic> clickData = json.decode(existingData);

      // Increment the click count for this item
      final currentCount = clickData[itemId.toString()] ?? 0;
      clickData[itemId.toString()] = currentCount + 1;

      // Save back to preferences
      await prefs.setString(key, json.encode(clickData));
    } catch (e) {
      debugPrint('Error tracking link click: $e');
    }
  }

  // Get link click counts for a specific post
  static Future<Map<int, int>> getLinkClickCounts(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$postId';

      final data = prefs.getString(key);
      if (data == null) return {};

      final Map<String, dynamic> clickData = json.decode(data);

      // Convert string keys back to integers
      return clickData.map(
        (key, value) => MapEntry(int.parse(key), value as int),
      );
    } catch (e) {
      debugPrint('Error getting link click counts: $e');
      return {};
    }
  }

  // Get click count for a specific item
  static Future<int> getItemClickCount(String postId, int itemId) async {
    try {
      final clickCounts = await getLinkClickCounts(postId);
      return clickCounts[itemId] ?? 0;
    } catch (e) {
      debugPrint('Error getting item click count: $e');
      return 0;
    }
  }

  // Clear all click data for a post (useful for testing)
  static Future<void> clearPostClicks(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$postId';
      await prefs.remove(key);
    } catch (e) {
      debugPrint('Error clearing post clicks: $e');
    }
  }

  // Get total click count for a post
  static Future<int> getTotalClickCount(String postId) async {
    try {
      final clickCounts = await getLinkClickCounts(postId);
      return clickCounts.values.fold<int>(0, (sum, count) => sum + count);
    } catch (e) {
      debugPrint('Error getting total click count: $e');
      return 0;
    }
  }
}
