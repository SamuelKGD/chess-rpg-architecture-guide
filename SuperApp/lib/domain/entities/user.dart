// lib/domain/entities/user.dart
// Entité domaine : Profil utilisateur étudiant

class UserEntity {
  final String id;
  final String authId;
  final String email;
  final String? fullName;
  final String schoolDomain;
  final bool isStudentVerified;
  final DateTime? verifiedAt;
  final String? avatarUrl;
  final String? phone;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.authId,
    required this.email,
    this.fullName,
    required this.schoolDomain,
    required this.isStudentVerified,
    this.verifiedAt,
    this.avatarUrl,
    this.phone,
    required this.createdAt,
  });

  UserEntity copyWith({
    String? fullName,
    bool? isStudentVerified,
    DateTime? verifiedAt,
    String? avatarUrl,
    String? phone,
  }) {
    return UserEntity(
      id: id,
      authId: authId,
      email: email,
      fullName: fullName ?? this.fullName,
      schoolDomain: schoolDomain,
      isStudentVerified: isStudentVerified ?? this.isStudentVerified,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      createdAt: createdAt,
    );
  }
}
