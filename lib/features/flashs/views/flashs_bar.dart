import 'package:flutter/material.dart';
import '../../../design_system/brutalist_theme.dart';
import '../models/flash_story.dart';
import '../providers/flashs_provider.dart';

/// Bandeau horizontal de stories éphémères (Les Flashs).
///
/// Affiché en haut du Porte-Voix sous forme de [ListView] horizontal.
/// Inspiré des Stories Instagram — contenu éphémère 24h.

class FlashsBar extends StatelessWidget {
  const FlashsBar({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Connecter au FlashsProvider réel
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: 0, // Remplacer par provider.stories.length
        itemBuilder: (context, index) {
          return const _FlashThumbnail();
        },
      ),
    );
  }
}

class _FlashThumbnail extends StatelessWidget {
  const _FlashThumbnail();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border: Border.all(color: BrutalistColors.accentRed, width: 2),
        color: BrutalistColors.surface,
      ),
      child: const Center(
        child: Icon(Icons.flash_on, color: BrutalistColors.accentYellow),
      ),
    );
  }
}
