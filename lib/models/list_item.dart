class ListItem {
  final int id;
  final String text;
  final String? url;
  final bool isCompleted;
  final int completionCount;

  const ListItem({
    required this.id,
    required this.text,
    this.url,
    this.isCompleted = false,
    this.completionCount = 0,
  });

  // Create from map
  factory ListItem.fromMap(Map<String, dynamic> map) {
    return ListItem(
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
  ListItem copyWith({
    int? id,
    String? text,
    String? url,
    bool? isCompleted,
    int? completionCount,
  }) {
    return ListItem(
      id: id ?? this.id,
      text: text ?? this.text,
      url: url ?? this.url,
      isCompleted: isCompleted ?? this.isCompleted,
      completionCount: completionCount ?? this.completionCount,
    );
  }
}
