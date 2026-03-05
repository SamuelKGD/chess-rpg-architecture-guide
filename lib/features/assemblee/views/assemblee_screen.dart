import 'package:flutter/material.dart';
import '../../../design_system/brutalist_theme.dart';
import '../providers/assemblee_provider.dart';

/// Écran principal de L'Assemblée — Organisation communautaire.
///
/// Onglets : Groupes Filières, Événements, Annuaire Campus.
/// Inspiré de Facebook 2004 — simplicité et utilité.

class AssembleeScreen extends StatelessWidget {
  const AssembleeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: BrutalistColors.backgroundDark,
        appBar: AppBar(
          title: Text(
            'L\'ASSEMBLÉE',
            style: BrutalistTypography.headlineLarge,
          ),
          backgroundColor: BrutalistColors.surface,
          bottom: const TabBar(
            indicatorColor: BrutalistColors.accentYellow,
            labelColor: BrutalistColors.accentYellow,
            unselectedLabelColor: BrutalistColors.textSecondary,
            tabs: [
              Tab(text: 'GROUPES'),
              Tab(text: 'ÉVÉNEMENTS'),
              Tab(text: 'ANNUAIRE'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GroupsTab(),
            _EventsTab(),
            _DirectoryTab(),
          ],
        ),
      ),
    );
  }
}

class _GroupsTab extends StatelessWidget {
  const _GroupsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Groupes par filière',
        style: BrutalistTypography.bodyLarge,
      ),
    );
  }
}

class _EventsTab extends StatelessWidget {
  const _EventsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Événements campus',
        style: BrutalistTypography.bodyLarge,
      ),
    );
  }
}

class _DirectoryTab extends StatelessWidget {
  const _DirectoryTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Annuaire campus',
        style: BrutalistTypography.bodyLarge,
      ),
    );
  }
}
