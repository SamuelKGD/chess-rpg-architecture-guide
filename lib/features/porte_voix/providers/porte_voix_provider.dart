import 'package:flutter/foundation.dart';
import '../models/vertical_post.dart';

/// Provider pour Le Porte-Voix — gère l'état du feed vertical.
///
/// Charge les posts depuis Supabase, triés par date + karma.
/// Fournit les méthodes de vote et de création de post.

class PorteVoixProvider extends ChangeNotifier {
  List<VerticalPost> _posts = [];
  bool _isLoading = false;

  List<VerticalPost> get posts => _posts;
  bool get isLoading => _isLoading;

  /// Charge les posts depuis Supabase (chronologique + karma).
  Future<void> loadPosts() async {
    _isLoading = true;
    notifyListeners();

    // TODO: Remplacer par un appel Supabase réel
    // final response = await supabase
    //     .from('vertical_posts')
    //     .select('*, profiles(username)')
    //     .order('created_at', ascending: false);
    _posts = [];

    _isLoading = false;
    notifyListeners();
  }

  /// Vote (upvote/downvote) sur un post.
  Future<void> vote(String postId, {required bool isUpvote}) async {
    // TODO: Appel Supabase pour insérer/modifier karma_votes
    notifyListeners();
  }

  /// Crée un nouveau post.
  Future<void> createPost(VerticalPost post) async {
    // TODO: Appel Supabase pour insérer dans vertical_posts
    notifyListeners();
  }
}
