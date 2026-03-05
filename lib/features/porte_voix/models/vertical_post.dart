/// Modèle de données pour un post vertical (Le Porte-Voix).
///
/// Représente un post plein écran dans le feed vertical swipeable.
/// Types : text, image, video, tract.

enum PostType { text, image, video, tract }

class VerticalPost {
  final String id;
  final String authorId;
  final String? authorUsername;
  final PostType type;
  final String? title;
  final String? body;
  final String? mediaUrl;
  final int karmaScore;
  final DateTime createdAt;

  const VerticalPost({
    required this.id,
    required this.authorId,
    this.authorUsername,
    required this.type,
    this.title,
    this.body,
    this.mediaUrl,
    this.karmaScore = 0,
    required this.createdAt,
  });

  factory VerticalPost.fromJson(Map<String, dynamic> json) {
    return VerticalPost(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      authorUsername: json['author_username'] as String?,
      type: PostType.values.byName(json['type'] as String),
      title: json['title'] as String?,
      body: json['body'] as String?,
      mediaUrl: json['media_url'] as String?,
      karmaScore: (json['karma_score'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_id': authorId,
      'type': type.name,
      'title': title,
      'body': body,
      'media_url': mediaUrl,
    };
  }
}
