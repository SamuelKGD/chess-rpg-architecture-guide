import 'package:flutter/material.dart';
import 'brutalist_theme.dart';

/// Composants réutilisables du Design System brutaliste.
///
/// Bordures épaisses, ombres dures (hard shadows, pas de blur),
/// design "brut" mais animations ultra-fluides.

class BrutalistButton extends StatelessWidget {
  const BrutalistButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = BrutalistColors.accentYellow,
  });

  final String label;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(
          label.toUpperCase(),
          style: BrutalistTypography.label,
        ),
      ),
    );
  }
}

class BrutalistCard extends StatelessWidget {
  const BrutalistCard({
    super.key,
    required this.child,
    this.borderColor = Colors.white,
  });

  final Widget child;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BrutalistColors.surface,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Colors.white24,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

class BrutalistAvatar extends StatelessWidget {
  const BrutalistAvatar({
    super.key,
    this.imageUrl,
    this.size = 48,
  });

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 2),
        color: BrutalistColors.surface,
      ),
      child: imageUrl != null
          ? Image.network(imageUrl!, fit: BoxFit.cover)
          : Icon(Icons.person, size: size * 0.6, color: Colors.white),
    );
  }
}
