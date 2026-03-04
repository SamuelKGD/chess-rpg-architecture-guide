// lib/domain/usecases/register_student.dart
// Cas d'utilisation : Inscription d'un étudiant avec vérification email

import '../repositories/auth_repository.dart';
import '../../core/utils/email_validator.dart';

class RegisterStudentUseCase {
  final AuthRepository _authRepository;

  const RegisterStudentUseCase(this._authRepository);

  /// Inscription avec validation stricte du domaine email.
  ///
  /// Throws [InvalidStudentEmailException] si le domaine n'est pas reconnu.
  Future<void> call({
    required String email,
    required String password,
    required String fullName,
  }) async {
    // Validation côté client avant l'appel réseau
    final result = validateStudentEmail(email);
    if (result != EmailValidationResult.valid) {
      throw InvalidStudentEmailException(
        emailValidationMessage(result) ?? 'Email étudiant invalide.',
      );
    }

    await _authRepository.signUp(
      email: email,
      password: password,
      fullName: fullName,
    );

    // Envoi automatique de l'OTP de vérification après inscription
    await _authRepository.sendVerificationOtp(email);
  }
}

class InvalidStudentEmailException implements Exception {
  final String message;
  const InvalidStudentEmailException(this.message);

  @override
  String toString() => 'InvalidStudentEmailException: $message';
}
