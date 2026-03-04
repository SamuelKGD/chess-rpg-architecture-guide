// lib/core/utils/email_validator.dart
// Utilitaire de validation des emails étudiants

import '../constants/app_constants.dart';

/// Résultat de la validation d'un email étudiant
enum EmailValidationResult {
  /// Email valide et domaine reconnu
  valid,
  /// Format d'email invalide
  invalidFormat,
  /// Format correct mais domaine non reconnu comme institutionnel
  unknownDomain,
}

/// Valide qu'un email appartient à un domaine étudiant reconnu.
///
/// Stratégie de validation en deux étapes :
/// 1. Vérification du format via regex
/// 2. Vérification du domaine dans la whitelist ou via suffixe .edu
EmailValidationResult validateStudentEmail(String email) {
  final trimmed = email.trim().toLowerCase();

  // Étape 1 : format général d'email
  if (!kStudentEmailRegex.hasMatch(trimmed)) {
    return EmailValidationResult.invalidFormat;
  }

  // Étape 2 : extraction du domaine
  final parts = trimmed.split('@');
  if (parts.length != 2 || parts[1].isEmpty) {
    return EmailValidationResult.invalidFormat;
  }

  final domain = parts[1];

  // Vérifie le suffixe .edu (cas général international)
  if (domain.endsWith('.edu')) {
    return EmailValidationResult.valid;
  }

  // Vérifie la whitelist exacte
  if (kAllowedStudentDomains.contains(domain)) {
    return EmailValidationResult.valid;
  }

  // Vérifie les sous-domaines d'académie française (ac.XX.fr ou étudiant.XX.fr)
  if (domain.contains('.ac.') || domain.startsWith('etu.') || domain.startsWith('student.')) {
    return EmailValidationResult.valid;
  }

  return EmailValidationResult.unknownDomain;
}

/// Retourne le message d'erreur localisé selon le résultat de validation.
String? emailValidationMessage(EmailValidationResult result) {
  switch (result) {
    case EmailValidationResult.valid:
      return null;
    case EmailValidationResult.invalidFormat:
      return 'Veuillez entrer une adresse email valide.';
    case EmailValidationResult.unknownDomain:
      return 'Ce domaine n\'est pas reconnu comme institutionnel. '
          'Utilisez votre adresse email universitaire (.edu ou .fr).';
  }
}
