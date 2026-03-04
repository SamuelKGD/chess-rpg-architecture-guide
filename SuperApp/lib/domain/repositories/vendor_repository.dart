// lib/domain/repositories/vendor_repository.dart
// Interface abstraite du repository vendeurs et catalogue

import '../entities/vendor.dart';
import '../entities/product.dart';

abstract class VendorRepository {
  /// Retourne la liste des vendeurs actifs, optionnellement filtrés par catégorie.
  Future<List<VendorEntity>> getVendors({VendorCategory? category});

  /// Retourne le détail d'un vendeur.
  Future<VendorEntity> getVendorById(String vendorId);

  /// Retourne le catalogue d'un vendeur, optionnellement filtré par catégorie produit.
  Future<List<ProductEntity>> getProductsByVendor(
    String vendorId, {
    String? category,
  });

  /// Retourne le détail d'un produit.
  Future<ProductEntity> getProductById(String productId);
}
