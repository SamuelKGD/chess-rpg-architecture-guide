import 'package:flutter/material.dart';
import '../../../design_system/brutalist_theme.dart';
import '../../../design_system/brutalist_components.dart';

/// Écran principal du Contre-Marché — Marketplace P2P.
///
/// Affiche les annonces actives avec filtres par campus.
/// Intégration fluide dans le Porte-Voix et l'Assemblée.

class ContreMarcheScreen extends StatelessWidget {
  const ContreMarcheScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrutalistColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: BrutalistColors.surface,
        title: Text(
          'CONTRE-MARCHÉ',
          style: BrutalistTypography.headlineLarge,
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 0, // TODO: Connecter au provider
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: BrutalistCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Annonce', style: BrutalistTypography.headlineLarge),
                    const SizedBox(height: 8),
                    Text('Description', style: BrutalistTypography.bodyLarge),
                    const SizedBox(height: 12),
                    BrutalistButton(
                      label: 'Commander',
                      color: BrutalistColors.accentGreen,
                      onPressed: () {
                        // TODO: Lancer le flux de commande
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
