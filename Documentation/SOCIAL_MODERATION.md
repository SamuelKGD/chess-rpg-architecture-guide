# 🛡️ Réseau Social "Safe" — Modération & Système de Karma

## Table des Matières

1. [Philosophie "No-Notification"](#philosophie-no-notification)
2. [Home Screen — Fil d'Actualité Campus](#home-screen--fil-dactualité-campus)
3. [Système de Modération](#système-de-modération)
4. [Shadowban Automatique](#shadowban-automatique)
5. [Système de Karma](#système-de-karma)
6. [Implémentation Technique](#implémentation-technique)

---

## Philosophie "No-Notification"

### Principe : Pull > Push

L'application ne pousse **aucune notification marketing**. L'utilisateur vient consulter le fil campus de sa propre initiative.

| Type de Notification | Autorisé | Exemple |
|----------------------|----------|---------|
| **Marketing** | ❌ Jamais | "Nouveau partenaire !" |
| **Transactionnel** | ✅ Oui | "Votre commande est prête" |
| **Sécurité** | ✅ Oui | "Connexion depuis un nouvel appareil" |
| **Social organique** | ⚠️ Opt-in | "Quelqu'un a répondu à votre post" |

### Rétention Organique

La rétention repose sur la valeur du contenu campus, pas sur le spam :

```
┌─────────────────────────────────────────────┐
│  Boucle de rétention organique              │
│                                             │
│  1. Étudiant consulte le fil campus         │
│           │                                 │
│  2. Trouve du contenu utile                 │
│     (menu RU, bons plans, posts)            │
│           │                                 │
│  3. Contribue (post, réponse, livraison)    │
│           │                                 │
│  4. Gagne du karma → visibilité             │
│           │                                 │
│  5. D'autres étudiants voient son contenu   │
│           │                                 │
│  └────────┘ (retour à l'étape 1)            │
└─────────────────────────────────────────────┘
```

---

## Home Screen — Fil d'Actualité Campus

### Composition du Fil

Le fil mixe trois types de contenu, pondérés par pertinence :

```
┌─────────────────────────────────────────┐
│  📍 Campus Paris-Sorbonne               │
│                                          │
│  ┌──────────────────────────────────┐   │
│  │ 🍽️ Menu du RU — Aujourd'hui      │   │
│  │ Entrée : Salade composée         │   │
│  │ Plat : Poulet rôti               │   │
│  │ Dessert : Tarte aux pommes       │   │
│  │ 3.30€                            │   │
│  └──────────────────────────────────┘   │
│                                          │
│  ┌──────────────────────────────────┐   │
│  │ 👤 Marie L. • il y a 15min       │   │
│  │ "Qui pour réviser à la BU ce     │   │
│  │  soir ? Droit constitutionnel"   │   │
│  │ ❤️ 12  💬 4  ⭐ Karma: trusted   │   │
│  └──────────────────────────────────┘   │
│                                          │
│  ┌──────────────────────────────────┐   │
│  │ 🏷️ Bon plan — Spotify -50%       │   │
│  │ Via Unidays • Expire demain      │   │
│  │ [Voir l'offre]                   │   │
│  └──────────────────────────────────┘   │
│                                          │
│  ┌──────────────────────────────────┐   │
│  │ 👤 Thomas B. • il y a 1h         │   │
│  │ "Quelqu'un a trouvé un chargeur  │   │
│  │  USB-C à l'amphi B ?"            │   │
│  │ ❤️ 3  💬 1                        │   │
│  └──────────────────────────────────┘   │
│                                          │
└─────────────────────────────────────────┘
```

### Algorithme de Tri du Fil

```
Score = (upvotes - downvotes)
      × karma_multiplier(author)
      × recency_decay(created_at)
      × type_boost(post_type)

Avec :
  karma_multiplier :
    newcomer   → 0.8
    member     → 1.0
    trusted    → 1.2
    ambassador → 1.5

  recency_decay :
    < 1h  → 1.0
    < 6h  → 0.8
    < 24h → 0.5
    > 24h → 0.2

  type_boost :
    ru_menu → 2.0 (toujours en haut)
    deal    → 1.5
    event   → 1.3
    general → 1.0
```

---

## Système de Modération

### Signalement Communautaire

Tout étudiant peut signaler un post avec une raison :

```
┌──────────────────────────────────────────┐
│  Signaler ce post                         │
│                                           │
│  ○ Spam                                   │
│  ○ Harcèlement                            │
│  ○ Discours haineux                       │
│  ○ Désinformation                         │
│  ○ Contenu inapproprié                    │
│  ○ Autre (préciser)                       │
│                                           │
│  [Description optionnelle...]             │
│                                           │
│  [Annuler]           [Signaler]           │
└──────────────────────────────────────────┘
```

### Pipeline de Modération

```
Post signalé
     │
     ▼
┌─────────────────┐
│ report_count++  │
└────────┬────────┘
         │
    ┌────┴─────┐
    │ Seuils   │
    └────┬─────┘
         │
    ┌────┼────────────────┐
    ▼    ▼                ▼
  1-2  3-4              5+
signaux signaux        signaux
    │    │                │
    ▼    ▼                ▼
 Rien  Masqué        Supprimé
       temporairement   + Shadowban
       (revue manuelle) (si récidive)
```

### Règles de Modération

| Nombre de signalements | Action automatique | Revue manuelle |
|-------------------------|--------------------|----------------|
| 1-2 | Aucune | Non |
| 3-4 | Post masqué (is_visible = false) | Oui, dans les 24h |
| 5+ | Post supprimé, auteur averti | Oui, immédiate |
| 3+ posts supprimés (même auteur) | Shadowban automatique | Oui, revue du compte |

---

## Shadowban Automatique

### Principe

Un utilisateur shadowbanné **ne sait pas** qu'il est banni. Ses posts sont visibles pour lui mais **invisibles pour les autres**.

### Déclencheurs

```
Shadowban automatique si :
  - 3+ posts supprimés par la modération en 30 jours
  - OU 10+ signalements confirmés en 30 jours
  - OU détection automatique de harcèlement (mots-clés + patterns)
```

### Implémentation

```sql
-- Le shadowban est un statut sur le profil utilisateur
-- account_status = 'shadowbanned'

-- La requête du fil filtre automatiquement :
-- posts.is_visible = true ET users.account_status != 'shadowbanned'
-- SAUF pour l'utilisateur lui-même (il voit ses propres posts)

CREATE OR REPLACE FUNCTION get_campus_feed(p_university_id UUID, p_user_id UUID)
RETURNS TABLE (
    post_id UUID,
    content TEXT,
    author_name TEXT,
    upvotes INTEGER,
    post_type TEXT,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        p.content,
        u.display_name,
        p.upvotes,
        p.post_type,
        p.created_at
    FROM posts p
    JOIN users u ON p.user_id = u.id
    WHERE p.university_id = p_university_id
      AND p.is_visible = true
      AND (
          u.account_status != 'shadowbanned'
          OR u.id = p_user_id  -- L'auteur voit toujours ses propres posts
      )
    ORDER BY
        CASE p.post_type
            WHEN 'ru_menu' THEN 0  -- Menus RU en premier
            ELSE 1
        END,
        (p.upvotes - p.downvotes)
        * CASE
            WHEN p.created_at > NOW() - INTERVAL '1 hour' THEN 1.0
            WHEN p.created_at > NOW() - INTERVAL '6 hours' THEN 0.8
            WHEN p.created_at > NOW() - INTERVAL '24 hours' THEN 0.5
            ELSE 0.2
          END
        DESC
    LIMIT 50;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Détection Automatique (Harcèlement)

```
Pipeline de détection :
  1. Analyse de contenu textuel (mots-clés + expressions)
  2. Analyse de pattern (même cible visée plusieurs fois)
  3. Analyse de fréquence (flood de messages)

Seuils :
  - Mots-clés toxiques détectés → flag pour revue
  - 3+ messages ciblant le même utilisateur en 1h → alerte
  - 10+ messages en 5 min → rate limiting automatique
```

---

## Système de Karma

### Principe

Les étudiants utiles gagnent du karma, ce qui augmente leur visibilité dans le fil. Le karma récompense les contributions positives.

### Points de Karma

| Action | Points | Catégorie |
|--------|--------|-----------|
| Post upvoté | +2 | social |
| Réponse acceptée (question) | +5 | social |
| Post downvoté | -1 | social |
| Livraison complétée | +3 | delivery |
| Livraison notée positivement (4-5★) | +2 | delivery |
| Livraison notée négativement (1-2★) | -2 | delivery |
| Signalement confirmé (modération juste) | +1 | moderation |
| Signalement rejeté (faux signalement) | -2 | moderation |
| Shadowban appliqué | -50 | moderation |

### Niveaux de Karma

```
┌───────────────┬──────────┬────────────────────────────────┐
│ Niveau        │ Score    │ Avantages                      │
├───────────────┼──────────┼────────────────────────────────┤
│ 🆕 newcomer   │ 0-49     │ Accès de base                  │
│ 👤 member     │ 50-199   │ Posts mieux classés (+0%)      │
│ ⭐ trusted    │ 200-499  │ Posts boostés (+20%)           │
│               │          │ Badge visible                  │
│ 🏆 ambassador │ 500+     │ Posts boostés (+50%)           │
│               │          │ Badge doré                     │
│               │          │ Accès revue modération         │
└───────────────┴──────────┴────────────────────────────────┘
```

### Calcul du Karma

```sql
-- Fonction de mise à jour du karma
CREATE OR REPLACE FUNCTION update_user_karma()
RETURNS TRIGGER AS $$
BEGIN
    -- Mettre à jour le score total et par catégorie
    UPDATE user_karma
    SET
        total_score = total_score + NEW.points,
        social_score = CASE
            WHEN NEW.event_type IN ('post_upvoted', 'answer_accepted', 'post_downvoted')
            THEN social_score + NEW.points
            ELSE social_score
        END,
        delivery_score = CASE
            WHEN NEW.event_type IN ('delivery_completed', 'delivery_rated_positive')
            THEN delivery_score + NEW.points
            ELSE delivery_score
        END,
        moderation_score = CASE
            WHEN NEW.event_type IN ('report_confirmed', 'report_rejected', 'shadowban_applied')
            THEN moderation_score + NEW.points
            ELSE moderation_score
        END,
        -- Recalculer le niveau
        karma_level = CASE
            WHEN total_score + NEW.points >= 500 THEN 'ambassador'
            WHEN total_score + NEW.points >= 200 THEN 'trusted'
            WHEN total_score + NEW.points >= 50  THEN 'member'
            ELSE 'newcomer'
        END,
        updated_at = NOW()
    WHERE user_id = NEW.user_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger : mise à jour automatique à chaque événement karma
CREATE TRIGGER trg_karma_update
    AFTER INSERT ON karma_events
    FOR EACH ROW
    EXECUTE FUNCTION update_user_karma();
```

### Anti-Gaming

Pour éviter la manipulation du karma :

| Règle | Description |
|-------|-------------|
| **Rate limit upvotes** | Max 20 upvotes/jour par utilisateur |
| **Auto-upvote interdit** | Impossible d'upvoter ses propres posts |
| **Ring detection** | Détection de groupes qui s'upvotent mutuellement |
| **Karma decay** | -10% du score par mois d'inactivité (plancher à 0) |
| **Nouveau compte** | Pas d'upvote pendant les 24 premières heures |

---

## Implémentation Technique

### Service de Modération (Dart/Flutter)

```dart
class ModerationService {
  final SupabaseClient _supabase;

  ModerationService(this._supabase);

  /// Signaler un post
  Future<void> reportPost({
    required String postId,
    required String reason,
    String? description,
  }) async {
    await _supabase.from('post_reports').insert({
      'post_id': postId,
      'reporter_id': _supabase.auth.currentUser!.id,
      'reason': reason,
      'description': description,
    });

    // Vérifier si le seuil de signalements est atteint
    await _supabase.rpc('check_report_threshold', params: {
      'p_post_id': postId,
    });
  }
}
```

### Edge Function : Vérification des Seuils

```typescript
// supabase/functions/check-report-threshold/index.ts

async function checkReportThreshold(postId: string) {
  // Compter les signalements
  const { count } = await supabase
    .from('post_reports')
    .select('*', { count: 'exact' })
    .eq('post_id', postId)
    .eq('status', 'pending');

  if (count >= 5) {
    // Supprimer le post
    await supabase.from('posts')
      .update({ is_visible: false, moderation_status: 'removed' })
      .eq('id', postId);

    // Vérifier si l'auteur doit être shadowbanné
    await checkShadowbanThreshold(postAuthorId);
  } else if (count >= 3) {
    // Masquer temporairement
    await supabase.from('posts')
      .update({ is_visible: false, moderation_status: 'under_review' })
      .eq('id', postId);
  }
}

async function checkShadowbanThreshold(userId: string) {
  // Compter les posts supprimés dans les 30 derniers jours
  const { count } = await supabase
    .from('posts')
    .select('*', { count: 'exact' })
    .eq('user_id', userId)
    .eq('moderation_status', 'removed')
    .gte('updated_at', new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString());

  if (count >= 3) {
    // Shadowban automatique
    await supabase.from('users')
      .update({ account_status: 'shadowbanned' })
      .eq('id', userId);

    // Logger l'événement karma
    await supabase.from('karma_events').insert({
      user_id: userId,
      event_type: 'shadowban_applied',
      points: -50,
    });
  }
}
```

### Service Karma (Dart/Flutter)

```dart
class KarmaService {
  final SupabaseClient _supabase;

  KarmaService(this._supabase);

  /// Récupérer le karma d'un utilisateur
  Future<UserKarma> getUserKarma(String userId) async {
    final data = await _supabase
        .from('user_karma')
        .select()
        .eq('user_id', userId)
        .single();

    return UserKarma.fromJson(data);
  }

  /// Upvoter un post (avec attribution de karma)
  Future<void> upvotePost(String postId) async {
    await _supabase.rpc('upvote_post', params: {
      'p_post_id': postId,
      'p_user_id': _supabase.auth.currentUser!.id,
    });
  }
}

class UserKarma {
  final int totalScore;
  final int socialScore;
  final int deliveryScore;
  final int moderationScore;
  final String karmaLevel;

  UserKarma({
    required this.totalScore,
    required this.socialScore,
    required this.deliveryScore,
    required this.moderationScore,
    required this.karmaLevel,
  });

  factory UserKarma.fromJson(Map<String, dynamic> json) {
    return UserKarma(
      totalScore: json['total_score'] ?? 0,
      socialScore: json['social_score'] ?? 0,
      deliveryScore: json['delivery_score'] ?? 0,
      moderationScore: json['moderation_score'] ?? 0,
      karmaLevel: json['karma_level'] ?? 'newcomer',
    );
  }
}
```
