# 📱 Arborescence Flutter MVP — Super-App Étudiante

## Table des Matières

1. [Structure du Projet](#structure-du-projet)
2. [Architecture par Feature](#architecture-par-feature)
3. [Design System "Campus"](#design-system-campus)
4. [Dépendances Clés](#dépendances-clés)

---

## Structure du Projet

```
superapp_etudiant/
├── android/
├── ios/
├── lib/
│   ├── main.dart                          # Point d'entrée
│   ├── app.dart                           # MaterialApp + Router
│   │
│   ├── core/                              # Utilitaires transversaux
│   │   ├── constants/
│   │   │   ├── app_colors.dart            # Palette Design System "Campus"
│   │   │   ├── app_typography.dart        # Typographie
│   │   │   ├── app_spacing.dart           # Espacements
│   │   │   └── api_endpoints.dart         # URLs API
│   │   ├── theme/
│   │   │   ├── campus_theme.dart          # ThemeData principal
│   │   │   └── campus_dark_theme.dart     # Mode sombre
│   │   ├── extensions/
│   │   │   ├── context_extensions.dart
│   │   │   └── datetime_extensions.dart
│   │   ├── utils/
│   │   │   ├── validators.dart            # Validation email .fr/.edu
│   │   │   └── formatters.dart            # Formatage prix, dates
│   │   └── errors/
│   │       ├── app_exception.dart
│   │       └── error_handler.dart
│   │
│   ├── data/                              # Couche données
│   │   ├── repositories/
│   │   │   ├── auth_repository.dart
│   │   │   ├── payment_repository.dart
│   │   │   ├── social_repository.dart
│   │   │   ├── discount_repository.dart
│   │   │   ├── delivery_repository.dart
│   │   │   └── menu_repository.dart
│   │   ├── models/
│   │   │   ├── user_model.dart
│   │   │   ├── post_model.dart
│   │   │   ├── order_model.dart
│   │   │   ├── payment_model.dart
│   │   │   ├── discount_model.dart
│   │   │   ├── partner_model.dart
│   │   │   ├── delivery_job_model.dart
│   │   │   ├── ru_menu_model.dart
│   │   │   └── karma_model.dart
│   │   └── providers/
│   │       ├── supabase_provider.dart     # Client Supabase
│   │       └── stripe_provider.dart       # Client Stripe
│   │
│   ├── services/                          # Logique métier
│   │   ├── auth_service.dart              # Inscription, login, vérification
│   │   ├── payment_service.dart           # Paiement Izly + Stripe + Split
│   │   ├── izly_service.dart              # Intégration spécifique Izly
│   │   ├── moderation_service.dart        # Signalement, shadowban
│   │   ├── karma_service.dart             # Gestion du karma
│   │   ├── notification_service.dart      # Notifications transactionnelles
│   │   └── ocr_service.dart              # OCR carte étudiante
│   │
│   └── features/                          # Features (écrans)
│       │
│       ├── auth/                          # Authentification
│       │   ├── screens/
│       │   │   ├── login_screen.dart
│       │   │   ├── register_screen.dart
│       │   │   ├── email_verification_screen.dart
│       │   │   └── student_card_upload_screen.dart
│       │   └── widgets/
│       │       ├── university_selector.dart
│       │       └── verification_status_badge.dart
│       │
│       ├── home/                          # Fil d'actualité campus
│       │   ├── screens/
│       │   │   └── home_screen.dart
│       │   └── widgets/
│       │       ├── campus_feed.dart       # Fil mixte
│       │       ├── ru_menu_card.dart      # Carte menu RU
│       │       ├── post_card.dart         # Carte post étudiant
│       │       ├── deal_card.dart         # Carte bon plan
│       │       └── create_post_sheet.dart # Bottom sheet création post
│       │
│       ├── payment/                       # Module paiement
│       │   ├── screens/
│       │   │   ├── payment_screen.dart
│       │   │   ├── izly_webview_screen.dart
│       │   │   └── payment_confirmation_screen.dart
│       │   └── widgets/
│       │       ├── payment_method_selector.dart
│       │       ├── split_bill_summary.dart
│       │       └── payment_status_indicator.dart
│       │
│       ├── marketplace/                   # Marketplace & réductions
│       │   ├── screens/
│       │   │   ├── marketplace_screen.dart
│       │   │   └── discount_detail_screen.dart
│       │   └── widgets/
│       │       ├── discount_card.dart
│       │       ├── partner_logo.dart
│       │       └── category_filter.dart
│       │
│       ├── delivery/                      # Livraison & job board
│       │   ├── screens/
│       │   │   ├── delivery_tracking_screen.dart
│       │   │   └── delivery_jobs_screen.dart
│       │   └── widgets/
│       │       ├── delivery_status_timeline.dart
│       │       └── job_card.dart
│       │
│       ├── social/                        # Réseau social
│       │   ├── screens/
│       │   │   ├── post_detail_screen.dart
│       │   │   └── report_screen.dart
│       │   └── widgets/
│       │       ├── comment_thread.dart
│       │       ├── karma_badge.dart
│       │       └── report_dialog.dart
│       │
│       └── profile/                       # Profil & paramètres
│           ├── screens/
│           │   ├── profile_screen.dart
│           │   └── settings_screen.dart
│           └── widgets/
│               ├── karma_summary.dart
│               ├── verification_info.dart
│               └── payment_methods_list.dart
│
├── test/                                  # Tests
│   ├── unit/
│   │   ├── services/
│   │   │   ├── payment_service_test.dart
│   │   │   ├── karma_service_test.dart
│   │   │   └── moderation_service_test.dart
│   │   └── models/
│   │       ├── user_model_test.dart
│   │       └── order_model_test.dart
│   ├── widget/
│   │   ├── post_card_test.dart
│   │   ├── ru_menu_card_test.dart
│   │   └── discount_card_test.dart
│   └── integration/
│       ├── payment_flow_test.dart
│       └── auth_flow_test.dart
│
├── supabase/                              # Configuration Supabase
│   ├── migrations/
│   │   ├── 001_create_universities.sql
│   │   ├── 002_create_users.sql
│   │   ├── 003_create_karma.sql
│   │   ├── 004_create_partners_discounts.sql
│   │   ├── 005_create_orders_payments.sql
│   │   ├── 006_create_posts_moderation.sql
│   │   ├── 007_create_delivery_jobs.sql
│   │   ├── 008_create_ru_menus.sql
│   │   └── 009_create_rls_policies.sql
│   └── functions/
│       ├── confirm-izly-payment/
│       │   └── index.ts
│       ├── create-split-order/
│       │   └── index.ts
│       ├── check-report-threshold/
│       │   └── index.ts
│       └── sync-ru-menu/
│           └── index.ts
│
├── assets/
│   ├── images/
│   │   ├── logo.svg
│   │   └── onboarding/
│   ├── fonts/
│   │   └── Inter/                         # Police Design System
│   └── i18n/
│       └── fr.json                        # Traductions françaises
│
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

---

## Architecture par Feature

Chaque feature suit le pattern **Screen → Widget → Service → Repository** :

```
┌──────────────────────────────────────────────┐
│  Feature: Payment                             │
│                                               │
│  Screen (payment_screen.dart)                 │
│    └── Widgets (split_bill_summary.dart)      │
│          └── Service (payment_service.dart)    │
│                └── Repository                 │
│                    (payment_repository.dart)   │
│                      └── Provider             │
│                         (supabase_provider.dart)│
└──────────────────────────────────────────────┘
```

### Responsabilités

| Couche | Rôle | Exemple |
|--------|------|---------|
| **Screen** | Orchestre les widgets, gère la navigation | `PaymentScreen` affiche le récapitulatif + lance le paiement |
| **Widget** | Composant UI réutilisable | `SplitBillSummary` affiche la répartition Izly/CB |
| **Service** | Logique métier | `PaymentService.createSplitPayment()` orchestre Izly + Stripe |
| **Repository** | Accès aux données (Supabase) | `PaymentRepository.insertPayment()` écrit en base |
| **Provider** | Client technique (Supabase, Stripe) | `SupabaseProvider.client` fournit l'instance |

---

## Design System "Campus"

### Palette de Couleurs

```dart
// lib/core/constants/app_colors.dart

class AppColors {
  // Couleurs principales
  static const Color primary = Color(0xFF1A56DB);       // Bleu campus
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1E3A8A);

  // Accent
  static const Color accent = Color(0xFF10B981);         // Vert succès
  static const Color accentWarm = Color(0xFFF59E0B);     // Jaune attention

  // Neutres
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);

  // Sémantiques
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Karma
  static const Color karmaNewcomer = Color(0xFF9CA3AF);
  static const Color karmaMember = Color(0xFF3B82F6);
  static const Color karmaTrusted = Color(0xFF10B981);
  static const Color karmaAmbassador = Color(0xFFF59E0B);
}
```

### Typographie

```dart
// lib/core/constants/app_typography.dart

class AppTypography {
  static const String fontFamily = 'Inter';

  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Color(0xFF6B7280),
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.0,
  );
}
```

### Composants UI Principaux

| Composant | Description |
|-----------|-------------|
| `CampusCard` | Carte avec ombre légère, coins arrondis 12px |
| `CampusButton` | Bouton primaire bleu, secondaire outline |
| `CampusBadge` | Badge karma (couleur selon niveau) |
| `CampusAvatar` | Avatar rond avec badge vérification |
| `CampusBottomSheet` | Bottom sheet pour actions (créer post, signaler) |
| `CampusChip` | Tag filtrable (catégorie, type de post) |

---

## Dépendances Clés

```yaml
# pubspec.yaml (extrait)

dependencies:
  flutter:
    sdk: flutter

  # Backend
  supabase_flutter: ^2.0.0           # Client Supabase
  
  # Paiement
  flutter_stripe: ^10.0.0            # Stripe SDK
  flutter_inappwebview: ^6.0.0       # Webview Izly sécurisée
  
  # État
  flutter_riverpod: ^2.0.0           # State management
  
  # Navigation
  go_router: ^14.0.0                 # Routing déclaratif
  
  # UI
  cached_network_image: ^3.0.0       # Images avec cache
  shimmer: ^3.0.0                    # Loading placeholders
  
  # Utilitaires
  intl: ^0.19.0                      # Formatage dates/nombres FR
  google_mlkit_text_recognition: ^0.12.0  # OCR carte étudiante
  image_picker: ^1.0.0               # Upload photo carte

dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.0.0                    # Mocks pour tests
  build_runner: ^2.0.0
```
