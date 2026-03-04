// test/email_validator_test.dart
// Tests unitaires pour la validation d'email étudiant

import '../lib/core/utils/email_validator.dart';
import '../lib/core/constants/app_constants.dart';

// Minimal test runner (no external test framework needed for Dart)
void main() {
  var passed = 0;
  var failed = 0;

  void expect(dynamic actual, dynamic expected, String testName) {
    if (actual == expected) {
      print('✅ PASS: $testName');
      passed++;
    } else {
      print('❌ FAIL: $testName\n   Expected: $expected\n   Got:      $actual');
      failed++;
    }
  }

  // ---- Format invalide ----
  expect(
    validateStudentEmail(''),
    EmailValidationResult.invalidFormat,
    'Empty string → invalidFormat',
  );
  expect(
    validateStudentEmail('notanemail'),
    EmailValidationResult.invalidFormat,
    'No @ symbol → invalidFormat',
  );
  expect(
    validateStudentEmail('@univ-paris.fr'),
    EmailValidationResult.invalidFormat,
    'Missing local part → invalidFormat',
  );

  // ---- Domaine non reconnu ----
  expect(
    validateStudentEmail('user@gmail.com'),
    EmailValidationResult.unknownDomain,
    'Gmail → unknownDomain',
  );
  expect(
    validateStudentEmail('user@hotmail.fr'),
    EmailValidationResult.unknownDomain,
    'Hotmail → unknownDomain',
  );
  expect(
    validateStudentEmail('user@yahoo.fr'),
    EmailValidationResult.unknownDomain,
    'Yahoo → unknownDomain',
  );

  // ---- Emails valides ----
  expect(
    validateStudentEmail('jean.dupont@univ-paris.fr'),
    EmailValidationResult.valid,
    'Recognized .fr university → valid',
  );
  expect(
    validateStudentEmail('alice@student.mit.edu'),
    EmailValidationResult.valid,
    '.edu suffix → valid',
  );
  expect(
    validateStudentEmail('bob@hec.edu'),
    EmailValidationResult.valid,
    'Whitelisted grande école → valid',
  );
  expect(
    validateStudentEmail('charlie@paris-saclay.fr'),
    EmailValidationResult.valid,
    'Whitelisted paris-saclay.fr → valid',
  );
  expect(
    validateStudentEmail('dana@etu.univ-lyon3.fr'),
    EmailValidationResult.valid,
    'etu. subdomain → valid',
  );
  expect(
    validateStudentEmail('EVA@STUDENT.POLYTECHNIQUE.EDU'),
    EmailValidationResult.valid,
    'Case insensitive .edu → valid',
  );

  // ---- Messages d'erreur ----
  expect(
    emailValidationMessage(EmailValidationResult.valid),
    null,
    'Valid email → no error message',
  );
  expect(
    emailValidationMessage(EmailValidationResult.invalidFormat) != null,
    true,
    'InvalidFormat → non-null message',
  );
  expect(
    emailValidationMessage(EmailValidationResult.unknownDomain) != null,
    true,
    'UnknownDomain → non-null message',
  );

  // ---- CartEntity tests ----
  final emptyCart = CartEntity.empty();
  expect(emptyCart.isEmpty, true, 'New cart is empty');
  expect(emptyCart.totalItemCount, 0, 'New cart has 0 items');
  expect(emptyCart.subtotal, 0.0, 'New cart subtotal is 0');

  final item1 = CartItem(
    productId: 'p1',
    vendorId: 'v1',
    productName: 'Burger',
    unitPrice: 12.50,
    quantity: 2,
  );
  final cartWithItem = emptyCart.addItem(item1);
  expect(cartWithItem.isEmpty, false, 'Cart with item is not empty');
  expect(cartWithItem.totalItemCount, 2, 'Cart has 2 items after add');
  expect(cartWithItem.subtotal, 25.0, 'Cart subtotal = 12.50 × 2 = 25.00');
  expect(cartWithItem.vendorCount, 1, 'Cart has 1 vendor');

  // Add from a second vendor
  final item2 = CartItem(
    productId: 'p2',
    vendorId: 'v2',
    productName: 'Laptop',
    unitPrice: 899.0,
    quantity: 1,
  );
  final multiVendorCart = cartWithItem.addItem(item2);
  expect(multiVendorCart.vendorCount, 2, 'Cart has 2 vendors after adding from different vendor');
  expect(multiVendorCart.totalItemCount, 3, 'Cart has 3 items total');

  // Increase quantity of existing item
  final sameItem = CartItem(
    productId: 'p1',
    vendorId: 'v1',
    productName: 'Burger',
    unitPrice: 12.50,
    quantity: 1,
  );
  final cartWithMore = cartWithItem.addItem(sameItem);
  expect(cartWithMore.totalItemCount, 3, 'Adding same item increases quantity');

  // Remove item
  final cartAfterRemove = multiVendorCart.removeItem('p1', 'v1');
  expect(cartAfterRemove.vendorCount, 1, 'Vendor removed when all items removed');

  // Update quantity to 0 removes item
  final cartZeroQty = multiVendorCart.updateQuantity('p1', 'v1', 0);
  expect(cartZeroQty.itemsByVendor.containsKey('v1'), false, 'Update to 0 removes item');

  // Promo code
  final cartWithPromo = emptyCart.addItem(item1).applyPromo('TEST10', 2.50);
  expect(cartWithPromo.promoCode, 'TEST10', 'Promo code applied');
  expect(cartWithPromo.discountAmount, 2.50, 'Discount amount set');
  expect(cartWithPromo.netTotal, 22.50, 'Net total = 25 - 2.50 = 22.50');

  final cartClearedPromo = cartWithPromo.clearPromo();
  expect(cartClearedPromo.promoCode, null, 'Promo cleared');
  expect(cartClearedPromo.discountAmount, 0.0, 'Discount reset to 0');

  // Clear cart
  final clearedCart = multiVendorCart.clear();
  expect(clearedCart.isEmpty, true, 'Cleared cart is empty');

  // ---- Summary ----
  print('\n=============================');
  print('Results: $passed passed, $failed failed');
  print('=============================');
  if (failed > 0) {
    throw Exception('$failed tests failed');
  }
}
