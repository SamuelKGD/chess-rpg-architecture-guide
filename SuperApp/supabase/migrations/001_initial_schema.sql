-- =====================================================
-- SCHEMA DE BASE DE DONNÉES — EduMarket Super-App
-- Supabase / PostgreSQL
-- =====================================================

-- Extension UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis"; -- Pour les calculs de distance

-- =====================================================
-- TABLE : users
-- Profils étudiants avec vérification institutionnelle
-- =====================================================
CREATE TABLE public.users (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auth_id        UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email          TEXT UNIQUE NOT NULL,
  full_name      TEXT,
  school_domain  TEXT NOT NULL,           -- ex: "univ-paris.fr", "student.edu"
  is_student_verified BOOLEAN NOT NULL DEFAULT FALSE,
  verified_at    TIMESTAMPTZ,
  avatar_url     TEXT,
  phone          TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index sur le domaine pour filtrage rapide
CREATE INDEX idx_users_school_domain ON public.users (school_domain);
CREATE INDEX idx_users_verified ON public.users (is_student_verified);

-- =====================================================
-- TABLE : vendors
-- Marques / Restaurants / Boutiques partenaires
-- =====================================================
CREATE TABLE public.vendors (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name           TEXT NOT NULL,
  description    TEXT,
  category       TEXT NOT NULL CHECK (category IN ('food', 'tech', 'stationery', 'other')),
  logo_url       TEXT,
  banner_url     TEXT,
  address        TEXT NOT NULL,
  latitude       DOUBLE PRECISION,
  longitude      DOUBLE PRECISION,
  stripe_account_id TEXT,               -- Compte Stripe Connect du vendeur
  is_active      BOOLEAN NOT NULL DEFAULT TRUE,
  opening_hours  JSONB,                 -- { "mon": "09:00-22:00", "tue": ... }
  delivery_zone_radius_km NUMERIC(5,2) DEFAULT 5.0,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_vendors_category ON public.vendors (category);
CREATE INDEX idx_vendors_active ON public.vendors (is_active);

-- =====================================================
-- TABLE : catalog
-- Produits liés aux Vendors
-- =====================================================
CREATE TABLE public.catalog (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vendor_id      UUID NOT NULL REFERENCES public.vendors(id) ON DELETE CASCADE,
  name           TEXT NOT NULL,
  description    TEXT,
  price          NUMERIC(10,2) NOT NULL CHECK (price >= 0),
  original_price NUMERIC(10,2),         -- Pour afficher les promotions
  image_url      TEXT,
  category       TEXT NOT NULL,         -- Ex: "burger", "sushi", "laptop"
  is_available   BOOLEAN NOT NULL DEFAULT TRUE,
  stock_count    INT,                   -- NULL = illimité
  metadata       JSONB,                 -- Extras (taille, allergènes, etc.)
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_catalog_vendor ON public.catalog (vendor_id);
CREATE INDEX idx_catalog_available ON public.catalog (is_available);
CREATE INDEX idx_catalog_category ON public.catalog (category);

-- =====================================================
-- TABLE : orders
-- Commande globale multi-vendor
-- =====================================================
CREATE TABLE public.orders (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id        UUID NOT NULL REFERENCES public.users(id),
  status         TEXT NOT NULL DEFAULT 'pending'
                   CHECK (status IN ('pending','confirmed','preparing','in_delivery','delivered','cancelled')),
  total_amount   NUMERIC(10,2) NOT NULL,
  delivery_fee   NUMERIC(10,2) NOT NULL DEFAULT 0,
  platform_fee   NUMERIC(10,2) NOT NULL DEFAULT 0,
  delivery_address TEXT NOT NULL,
  delivery_lat   DOUBLE PRECISION,
  delivery_lng   DOUBLE PRECISION,
  stripe_payment_intent_id TEXT,
  promo_code     TEXT,
  discount_amount NUMERIC(10,2) DEFAULT 0,
  notes          TEXT,
  estimated_delivery_at TIMESTAMPTZ,
  delivered_at   TIMESTAMPTZ,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_orders_user ON public.orders (user_id);
CREATE INDEX idx_orders_status ON public.orders (status);

-- =====================================================
-- TABLE : sub_orders
-- Sous-commandes par vendeur (split d'une order globale)
-- =====================================================
CREATE TABLE public.sub_orders (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id       UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  vendor_id      UUID NOT NULL REFERENCES public.vendors(id),
  status         TEXT NOT NULL DEFAULT 'pending'
                   CHECK (status IN ('pending','confirmed','preparing','ready','picked_up','delivered','cancelled')),
  subtotal       NUMERIC(10,2) NOT NULL,
  vendor_fee     NUMERIC(10,2) NOT NULL DEFAULT 0,
  stripe_transfer_id TEXT,             -- Transfer Stripe vers le vendeur
  tracking_url   TEXT,                 -- Lien suivi Stuart/Uber Direct
  driver_info    JSONB,                -- { "name": "...", "phone": "...", "eta": ... }
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sub_orders_order ON public.sub_orders (order_id);
CREATE INDEX idx_sub_orders_vendor ON public.sub_orders (vendor_id);
CREATE INDEX idx_sub_orders_status ON public.sub_orders (status);

-- =====================================================
-- TABLE : order_items
-- Lignes de produit dans une sous-commande
-- =====================================================
CREATE TABLE public.order_items (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sub_order_id   UUID NOT NULL REFERENCES public.sub_orders(id) ON DELETE CASCADE,
  product_id     UUID NOT NULL REFERENCES public.catalog(id),
  quantity       INT NOT NULL CHECK (quantity > 0),
  unit_price     NUMERIC(10,2) NOT NULL,  -- Prix au moment de la commande
  total_price    NUMERIC(10,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
  customization  JSONB,                   -- Options choisies (taille, extras)
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_order_items_sub_order ON public.order_items (sub_order_id);

-- =====================================================
-- TABLE : promo_codes
-- Codes promotionnels statiques (Phase 2)
-- =====================================================
CREATE TABLE public.promo_codes (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code           TEXT UNIQUE NOT NULL,
  discount_type  TEXT NOT NULL CHECK (discount_type IN ('percentage','fixed')),
  discount_value NUMERIC(10,2) NOT NULL,
  min_order_amount NUMERIC(10,2) DEFAULT 0,
  max_uses       INT,
  current_uses   INT NOT NULL DEFAULT 0,
  valid_from     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  valid_until    TIMESTAMPTZ,
  vendor_id      UUID REFERENCES public.vendors(id), -- NULL = toutes enseignes
  is_active      BOOLEAN NOT NULL DEFAULT TRUE,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.catalog ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sub_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- Users : chaque utilisateur ne voit que son propre profil
CREATE POLICY "users_select_own" ON public.users
  FOR SELECT USING (auth.uid() = auth_id);

CREATE POLICY "users_update_own" ON public.users
  FOR UPDATE USING (auth.uid() = auth_id);

-- Vendors : lecture publique (utilisateurs vérifiés seulement)
CREATE POLICY "vendors_select_verified" ON public.vendors
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE auth_id = auth.uid() AND is_student_verified = TRUE
    )
  );

-- Catalog : lecture publique pour utilisateurs vérifiés
CREATE POLICY "catalog_select_verified" ON public.catalog
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE auth_id = auth.uid() AND is_student_verified = TRUE
    )
  );

-- Orders : chaque user voit ses propres commandes
CREATE POLICY "orders_select_own" ON public.orders
  FOR SELECT USING (
    user_id IN (
      SELECT id FROM public.users WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY "orders_insert_own" ON public.orders
  FOR INSERT WITH CHECK (
    user_id IN (
      SELECT id FROM public.users WHERE auth_id = auth.uid()
    )
  );

-- =====================================================
-- TRIGGERS : updated_at automatique
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER vendors_updated_at
  BEFORE UPDATE ON public.vendors
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER catalog_updated_at
  BEFORE UPDATE ON public.catalog
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER orders_updated_at
  BEFORE UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER sub_orders_updated_at
  BEFORE UPDATE ON public.sub_orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
