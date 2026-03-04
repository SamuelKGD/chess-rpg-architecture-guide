// lib/presentation/blocs/cart_bloc.dart
// BLoC de gestion du panier multi-vendeurs

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/cart.dart';

// ---------- Events ----------

abstract class CartEvent extends Equatable {
  const CartEvent();
  @override
  List<Object?> get props => [];
}

class CartItemAdded extends CartEvent {
  final CartItem item;
  const CartItemAdded(this.item);
  @override
  List<Object?> get props => [item.productId, item.vendorId, item.quantity];
}

class CartItemRemoved extends CartEvent {
  final String productId;
  final String vendorId;
  const CartItemRemoved({required this.productId, required this.vendorId});
  @override
  List<Object?> get props => [productId, vendorId];
}

class CartQuantityUpdated extends CartEvent {
  final String productId;
  final String vendorId;
  final int quantity;
  const CartQuantityUpdated({
    required this.productId,
    required this.vendorId,
    required this.quantity,
  });
  @override
  List<Object?> get props => [productId, vendorId, quantity];
}

class CartPromoApplied extends CartEvent {
  final String promoCode;
  final double discountAmount;
  const CartPromoApplied({required this.promoCode, required this.discountAmount});
  @override
  List<Object?> get props => [promoCode, discountAmount];
}

class CartPromoRemoved extends CartEvent {
  const CartPromoRemoved();
}

class CartCleared extends CartEvent {
  const CartCleared();
}

// ---------- State ----------

class CartState extends Equatable {
  final CartEntity cart;
  final bool isLoading;
  final String? errorMessage;

  const CartState({
    required this.cart,
    this.isLoading = false,
    this.errorMessage,
  });

  factory CartState.initial() => CartState(cart: CartEntity.empty());

  CartState copyWith({
    CartEntity? cart,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CartState(
      cart: cart ?? this.cart,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [cart, isLoading, errorMessage];
}

// ---------- BLoC ----------

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(CartState.initial()) {
    on<CartItemAdded>(_onItemAdded);
    on<CartItemRemoved>(_onItemRemoved);
    on<CartQuantityUpdated>(_onQuantityUpdated);
    on<CartPromoApplied>(_onPromoApplied);
    on<CartPromoRemoved>(_onPromoRemoved);
    on<CartCleared>(_onCleared);
  }

  void _onItemAdded(CartItemAdded event, Emitter<CartState> emit) {
    final updatedCart = state.cart.addItem(event.item);
    emit(state.copyWith(cart: updatedCart));
  }

  void _onItemRemoved(CartItemRemoved event, Emitter<CartState> emit) {
    final updatedCart =
        state.cart.removeItem(event.productId, event.vendorId);
    emit(state.copyWith(cart: updatedCart));
  }

  void _onQuantityUpdated(CartQuantityUpdated event, Emitter<CartState> emit) {
    final updatedCart = state.cart.updateQuantity(
      event.productId,
      event.vendorId,
      event.quantity,
    );
    emit(state.copyWith(cart: updatedCart));
  }

  void _onPromoApplied(CartPromoApplied event, Emitter<CartState> emit) {
    final updatedCart =
        state.cart.applyPromo(event.promoCode, event.discountAmount);
    emit(state.copyWith(cart: updatedCart));
  }

  void _onPromoRemoved(CartPromoRemoved event, Emitter<CartState> emit) {
    emit(state.copyWith(cart: state.cart.clearPromo()));
  }

  void _onCleared(CartCleared event, Emitter<CartState> emit) {
    emit(CartState.initial());
  }
}
