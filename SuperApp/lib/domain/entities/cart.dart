// lib/domain/entities/cart.dart
// Entité domaine : Panier multi-vendeurs

class CartItem {
  final String productId;
  final String vendorId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final String? imageUrl;
  final Map<String, dynamic>? customization;

  const CartItem({
    required this.productId,
    required this.vendorId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.imageUrl,
    this.customization,
  });

  double get totalPrice => unitPrice * quantity;

  CartItem copyWith({int? quantity, Map<String, dynamic>? customization}) {
    return CartItem(
      productId: productId,
      vendorId: vendorId,
      productName: productName,
      unitPrice: unitPrice,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl,
      customization: customization ?? this.customization,
    );
  }
}

/// Panier global regroupant les items par vendeur
class CartEntity {
  final Map<String, List<CartItem>> itemsByVendor;
  final String? promoCode;
  final double discountAmount;

  const CartEntity({
    required this.itemsByVendor,
    this.promoCode,
    this.discountAmount = 0,
  });

  factory CartEntity.empty() => const CartEntity(itemsByVendor: {});

  /// Tous les items à plat
  List<CartItem> get allItems =>
      itemsByVendor.values.expand((items) => items).toList();

  /// Nombre total d'articles
  int get totalItemCount =>
      allItems.fold(0, (sum, item) => sum + item.quantity);

  /// Sous-total avant remise et livraison
  double get subtotal =>
      allItems.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// Total net après remise
  double get netTotal => subtotal - discountAmount;

  bool get isEmpty => itemsByVendor.isEmpty;

  int get vendorCount => itemsByVendor.keys.length;

  CartEntity addItem(CartItem item) {
    final updated = Map<String, List<CartItem>>.from(itemsByVendor);
    final vendorItems = List<CartItem>.from(updated[item.vendorId] ?? []);

    final existingIndex = vendorItems.indexWhere(
      (i) => i.productId == item.productId,
    );

    if (existingIndex >= 0) {
      vendorItems[existingIndex] = vendorItems[existingIndex].copyWith(
        quantity: vendorItems[existingIndex].quantity + item.quantity,
      );
    } else {
      vendorItems.add(item);
    }

    updated[item.vendorId] = vendorItems;
    return CartEntity(
      itemsByVendor: updated,
      promoCode: promoCode,
      discountAmount: discountAmount,
    );
  }

  CartEntity removeItem(String productId, String vendorId) {
    final updated = Map<String, List<CartItem>>.from(itemsByVendor);
    final vendorItems = List<CartItem>.from(updated[vendorId] ?? []);
    vendorItems.removeWhere((i) => i.productId == productId);
    if (vendorItems.isEmpty) {
      updated.remove(vendorId);
    } else {
      updated[vendorId] = vendorItems;
    }
    return CartEntity(
      itemsByVendor: updated,
      promoCode: promoCode,
      discountAmount: discountAmount,
    );
  }

  CartEntity updateQuantity(String productId, String vendorId, int quantity) {
    if (quantity <= 0) return removeItem(productId, vendorId);
    final updated = Map<String, List<CartItem>>.from(itemsByVendor);
    final vendorItems = List<CartItem>.from(updated[vendorId] ?? []);
    final idx = vendorItems.indexWhere((i) => i.productId == productId);
    if (idx >= 0) {
      vendorItems[idx] = vendorItems[idx].copyWith(quantity: quantity);
      updated[vendorId] = vendorItems;
    }
    return CartEntity(
      itemsByVendor: updated,
      promoCode: promoCode,
      discountAmount: discountAmount,
    );
  }

  CartEntity applyPromo(String code, double discount) {
    return CartEntity(
      itemsByVendor: itemsByVendor,
      promoCode: code,
      discountAmount: discount,
    );
  }

  CartEntity clearPromo() {
    return CartEntity(itemsByVendor: itemsByVendor);
  }

  CartEntity clear() => CartEntity.empty();
}
