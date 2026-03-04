// lib/presentation/screens/home/hub_dashboard_screen.dart
// Dashboard "Hub Étudiant" — Offres promotionnelles et navigation principale

import 'package:flutter/material.dart';

/// Dashboard principal affiché après vérification.
/// Présente les codes promo et l'accès aux fonctionnalités.
class HubDashboardScreen extends StatelessWidget {
  const HubDashboardScreen({super.key});

  // Codes promo statiques (Phase 1 — en dur, dynamique en Phase 2 via Supabase)
  static const List<_PromoOffer> _promos = [
    _PromoOffer(
      code: 'BIENVENUE10',
      title: '10% sur votre 1ère commande',
      subtitle: 'Tous les vendeurs • Illimité',
      color: Color(0xFF4CAF50),
      icon: Icons.celebration_outlined,
    ),
    _PromoOffer(
      code: 'BURGER5',
      title: '-5€ sur les burgers',
      subtitle: 'Commande min. 20€ • Valable 7 jours',
      color: Color(0xFFFF7043),
      icon: Icons.fastfood_outlined,
    ),
    _PromoOffer(
      code: 'TECH20',
      title: '20% sur la tech',
      subtitle: 'Accessoires & périphériques • Ce week-end',
      color: Color(0xFF3F51B5),
      icon: Icons.devices_outlined,
    ),
    _PromoOffer(
      code: 'RENTRÉE',
      title: 'Pack rentrée à -15%',
      subtitle: 'Fournitures scolaires • Jusqu\'au 30 sept.',
      color: Color(0xFF9C27B0),
      icon: Icons.school_outlined,
    ),
  ];

  static const List<_CategoryShortcut> _categories = [
    _CategoryShortcut(label: 'Burger', icon: Icons.lunch_dining_outlined, category: 'food'),
    _CategoryShortcut(label: 'Sushi', icon: Icons.set_meal_outlined, category: 'food'),
    _CategoryShortcut(label: 'Papeterie', icon: Icons.edit_note_outlined, category: 'stationery'),
    _CategoryShortcut(label: 'Tech', icon: Icons.laptop_outlined, category: 'tech'),
    _CategoryShortcut(label: 'Tout', icon: Icons.grid_view_outlined, category: null),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header avec salutation
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour 👋',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            'Hub Étudiant',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Icône panier
                    IconButton.filledTonal(
                      onPressed: () {
                        // TODO: Navigate to cart
                      },
                      icon: const Icon(Icons.shopping_cart_outlined),
                    ),
                  ],
                ),
              ),
            ),

            // Raccourcis catégories
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: SizedBox(
                  height: 80,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final cat = _categories[i];
                      return _CategoryChip(shortcut: cat);
                    },
                  ),
                ),
              ),
            ),

            // Section Offres Promotionnelles
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text(
                  '🎁 Offres étudiantes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Carrousel horizontal des promos
            SliverToBoxAdapter(
              child: SizedBox(
                height: 140,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: _promos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => _PromoCard(offer: _promos[i]),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Accès rapide Marketplace
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FilledButton.icon(
                  onPressed: () {
                    // TODO: Navigate to marketplace
                  },
                  icon: const Icon(Icons.storefront_outlined),
                  label: const Text('Explorer le Marketplace'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

// ---------- Widgets auxiliaires ----------

class _PromoOffer {
  final String code;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  const _PromoOffer({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });
}

class _PromoCard extends StatelessWidget {
  final _PromoOffer offer;
  const _PromoCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: offer.color,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(offer.icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  offer.code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            offer.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            offer.subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CategoryShortcut {
  final String label;
  final IconData icon;
  final String? category;
  const _CategoryShortcut({
    required this.label,
    required this.icon,
    required this.category,
  });
}

class _CategoryChip extends StatelessWidget {
  final _CategoryShortcut shortcut;
  const _CategoryChip({required this.shortcut});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        // TODO: Navigate to marketplace with category filter
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(shortcut.icon, size: 28, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              shortcut.label,
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
