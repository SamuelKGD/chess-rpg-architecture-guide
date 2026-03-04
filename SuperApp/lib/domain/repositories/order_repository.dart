// lib/domain/repositories/order_repository.dart
// Interface abstraite du repository des commandes

import '../entities/cart.dart';

abstract class OrderRepository {
  /// Valide le panier, calcule les frais et crée le PaymentIntent Stripe.
  /// Retourne le client_secret du PaymentIntent.
  Future<({String clientSecret, Map<String, dynamic> orderSummary})> validateOrder({
    required CartEntity cart,
    required String deliveryAddress,
    required double deliveryLat,
    required double deliveryLng,
  });

  /// Dispatche la commande après confirmation du paiement Stripe.
  Future<Map<String, dynamic>> dispatchOrder({
    required String orderId,
    required String paymentIntentId,
  });

  /// Retourne l'historique de commandes de l'utilisateur courant.
  Future<List<Map<String, dynamic>>> getOrderHistory();

  /// Stream de mises à jour en temps réel d'une commande.
  Stream<Map<String, dynamic>> watchOrder(String orderId);
}
