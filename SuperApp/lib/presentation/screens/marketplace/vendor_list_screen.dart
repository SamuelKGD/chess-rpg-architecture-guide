// lib/presentation/screens/marketplace/vendor_list_screen.dart
// Listing des vendeurs avec filtres par catégorie

import 'package:flutter/material.dart';

import '../../../domain/entities/vendor.dart';

/// Écran principal du Marketplace.
/// Affiche les vendeurs avec filtres par catégorie (Burger, Sushi, Papeterie, Tech).
class VendorListScreen extends StatefulWidget {
  const VendorListScreen({super.key});

  @override
  State<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<VendorListScreen> {
  VendorCategory? _selectedCategory;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static const List<_FilterOption> _filters = [
    _FilterOption(label: 'Tout', category: null, icon: Icons.grid_view_outlined),
    _FilterOption(label: 'Food', category: VendorCategory.food, icon: Icons.fastfood_outlined),
    _FilterOption(label: 'Tech', category: VendorCategory.tech, icon: Icons.devices_outlined),
    _FilterOption(
      label: 'Papeterie',
      category: VendorCategory.stationery,
      icon: Icons.menu_book_outlined,
    ),
    _FilterOption(label: 'Autre', category: VendorCategory.other, icon: Icons.more_horiz),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Rechercher un vendeur ou produit...',
              leading: const Icon(Icons.search),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filtres catégorie
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final filter = _filters[i];
                final selected = _selectedCategory == filter.category;
                return FilterChip(
                  label: Text(filter.label),
                  avatar: Icon(filter.icon, size: 16),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _selectedCategory = filter.category),
                );
              },
            ),
          ),
          const Divider(height: 1),

          // Liste des vendeurs
          Expanded(
            child: _VendorListBody(
              category: _selectedCategory,
              searchQuery: _searchController.text,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Corps de la liste (à connecter au BLoC) ----------

class _VendorListBody extends StatelessWidget {
  final VendorCategory? category;
  final String searchQuery;

  const _VendorListBody({required this.category, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with BlocBuilder<VendorBloc, VendorState>
    // Données de démonstration
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5, // placeholder count
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _VendorCard(
        name: 'Vendeur ${i + 1}',
        category: category ?? VendorCategory.food,
        deliveryTime: '${20 + i * 5} min',
        deliveryFee: '${(1.99 + i * 0.5).toStringAsFixed(2)} €',
        logoUrl: null,
        onTap: () {
          // TODO: Navigate to vendor detail
        },
      ),
    );
  }
}

class _VendorCard extends StatelessWidget {
  final String name;
  final VendorCategory category;
  final String deliveryTime;
  final String deliveryFee;
  final String? logoUrl;
  final VoidCallback onTap;

  const _VendorCard({
    required this.name,
    required this.category,
    required this.deliveryTime,
    required this.deliveryFee,
    this.logoUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner placeholder
            Container(
              height: 100,
              color: theme.colorScheme.surfaceContainerHighest,
              child: Center(
                child: Icon(
                  Icons.storefront_outlined,
                  size: 40,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 12),
                          const SizedBox(width: 4),
                          Text(deliveryTime, style: theme.textTheme.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Livraison $deliveryFee',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterOption {
  final String label;
  final VendorCategory? category;
  final IconData icon;
  const _FilterOption({
    required this.label,
    required this.category,
    required this.icon,
  });
}
