import 'package:flutter/foundation.dart';

/// The three real top-level sections owned by Connections.
enum ZyraConnectionsSection {
  journeys(0),
  activity(1),
  introductions(2);

  final int page;
  const ZyraConnectionsSection(this.page);

  static ZyraConnectionsSection fromPage(int page) => switch (page) {
    1 => ZyraConnectionsSection.activity,
    2 => ZyraConnectionsSection.introductions,
    _ => ZyraConnectionsSection.journeys,
  };
}

/// Shared shell-to-page navigation intent for the kept-alive Connections tab.
///
/// The tab lives in an IndexedStack, so merely selecting tab 1 preserves the
/// last Journeys/Activity/Introductions page. Dashboard uses [open] before it
/// selects Connections; the mounted page then moves to the requested section.
class ZyraConnectionsSectionController extends ChangeNotifier {
  ZyraConnectionsSection _section;
  int _collapseRevision = 0;

  ZyraConnectionsSectionController({
    ZyraConnectionsSection initialSection = ZyraConnectionsSection.journeys,
  }) : _section = initialSection;

  ZyraConnectionsSection get section => _section;
  int get collapseRevision => _collapseRevision;

  /// External navigation request. It deliberately notifies even when the
  /// value matches so a caller can restore a section after state restoration.
  void open(ZyraConnectionsSection section) {
    _section = section;
    notifyListeners();
  }

  /// Records a user-driven swipe without asking the page to animate to itself.
  void synchroniseFromPage(ZyraConnectionsSection section) {
    _section = section;
  }

  /// Tells the kept-alive Connections screen to close any expanded person
  /// card. The revision is separate from [section] so selecting another app
  /// tab can clean the page without changing which Connections segment the
  /// person returns to.
  void collapseCards() {
    _collapseRevision++;
    notifyListeners();
  }
}

/// One open person card across Journeys, Activity and Introductions.
///
/// Cards keep their own animation and scroll mechanics, while this notifier
/// owns the only piece of shared truth: which stable card id may be open.
class ZyraConnectionsExpansionController extends ValueNotifier<String?> {
  ZyraConnectionsExpansionController() : super(null);

  void open(String cardId) => value = cardId;

  void close(String cardId) {
    if (value == cardId) value = null;
  }

  void collapseAll() => value = null;
}
