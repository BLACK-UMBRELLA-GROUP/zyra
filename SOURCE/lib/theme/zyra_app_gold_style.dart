import 'package:flutter/foundation.dart';

/// LOCK 21 V2: the retired member Gold preference never affects the canvas.
class ZyraAppGoldStyle extends ChangeNotifier {
  ZyraAppGoldStyle._();

  static final instance = ZyraAppGoldStyle._();
  bool get enabled => false;
  int get revision => 0;

  // The old action has no effect, including when retained by an older view.
  bool select(
    bool value, {
    required int expectedGeneration,
    required int expectedRevision,
  }) => false;

  // Legacy persisted values are intentionally left intact and ignored.
  void restore(bool _) {}
  void restoreCurrent() {}
}
