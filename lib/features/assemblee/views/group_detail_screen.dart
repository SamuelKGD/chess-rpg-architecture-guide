import 'package:flutter/material.dart';
import '../../../design_system/brutalist_theme.dart';

/// Écran de détail d'un groupe d'étude.
///
/// Affiche les membres, fiches de cours partagées et événements du groupe.

class GroupDetailScreen extends StatelessWidget {
  const GroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrutalistColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: BrutalistColors.surface,
        title: Text(
          'GROUPE',
          style: BrutalistTypography.headlineLarge,
        ),
      ),
      body: const Center(
        child: Text(
          'Détail du groupe',
          style: BrutalistTypography.bodyLarge,
        ),
      ),
    );
  }
}
