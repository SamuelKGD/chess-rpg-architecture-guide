# 🗄️ Schéma de Base de Données — Super-App Étudiante

**Backend : Supabase (PostgreSQL) avec Row Level Security (RLS)**

---

## Table des Matières

1. [Vue d'Ensemble](#vue-densemble)
2. [Schéma Complet](#schéma-complet)
3. [Tables Détaillées](#tables-détaillées)
4. [Politiques RLS](#politiques-rls)
5. [Index & Performance](#index--performance)

---

## Vue d'Ensemble

### Diagramme Entité-Relation (Simplifié)

```
universities ─────< users >───── user_karma
                     │
                     ├────< posts >────< post_reports
                     │
                     ├────< orders >───< payments
                     │                     │
                     │              (izly / stripe)
                     │
                     ├────< user_discounts
                     │          │
                     │     discounts >──── partners
                     │
                     └────< delivery_jobs
```

---

## Schéma Complet

### Table `universities`

```sql
CREATE TABLE universities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    domain TEXT NOT NULL UNIQUE,        -- ex: 'univ-paris1.fr'
    city TEXT NOT NULL,
    region TEXT,
    crous_id TEXT,                       -- Identifiant CROUS associé
    ru_menu_webhook_url TEXT,            -- URL webhook pour le menu du RU
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Table `users`

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    university_id UUID REFERENCES universities(id),
    email TEXT NOT NULL UNIQUE,
    display_name TEXT NOT NULL,
    avatar_url TEXT,
    -- Vérification
    verification_level INTEGER DEFAULT 0, -- 0: non vérifié, 1: email, 2: OCR
    verification_status TEXT DEFAULT 'pending'
        CHECK (verification_status IN ('pending', 'verified', 'rejected', 'alumni')),
    student_card_url TEXT,                -- URL stockage Supabase (pour OCR)
    -- Statut
    account_status TEXT DEFAULT 'active'
        CHECK (account_status IN ('active', 'alumni', 'suspended', 'shadowbanned')),
    -- Profil
    graduation_year INTEGER,
    field_of_study TEXT,
    bio TEXT,
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_seen_at TIMESTAMPTZ
);
```

### Table `user_karma`

```sql
CREATE TABLE user_karma (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    total_score INTEGER DEFAULT 0,
    -- Détail par catégorie
    social_score INTEGER DEFAULT 0,      -- Posts utiles, bonnes réponses
    delivery_score INTEGER DEFAULT 0,    -- Livraisons fiables
    moderation_score INTEGER DEFAULT 0,  -- Signalements justes
    -- Niveau calculé
    karma_level TEXT DEFAULT 'newcomer'
        CHECK (karma_level IN ('newcomer', 'member', 'trusted', 'ambassador')),
    -- Timestamps
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Table `karma_events`

```sql
CREATE TABLE karma_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL
        CHECK (event_type IN (
            'post_upvoted', 'answer_accepted', 'delivery_completed',
            'delivery_rated_positive', 'report_confirmed',
            'post_downvoted', 'report_rejected', 'shadowban_applied'
        )),
    points INTEGER NOT NULL,             -- Positif ou négatif
    metadata JSONB,                      -- Détails contextuels
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Table `partners`

```sql
CREATE TABLE partners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    logo_url TEXT,
    website_url TEXT,
    category TEXT NOT NULL
        CHECK (category IN ('food', 'entertainment', 'transport', 'education', 'shopping', 'services')),
    -- Type de partenaire
    partner_type TEXT DEFAULT 'national'
        CHECK (partner_type IN ('national', 'local')),
    -- Webhook pour synchronisation stocks
    webhook_url TEXT,
    webhook_secret TEXT,
    -- Contact
    contact_email TEXT,
    -- Statut
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Table `discounts`

```sql
CREATE TABLE discounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    partner_id UUID REFERENCES partners(id) ON DELETE CASCADE,
    university_id UUID REFERENCES universities(id),  -- NULL = national
    -- Détails de l'offre
    title TEXT NOT NULL,
    description TEXT,
    discount_type TEXT NOT NULL
        CHECK (discount_type IN ('percentage', 'fixed_amount', 'free_item', 'bogo')),
    discount_value DECIMAL(10,2),        -- Ex: 20.00 pour 20%
    -- Conditions
    min_purchase DECIMAL(10,2) DEFAULT 0,
    max_uses_per_user INTEGER,           -- NULL = illimité
    max_total_uses INTEGER,              -- NULL = illimité
    current_uses INTEGER DEFAULT 0,
    -- Code / lien
    promo_code TEXT,
    redirect_url TEXT,                   -- Lien vers l'offre partenaire
    -- Validité
    is_national BOOLEAN DEFAULT false,   -- Visible par toutes les universités
    starts_at TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    -- Métadonnées
    image_url TEXT,
    tags TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Table `user_discounts`

```sql
-- Suivi de l'utilisation des réductions par utilisateur
CREATE TABLE user_discounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    discount_id UUID REFERENCES discounts(id) ON DELETE CASCADE,
    used_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, discount_id, used_at)
);
```

### Table `orders`

```sql
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    university_id UUID REFERENCES universities(id),
    -- Détails
    order_type TEXT NOT NULL
        CHECK (order_type IN ('ru_meal', 'delivery', 'marketplace')),
    total_amount DECIMAL(10,2) NOT NULL,
    -- Split payment
    izly_amount DECIMAL(10,2) DEFAULT 0,
    stripe_amount DECIMAL(10,2) DEFAULT 0,
    -- Statut
    status TEXT DEFAULT 'pending'
        CHECK (status IN ('pending', 'payment_processing', 'paid', 'preparing',
                          'delivering', 'completed', 'cancelled', 'refunded')),
    -- Livraison (si applicable)
    delivery_address TEXT,
    delivery_job_id UUID,
    -- Métadonnées
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Table `payments`

```sql
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    -- Fournisseur
    provider TEXT NOT NULL
        CHECK (provider IN ('izly', 'stripe')),
    -- Montants
    amount DECIMAL(10,2) NOT NULL,
    currency TEXT DEFAULT 'EUR',
    -- Identifiants externes
    external_transaction_id TEXT,        -- ID Izly ou Stripe
    stripe_payment_intent_id TEXT,
    -- Statut
    status TEXT DEFAULT 'pending'
        CHECK (status IN ('pending', 'processing', 'confirmed', 'failed', 'refunded')),
    -- Timestamps
    confirmed_at TIMESTAMPTZ,
    failed_at TIMESTAMPTZ,
    refunded_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Table `payment_audit_log`

```sql
CREATE TABLE payment_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    action TEXT NOT NULL
        CHECK (action IN ('initiate', 'confirm', 'fail', 'refund', 'split_start', 'split_complete')),
    provider TEXT NOT NULL,
    amount DECIMAL(10,2),
    order_id UUID REFERENCES orders(id),
    metadata JSONB,
    ip_address INET,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Table `posts`

```sql
CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    university_id UUID REFERENCES universities(id),
    -- Contenu
    content TEXT NOT NULL,
    post_type TEXT DEFAULT 'general'
        CHECK (post_type IN ('general', 'question', 'event', 'deal', 'ru_menu', 'lost_found')),
    -- Engagement
    upvotes INTEGER DEFAULT 0,
    downvotes INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    -- Modération
    is_visible BOOLEAN DEFAULT true,     -- false = shadowbanned ou supprimé
    moderation_status TEXT DEFAULT 'clean'
        CHECK (moderation_status IN ('clean', 'reported', 'under_review', 'removed')),
    report_count INTEGER DEFAULT 0,
    -- Métadonnées
    image_urls TEXT[],
    location_name TEXT,                  -- Ex: "BU Sciences", "RU Mabillon"
    tags TEXT[],
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Table `post_comments`

```sql
CREATE TABLE post_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    parent_comment_id UUID REFERENCES post_comments(id), -- Réponses imbriquées
    content TEXT NOT NULL,
    upvotes INTEGER DEFAULT 0,
    is_visible BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Table `post_reports`

```sql
-- Signalements communautaires
CREATE TABLE post_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    reporter_id UUID REFERENCES users(id) ON DELETE CASCADE,
    reason TEXT NOT NULL
        CHECK (reason IN ('spam', 'harassment', 'hate_speech', 'misinformation',
                          'inappropriate', 'other')),
    description TEXT,
    status TEXT DEFAULT 'pending'
        CHECK (status IN ('pending', 'reviewed', 'confirmed', 'dismissed')),
    reviewed_by UUID REFERENCES users(id),
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(post_id, reporter_id)         -- Un seul signalement par utilisateur par post
);
```

### Table `ru_menus`

```sql
-- Menus du Restaurant Universitaire synchronisés
CREATE TABLE ru_menus (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    university_id UUID REFERENCES universities(id),
    -- Menu du jour
    menu_date DATE NOT NULL,
    meal_type TEXT NOT NULL
        CHECK (meal_type IN ('lunch', 'dinner')),
    -- Contenu
    starter TEXT,
    main_course TEXT NOT NULL,
    side_dish TEXT,
    dessert TEXT,
    -- Prix
    price_student DECIMAL(10,2) DEFAULT 3.30,
    price_non_student DECIMAL(10,2),
    -- Métadonnées
    is_vegetarian BOOLEAN DEFAULT false,
    allergens TEXT[],
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(university_id, menu_date, meal_type)
);
```

### Table `delivery_jobs`

```sql
-- Job board pour livreurs étudiants
CREATE TABLE delivery_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    university_id UUID REFERENCES universities(id),
    order_id UUID REFERENCES orders(id),
    -- Livreur
    courier_id UUID REFERENCES users(id),
    -- Détails
    pickup_location TEXT NOT NULL,
    delivery_location TEXT NOT NULL,
    estimated_duration_min INTEGER,
    -- Rémunération
    payment_amount DECIMAL(10,2) NOT NULL,
    tip_amount DECIMAL(10,2) DEFAULT 0,
    -- Statut
    status TEXT DEFAULT 'available'
        CHECK (status IN ('available', 'claimed', 'picking_up', 'delivering',
                          'completed', 'cancelled')),
    -- Évaluation
    courier_rating INTEGER CHECK (courier_rating BETWEEN 1 AND 5),
    customer_rating INTEGER CHECK (customer_rating BETWEEN 1 AND 5),
    -- Timestamps
    claimed_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## Politiques RLS

### Isolation par Université

```sql
-- Activer RLS sur toutes les tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE discounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE delivery_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE ru_menus ENABLE ROW LEVEL SECURITY;

-- Users : lecture des profils de la même université
CREATE POLICY "users_read_same_university" ON users
    FOR SELECT USING (
        university_id = (
            SELECT university_id FROM users WHERE id = auth.uid()
        )
    );

-- Users : modification de son propre profil uniquement
CREATE POLICY "users_update_own" ON users
    FOR UPDATE USING (id = auth.uid());

-- Posts : lecture des posts de sa propre université
CREATE POLICY "posts_read_university" ON posts
    FOR SELECT USING (
        university_id = (
            SELECT university_id FROM users WHERE id = auth.uid()
        )
    );

-- Posts : création de posts dans sa propre université
CREATE POLICY "posts_create_own" ON posts
    FOR INSERT WITH CHECK (
        user_id = auth.uid()
        AND university_id = (
            SELECT university_id FROM users WHERE id = auth.uid()
        )
    );

-- Discounts : nationaux visibles par tous, locaux par université
CREATE POLICY "discounts_read" ON discounts
    FOR SELECT USING (
        is_national = true
        OR university_id = (
            SELECT university_id FROM users WHERE id = auth.uid()
        )
    );

-- Orders : lecture de ses propres commandes uniquement
CREATE POLICY "orders_read_own" ON orders
    FOR SELECT USING (user_id = auth.uid());

-- Payments : lecture de ses propres paiements uniquement
CREATE POLICY "payments_read_own" ON payments
    FOR SELECT USING (user_id = auth.uid());

-- Delivery Jobs : visibles par université
CREATE POLICY "delivery_jobs_read_university" ON delivery_jobs
    FOR SELECT USING (
        university_id = (
            SELECT university_id FROM users WHERE id = auth.uid()
        )
    );

-- RU Menus : visibles par université
CREATE POLICY "ru_menus_read_university" ON ru_menus
    FOR SELECT USING (
        university_id = (
            SELECT university_id FROM users WHERE id = auth.uid()
        )
    );
```

---

## Index & Performance

```sql
-- Index pour les requêtes fréquentes
CREATE INDEX idx_users_university ON users(university_id);
CREATE INDEX idx_users_verification ON users(verification_status);
CREATE INDEX idx_posts_university_created ON posts(university_id, created_at DESC);
CREATE INDEX idx_posts_type ON posts(post_type);
CREATE INDEX idx_posts_visible ON posts(is_visible) WHERE is_visible = true;
CREATE INDEX idx_discounts_university ON discounts(university_id);
CREATE INDEX idx_discounts_active ON discounts(is_active, starts_at, expires_at);
CREATE INDEX idx_discounts_partner ON discounts(partner_id);
CREATE INDEX idx_orders_user ON orders(user_id, created_at DESC);
CREATE INDEX idx_payments_order ON payments(order_id);
CREATE INDEX idx_payments_provider ON payments(provider, status);
CREATE INDEX idx_delivery_jobs_university ON delivery_jobs(university_id, status);
CREATE INDEX idx_delivery_jobs_courier ON delivery_jobs(courier_id);
CREATE INDEX idx_ru_menus_university_date ON ru_menus(university_id, menu_date);
CREATE INDEX idx_karma_events_user ON karma_events(user_id, created_at DESC);
CREATE INDEX idx_post_reports_post ON post_reports(post_id, status);
```
