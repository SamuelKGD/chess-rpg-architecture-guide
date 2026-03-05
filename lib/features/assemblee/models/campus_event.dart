/// Modèle de données pour un événement campus (L'Assemblée).
///
/// Événements organisés par les groupes ou individuellement.

class CampusEvent {
  final String id;
  final String title;
  final String? description;
  final String? location;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String organizerId;
  final String? groupId;
  final int rsvpCount;
  final DateTime createdAt;

  const CampusEvent({
    required this.id,
    required this.title,
    this.description,
    this.location,
    required this.startsAt,
    this.endsAt,
    required this.organizerId,
    this.groupId,
    this.rsvpCount = 0,
    required this.createdAt,
  });

  factory CampusEvent.fromJson(Map<String, dynamic> json) {
    return CampusEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: json['ends_at'] != null
          ? DateTime.parse(json['ends_at'] as String)
          : null,
      organizerId: json['organizer_id'] as String,
      groupId: json['group_id'] as String?,
      rsvpCount: (json['rsvp_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'starts_at': startsAt.toIso8601String(),
      'ends_at': endsAt?.toIso8601String(),
      'organizer_id': organizerId,
      'group_id': groupId,
    };
  }
}
