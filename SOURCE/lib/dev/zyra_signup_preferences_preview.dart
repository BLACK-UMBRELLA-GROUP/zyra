// LOCK 34 setup wrapper. The existing preference editor owns its questions;
// this caller-owned surface keeps the continuation bar above every child.
import 'package:flutter/material.dart';

import '../screens/profile/compatibility_editors.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_developer_title.dart';
import '../widgets/zyra_tap_feedback.dart';
import 'zyra_preview_navigation_checkpoint.dart';

class ZyraSignupPreferencesPreview extends StatefulWidget {
  const ZyraSignupPreferencesPreview({
    super.key,
    required this.initialDraft,
    required this.canAct,
    required this.canRetain,
    required this.onChanged,
    required this.onNext,
    required this.onLater,
    required this.onBack,
    this.bridge,
  });

  final ZyraCompatibilityDraft initialDraft;
  final bool Function() canAct, canRetain;
  final ValueChanged<ZyraCompatibilityDraft> onChanged;
  final VoidCallback onNext, onLater, onBack;
  final ZyraDeveloperPreviewBridge? bridge;

  @override
  State<ZyraSignupPreferencesPreview> createState() =>
      _ZyraSignupPreferencesPreviewState();
}

class _ZyraSignupPreferencesPreviewState
    extends State<ZyraSignupPreferencesPreview> {
  late final _opening = widget;
  late final _initial = widget.initialDraft.copy();
  late ZyraCompatibilityDraft _draft = _initial.copy();
  final _navigator = GlobalKey<NavigatorState>();

  bool get _current => mounted && _opening.canAct();
  bool get _retained => mounted && _opening.canRetain();
  bool _canAct() => _current;
  bool _canRetain() => _retained;
  void _return(ZyraCompatibilityDraft? _) {
    if (_current) _opening.onBack();
  }

  void _changed(ZyraCompatibilityDraft draft) {
    if (!_current) return;
    final copy = draft.copy();
    setState(() => _draft = copy);
    _opening.onChanged(copy.copy());
  }

  Future<bool> _persist(ZyraCompatibilityDraft draft) async {
    if (!_current) return false;
    _changed(draft);
    return _current;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final readable =
          box.maxWidth < 360 ||
          MediaQuery.textScalerOf(context).scale(12) > 15.6;
      if (readable) {
        return Column(
          children: [
            Expanded(child: _editor()),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: _bar(stacked: true),
            ),
          ],
        );
      }
      return Stack(
        children: [
          Positioned.fill(child: _editor()),
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: _bar(stacked: false),
          ),
        ],
      );
    },
  );

  Widget _editor() => ZyraDeveloperOwnedNavigatorScope(
    bridge: _opening.bridge,
    navigatorKey: _navigator,
    canPresent: _canAct,
    child: Navigator(
      key: _navigator,
      observers: [ZyraPreviewRouteObserver()],
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (_) => CompatibilityEditorScreen.preview(
          kind: CompatibilityEditorKind.trafficLights,
          initialDraft: _initial,
          canAct: _canAct,
          canRetain: _canRetain,
          canActChanges: _opening.bridge,
          preferenceSetup: true,
          onPreferenceChanged: _changed,
          onPersist: _persist,
          onPreviewReturn: _return,
        ),
      ),
    ),
  );

  Widget _bar({required bool stacked}) {
    final progress = Text(
      'Setting up · Partner preferences\n'
      '${_draft.preferenceAnswerCount}/${_draft.preferenceOptionCount} answered',
      key: const ValueKey('signup_preference_progress'),
      style: ZyraText.body(size: 12, color: ZyraColors.ivoryTop),
    );
    final later = TextButton(
      key: const ValueKey('signup_preferences_later'),
      onPressed: ZyraTapFeedback.onTap(context, () {
        if (_current) _opening.onLater();
      }),
      style: TextButton.styleFrom(
        foregroundColor: ZyraColors.goldText,
        textStyle: ZyraText.button(size: 11),
      ),
      child: const Text('Finish later'),
    );
    final next = FilledButton(
      key: const ValueKey('signup_preferences_next'),
      onPressed: ZyraTapFeedback.onTap(context, () {
        if (_current) _opening.onNext();
      }),
      style: FilledButton.styleFrom(
        minimumSize: const Size(44, 40),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        backgroundColor: ZyraColors.actionFill,
        foregroundColor: ZyraColors.onAction,
        textStyle: ZyraText.button(size: 12),
      ),
      child: const Text('Next ›'),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ZyraColors.espresso,
        borderRadius: BorderRadius.circular(30),
        boxShadow: ZyraColors.cardShadows,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        child: stacked
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  progress,
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: later),
                      Expanded(child: next),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(child: progress),
                  later,
                  next,
                ],
              ),
      ),
    );
  }
}
