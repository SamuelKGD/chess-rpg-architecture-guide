import 'package:flutter/foundation.dart';
import '../models/study_group.dart';
import '../models/campus_event.dart';

/// Provider pour L'Assemblée — gère groupes et événements.
///
/// Charge les groupes par filière, les événements campus,
/// et gère l'adhésion aux groupes.

class AssembleeProvider extends ChangeNotifier {
  List<StudyGroup> _groups = [];
  List<CampusEvent> _events = [];
  bool _isLoading = false;

  List<StudyGroup> get groups => _groups;
  List<CampusEvent> get events => _events;
  bool get isLoading => _isLoading;

  /// Charge les groupes depuis Supabase.
  Future<void> loadGroups({String? filiere}) async {
    _isLoading = true;
    notifyListeners();

    // TODO: Remplacer par un appel Supabase réel
    // _groups = response.map(StudyGroup.fromJson).toList();

    _isLoading = false;
    notifyListeners();
  }

  /// Charge les événements à venir.
  Future<void> loadEvents() async {
    _isLoading = true;
    notifyListeners();

    // TODO: Remplacer par un appel Supabase réel
    // _events = response.map(CampusEvent.fromJson).toList();

    _isLoading = false;
    notifyListeners();
  }

  /// Rejoindre un groupe.
  Future<void> joinGroup(String groupId) async {
    // TODO: Appel Supabase pour insérer dans group_members
    notifyListeners();
  }

  /// Quitter un groupe.
  Future<void> leaveGroup(String groupId) async {
    // TODO: Appel Supabase pour supprimer de group_members
    notifyListeners();
  }
}
