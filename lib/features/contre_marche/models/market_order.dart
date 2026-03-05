/// Modèle de données pour une commande du Contre-Marché.
///
/// Gère le cycle de vie d'une commande : pending → paid → assigned → delivered.
/// Supporte IZLY et Stripe comme méthodes de paiement.

enum OrderStatus { pending, paid, assigned, delivered, cancelled }

enum PaymentMethod { izly, stripe }

class MarketOrder {
  final String id;
  final String listingId;
  final String buyerId;
  final String? courierId;
  final OrderStatus status;
  final PaymentMethod? paymentMethod;
  final int totalCents;
  final String? stripePaymentIntentId;
  final bool isPeerCourier;
  final DateTime createdAt;

  const MarketOrder({
    required this.id,
    required this.listingId,
    required this.buyerId,
    this.courierId,
    this.status = OrderStatus.pending,
    this.paymentMethod,
    required this.totalCents,
    this.stripePaymentIntentId,
    this.isPeerCourier = true,
    required this.createdAt,
  });

  /// Prix formaté en euros.
  String get formattedTotal {
    final euros = totalCents ~/ 100;
    final cents = totalCents % 100;
    return '$euros,${cents.toString().padLeft(2, '0')} €';
  }

  factory MarketOrder.fromJson(Map<String, dynamic> json) {
    return MarketOrder(
      id: json['id'] as String,
      listingId: json['listing_id'] as String,
      buyerId: json['buyer_id'] as String,
      courierId: json['courier_id'] as String?,
      status: OrderStatus.values.byName(json['status'] as String),
      paymentMethod: json['payment_method'] != null
          ? PaymentMethod.values.byName(json['payment_method'] as String)
          : null,
      totalCents: (json['total_cents'] as num).toInt(),
      stripePaymentIntentId: json['stripe_payment_intent_id'] as String?,
      isPeerCourier: (json['is_peer_courier'] as bool?) ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'listing_id': listingId,
      'buyer_id': buyerId,
      'payment_method': paymentMethod?.name,
      'total_cents': totalCents,
    };
  }
}
