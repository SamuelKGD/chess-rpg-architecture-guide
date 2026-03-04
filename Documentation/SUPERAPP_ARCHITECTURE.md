# 🎓 Architecture Technique — Super-App Étudiante Française Souveraine

**Philosophie : "Des étudiants, pour les étudiants"**
**Politique : 0 notification marketing — Rétention organique via le social**

---

## Table des Matières

1. [Vue d'Ensemble](#vue-densemble)
2. [Stack Technique](#stack-technique)
3. [Modules Principaux](#modules-principaux)
4. [Sécurité & Souveraineté](#sécurité--souveraineté)
5. [Architecture en Couches](#architecture-en-couches)
6. [Documents Détaillés](#documents-détaillés)

---

## Vue d'Ensemble

La Super-App étudiante est une plateforme mobile souveraine conçue pour centraliser les besoins quotidiens des étudiants français :

- **Paiement hybride** (Izly + CB via Stripe Connect)
- **Vérification d'identité** étudiante (email .fr/.edu + OCR carte étudiante)
- **Marketplace agrégateur** de réductions (Spotify, Unidays, partenaires locaux)
- **Réseau social campus** avec fil d'actualité local (pull, pas push)
- **Logistique étudiante** (livraison par étudiants, job board intégré)

### Principes Directeurs

| Principe | Description |
|----------|-------------|
| **Pull > Push** | L'utilisateur vient consulter, aucune notification marketing |
| **Souveraineté** | Données hébergées en France (Supabase self-hosted ou Scaleway) |
| **Isolation** | RLS strict : chaque université est un silo de données |
| **Emploi étudiant** | Les livreurs sont des étudiants (job board intégré) |
| **Agrégation** | L'app ne vend pas, elle agrège les réductions existantes |

---

## Stack Technique

```
┌──────────────────────────────────────────────────┐
│                   FRONTEND                        │
│  Flutter (Dart) — Design System "Campus" épuré    │
│  iOS + Android depuis un seul codebase            │
└──────────────────────────────────────────────────┘
                        ↕ REST / Realtime
┌──────────────────────────────────────────────────┐
│                   BACKEND                         │
│  Supabase (PostgreSQL + Auth + Storage + Edge Fn) │
│  RLS (Row Level Security) par université          │
└──────────────────────────────────────────────────┘
                        ↕ Webhooks / API
┌──────────────────────────────────────────────────┐
│              SERVICES EXTERNES                    │
│  Izly (S-Money/BPCE) │ Stripe Connect │ OCR API  │
│  Partenaires (Spotify, Unidays, locaux)           │
└──────────────────────────────────────────────────┘
```

### Choix Techniques Justifiés

| Composant | Choix | Justification |
|-----------|-------|---------------|
| Frontend | Flutter | Cross-platform, performance native, Design System custom |
| Backend | Supabase | PostgreSQL managé, Auth intégré, RLS natif, Realtime |
| Paiement primaire | Izly (S-Money/BPCE) | Standard CROUS, obligatoire pour les repas universitaires |
| Paiement secondaire | Stripe Connect | Backup CB, Split Bill, marketplace |
| OCR | Google ML Kit (on-device) | Vérification carte étudiante sans envoi serveur |
| Hébergement | Scaleway / OVH | Souveraineté française des données |

---

## Modules Principaux

### 1. Module de Paiement Hybride (Izly + CB)

Le défi principal est l'intégration du système Izly (réseau CROUS) avec un fallback CB.

- **Connecteur Izly** via S-Money/BPCE ou Webview sécurisée
- **Stripe Connect** pour achats hors réseau CROUS
- **Split Bill** natif : diviser entre Izly et CB

→ Voir [PAYMENT_FLOW.md](PAYMENT_FLOW.md) pour les diagrammes de flux détaillés
→ Voir [IZLY_INTEGRATION.md](../IZLY_INTEGRATION.md) pour l'intégration tierce sécurisée

### 2. Identité & Vérification (Modèle GitHub Education)

Gatekeeper à deux niveaux :

```
Inscription
    │
    ▼
[Niveau 1] Email universitaire (.fr / .edu)
    │
    ├── ✅ Vérifié → Accès complet
    │
    └── ❌ Échec → [Niveau 2] Upload carte étudiante + OCR
                        │
                        ├── ✅ OCR validé → Accès complet
                        │
                        └── ❌ Échec → Revue manuelle (modération)
```

**Cycle de vie des comptes :**

| Statut | Droits | Durée |
|--------|--------|-------|
| **Étudiant actif** | Accès complet (paiement, social, marketplace) | Année universitaire |
| **Alumni** | Réseau social + marketplace (pas de paiement Izly) | Illimité |
| **Suspendu** | Aucun accès | Jusqu'à revue |

### 3. Marketplace Agrégateur & Logistique

L'app ne vend pas : elle agrège les réductions existantes.

- **Partenaires** : Spotify, Unidays, commerces locaux
- **Webhooks** : Synchronisation stocks/offres en temps réel
- **Livraison** : API Dispatch compatible Deliveroo, livreurs étudiants
- **Job Board** : Offres de livraison intégrées pour étudiants

### 4. Réseau Social "Safe" (No-Notification)

Philosophie **Pull** : l'utilisateur vient consulter le fil campus.

**Home Screen** — Fil mixte :
- Posts étudiants ("Qui pour réviser à la BU ?")
- Bons plans du jour (offres limitées)
- Menu du RU synchronisé

**Modération** :
- Signalement communautaire
- Shadowban automatique (harcèlement détecté)
- Système de Karma (visibilité proportionnelle à la contribution)

→ Voir [SOCIAL_MODERATION.md](SOCIAL_MODERATION.md) pour la logique détaillée

---

## Sécurité & Souveraineté

### Row Level Security (RLS)

Chaque requête est filtrée par `university_id` :

```sql
-- Politique RLS : un étudiant ne voit que les données de son université
CREATE POLICY "university_isolation" ON posts
    USING (university_id = auth.jwt() -> 'university_id');

CREATE POLICY "university_isolation" ON discounts
    USING (
        university_id = auth.jwt() -> 'university_id'
        OR is_national = true
    );
```

### Sécurité des Paiements

| Mesure | Détail |
|--------|--------|
| Izly | Authentification OAuth2 via S-Money, tokens éphémères |
| Stripe | Stripe Connect, PCI DSS Level 1, clés serveur uniquement |
| Split Bill | Transactions atomiques (commit ou rollback complet) |
| Données | Chiffrement AES-256 au repos, TLS 1.3 en transit |

### RGPD & Conformité

- Consentement explicite à l'inscription
- Droit à l'effacement (suppression compte + données)
- Données hébergées en France (Scaleway / OVH)
- Logs d'accès et audit trail

---

## Architecture en Couches

```
┌─────────────────────────────────────────────────────────┐
│                  COUCHE PRÉSENTATION                     │
│  Flutter Widgets │ Design System "Campus" │ Navigation   │
└─────────────────────────────────────────────────────────┘
                            ↕
┌─────────────────────────────────────────────────────────┐
│                  COUCHE LOGIQUE MÉTIER                    │
│  PaymentService │ AuthService │ SocialService │ Karma    │
│  ModerationService │ MarketplaceService │ DeliveryService│
└─────────────────────────────────────────────────────────┘
                            ↕
┌─────────────────────────────────────────────────────────┐
│                  COUCHE DONNÉES                          │
│  Supabase Client │ Repository Pattern │ Cache local      │
└─────────────────────────────────────────────────────────┘
                            ↕
┌─────────────────────────────────────────────────────────┐
│                  COUCHE INFRASTRUCTURE                    │
│  Supabase (PostgreSQL + Auth + Storage + Realtime)       │
│  Izly API │ Stripe API │ OCR ML Kit │ Webhooks           │
└─────────────────────────────────────────────────────────┘
```

---

## Documents Détaillés

| Document | Contenu |
|----------|---------|
| [PAYMENT_FLOW.md](PAYMENT_FLOW.md) | Diagrammes de flux paiement mixte (Izly + CB), Split Bill |
| [IZLY_INTEGRATION.md](../IZLY_INTEGRATION.md) | Guide d'intégration Izly, authentification tierce sécurisée |
| [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) | Schéma PostgreSQL complet (users, payments, discounts, karma, moderation) |
| [SOCIAL_MODERATION.md](SOCIAL_MODERATION.md) | Modération communautaire, shadowban, système de Karma |
| [FLUTTER_PROJECT_STRUCTURE.md](FLUTTER_PROJECT_STRUCTURE.md) | Arborescence Flutter MVP, Design System "Campus" |

---

## Faisabilité de l'Intégration Izly

### Analyse

| Aspect | Faisabilité | Remarque |
|--------|-------------|----------|
| **API S-Money** | ⚠️ Moyenne | API non publique, nécessite partenariat BPCE/CROUS |
| **Webview sécurisée** | ✅ Haute | Fallback viable via portail web Izly dans une Webview |
| **Solde Izly** | ⚠️ Moyenne | Lecture du solde dépend de l'accès API |
| **Split Bill** | ✅ Haute | Orchestré côté serveur, indépendant d'Izly |
| **Backup CB** | ✅ Haute | Stripe Connect est mature et bien documenté |

### Stratégie d'Intégration MVP

1. **Phase 1 (MVP)** : Webview sécurisée pour paiement Izly + Stripe Connect pour CB
2. **Phase 2** : Partenariat BPCE pour accès API S-Money directe
3. **Phase 3** : SDK natif Izly si disponible

→ Voir [IZLY_INTEGRATION.md](../IZLY_INTEGRATION.md) pour le plan technique complet.
