// Browse — BROWSE_UX_SPEC_CURRENT_VERSION_V3.md + PROFILE DECISION
// SYSTEM/Summary.md. Current terminology (DR-ZYRA-099, 2026-07-25):
// 🔴 Pass (was: Decline — no record, no notification), 🟡 Save
// (private bookmark), 🟢 Consider (was: Like — Outgoing Potential;
// mutual Consider = Match event = Potential Journey created).
//
// Visual treatment (2026-07-18) adapted from the founder's old Lovable
// prototype (src/routes/home.tsx + AppShell.tsx GLASS_BTN) after his
// review request: full-bleed edge-to-edge photo (no card padding/
// rounding), tap left/right half to cycle multiple photos, a vertical
// dot indicator on the LEFT side that fades while holding the photo
// (matches their actual code — he recalled it as the right side, but
// their source has it on the left; went with the source), and real
// glassmorphism (backdrop blur, not just a flat tint) on a brief
// tinted glass "flash" confirmation on each decision.
//
// 2026-07-25, DR-ZYRA-099 (Founder decision, direct quote: "we will
// stick with swiping actions for cleaner UI"): the floating action
// button row is REMOVED. Primary actions are now swipe gestures on
// the card itself — swipe left = Consider, swipe right = Pass, swipe
// down = Save — with the card following the finger and flying off in
// the swipe direction on release past threshold, snapping back
// otherwise. Terminology renamed Decline→Pass, Like→Consider
// throughout this file's UI layer (enum, handler names, comments).
//
// NOT renamed: AppState's underlying `decline()`/`declined`/`like()`/
// `outgoingLikes` API — those are internal method/field names used
// elsewhere (e.g. profile_screen.dart's Connections counts) and were
// judged out of scope for tonight's UI-layer change; flagged in
// SEEKER NAVIGATION/Summary.md and OA-ZYRA-138 as a known, not-yet-
// closed doc/code terminology gap. This file calls the old method
// names (`AppState.instance.decline(...)`, `.like(...)`) from the new
// `_onPass`/`_onConsider` handlers.

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/seeker_profile.dart';
import '../../services/zyra_discovery_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/glass_icon_button.dart';
import '../subscription/upgrade_screen.dart';
import 'match_notification_screen.dart';

const int _dailyProfileLimit = 50;

// Swipe distance (px) past which a release commits to the action,
// rather than snapping back. Kept generous so accidental drags while
// viewing a photo don't misfire.
const double _swipeCommitThreshold = 120;

enum _Decision { pass, save, consider }

class BrowseScreen extends StatefulWidget {
  // Renamed from onNavigateToMatches 2026-07-26 (nav bar fix) — the
  // tab it jumps to is now Connections, not a standalone Matches tab.
  final VoidCallback? onNavigateToConnections;
  const BrowseScreen({super.key, this.onNavigateToConnections});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  int _index = 0;
  int _viewed = 0;
  int _photoIndex = 0;
  bool _interacting = false;
  _Decision? _flash;

  // Swipe-gesture state (DR-ZYRA-099). _dragOffset is the card's live
  // visual offset while a finger is down; _dragStartGlobal anchors the
  // gesture so onPanUpdate can compute delta without accumulating
  // floating-point drift.
  Offset _dragOffset = Offset.zero;
  Offset? _dragStartGlobal;
  bool _dragCommitted = false;

  // Starts as mockProfiles so the screen renders immediately; replaced
  // by real candidates once ZyraDiscoveryService resolves (falls back
  // to mockProfiles itself if there's nothing real to show yet — see
  // that service's doc comment).
  List<SeekerProfile> _profiles = mockProfiles;

  @override
  void initState() {
    super.initState();
    ZyraDiscoveryService.fetchCandidates().then((list) {
      if (mounted) setState(() => _profiles = list);
    });
  }

  SeekerProfile? get _current => _index < _profiles.length ? _profiles[_index] : null;

  // OA-ZYRA-125 §5: the "0/50 Profiles" counter is hidden during normal
  // browsing entirely. This is the only place the limit surfaces — a
  // modal, shown once, right when it's reached.
  bool get _limitReached => _viewed >= _dailyProfileLimit;

  void _advance() {
    setState(() {
      _viewed++;
      _index++;
      _photoIndex = 0;
    });
    if (_viewed == _dailyProfileLimit) {
      // Fires once, exactly on the transition into the limit — not on
      // every subsequent action, which _onPass/_onSave/_onConsider guard
      // against separately below.
      Future.microtask(_showLimitReachedModal);
    }
  }

