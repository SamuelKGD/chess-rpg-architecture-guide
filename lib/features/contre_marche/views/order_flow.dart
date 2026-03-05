import 'package:flutter/material.dart';
import '../../../design_system/brutalist_theme.dart';
import '../../../design_system/brutalist_components.dart';

/// Flux de commande du Contre-Marché.
///
/// Étapes : Sélection paiement (IZLY/Stripe) → Confirmation → Suivi.
/// Attribution automatique d'un coursier "Allié" (étudiant P2P).

class OrderFlow extends StatelessWidget {
  const OrderFlow({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrutalistColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: BrutalistColors.surface,
        title: Text('COMMANDE', style: BrutalistTypography.headlineLarge),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'MÉTHODE DE PAIEMENT',
              style: BrutalistTypography.displayMedium,
            ),
            const SizedBox(height: 24),
            BrutalistButton(
              label: 'Payer avec IZLY',
              color: BrutalistColors.accentYellow,
              onPressed: () {
                // TODO: Intégration IZLY
              },
            ),
            const SizedBox(height: 16),
            BrutalistButton(
              label: 'Payer par Carte (Stripe)',
              color: BrutalistColors.accentGreen,
              onPressed: () {
                // TODO: Intégration Stripe
              },
            ),
            const Spacer(),
            Text(
              'UN ALLIÉ ÉTUDIANT SERA PRIORITAIRE\nPOUR LA LIVRAISON.',
              style: BrutalistTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
