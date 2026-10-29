// Memory-only presentation data. Never an authorization, persistence or
// member-data adapter; every resumed UI still needs fresh owner admission.
import 'package:flutter/material.dart';

import 'zyra_browse_filter.dart';
import 'zyra_view_request_draft_model.dart';

/// Measures the first real background departure, not the authorization wait.
/// Inactive-only system sheets do not start the reset interval.
class ZyraPreviewAwayWindow {
  ZyraPreviewAwayWindow({Duration Function()? elapsed}) {
    _elapsed =
        elapsed ??
        (() => Duration(
          microseconds: DateTime.now().toUtc().microsecondsSinceEpoch,
        ));
  }
  static const resetAfter = Duration(minutes: 15);
  late final Duration Function() _elapsed;
  Duration? _backgroundAt;
  bool _finished = true;
  bool _restore = true;

  void inactive() {
    _finished = false;
  }

  void background() {
    _backgroundAt ??= _elapsed();
    _finished = false;
  }

  bool resume() {
    if (_finished) return _restore;
    final start = _backgroundAt;
    final away = start == null ? Duration.zero : _elapsed() - start;
    _restore = !away.isNegative && away < resetAfter;
    _backgroundAt = null;
    _finished = true;
    return _restore;
  }
}

/// A detached fixed-fixture checkpoint. No text drafts, photos/URLs, widgets,
/// controllers, callbacks, pending operations or real disclosure grants.
class ZyraPreviewNavigationCheckpoint {
  ZyraPreviewNavigationCheckpoint({
    required this.guardian,
    required this.model,
    required this.tab,
    required Iterable<String> pages,
    this.personId,
    this.requestsTab = 0,
    this.guardianPage = 0,
    this.networkTab = 0,
    this.guardianJourneyId,
    this.browseId,
    this.browseFilter = const ZyraBrowseFilter(),
    Iterable<String> browseHistory = const [],
    this.browseCursor = -1,
    Map<String, int> photoIndices = const {},
    Map<String, int> galleryIndices = const {},
    Map<String, double> positions = const {},
    this.scrollOffset = 0,
    this.mainGuardianId = 'draft-guardian-hassan',
    Iterable<String> removedGuardians = const [],
    Map<String, bool> guardianHistory = const {},
    Iterable<String> networkSent = const [],
    this.seekerMembership = 'Seeker One',
    this.guardianMembership = 'Guardian One',
    this.compatibilityBalance,
    this.compatibilityRevealed = false,
    this.accountDestination,
    this.settingsDetail,
  }) : pages = List.unmodifiable(pages.take(8)),
       browseHistory = List.unmodifiable(browseHistory.take(11)),
       photoIndices = Map.unmodifiable(
         Map.fromEntries(photoIndices.entries.take(64)),
       ),
       galleryIndices = Map.unmodifiable(
         Map.fromEntries(galleryIndices.entries.take(64)),
       ),
       positions = Map.unmodifiable(
         Map.fromEntries(positions.entries.take(64)),
       ),
       removedGuardians = Set.unmodifiable(removedGuardians.take(64)),
       guardianHistory = Map.unmodifiable(
         Map.fromEntries(guardianHistory.entries.take(64)),
       ),
       networkSent = Set.unmodifiable(networkSent.take(64));

  final bool guardian;
  final ViewRequestDraftSnapshot model;
  final int tab, requestsTab, guardianPage, networkTab;
  final List<String> pages, browseHistory;
  final String? personId, guardianJourneyId, browseId;
  final ZyraBrowseFilter browseFilter;
  final int browseCursor;
  // Actual photo ordinals for the standalone full-profile viewer.
  final Map<String, int> photoIndices;
  // Bounded card pages: details at zero, then actual photo ordinals plus one.
  final Map<String, int> galleryIndices;
  final Map<String, double> positions;
  final double scrollOffset;
  final String mainGuardianId, seekerMembership, guardianMembership;
  final Set<String> removedGuardians, networkSent;
  final Map<String, bool> guardianHistory;
  final int? compatibilityBalance;
  final bool compatibilityRevealed;

  // Detached informational subject IDs only. The fresh shell validates the
  // role and parent chain; these never carry an action, editor or permission.
  final String? accountDestination, settingsDetail;
}

/// Scroll-position storage accepts only finite scalar offsets and primitive
/// PageStorage keys. It never keeps an Element/controller or arbitrary data.
/// Each fresh shell owns a NEW bucket and a NEW guard; only its immutable
/// numeric snapshot may leave the shell.
class ZyraPreviewPositionBucket extends PageStorageBucket {
  ZyraPreviewPositionBucket({
    required this.canWrite,
    required this.onChanged,
    Map<String, double> initial = const {},
  }) {
    for (final entry in initial.entries.take(64)) {
      if (_validKey(entry.key) && _validOffset(entry.value)) {
        _positions[entry.key] = entry.value;
      }
    }
  }
  final bool Function() canWrite;
  final VoidCallback onChanged;
  final _positions = <String, double>{};
  Map<String, double> get snapshot => Map.unmodifiable(_positions);
  static bool _validKey(String key) => key.isNotEmpty && key.length <= 512;
  static bool _validOffset(double value) =>
      value.isFinite && value >= 0 && value <= 1000000;

  String? _key(BuildContext context, Object? identifier) {
    if (identifier != null) {
      return identifier is String && _validKey(identifier)
          ? 'id:$identifier'
          : null;
    }
    final keys = <String>[];
    bool visit(Element element) {
      final key = element.widget.key;
      if (key is PageStorageKey) {
        final value = key.value;
        if (value is! String && value is! int) return false;
        keys.add('${value.runtimeType}:$value');
      }
      return keys.length < 8 && element.widget is! PageStorage;
    }

    visit(context as Element);
    context.visitAncestorElements(visit);
    final key = keys.reversed.join('/');
    return _validKey(key) ? key : null;
  }

  @override
  dynamic readState(BuildContext context, {Object? identifier}) {
    final key = _key(context, identifier);
    return key == null ? null : _positions[key];
  }

  @override
  void writeState(BuildContext context, dynamic data, {Object? identifier}) {
    if (!canWrite() || data is! double || !_validOffset(data)) return;
    final key = _key(context, identifier);
    if (key == null ||
        (_positions.length >= 64 && !_positions.containsKey(key))) {
      return;
    }
    if (_positions[key] == data) return;
    _positions[key] = data;
    onChanged();
  }
}
