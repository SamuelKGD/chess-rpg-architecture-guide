# TECH_SPEC.md — Super-App Étudiante

> Document de référence pour les choix techniques du projet. À valider avant la génération du code principal.

---

## 1. Vue d'ensemble

**Nom du projet** : EduMarket Super-App  
**Cible** : Étudiants vérifiés via email institutionnel (.edu / .fr)  
**Modèle** : Agrégateur de livraison multi-enseignes avec accès exclusif étudiant  

---

## 2. Stack Technique Retenue

### Frontend : Flutter

| Critère | Détail |
|---------|--------|
| **Langage** | Dart |
| **Moteur de rendu** | Skia / Impeller (iOS) |
| **Cible** | iOS + Android (+ Web future) |
| **Justification** | Performance native, un seul codebase, widgets riches |

**Packages clés :**

```yaml
dependencies:
  flutter_bloc: ^8.1.3        # State Management (BLoC pattern)
  go_router: ^13.0.0          # Navigation déclarative
  supabase_flutter: ^2.3.0    # Backend-as-a-Service
  stripe_flutter: ^10.1.0     # Paiement
  dio: ^5.4.0                 # HTTP client
  freezed_annotation: ^2.4.1  # Immutable data classes
  json_serializable: ^6.7.1   # Sérialisation JSON
  get_it: ^7.6.7              # Injection de dépendances
  shared_preferences: ^2.2.2  # Stockage local
  cached_network_image: ^3.3.1 # Images en cache
  geolocator: ^11.0.0         # Géolocalisation

dev_dependencies:
  build_runner: ^2.4.8
  freezed: ^2.4.7
  mocktail: ^1.0.3
  bloc_test: ^9.1.6
```

---

### Backend : Supabase

| Service | Usage |
|---------|-------|
| **Auth** | Email OTP, session JWT, Row Level Security |
| **PostgreSQL** | Base de données relationnelle principale |
| **Edge Functions** | Logique métier (Deno/TypeScript) |
| **Realtime** | Mises à jour de statut des commandes |
| **Storage** | Images produits / logos vendeurs |

**Justification** : Open-source, Auth + DB + Realtime en un, compatible RLS pour sécuriser les données par rôle.

---

### Paiement : Stripe Connect

| Feature | Détail |
|---------|--------|
| **Mode** | Stripe Connect (Platform + Connected Accounts) |
| **Split** | Application fee automatique plateforme/vendeur |
| **Méthodes** | Card, Apple Pay, Google Pay |
| **Sécurité** | PCI-DSS Level 1, 3D Secure 2 |

---

### Logistique : Stuart API (Phase 1)

| Option | Statut |
|--------|--------|
| Stuart API | ✅ Retenu (Phase 1) |
| Uber Direct | 🔄 Fallback Phase 2 |
| Flotte interne | 🔮 Phase 3 (si volume suffisant) |

---

## 3. Architecture Applicative : Clean Architecture

```
lib/
├── core/                    # Transversal (erreurs, constantes, utils)
│   ├── constants/
│   ├── errors/
│   └── utils/
├── data/                    # Couche Données
│   ├── datasources/         # Supabase, APIs externes
│   ├── models/              # DTOs + sérialisation JSON
│   └── repositories/        # Implémentations concrètes
├── domain/                  # Couche Domaine (pure Dart, zéro framework)
│   ├── entities/            # Objets métier
│   ├── repositories/        # Interfaces abstraites
│   └── usecases/            # Cas d'utilisation
└── presentation/            # Couche UI
    ├── screens/             # Pages de l'application
    ├── widgets/             # Composants réutilisables
    └── blocs/               # State Management (BLoC)
```

**Principe de dépendance** : `presentation` → `domain` ← `data`  
Le domaine ne dépend d'aucun framework externe.

---

## 4. Sécurité & Conformité

| Mesure | Implémentation |
|--------|---------------|
| Vérification étudiant | Regex + whitelist domaines + OTP email |
| Auth token | JWT signé Supabase (expiration 1h, refresh 7j) |
| Données sensibles | Row Level Security (RLS) PostgreSQL |
| Paiement | Jamais de données carte côté serveur (Stripe.js) |
| RGPD | Consentement explicite, droit à l'oubli via Supabase |

---

## 5. Environnements

| Env | URL Supabase | Stripe Mode |
|-----|-------------|-------------|
| `dev` | `https://xxx-dev.supabase.co` | Test |
| `staging` | `https://xxx-stg.supabase.co` | Test |
| `production` | `https://xxx.supabase.co` | Live |

Configuration via fichiers `.env` + `flutter_dotenv`.

---

## 6. Roadmap des Phases

| Phase | Contenu | Durée estimée |
|-------|---------|---------------|
| **Phase 1** | Auth + DB + Structure | 2 semaines |
| **Phase 2** | Écrans principaux + Panier | 3 semaines |
| **Phase 3** | Paiement + Logistique | 2 semaines |
| **Phase 4** | Tests + Optimisation | 1 semaine |

---

> ⚠️ **Validation requise** : Confirmer la stack avant la génération du code `main.dart` et des premiers écrans.
