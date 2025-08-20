import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String title;
  final String description;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final List<String> imageUrls;
  final String? videoUrl;
  final String? category;
  final List<PostItem> items;
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final bool isTrending;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> likedBy;
  final List<String> bookmarkedBy;
  final List<String> tags;

  const Post({
    required this.id,
    required this.title,
    required this.description,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.imageUrls,
    this.videoUrl,
    this.category,
    required this.items,
    this.likeCount = 0,
    this.commentCount = 0,
    this.viewCount = 0,
    this.isTrending = false,
    required this.createdAt,
    required this.updatedAt,
    this.likedBy = const [],
    this.bookmarkedBy = const [],
    this.tags = const [],
  });

  // Create from Firestore document
  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorAvatar: data['authorAvatar'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      videoUrl: data['videoUrl'],
      category: data['category'],
      items:
          (data['items'] as List<dynamic>?)
              ?.map((item) => PostItem.fromMap(item))
              .toList() ??
          [],
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      viewCount: data['viewCount'] ?? 0,
      isTrending: data['isTrending'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      likedBy: List<String>.from(data['likedBy'] ?? []),
      bookmarkedBy: List<String>.from(data['bookmarkedBy'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'imageUrls': imageUrls,
      'videoUrl': videoUrl,
      'category': category,
      'items': items.map((item) => item.toMap()).toList(),
      'likeCount': likeCount,
      'commentCount': commentCount,
      'viewCount': viewCount,
      'isTrending': isTrending,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'likedBy': likedBy,
      'bookmarkedBy': bookmarkedBy,
      'tags': tags,
    };
  }

  // Create a copy with updated fields
  Post copyWith({
    String? id,
    String? title,
    String? description,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    List<String>? imageUrls,
    String? videoUrl,
    String? category,
    List<PostItem>? items,
    int? likeCount,
    int? commentCount,
    int? viewCount,
    bool? isTrending,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? likedBy,
    List<String>? bookmarkedBy,
    List<String>? tags,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrl: videoUrl ?? this.videoUrl,
      category: category ?? this.category,
      items: items ?? this.items,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      viewCount: viewCount ?? this.viewCount,
      isTrending: isTrending ?? this.isTrending,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likedBy: likedBy ?? this.likedBy,
      bookmarkedBy: bookmarkedBy ?? this.bookmarkedBy,
      tags: tags ?? this.tags,
    );
  }
}

class PostItem {
  final int id;
  final String text;
  final String? url;
  final bool isCompleted;
  final int completionCount;

  const PostItem({
    required this.id,
    required this.text,
    this.url,
    this.isCompleted = false,
    this.completionCount = 0,
  });

  // Create from map
  factory PostItem.fromMap(Map<String, dynamic> map) {
    return PostItem(
      id: map['id'] ?? 0,
      text: map['text'] ?? '',
      url: map['url'],
      isCompleted: map['isCompleted'] ?? false,
      completionCount: map['completionCount'] ?? 0,
    );
  }

  // Convert to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'url': url,
      'isCompleted': isCompleted,
      'completionCount': completionCount,
    };
  }

  // Create a copy with updated fields
  PostItem copyWith({
    int? id,
    String? text,
    String? url,
    bool? isCompleted,
    int? completionCount,
  }) {
    return PostItem(
      id: id ?? this.id,
      text: text ?? this.text,
      url: url ?? this.url,
      isCompleted: isCompleted ?? this.isCompleted,
      completionCount: completionCount ?? this.completionCount,
    );
  }
}
