// lib/domain/entities/vendor.dart
// Entité domaine : Vendeur / Enseigne partenaire

enum VendorCategory { food, tech, stationery, other }

class VendorEntity {
  final String id;
  final String name;
  final String? description;
  final VendorCategory category;
  final String? logoUrl;
  final String? bannerUrl;
  final String address;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final Map<String, String>? openingHours;
  final double deliveryZoneRadiusKm;

  const VendorEntity({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    this.logoUrl,
    this.bannerUrl,
    required this.address,
    this.latitude,
    this.longitude,
    required this.isActive,
    this.openingHours,
    this.deliveryZoneRadiusKm = 5.0,
  });
}
