// lib/domain/repositories/auth_repository.dart
// Interface abstraite du repository d'authentification

import '../entities/user.dart';

abstract class AuthRepository {
  /// Inscrit un utilisateur avec un email étudiant.
  /// Lance une exception [InvalidStudentEmailException] si le domaine n'est pas valide.
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  });

  /// Connecte un utilisateur existant.
  Future<UserEntity> signIn({
    required String email,
    required String password,
  });

  /// Envoie un OTP sur l'email de l'utilisateur pour vérifier son statut étudiant.
  Future<void> sendVerificationOtp(String email);

  /// Vérifie l'OTP reçu par l'utilisateur.
  /// Retourne l'entité utilisateur mise à jour avec [isStudentVerified] = true.
  Future<UserEntity> verifyOtp({
    required String email,
    required String token,
  });

  /// Déconnecte l'utilisateur courant.
  Future<void> signOut();

  /// Retourne l'utilisateur actuellement connecté, ou null.
  Future<UserEntity?> getCurrentUser();

  /// Stream de changements d'état d'authentification.
  Stream<UserEntity?> get authStateChanges;
}