  Future<void> _showLimitReachedModal() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (dialogContext) => Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 36),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.22), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.hourglass_bottom, color: Colors.white, size: 30),
                  const SizedBox(height: 14),
                  Text("You've reached today's limit", style: ZyraText.heading(size: 18), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    "You've viewed $_dailyProfileLimit profiles today. New profiles unlock in 2h 30m, or upgrade to ZYRA One for unlimited browsing.",
                    style: ZyraText.subtext(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UpgradeScreen()));
                      },
                      child: const Text('Upgrade to ZYRA One'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text('Not now', style: ZyraText.subtext()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFlash(_Decision d) {
    setState(() => _flash = d);
    Timer(const Duration(milliseconds: 380), () {
      if (mounted) setState(() => _flash = null);
    });
  }

  void _onPass() {
    if (_limitReached) {
      _showLimitReachedModal();
      return;
    }
    final profile = _current;
    if (profile != null) AppState.instance.decline(profile);
    _showFlash(_Decision.pass);
    Timer(const Duration(milliseconds: 280), _advance);
  }

  void _onSave() {
    if (_limitReached) {
      _showLimitReachedModal();
      return;
    }
    final profile = _current;
    if (profile != null) {
      AppState.instance.save(profile);
      ZyraDiscoveryService.recordSave(profile.id);
    }
    _showFlash(_Decision.save);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved — kept private, no notification sent.'), duration: Duration(seconds: 1)),
    );
    Timer(const Duration(milliseconds: 280), _advance);
  }

  void _onConsider() {
    if (_limitReached) {
      _showLimitReachedModal();
      return;
    }
    final profile = _current;
    if (profile == null) return;
    final isMatch = AppState.instance.like(profile);
    ZyraDiscoveryService.recordLike(profile.id);
    _showFlash(_Decision.consider);
    Timer(const Duration(milliseconds: 280), () {
      if (isMatch) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MatchNotificationScreen(
              matchedWith: profile,
              onViewMatch: () {
                Navigator.of(context).pop();
                widget.onNavigateToConnections?.call();
              },
            ),
          ),
        );
      }
      _advance();
    });
  }

  void _tapPhoto(TapUpDetails details, double width) {
    final profile = _current;
    if (profile == null || profile.photos.length <= 1) return;
    final goRight = details.localPosition.dx > width / 2;
    setState(() {
      if (goRight) {
        _photoIndex = _photoIndex >= profile.photos.length - 1 ? 0 : _photoIndex + 1;
      } else {
        _photoIndex = _photoIndex <= 0 ? 0 : _photoIndex - 1;
      }
    });
  }

  // --- Swipe gesture handling (DR-ZYRA-099) ---------------------------

  void _onPanStart(DragStartDetails details) {
    _dragStartGlobal = details.globalPosition;
    _dragCommitted = false;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_dragStartGlobal == null) return;
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final dx = _dragOffset.dx;
    final dy = _dragOffset.dy;
    final horizontalDominant = dx.abs() > dy.abs();

    if (horizontalDominant && dx.abs() > _swipeCommitThreshold) {
      _commitSwipe(dx > 0 ? _Decision.pass : _Decision.consider);
    } else if (!horizontalDominant && dy > _swipeCommitThreshold) {
      _commitSwipe(_Decision.save);
    } else {
      // Below threshold — snap back to centre.
      setState(() => _dragOffset = Offset.zero);
    }
    _dragStartGlobal = null;
  }

  void _commitSwipe(_Decision decision) {
    if (_dragCommitted) return;
    _dragCommitted = true;
    // Fling the card the rest of the way off-screen in the swipe
    // direction, then run the matching action exactly as the old
    // button handlers did.
    final flingTarget = switch (decision) {
      _Decision.pass => const Offset(600, 0),
      _Decision.consider => const Offset(-600, 0),
      _Decision.save => const Offset(0, 900),
    };
    setState(() => _dragOffset = flingTarget);
    switch (decision) {
      case _Decision.pass:
        _onPass();
      case _Decision.save:
        _onSave();
      case _Decision.consider:
        _onConsider();
    }
    // Reset the drag offset once _advance() (called by the handlers
    // above, after their own short delay) has moved on to the next
    // profile, so the new card doesn't inherit the old one's fling
    // position.
    Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _dragOffset = Offset.zero);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = _current;
    // 2026-07-25, DR-ZYRA-101 audit item 1 (Founder decision: "switch
    // to gradient"): gender-matched gradient, not flat — Browse is
    // only ever reached by a signed-in, onboarded Seeker, so gender is
    // always known here, same as every other profile-context screen
    // fixed under DR-ZYRA-101 (ZyraColors.genderGradient()).
    return Container(
      decoration: BoxDecoration(gradient: ZyraColors.genderGradient(AppState.instance.gender)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed photo, edge to edge — no outer padding, no rounding.
          if (profile == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.white38, size: 32),
                    const SizedBox(height: 12),
                    Text('You\'re all caught up', style: ZyraText.heading(size: 18)),
                    const SizedBox(height: 6),
                    Text('More profiles will appear as new members join.', style: ZyraText.subtext(), textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) => GestureDetector(
                onTapUp: (d) => _tapPhoto(d, constraints.maxWidth),
                onLongPressStart: (_) => setState(() => _interacting = true),
                onLongPressEnd: (_) => setState(() => _interacting = false),
                // Swipe gestures (DR-ZYRA-099) — left = Consider, right =
                // Pass, down = Save. Coexists with the tap/long-press
                // recognisers above: a plain tap has no meaningful pan
                // delta, so onPanEnd's threshold check below simply does
                // nothing and the tap fires normally.
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: AnimatedContainer(
                  duration: _dragStartGlobal == null
                      ? const Duration(milliseconds: 260)
                      : Duration.zero,
                  curve: Curves.easeOut,
                  transform: Matrix4.identity()
                    ..translate(_dragOffset.dx, _dragOffset.dy)
                    ..rotateZ(_dragOffset.dx / 900),
                  transformAlignment: Alignment.center,
                  child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      profile.photos[_photoIndex],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF1A1220)),
                    ),
                    // Top gradient — status bar / glass button legibility.
                    Container(
                      alignment: Alignment.topCenter,
                      height: 130,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x66000000), Colors.transparent],
                        ),
                      ),
                    ),
                    // Bottom gradient — identity block legibility.
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 300,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0x40000000), Color(0xA6000000)],
                            stops: [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Left-side vertical photo dots (matches source: left, not right).
                    if (profile.photos.length > 1)
                      Positioned(
                        left: 16,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: AnimatedOpacity(
                            opacity: _interacting ? 0.35 : 1,
                            duration: const Duration(milliseconds: 200),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(profile.photos.length, (i) {
                                final active = i == _photoIndex;
                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 3),
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 0.5),
                                    color: active ? Colors.white : Colors.white.withOpacity(0.32),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                    // Identity block — bottom-left, large name/age/location.
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 130,
                      child: AnimatedOpacity(
                        opacity: _interacting ? 0.35 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.firstName,
                              style: ZyraText.heading(size: 30).copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text('${profile.age}', style: ZyraText.body(size: 17, color: Colors.white.withOpacity(0.95))),
                            const SizedBox(height: 4),
                            Text(profile.city, style: ZyraText.body(size: 14, color: Colors.white.withOpacity(0.9))),
                          ],
                        ),
                      ),
                    ),
                  ],
                  ),
                ),
              ),
            ),

          // OA-ZYRA-125 §5: the "X/50 profiles" counter chip that used to
          // sit here permanently is removed. The limit now only ever
          // surfaces as the modal in _showLimitReachedModal(), triggered
          // right when the limit is hit — see _advance() and the
          // _limitReached guards in _onPass/_onSave/_onConsider.

          // Decision flash — brief tinted glass confirmation, centred.
          if (_flash != null)
            Center(
              child: GlassFlashCircle(
                icon: switch (_flash!) {
                  _Decision.pass => Icons.close,
                  _Decision.save => Icons.bookmark,
                  _Decision.consider => Icons.favorite,
                },
                tint: switch (_flash!) {
                  _Decision.pass => const Color(0x52F47272),
                  _Decision.save => const Color(0x57EED26C),
                  _Decision.consider => const Color(0x5784C88E),
                },
              ),
            ),

          // 2026-07-25, DR-ZYRA-099: the floating glass action-button row
          // (Pass/Save/Consider buttons) is removed here per the Founder's
          // explicit "stick with swiping actions for cleaner UI" decision.
          // All three actions are now reachable only via the swipe
          // gestures wired into the GestureDetector above (_onPanEnd /
          // _commitSwipe) — see this file's header comment for the
          // full DR-ZYRA-099 rationale.
        ],
      ),
    );
  }
}
