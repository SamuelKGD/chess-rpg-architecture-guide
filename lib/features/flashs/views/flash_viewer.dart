import 'package:flutter/material.dart';
import '../../../design_system/brutalist_theme.dart';

/// Visualiseur plein écran pour une story Flash.
///
/// Affiche le contenu éphémère avec une barre de progression
/// et gère le tap pour passer à la story suivante.

class FlashViewer extends StatelessWidget {
  const FlashViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrutalistColors.backgroundDark,
      body: GestureDetector(
        onTapUp: (_) {
          // TODO: Naviguer vers la story suivante ou fermer
        },
        child: const Center(
          child: Text(
            'FLASH',
            style: BrutalistTypography.displayLarge,
          ),
        ),
      ),
    );
  }
}
