# 🔥 VISION UX & ARCHITECTURE — Super-App Étudiante

> **ADN** : Militant, brutaliste, émancipateur — "Par et pour les étudiants."
> **Stack** : Flutter · Supabase · Stripe · IZLY API
> **Design System** : Modern Brutalism (haute intensité, animations fluides 60fps)

---

## Table des Matières

1. [Philosophie UX](#1-philosophie-ux)
2. [Les 4 Piliers](#2-les-4-piliers)
3. [Design System — Modern Brutalism](#3-design-system--modern-brutalism)
4. [Architecture Flutter](#4-architecture-flutter)
5. [Modélisation DB (Supabase)](#5-modélisation-db-supabase)
6. [Intégrations Externes](#6-intégrations-externes)
7. [Roadmap Itérative](#7-roadmap-itérative)

---

## 1. Philosophie UX

### Fusion d'identité militante et d'engagement moderne

L'application fusionne les **mécaniques d'engagement les plus efficaces** (TikTok, Instagram, Facebook) avec une **identité visuelle brutaliste et militante** inspirée des révoltes étudiantes. Le résultat : une expérience qui capte l'attention sans être toxique.

| Principe | Traduction UX |
|----------|---------------|
| **Par et pour les étudiants** | Algorithme chronologique + Karma (pas de rétention toxique) |
| **Brutalisme** | Typographie massive, bordures épaisses, ombres dures |
| **Émancipation financière** | Contre-Marché P2P intégré nativement |
| **Modernité** | Swipe vertical, stories éphémères, animations 60fps |

---

## 2. Les 4 Piliers

### 2.1 "Le Porte-Voix" — Fil d'actualité vertical (Inspiré TikTok)

| Aspect | Détail |
|--------|--------|
| **Mécanique** | `PageView` vertical plein écran (Swipe Up) |
| **Contenu** | Posts texte brutalistes, vidéos campus, "Tracts" visuels |
| **Algorithme** | Chronologique + Karma (upvotes). Zéro rétention toxique. |
| **Widget clé** | `PageView(scrollDirection: Axis.vertical)` |

**Flux utilisateur :**
```
Ouverture app → Porte-Voix (plein écran)
  ↓ Swipe Up → Post suivant
  ↓ Tap Upvote → Karma +1
  ↓ Tap Commentaire → Bottom Sheet
  ↓ Tap Partager → Share Sheet natif
```

### 2.2 "Les Flashs" — Stories éphémères (Inspiré Instagram)

| Aspect | Détail |
|--------|--------|
| **Mécanique** | `ListView` horizontal en haut de l'écran |
| **Contenu** | Éphémère (24h) — alertes soirées, urgences campus, offres flash |
| **Position** | Bandeau au-dessus du Porte-Voix |
| **Widget clé** | `ListView(scrollDirection: Axis.horizontal)` |

**Types de Flashs :**
- 🎉 **Soirée** — Événements éphémères
- 🚨 **Urgence** — Alertes campus temps réel
- 🛒 **Offre Flash** — Promos Contre-Marché ("Rupture de stock imminente au RU")

### 2.3 "L'Assemblée" — Organisation communautaire (Inspiré Facebook 2004)

| Aspect | Détail |
|--------|--------|
| **Mécanique** | Onglet dédié avec navigation par groupes |
| **Contenu** | Groupes par filière, fiches de cours P2P, événements, annuaire |
| **Widget clé** | `TabBarView` + `ListView` imbriqué |

**Sous-sections :**
- 📚 **Groupes Filières** — Droit, Info, Médecine, etc.
- 📋 **Fiches de Cours** — Partage P2P par matière
- 📅 **Événements** — Création, RSVP, rappels
- 🔍 **Annuaire Campus** — Recherche étudiants/associations

### 2.4 "Le Contre-Marché" — Moteur économique P2P

| Aspect | Détail |
|--------|--------|
| **Mécanique** | Intégration fluide dans Porte-Voix et Assemblée |
| **Paiement** | IZLY (Crous) + Stripe |
| **Livraison** | Système "Alliés" — coursiers étudiants P2P prioritaires |
| **Widget clé** | Cards intégrées dans le feed + page dédiée |

**Flux commande :**
```
Produit dans le feed → Tap "Commander"
  → Sélection méthode paiement (IZLY / Stripe)
  → Attribution coursier "Allié" (étudiant P2P)
  → Si aucun Allié dispo → coursier pro
  → Suivi temps réel
```

---

## 3. Design System — Modern Brutalism

### 3.1 Palette de Couleurs

```dart
// lib/design_system/brutalist_theme.dart

class BrutalistColors {
  // Backgrounds — High Contrast
  static const Color backgroundDark  = Color(0xFF0A0A0A);
  static const Color backgroundLight = Color(0xFFF5F5F0);
  static const Color surface         = Color(0xFF1A1A1A);

  // Accents — Néon / Stabilo (Call-to-Action)
  static const Color accentYellow = Color(0xFFE6FF00);
  static const Color accentRed    = Color(0xFFFF2D2D);
  static const Color accentGreen  = Color(0xFF00FF85);

  // Text
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textOnAccent  = Color(0xFF0A0A0A);
}
```

### 3.2 Typographie

```dart
class BrutalistTypography {
  // Titres — Effet pancarte / tract
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'SpaceGrotesk',  // Police Display massive sans-serif
    fontSize: 48,
    fontWeight: FontWeight.w900,
    letterSpacing: -2,
    height: 0.95,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
  );

  // Corps de texte
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
}
```

### 3.3 Composants Brutalistes

| Composant | Style |
|-----------|-------|
| **Boutons** | Bordures 3px, ombres dures (offset 4px, pas de blur), fond accent |
| **Cards** | Bordures épaisses 2px, coins droits ou très léger radius (4px) |
| **Inputs** | Bordure noire 2px, fond transparent, placeholder uppercase |
| **Avatars** | Carrés avec bordure, pas de cercle |
| **Animations** | Ultra-fluides 60fps — `spring()` curves, pas de `linear` |

```dart
class BrutalistDecorations {
  static BoxDecoration hardShadowCard({Color borderColor = Colors.white}) {
    return BoxDecoration(
      color: BrutalistColors.surface,
      border: Border.all(color: borderColor, width: 2),
      boxShadow: const [
        BoxShadow(
          color: Colors.white24,
          offset: Offset(4, 4),
          blurRadius: 0, // Ombre dure — pas de blur
        ),
      ],
    );
  }
}
```

---

## 4. Architecture Flutter

### 4.1 Arborescence du Projet

```
lib/
├── main.dart
├── app.dart
│
├── design_system/
│   ├── brutalist_theme.dart        # ThemeData, couleurs, typo
│   ├── brutalist_components.dart   # Boutons, cards, inputs réutilisables
│   └── brutalist_animations.dart   # Courbes et transitions 60fps
│
├── features/
│   ├── porte_voix/                 # Pilier 1 — Feed vertical
│   │   ├── models/
│   │   │   └── vertical_post.dart
│   │   ├── views/
│   │   │   ├── porte_voix_screen.dart
│   │   │   └── post_card.dart
│   │   └── providers/
│   │       └── porte_voix_provider.dart
│   │
│   ├── flashs/                     # Pilier 2 — Stories éphémères
│   │   ├── models/
│   │   │   └── flash_story.dart
│   │   ├── views/
│   │   │   ├── flashs_bar.dart
│   │   │   └── flash_viewer.dart
│   │   └── providers/
│   │       └── flashs_provider.dart
│   │
│   ├── assemblee/                  # Pilier 3 — Communauté
│   │   ├── models/
│   │   │   ├── study_group.dart
│   │   │   └── campus_event.dart
│   │   ├── views/
│   │   │   ├── assemblee_screen.dart
│   │   │   └── group_detail_screen.dart
│   │   └── providers/
│   │       └── assemblee_provider.dart
│   │
│   └── contre_marche/              # Pilier 4 — Marketplace P2P
│       ├── models/
│       │   ├── market_listing.dart
│       │   └── market_order.dart
│       ├── views/
│       │   ├── contre_marche_screen.dart
│       │   └── order_flow.dart
│       └── providers/
│           └── contre_marche_provider.dart
│
├── core/
│   ├── supabase_client.dart        # Configuration Supabase
│   ├── auth_service.dart           # Authentification
│   └── karma_engine.dart           # Calcul Karma / classement
│
└── shared/
    ├── widgets/                    # Widgets transverses
    └── utils/                      # Helpers, extensions
```

### 4.2 Navigation Principale

```
BottomNavigationBar (3 onglets)
  ├── [0] Porte-Voix  → Feed vertical + Flashs (bandeau haut)
  ├── [1] Assemblée   → Groupes, événements, annuaire
  └── [2] Profil      → Stats Karma, commandes, paramètres

Le Contre-Marché est intégré transversalement (pas d'onglet dédié).
```

---

## 5. Modélisation DB (Supabase)

> Schéma SQL complet disponible dans [`supabase/schema.sql`](supabase/schema.sql)

### 5.1 Vue d'ensemble des Tables

```
┌──────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   profiles   │────▶│  vertical_posts  │     │    stories      │
│  (étudiants) │     │  (Porte-Voix)    │     │  (Flashs 24h)   │
└──────┬───────┘     └──────────────────┘     └─────────────────┘
       │
       ├────▶ ┌──────────────────┐     ┌─────────────────┐
       │      │  study_groups    │────▶│  group_members   │
       │      │  (Assemblée)     │     └─────────────────┘
       │      └──────────────────┘
       │
       ├────▶ ┌──────────────────┐     ┌─────────────────┐
       │      │ market_listings  │────▶│  market_orders   │
       │      │ (Contre-Marché)  │     │  (commandes)     │
       │      └──────────────────┘     └─────────────────┘
       │
       └────▶ ┌──────────────────┐
              │   karma_votes    │
              │  (upvotes)       │
              └──────────────────┘
```

### 5.2 Tables Principales

| Table | Rôle | Clé étrangère |
|-------|------|---------------|
| `profiles` | Profils étudiants (campus, filière, karma) | `auth.users.id` |
| `vertical_posts` | Posts du Porte-Voix | `profiles.id` |
| `stories` | Flashs éphémères (TTL 24h) | `profiles.id` |
| `karma_votes` | Votes up/down sur les posts | `profiles.id`, `vertical_posts.id` |
| `study_groups` | Groupes par filière | `profiles.id` (créateur) |
| `group_members` | Membres d'un groupe | `profiles.id`, `study_groups.id` |
| `campus_events` | Événements campus | `profiles.id`, `study_groups.id` |
| `market_listings` | Annonces Contre-Marché | `profiles.id` |
| `market_orders` | Commandes avec paiement | `profiles.id` (acheteur/coursier) |

### 5.3 Row Level Security (RLS)

Toutes les tables utilisent **Supabase RLS** :
- Les utilisateurs ne peuvent modifier que **leurs propres** données.
- Les lectures sont publiques pour le feed et les groupes.
- Les commandes sont visibles uniquement par l'acheteur, le vendeur et le coursier.

---

## 6. Intégrations Externes

### 6.1 IZLY (API Crous)

| Endpoint | Usage |
|----------|-------|
| Authentification IZLY | Lier le compte Crous de l'étudiant |
| Paiement IZLY | Payer les commandes Contre-Marché via solde IZLY |
| Consultation solde | Afficher le solde dans le profil |

### 6.2 Stripe

| Fonctionnalité | Usage |
|-----------------|-------|
| Stripe Connect | Chaque vendeur/coursier a un compte connecté |
| Payment Intents | Paiements sécurisés par carte |
| Webhooks | Confirmation de paiement → mise à jour commande |

### 6.3 Supabase Realtime

| Canal | Usage |
|-------|-------|
| `vertical_posts` | Nouveau post → push dans le feed |
| `stories` | Nouveau Flash → mise à jour bandeau |
| `market_orders` | Suivi commande temps réel |

---

## 7. Roadmap Itérative

### Phase 1 — MVP (4 semaines)
- [ ] Authentification Supabase (email + magic link)
- [ ] Feed Porte-Voix (PageView vertical + posts texte)
- [ ] Flashs (stories éphémères 24h)
- [ ] Design System brutaliste de base

### Phase 2 — Communauté (3 semaines)
- [ ] Assemblée : groupes par filière
- [ ] Partage de fiches de cours P2P
- [ ] Événements campus + RSVP

### Phase 3 — Marketplace (4 semaines)
- [ ] Contre-Marché : annonces + commandes
- [ ] Intégration Stripe Connect
- [ ] Système Alliés (coursiers étudiants P2P)

### Phase 4 — Polish (2 semaines)
- [ ] Intégration IZLY
- [ ] Animations brutalistes 60fps
- [ ] Tests de charge Supabase
- [ ] Beta campus pilote

---

> **Ce document est vivant.** Il sera mis à jour à chaque itération pour refléter les décisions d'architecture et de design prises en cours de développement.
