import 'package:flutter/material.dart';
import '../models/vertical_post.dart';
import '../providers/porte_voix_provider.dart';
import 'post_card.dart';

/// Écran principal du Porte-Voix — Feed vertical plein écran.
///
/// Utilise un [PageView] vertical (Swipe Up) inspiré de TikTok.
/// Le bandeau des Flashs est affiché au-dessus.

class PorteVoixScreen extends StatefulWidget {
  const PorteVoixScreen({super.key});

  @override
  State<PorteVoixScreen> createState() => _PorteVoixScreenState();
}

class _PorteVoixScreenState extends State<PorteVoixScreen> {
  final PageController _pageController = PageController();
  final PorteVoixProvider _provider = PorteVoixProvider();

  @override
  void initState() {
    super.initState();
    _provider.loadPosts();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: _provider,
        builder: (context, _) {
          final posts = _provider.posts;

          if (posts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return PostCard(post: posts[index]);
            },
          );
        },
      ),
    );
  }
}
