import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class InteractionService {
  static const String _likesKeyPrefix = 'likes_';
  static const String _commentsKeyPrefix = 'comments_';
  
  // Save like state for a post
  static Future<void> toggleLike(String postId, bool isLiked) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_likesKeyPrefix$postId';
      await prefs.setBool(key, isLiked);
    } catch (e) {
      debugPrint('Error saving like state: $e');
    }
  }
  
  // Get like state for a post
  static Future<bool> isPostLiked(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_likesKeyPrefix$postId';
      return prefs.getBool(key) ?? false;
    } catch (e) {
      debugPrint('Error getting like state: $e');
      return false;
    }
  }
  
  // Get all liked posts
  static Future<Set<String>> getLikedPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final likedPosts = <String>{};
      
      for (final key in keys) {
        if (key.startsWith(_likesKeyPrefix)) {
          final isLiked = prefs.getBool(key) ?? false;
          if (isLiked) {
            final postId = key.substring(_likesKeyPrefix.length);
            likedPosts.add(postId);
          }
        }
      }
      
      return likedPosts;
    } catch (e) {
      debugPrint('Error getting liked posts: $e');
      return <String>{};
    }
  }
  
  // Save comment for a post
  static Future<void> addComment(String postId, String comment, String authorName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_commentsKeyPrefix$postId';
      
      // Get existing comments
      final existingData = prefs.getString(key) ?? '[]';
      final List<dynamic> comments = json.decode(existingData);
      
      // Add new comment
      final newComment = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': comment,
        'author': authorName,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      comments.add(newComment);
      
      // Save back to preferences
      await prefs.setString(key, json.encode(comments));
    } catch (e) {
      debugPrint('Error saving comment: $e');
    }
  }
  
  // Get comments for a post
  static Future<List<Map<String, dynamic>>> getComments(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_commentsKeyPrefix$postId';
      
      final data = prefs.getString(key);
      if (data == null) return [];
      
      final List<dynamic> comments = json.decode(data);
      return comments.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error getting comments: $e');
      return [];
    }
  }
  
  // Get comment count for a post
  static Future<int> getCommentCount(String postId) async {
    try {
      final comments = await getComments(postId);
      return comments.length;
    } catch (e) {
      debugPrint('Error getting comment count: $e');
      return 0;
    }
  }
  
  // Clear all interactions for a post (useful for testing)
  static Future<void> clearPostInteractions(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_likesKeyPrefix$postId');
      await prefs.remove('$_commentsKeyPrefix$postId');
    } catch (e) {
      debugPrint('Error clearing post interactions: $e');
    }
  }
}
