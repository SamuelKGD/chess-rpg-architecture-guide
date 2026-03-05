/// Modèle de données pour une annonce du Contre-Marché.
///
/// Représente un produit ou service mis en vente par un étudiant.

enum ListingStatus { active, sold, expired }

class MarketListing {
  final String id;
  final String sellerId;
  final String? sellerUsername;
  final String title;
  final String? description;
  final int priceCents;
  final String? imageUrl;
  final ListingStatus status;
  final String? campus;
  final DateTime createdAt;

  const MarketListing({
    required this.id,
    required this.sellerId,
    this.sellerUsername,
    required this.title,
    this.description,
    required this.priceCents,
    this.imageUrl,
    this.status = ListingStatus.active,
    this.campus,
    required this.createdAt,
  });

  /// Prix formaté en euros.
  String get formattedPrice {
    final euros = priceCents ~/ 100;
    final cents = priceCents % 100;
    return '$euros,${cents.toString().padLeft(2, '0')} €';
  }

  factory MarketListing.fromJson(Map<String, dynamic> json) {
    return MarketListing(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      sellerUsername: json['seller_username'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      priceCents: (json['price_cents'] as num).toInt(),
      imageUrl: json['image_url'] as String?,
      status: ListingStatus.values.byName(json['status'] as String),
      campus: json['campus'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seller_id': sellerId,
      'title': title,
      'description': description,
      'price_cents': priceCents,
      'image_url': imageUrl,
      'campus': campus,
    };
  }
}
