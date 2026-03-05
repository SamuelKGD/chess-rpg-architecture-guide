/// Modèle de données pour une story Flash (Les Flashs).
///
/// Contenu éphémère (24h) — alertes soirées, urgences campus, offres flash.

enum StoryType { soiree, urgence, offreFlash }

class FlashStory {
  final String id;
  final String authorId;
  final String? authorUsername;
  final StoryType type;
  final String? content;
  final String? mediaUrl;
  final DateTime expiresAt;
  final DateTime createdAt;

  const FlashStory({
    required this.id,
    required this.authorId,
    this.authorUsername,
    required this.type,
    this.content,
    this.mediaUrl,
    required this.expiresAt,
    required this.createdAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory FlashStory.fromJson(Map<String, dynamic> json) {
    return FlashStory(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      authorUsername: json['author_username'] as String?,
      type: _parseStoryType(json['type'] as String),
      content: json['content'] as String?,
      mediaUrl: json['media_url'] as String?,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static StoryType _parseStoryType(String value) {
    switch (value) {
      case 'soiree':
        return StoryType.soiree;
      case 'urgence':
        return StoryType.urgence;
      case 'offre_flash':
        return StoryType.offreFlash;
      default:
        return StoryType.soiree;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_id': authorId,
      'type': _storyTypeToString(type),
      'content': content,
      'media_url': mediaUrl,
    };
  }

  static String _storyTypeToString(StoryType type) {
    switch (type) {
      case StoryType.soiree:
        return 'soiree';
      case StoryType.urgence:
        return 'urgence';
      case StoryType.offreFlash:
        return 'offre_flash';
    }
  }
}
