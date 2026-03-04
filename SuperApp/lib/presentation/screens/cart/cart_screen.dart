// lib/presentation/screens/cart/cart_screen.dart
// Panier multi-vendeurs avec gestion d'état complexe

import 'package:flutter/material.dart';

import '../../../domain/entities/cart.dart';

/// Écran Panier — Affiche les items regroupés par vendeur.
/// Supporte les articles provenant de plusieurs enseignes simultanément.
class CartScreen extends StatelessWidget {
  final CartEntity cart;
  final VoidCallback? onCheckout;

  const CartScreen({super.key, required this.cart, this.onCheckout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mon panier')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 80,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Votre panier est vide',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Explorer le Marketplace'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Panier (${cart.totalItemCount})'),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: dispatch ClearCartEvent via BLoC
            },
            child: Text(
              'Vider',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Avertissement si multi-vendeurs (info UX)
          if (cart.vendorCount > 1)
            Container(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${cart.vendorCount} enseignes — livraisons séparées',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),

          // Liste des groupes par vendeur
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cart.itemsByVendor.length,
              itemBuilder: (context, i) {
                final vendorId = cart.itemsByVendor.keys.elementAt(i);
                final items = cart.itemsByVendor[vendorId]!;
                return _VendorCartGroup(
                  vendorId: vendorId,
                  items: items,
                );
              },
            ),
          ),

          // Récapitulatif et bouton de paiement
          _CartSummary(cart: cart, onCheckout: onCheckout),
        ],
      ),
    );
  }
}

// ---------- Groupe d'items par vendeur ----------

class _VendorCartGroup extends StatelessWidget {
  final String vendorId;
  final List<CartItem> items;

  const _VendorCartGroup({required this.vendorId, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtotal = items.fold(0.0, (s, i) => s + i.totalPrice);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête vendeur
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Icon(Icons.storefront_outlined,
                    size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    // TODO: Resolve vendor name from BLoC state
                    'Vendeur ($vendorId)',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${subtotal.toStringAsFixed(2)} €',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          ...items.map((item) => _CartItemTile(item: item)),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: item.imageUrl != null
            ? Image.network(
                item.imageUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              )
            : Container(
                width: 48,
                height: 48,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(Icons.image_outlined,
                    color: theme.colorScheme.onSurfaceVariant),
              ),
      ),
      title: Text(item.productName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${item.unitPrice.toStringAsFixed(2)} €'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () {
              // TODO: dispatch UpdateQuantityEvent via BLoC
            },
          ),
          Text('${item.quantity}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              )),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              // TODO: dispatch UpdateQuantityEvent via BLoC
            },
          ),
        ],
      ),
    );
  }
}

// ---------- Récapitulatif total + bouton paiement ----------

class _CartSummary extends StatelessWidget {
  final CartEntity cart;
  final VoidCallback? onCheckout;

  const _CartSummary({required this.cart, this.onCheckout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Sous-total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sous-total'),
              Text('${cart.subtotal.toStringAsFixed(2)} €'),
            ],
          ),
          if (cart.discountAmount > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Code promo (${cart.promoCode})',
                    style: TextStyle(color: theme.colorScheme.primary)),
                Text(
                  '- ${cart.discountAmount.toStringAsFixed(2)} €',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Livraison',
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
              ),
              Text(
                'Calculée à l\'étape suivante',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total estimé',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '${cart.netTotal.toStringAsFixed(2)} €',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onCheckout,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Passer la commande',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
