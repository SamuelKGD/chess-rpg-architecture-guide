# EduMarket Super-App — Structure du Projet

## Arborescence complète

```
SuperApp/
├── TECH_SPEC.md                              # ← Spécifications techniques (à valider)
│
├── lib/
│   ├── core/                                 # Code transversal (aucune dépendance UI/data)
│   │   ├── constants/
│   │   │   └── app_constants.dart            # Domaines étudiants, regex, constantes
│   │   ├── errors/
│   │   │   └── (exceptions métier)
│   │   └── utils/
│   │       └── email_validator.dart          # Logique de validation email institutionnel
│   │
│   ├── domain/                               # Couche Domaine (pure Dart, 0 framework)
│   │   ├── entities/
│   │   │   ├── user.dart                     # Profil étudiant
│   │   │   ├── vendor.dart                   # Enseigne partenaire
│   │   │   ├── product.dart                  # Article du catalogue
│   │   │   └── cart.dart                     # Panier multi-vendeurs (logique complexe)
│   │   ├── repositories/                     # Interfaces abstraites (contrats)
│   │   │   ├── auth_repository.dart
│   │   │   ├── vendor_repository.dart
│   │   │   └── order_repository.dart
│   │   └── usecases/                         # Cas d'utilisation métier
│   │       └── register_student.dart         # Inscription avec validation email bloquante
│   │
│   ├── data/                                 # Couche Données (à implémenter Phase 2)
│   │   ├── datasources/
│   │   │   └── (Supabase, Stuart API clients)
│   │   ├── models/
│   │   │   └── (DTOs JSON Supabase)
│   │   └── repositories/
│   │       └── (Implémentations concrètes)
│   │
│   └── presentation/                         # Couche UI (Flutter)
│       ├── screens/
│       │   ├── auth/
│       │   │   ├── register_screen.dart       # Inscription bloquante sans email valide
│       │   │   └── otp_verification_screen.dart # Vérification OTP 6 chiffres
│       │   ├── home/
│       │   │   └── hub_dashboard_screen.dart  # Hub étudiant + codes promo
│       │   ├── marketplace/
│       │   │   └── vendor_list_screen.dart    # Listing vendeurs + filtres catégorie
│       │   └── cart/
│       │       └── cart_screen.dart           # Panier multi-vendeurs
│       ├── widgets/
│       │   └── (Composants réutilisables)
│       └── blocs/
│           └── cart_bloc.dart                 # State Management panier (BLoC pattern)
│
├── supabase/
│   ├── migrations/
│   │   └── 001_initial_schema.sql             # Schéma DB complet (Users, Vendors, Catalog, Orders)
│   └── functions/
│       ├── validate-order/
│       │   └── index.ts                       # Edge Function : validation commande + Stripe
│       ├── delivery-fee/
│       │   └── index.ts                       # Edge Function : frais livraison dynamiques
│       └── dispatch-order/
│           └── index.ts                       # Edge Function : dispatch multi-vendeurs
│
└── test/
    └── email_validator_test.dart              # Tests unitaires (email + CartEntity)
```

---

## Principe de dépendance (Clean Architecture)

```
┌─────────────────────────────────────────┐
│  presentation/  (Flutter + BLoC)        │
│   ↓ dépend de                           │
├─────────────────────────────────────────┤
│  domain/  (Pure Dart)                   │
│   ↑ implémenté par                      │
├─────────────────────────────────────────┤
│  data/  (Supabase + APIs externes)      │
└─────────────────────────────────────────┘
         ↕ injection via get_it
    core/ (transversal à toutes les couches)
```

---

## Flux d'authentification étudiant

```
User saisit email
      ↓
validateStudentEmail() ← regex + whitelist domaines
      ↓ (invalide)           ↓ (valide)
Erreur bloquante UI     signUp() Supabase Auth
                              ↓
                        sendVerificationOtp()
                              ↓
                        OtpVerificationScreen
                              ↓
                        verifyOtp() Supabase
                              ↓
                        users.is_student_verified = TRUE
                              ↓
                        HubDashboardScreen ✅
```

---

## Flux commande multi-vendeurs

```
CartScreen (items de plusieurs vendeurs)
      ↓
validate-order Edge Function
   ├─ Vérif. stock + disponibilité
   ├─ Application code promo
   ├─ Appel delivery-fee (Haversine distance)
   └─ Création PaymentIntent Stripe
      ↓
Paiement Stripe (3DS2 si requis)
      ↓
dispatch-order Edge Function
   ├─ Vérif. PaymentIntent succeeded
   ├─ Pour chaque vendeur :
   │   ├─ Transfer Stripe Connect (90%)
   │   └─ Création job Stuart API
   └─ Mise à jour statuts (Realtime Supabase)
```
