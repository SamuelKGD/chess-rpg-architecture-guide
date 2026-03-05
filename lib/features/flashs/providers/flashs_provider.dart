import 'package:flutter/foundation.dart';
import '../models/flash_story.dart';

/// Provider pour Les Flashs — gère les stories éphémères.
///
/// Charge les stories actives (non expirées) depuis Supabase.
/// Écoute les mises à jour en temps réel via Supabase Realtime.

class FlashsProvider extends ChangeNotifier {
  List<FlashStory> _stories = [];
  bool _isLoading = false;

  List<FlashStory> get stories => _stories;
  bool get isLoading => _isLoading;

  /// Charge les stories actives (expires_at > NOW()).
  Future<void> loadStories() async {
    _isLoading = true;
    notifyListeners();

    // TODO: Remplacer par un appel Supabase réel
    // final response = await supabase
    //     .from('stories')
    //     .select('*, profiles(username)')
    //     .gt('expires_at', DateTime.now().toIso8601String())
    //     .order('created_at', ascending: false);
    _stories = [];

    _isLoading = false;
    notifyListeners();
  }

  /// Crée une nouvelle story Flash.
  Future<void> createStory(FlashStory story) async {
    // TODO: Appel Supabase pour insérer dans stories
    notifyListeners();
  }
}
