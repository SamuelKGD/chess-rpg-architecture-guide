// lib/core/constants/app_constants.dart
// Constantes globales de l'application

/// Domaines universitaires autorisés pour la vérification étudiant
const List<String> kAllowedStudentDomains = [
  // France — universités publiques
  'univ-paris.fr',
  'sorbonne-universite.fr',
  'univ-lille.fr',
  'univ-lyon1.fr',
  'univ-lyon2.fr',
  'univ-lyon3.fr',
  'univ-bordeaux.fr',
  'univ-nantes.fr',
  'univ-rennes1.fr',
  'univ-strasbourg.fr',
  'univ-toulouse3.fr',
  'univ-grenoble-alpes.fr',
  'u-paris.fr',
  'paris-saclay.fr',
  'polytechnique.edu',
  // Grandes écoles
  'hec.edu',
  'essec.edu',
  'em-lyon.com',
  'centralelille.fr',
  // International
  'ac-paris.fr',
];

/// Regex de validation d'email étudiant
/// Accepte : tout email dont le domaine est dans [kAllowedStudentDomains]
/// ou dont le TLD est .edu
final RegExp kStudentEmailRegex = RegExp(
  r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.(edu|ac\.[a-z]{2}|[a-z]{2,6}\.fr)$',
  caseSensitive: false,
);

/// Délai de renvoi de l'OTP en secondes
const int kOtpResendCooldownSeconds = 60;

/// Durée de validité de l'OTP en minutes
const int kOtpExpiryMinutes = 10;

/// Frais de plateforme (5%)
const double kPlatformFeeRate = 0.05;

/// Nombre maximum d'articles dans le panier par vendeur
const int kMaxItemsPerVendor = 20;

/// Rayon de livraison maximal en km
const double kMaxDeliveryRadiusKm = 15.0;

/// Message affiché à l'utilisateur si le code OTP est invalide ou expiré
const String kOtpInvalidMessage =
    'Code invalide ou expiré. Veuillez réessayer.';
