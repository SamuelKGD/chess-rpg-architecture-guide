import 'package:flutter/material.dart';
import '../../../design_system/brutalist_theme.dart';
import '../models/vertical_post.dart';

/// Carte plein écran pour un post dans le Porte-Voix.
///
/// Affiche le contenu brutaliste (typo massive, fond sombre)
/// avec les actions Karma (upvote), commentaire et partage.

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post});

  final VerticalPost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: BrutalistColors.backgroundDark,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          // Titre brutaliste
          if (post.title != null)
            Text(
              post.title!.toUpperCase(),
              style: BrutalistTypography.displayLarge,
            ),
          const SizedBox(height: 16),
          // Corps du post
          if (post.body != null)
            Text(post.body!, style: BrutalistTypography.bodyLarge),
          const Spacer(),
          // Barre d'actions
          _buildActionBar(context),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _ActionButton(
          icon: Icons.arrow_upward,
          label: '${post.karmaScore}',
          color: BrutalistColors.accentYellow,
        ),
        const _ActionButton(
          icon: Icons.chat_bubble_outline,
          label: 'Commenter',
        ),
        const _ActionButton(
          icon: Icons.share,
          label: 'Partager',
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    this.color = Colors.white,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}
