/// Modèle de données pour un groupe d'étude (L'Assemblée).
///
/// Groupes par filière pour le partage de fiches de cours P2P.

class StudyGroup {
  final String id;
  final String name;
  final String? description;
  final String? filiere;
  final String? campus;
  final String creatorId;
  final int memberCount;
  final DateTime createdAt;

  const StudyGroup({
    required this.id,
    required this.name,
    this.description,
    this.filiere,
    this.campus,
    required this.creatorId,
    this.memberCount = 0,
    required this.createdAt,
  });

  factory StudyGroup.fromJson(Map<String, dynamic> json) {
    return StudyGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      filiere: json['filiere'] as String?,
      campus: json['campus'] as String?,
      creatorId: json['creator_id'] as String,
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'filiere': filiere,
      'campus': campus,
      'creator_id': creatorId,
    };
  }
}
