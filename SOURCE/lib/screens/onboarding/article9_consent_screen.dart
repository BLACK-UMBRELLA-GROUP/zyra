// Explicit consent for special-category data — Founder approved 2026-08-04.
//
// Sits between Chapter 2's location questions and its faith/background
// questions, because that is the last moment before the app asks for
// anything special-category. Consent has to come BEFORE the collection,
// not at the end of the chapter.
//
// WHAT MAKES THIS EXPLICIT CONSENT RATHER THAN A NOTICE
//
//   Specific    it names the exact categories, not "some personal data".
//   Informed    it says what they are used for and what other members see.
//   Unbundled   it is its own screen with its own decision, not a line in
//               a Terms checkbox.
//   Freely      declining is a REAL option that continues the flow. The
//   given       decline path is not a dead end and not a nag — if it were,
//               the consent would not be freely given and would not count.
//   Withdrawable  stated on screen, and Settings honours it.
//
// There is deliberately NO pre-ticked box and no styling that makes accept
// louder than decline beyond ordinary primary/secondary weighting.
//
// NOT LEGAL ADVICE. Wording is a draft. The Founder has confirmed a
// solicitor will review this text, the Privacy Policy, the Terms and the
// Compatibility Unlock flow before public launch. `kArticle9PolicyVersion`
// exists so that review can change the words without orphaning consent
// already recorded — bump it and prior consent stops counting.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../services/zyra_account_state.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_consent_service.dart';
import '../../services/zyra_developer_access.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';

class Article9ConsentScreen extends StatefulWidget {
  final ZyraBackgroundVariant background;

  /// A requested local rehearsal never records a real Article 9 decision.
  final bool devPreview;

  /// Called with true if consent was granted, false if declined.
  /// The caller decides what to skip — this screen does not navigate.
  final ValueChanged<bool> onDecision;

  const Article9ConsentScreen({
    super.key,
    required this.onDecision,
    this.background = ZyraBackgroundVariant.neutral,
    this.devPreview = false,
  });

  @override
  State<Article9ConsentScreen> createState() => _Article9ConsentScreenState();
}

class _Article9ConsentScreenState extends State<Article9ConsentScreen> {
  bool _busy = false;
  bool _revoked = false;
  late final String? _owner;
  late final int _generation;
  late final bool _previewMode;
  late final bool _previewAdmitted;
  StreamSubscription? _authSubscription;
  ModalRoute<dynamic>? _route;

  String? _currentOwner() {
    try {
      return ZyraAuth.currentUser?.id;
    } catch (_) {
      // An authorised local rehearsal need not create an Auth client.
      return null;
    }
  }

  bool get _current =>
      !_revoked &&
      !ZyraAccountState.isSigningOut &&
      _generation == ZyraAccountState.generation &&
      _owner == _currentOwner() &&
      _previewMode == widget.devPreview &&
      (_previewMode
          ? _previewAdmitted && ZyraDeveloperAccess.canUseDeveloperTools
          : _owner != null);

  bool get _canAct => mounted && _current && (_route?.isCurrent ?? true);

  @override
  void initState() {
    super.initState();
    _owner = _currentOwner();
    _generation = ZyraAccountState.generation;
    _previewMode = widget.devPreview;
    _previewAdmitted = _previewMode && ZyraDeveloperAccess.canUseDeveloperTools;
    AppState.instance.addListener(_changed);
    ZyraDeveloperAccess.authorizationChanges.addListener(_changed);
    try {
      _authSubscription = ZyraAuth.authStateChanges.listen(
        (_) => _changed(),
        onError: (Object _, StackTrace _) => _changed(force: true),
      );
    } catch (_) {
      if (!_previewMode) _revoked = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
    _changed();
  }

  @override
  void didUpdateWidget(covariant Article9ConsentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.devPreview != widget.devPreview) _changed(force: true);
  }

  void _changed({bool force = false}) {
    if (!mounted || _revoked || (!force && _current)) return;
    // A retained rendered choice belongs to one account lifetime. Changing
    // account or preview authority cannot silently retarget it to a new one.
    _revoked = true;
    _busy = false;
    final binding = WidgetsBinding.instance;
    if (binding.schedulerPhase != SchedulerPhase.persistentCallbacks) {
      setState(() {});
    }
    final route = _route;
    binding.addPostFrameCallback((_) {
      if (!mounted) return;
      if (route != null && !route.isFirst && route.isActive) {
        route.navigator?.removeRoute(route);
      } else {
        setState(() {});
      }
    });
    binding.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _revoked = true;
    AppState.instance.removeListener(_changed);
    ZyraDeveloperAccess.authorizationChanges.removeListener(_changed);
    _authSubscription?.cancel().ignore();
    super.dispose();
  }

  Future<void> _decide(bool granted) async {
    if (!_canAct || _busy) return;
    if (_previewMode) {
      _busy = true;
      try {
        if (_canAct) widget.onDecision(granted);
      } finally {
        _busy = false;
      }
      return;
    }
    setState(() => _busy = true);
    final ok = await ZyraConsentService.record(granted: granted);
    if (!mounted || !_current) return;
    setState(() => _busy = false);
    if (!_canAct) return;

    if (!ok) {
      // A consent we cannot evidence is a consent we do not have. Rather
      // than proceeding on an unrecorded "yes", say so and let them retry.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("We couldn't save your choice. Please try again."),
        ),
      );
      return;
    }
    widget.onDecision(granted);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ZyraDeveloperAccess.authorizationChanges,
    builder: (context, _) {
      if (widget.devPreview && !_current) {
        return Scaffold(
          key: const ValueKey('article9_preview_denied'),
          backgroundColor: ZyraColors.modalSheetSurface,
          body: const SizedBox.expand(),
        );
      }
      if (!_current) return const SizedBox.shrink();
      return _buildConsent(context);
    },
  );

  Widget _buildConsent(BuildContext context) => Scaffold(
    body: Container(
      constraints: const BoxConstraints.expand(),
      decoration: BoxDecoration(
        gradient: ZyraColors.backgroundFor(widget.background),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: ZyraColors.foreground.withValues(alpha: 0.6),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'YOUR PERMISSION',
                            style: ZyraText.chapterLabel(
                              color: ZyraColors.ink(0.70),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        kArticle9ConsentTitle,
                        style: ZyraText.heading(size: 26),
                      ),
                      SizedBox(height: 18),
                      Text(
                        kArticle9ConsentBody,
                        style: ZyraText.body(size: 15).copyWith(height: 1.55),
                      ),
                      SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: ZyraColors.iconButtonBg,
                          border: Border.all(
                            color: ZyraColors.iconButtonBorder,
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          kArticle9ConsentDeclineNote,
                          style: ZyraText.subtext(size: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Accept carries primary weight; decline is plainly
              // available and not buried. Making decline hard to find is
              // the single most common way consent stops being freely
              // given.
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _busy ? null : () => _decide(true),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: Text(
                    'I agree — use these answers to match me',
                    textAlign: TextAlign.center,
                    style: ZyraText.button(size: 14),
                  ),
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: _busy ? null : () => _decide(false),
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: Text(
                    'Skip these questions',
                    style: ZyraText.button(
                      size: 14,
                      color: ZyraColors.ink(0.70),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8),
              Center(
                child: Text(
                  'You can change this at any time in Settings.',
                  style: ZyraText.subtext(
                    size: 11.5,
                    color: ZyraColors.ink(0.54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
