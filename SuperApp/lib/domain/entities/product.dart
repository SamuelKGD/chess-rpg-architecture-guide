// lib/domain/entities/product.dart
// Entité domaine : Produit du catalogue

class ProductEntity {
  final String id;
  final String vendorId;
  final String name;
  final String? description;
  final double price;
  final double? originalPrice;
  final String? imageUrl;
  final String category;
  final bool isAvailable;
  final int? stockCount;
  final Map<String, dynamic>? metadata;

  const ProductEntity({
    required this.id,
    required this.vendorId,
    required this.name,
    this.description,
    required this.price,
    this.originalPrice,
    this.imageUrl,
    required this.category,
    required this.isAvailable,
    this.stockCount,
    this.metadata,
  });

  bool get isOnSale =>
      originalPrice != null && originalPrice! > price;

  double get discountPercent {
    if (!isOnSale) return 0;
    return ((originalPrice! - price) / originalPrice! * 100).roundToDouble();
  }
}
