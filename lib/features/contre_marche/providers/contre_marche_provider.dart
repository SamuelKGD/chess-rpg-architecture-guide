import 'package:flutter/foundation.dart';
import '../models/market_listing.dart';
import '../models/market_order.dart';

/// Provider pour Le Contre-Marché — gère annonces et commandes.
///
/// Charge les annonces actives, crée des commandes,
/// et gère le système Alliés (coursiers étudiants P2P).

class ContreMarcheProvider extends ChangeNotifier {
  List<MarketListing> _listings = [];
  List<MarketOrder> _orders = [];
  bool _isLoading = false;

  List<MarketListing> get listings => _listings;
  List<MarketOrder> get orders => _orders;
  bool get isLoading => _isLoading;

  /// Charge les annonces actives depuis Supabase.
  Future<void> loadListings({String? campus}) async {
    _isLoading = true;
    notifyListeners();

    // TODO: Remplacer par un appel Supabase réel
    // _listings = response.map(MarketListing.fromJson).toList();

    _isLoading = false;
    notifyListeners();
  }

  /// Crée une commande pour une annonce.
  Future<MarketOrder?> createOrder({
    required String listingId,
    required PaymentMethod paymentMethod,
  }) async {
    // TODO: Appel Supabase + Stripe/IZLY
    notifyListeners();
    return null;
  }

  /// Charge les commandes de l'utilisateur courant.
  Future<void> loadMyOrders() async {
    _isLoading = true;
    notifyListeners();

    // TODO: Remplacer par un appel Supabase réel
    // _orders = response.map(MarketOrder.fromJson).toList();

    _isLoading = false;
    notifyListeners();
  }

  /// Crée une nouvelle annonce.
  Future<void> createListing(MarketListing listing) async {
    // TODO: Appel Supabase pour insérer dans market_listings
    notifyListeners();
  }
}
