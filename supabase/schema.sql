-- =============================================================================
-- Super-App Étudiante — Schéma Supabase (PostgreSQL)
-- =============================================================================
-- Design : Modern Brutalism · Par et pour les étudiants
-- Tables : profiles, vertical_posts, stories, karma_votes,
--          study_groups, group_members, campus_events,
--          market_listings, market_orders
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ---------------------------------------------------------------------------
-- ENUM Types
-- ---------------------------------------------------------------------------
CREATE TYPE post_type      AS ENUM ('text', 'image', 'video', 'tract');
CREATE TYPE story_type     AS ENUM ('soiree', 'urgence', 'offre_flash');
CREATE TYPE vote_direction AS ENUM ('up', 'down');
CREATE TYPE order_status   AS ENUM ('pending', 'paid', 'assigned', 'delivered', 'cancelled');
CREATE TYPE payment_method AS ENUM ('izly', 'stripe');
CREATE TYPE listing_status AS ENUM ('active', 'sold', 'expired');

-- ---------------------------------------------------------------------------
-- 1. profiles — Profils étudiants
-- ---------------------------------------------------------------------------
CREATE TABLE profiles (
    id         UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username   TEXT UNIQUE NOT NULL,
    full_name  TEXT,
    campus     TEXT,
    filiere    TEXT,           -- ex: 'Droit', 'Informatique', 'Médecine'
    avatar_url TEXT,
    karma      INTEGER DEFAULT 0,
    stripe_account_id TEXT,   -- Stripe Connect ID (vendeurs/coursiers)
    izly_linked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- 2. vertical_posts — Le Porte-Voix (feed vertical)
-- ---------------------------------------------------------------------------
CREATE TABLE vertical_posts (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    author_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    type        post_type NOT NULL DEFAULT 'text',
    title       TEXT,                      -- Titre brutaliste (typo massive)
    body        TEXT,                      -- Corps du post
    media_url   TEXT,                      -- URL image/vidéo (Supabase Storage)
    karma_score INTEGER DEFAULT 0,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_posts_author    ON vertical_posts(author_id);
CREATE INDEX idx_posts_karma     ON vertical_posts(karma_score DESC);
CREATE INDEX idx_posts_created   ON vertical_posts(created_at DESC);

-- ---------------------------------------------------------------------------
-- 3. stories — Les Flashs (éphémères 24h)
-- ---------------------------------------------------------------------------
CREATE TABLE stories (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    author_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    type        story_type NOT NULL DEFAULT 'soiree',
    content     TEXT,
    media_url   TEXT,
    expires_at  TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '24 hours'),
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_stories_author  ON stories(author_id);
CREATE INDEX idx_stories_expires ON stories(expires_at);

-- ---------------------------------------------------------------------------
-- 4. karma_votes — Système de Karma (upvotes / downvotes)
-- ---------------------------------------------------------------------------
CREATE TABLE karma_votes (
    id        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    post_id   UUID NOT NULL REFERENCES vertical_posts(id) ON DELETE CASCADE,
    direction vote_direction NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, post_id)  -- Un vote par utilisateur par post
);

CREATE INDEX idx_votes_post ON karma_votes(post_id);

-- ---------------------------------------------------------------------------
-- 5. study_groups — L'Assemblée (groupes par filière)
-- ---------------------------------------------------------------------------
CREATE TABLE study_groups (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        TEXT NOT NULL,
    description TEXT,
    filiere     TEXT,                      -- Filière associée
    campus      TEXT,
    creator_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    member_count INTEGER DEFAULT 1,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_groups_filiere ON study_groups(filiere);
CREATE INDEX idx_groups_campus  ON study_groups(campus);

-- ---------------------------------------------------------------------------
-- 6. group_members — Adhésion aux groupes
-- ---------------------------------------------------------------------------
CREATE TABLE group_members (
    id        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id  UUID NOT NULL REFERENCES study_groups(id) ON DELETE CASCADE,
    user_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    role      TEXT DEFAULT 'member',       -- 'admin', 'moderator', 'member'
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(group_id, user_id)
);

CREATE INDEX idx_members_group ON group_members(group_id);
CREATE INDEX idx_members_user  ON group_members(user_id);

-- ---------------------------------------------------------------------------
-- 7. campus_events — Événements campus
-- ---------------------------------------------------------------------------
CREATE TABLE campus_events (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title       TEXT NOT NULL,
    description TEXT,
    location    TEXT,
    starts_at   TIMESTAMPTZ NOT NULL,
    ends_at     TIMESTAMPTZ,
    organizer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    group_id    UUID REFERENCES study_groups(id) ON DELETE SET NULL,
    rsvp_count  INTEGER DEFAULT 0,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_events_starts ON campus_events(starts_at);
CREATE INDEX idx_events_group  ON campus_events(group_id);

-- ---------------------------------------------------------------------------
-- 8. market_listings — Le Contre-Marché (annonces)
-- ---------------------------------------------------------------------------
CREATE TABLE market_listings (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    seller_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title       TEXT NOT NULL,
    description TEXT,
    price_cents INTEGER NOT NULL,          -- Prix en centimes
    image_url   TEXT,
    status      listing_status DEFAULT 'active',
    campus      TEXT,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_listings_seller ON market_listings(seller_id);
CREATE INDEX idx_listings_status ON market_listings(status);
CREATE INDEX idx_listings_campus ON market_listings(campus);

-- ---------------------------------------------------------------------------
-- 9. market_orders — Commandes Contre-Marché
-- ---------------------------------------------------------------------------
CREATE TABLE market_orders (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    listing_id     UUID NOT NULL REFERENCES market_listings(id) ON DELETE CASCADE,
    buyer_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    courier_id     UUID REFERENCES profiles(id) ON DELETE SET NULL,
    status         order_status DEFAULT 'pending',
    payment_method payment_method,
    total_cents    INTEGER NOT NULL,
    stripe_payment_intent_id TEXT,
    is_peer_courier BOOLEAN DEFAULT TRUE,  -- TRUE = coursier étudiant Allié
    created_at     TIMESTAMPTZ DEFAULT NOW(),
    updated_at     TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_orders_buyer   ON market_orders(buyer_id);
CREATE INDEX idx_orders_courier ON market_orders(courier_id);
CREATE INDEX idx_orders_status  ON market_orders(status);

-- ---------------------------------------------------------------------------
-- Row Level Security (RLS)
-- ---------------------------------------------------------------------------
ALTER TABLE profiles         ENABLE ROW LEVEL SECURITY;
ALTER TABLE vertical_posts   ENABLE ROW LEVEL SECURITY;
ALTER TABLE stories          ENABLE ROW LEVEL SECURITY;
ALTER TABLE karma_votes      ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_groups     ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members    ENABLE ROW LEVEL SECURITY;
ALTER TABLE campus_events    ENABLE ROW LEVEL SECURITY;
ALTER TABLE market_listings  ENABLE ROW LEVEL SECURITY;
ALTER TABLE market_orders    ENABLE ROW LEVEL SECURITY;

-- Profiles: lecture publique, écriture propriétaire
CREATE POLICY "Profiles are viewable by everyone"
    ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE USING (auth.uid() = id);

-- Posts: lecture publique, écriture propriétaire
CREATE POLICY "Posts are viewable by everyone"
    ON vertical_posts FOR SELECT USING (true);
CREATE POLICY "Users can create own posts"
    ON vertical_posts FOR INSERT WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Users can update own posts"
    ON vertical_posts FOR UPDATE USING (auth.uid() = author_id);
CREATE POLICY "Users can delete own posts"
    ON vertical_posts FOR DELETE USING (auth.uid() = author_id);

-- Stories: lecture publique, écriture propriétaire
CREATE POLICY "Stories are viewable by everyone"
    ON stories FOR SELECT USING (true);
CREATE POLICY "Users can create own stories"
    ON stories FOR INSERT WITH CHECK (auth.uid() = author_id);

-- Karma votes: lecture publique, écriture propriétaire
CREATE POLICY "Votes are viewable by everyone"
    ON karma_votes FOR SELECT USING (true);
CREATE POLICY "Users can cast own votes"
    ON karma_votes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can change own votes"
    ON karma_votes FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can remove own votes"
    ON karma_votes FOR DELETE USING (auth.uid() = user_id);

-- Study groups: lecture publique, écriture propriétaire
CREATE POLICY "Groups are viewable by everyone"
    ON study_groups FOR SELECT USING (true);
CREATE POLICY "Users can create groups"
    ON study_groups FOR INSERT WITH CHECK (auth.uid() = creator_id);
CREATE POLICY "Creators can update own groups"
    ON study_groups FOR UPDATE USING (auth.uid() = creator_id);

-- Group members: lecture publique, gestion par l'utilisateur
CREATE POLICY "Group memberships are viewable by everyone"
    ON group_members FOR SELECT USING (true);
CREATE POLICY "Users can join groups"
    ON group_members FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can leave groups"
    ON group_members FOR DELETE USING (auth.uid() = user_id);

-- Events: lecture publique, écriture organisateur
CREATE POLICY "Events are viewable by everyone"
    ON campus_events FOR SELECT USING (true);
CREATE POLICY "Users can create events"
    ON campus_events FOR INSERT WITH CHECK (auth.uid() = organizer_id);
CREATE POLICY "Organizers can update own events"
    ON campus_events FOR UPDATE USING (auth.uid() = organizer_id);

-- Market listings: lecture publique, écriture vendeur
CREATE POLICY "Listings are viewable by everyone"
    ON market_listings FOR SELECT USING (true);
CREATE POLICY "Users can create listings"
    ON market_listings FOR INSERT WITH CHECK (auth.uid() = seller_id);
CREATE POLICY "Sellers can update own listings"
    ON market_listings FOR UPDATE USING (auth.uid() = seller_id);

-- Market orders: lecture restreinte (acheteur, vendeur ou coursier)
CREATE POLICY "Order participants can view orders"
    ON market_orders FOR SELECT USING (
        auth.uid() = buyer_id
        OR auth.uid() = courier_id
        OR auth.uid() IN (
            SELECT seller_id FROM market_listings WHERE id = listing_id
        )
    );
CREATE POLICY "Buyers can create orders"
    ON market_orders FOR INSERT WITH CHECK (auth.uid() = buyer_id);

-- ---------------------------------------------------------------------------
-- Functions — Karma auto-update
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_karma_score()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE vertical_posts
    SET karma_score = (
        SELECT COALESCE(SUM(CASE WHEN direction = 'up' THEN 1 ELSE -1 END), 0)
        FROM karma_votes
        WHERE post_id = COALESCE(NEW.post_id, OLD.post_id)
    )
    WHERE id = COALESCE(NEW.post_id, OLD.post_id);

    UPDATE profiles
    SET karma = (
        SELECT COALESCE(SUM(karma_score), 0)
        FROM vertical_posts
        WHERE author_id = (
            SELECT author_id FROM vertical_posts
            WHERE id = COALESCE(NEW.post_id, OLD.post_id)
        )
    )
    WHERE id = (
        SELECT author_id FROM vertical_posts
        WHERE id = COALESCE(NEW.post_id, OLD.post_id)
    );

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_karma_vote_change
    AFTER INSERT OR UPDATE OR DELETE ON karma_votes
    FOR EACH ROW EXECUTE FUNCTION update_karma_score();

-- ---------------------------------------------------------------------------
-- Cron — Nettoyage stories expirées (via pg_cron ou Supabase Edge Function)
-- ---------------------------------------------------------------------------
-- Exécuter périodiquement :
-- DELETE FROM stories WHERE expires_at < NOW();
