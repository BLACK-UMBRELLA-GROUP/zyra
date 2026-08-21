// ZYRA developer panel — rebuilt 2026-08-18.
//
// Permanent actions: OPEN a real app destination and RESET supported test
// state. Everything else is contextual to the page that is open. Developer
// results stay inside this panel instead of covering the product with bottom
// snackbars.
//
// Active Journey is deliberately not a preview count. Fake active cards have
// no server match and cannot walk the Journey. "Open live Journey" finds the
// account's real Journey or creates a seeded one, then opens it.

import 'dart:async';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';

import '../constants/zyra_plan_names.dart';
import '../data/zyra_entitlements.dart';
import '../main.dart' show supabase;
import '../models/zyra_error_state.dart';
import '../models/journey_match.dart';
import '../screens/auth_gate.dart';
import '../screens/browse/browse_screen.dart'
    show zyraBasicConsiderLimit, zyraBasicSaveLimit, zyraOneSaveLimit;
import '../screens/journey/journey_flow_screen.dart';
import '../services/zyra_auth.dart';
import '../services/zyra_guardian_suggestion_service.dart';
import '../services/zyra_journey_service.dart';
import '../services/zyra_unlock_service.dart';
import '../state/app_state.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_glass_dialog.dart';
import '../widgets/zyra_full_screen_error.dart';
import 'zyra_dev_signup.dart';
import 'zyra_dev_scenario.dart';

class DevScenarioPanelV2 extends StatefulWidget {
  final ValueChanged<DevPage> onOpenPage;

  const DevScenarioPanelV2({super.key, required this.onOpenPage});

  @override
  State<DevScenarioPanelV2> createState() => _DevScenarioPanelV2State();
}

class _DevScenarioPanelV2State extends State<DevScenarioPanelV2> {
  static const double _panelWidth = 310;
  static const double _tabWidth = 30;

  bool _open = false;
  bool _busy = false;
  String? _notice;
  bool _noticeError = false;
  int _guardianSuggestions = 0;
  int _guardiansOnDecided = 0;

  ZyraDevScenario get _scenario => ZyraDevScenario.instance;
  ZyraJourneyLimits get _limits => ZyraEntitlements.of(AppState.instance.plan);
  bool get _isOne => AppState.instance.plan == ZyraPlan.one;

  @override
  void initState() {
    super.initState();
    _scenario.migrateToCleanSeekerPanel();
    _scenario.addListener(_onStateChanged);
    AppState.instance.addListener(_onStateChanged);
    unawaited(_syncServerMirrors());
  }

  @override
  void dispose() {
    _scenario.removeListener(_onStateChanged);
    AppState.instance.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _showNotice(String message, {bool error = false}) {
    if (!mounted) return;
    setState(() {
      _notice = message;
      _noticeError = error;
    });
  }

  void _openPage(DevPage page) {
    setState(() {
      _open = false;
      _notice = null;
    });
    widget.onOpenPage(page);
  }

  Future<void> _goHome() async {
    setState(() {
      _open = false;
      _notice = null;
    });
    // Home means the public start of the app: sign out, replay the splash,
    // then show Welcome with Apple/Google sign-up and sign-in. Previously this
    // replayed the splash while keeping the session, so AuthGate routed the
    // operator straight back into the signed-in shell.
    try {
      await ZyraAuth.signOut();
    } catch (error) {
      debugPrint('ZYRA developer Home sign-out failed: $error');
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate(playSplash: true)),
      (route) => false,
    );
  }

  void _startSignUp({required bool isWali}) {
    setState(() {
      _open = false;
      _notice = null;
    });
    ZyraDevSignUp.start(context, isWali: isWali);
  }

  void _previewError(ZyraErrorKind kind) {
    setState(() {
      _open = false;
      _notice = null;
    });
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (previewContext) => ZyraFullScreenError(
          kind: kind,
          referenceCode: 'ZY-DEMO',
          // Preview actions return to the live account so testing an error
          // never signs the Founder out or discards the screen underneath.
          onPrimary: () => Navigator.of(previewContext).pop(),
          onSecondary: () => Navigator.of(previewContext).pop(),
        ),
      ),
    );
  }

  Future<void> _syncServerMirrors() async {
    try {
      final pending = await ZyraGuardianSuggestionService.fetchPending();
      if (mounted) {
        setState(() => _guardianSuggestions = pending.length.clamp(0, 5));
      }
    } catch (_) {}
    try {
      final res = await supabase.rpc('zyra_dev_guardians_on_decided');
      if (mounted) {
        setState(
          () => _guardiansOnDecided = ((res as num?)?.toInt() ?? 0).clamp(0, 3),
        );
      }
    } catch (_) {}
  }

  Future<void> _setMembership(bool one) async {
    final target = one ? ZyraPlan.one : ZyraPlan.basic;
    if (AppState.instance.plan == target || _busy) return;
    setState(() => _busy = true);
    try {
      await supabase.rpc(
        'zyra_dev_set_seeker_plan',
        params: {
          'p_plan': one
              ? ZyraSubscriptionPlanType.seekerPremium.dbValue
              : ZyraSubscriptionPlanType.seekerBasic.dbValue,
        },
      );
      AppState.instance.setPlan(target);
      _showNotice('${one ? 'ZYRA One' : 'ZYRA Basic'} is active.');
    } catch (error) {
      debugPrint('ZYRA dev membership failed — $error');
      _showNotice(
        '$error'.contains('dev_accounts_only')
            ? 'Membership switching is available only on seeded test accounts.'
            : 'Membership did not change. Check the console and try again.',
        error: true,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setGuardianSuggestions(int count) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _guardianSuggestions = count;
    });
    try {
      final res = await supabase.rpc(
        'zyra_dev_set_guardian_suggestions',
        params: {'p_count': count},
      );
      final created = ((res as Map?)?['created'] as num?)?.toInt() ?? 0;
      AppState.instance.bumpSuggestions();
      _showNotice(
        count == 0
            ? 'Test Introductions cleared.'
            : created == 0
            ? 'No eligible test profiles were available.'
            : '$created Introduction${created == 1 ? '' : 's'} ready in Connections.',
        error: count > 0 && created == 0,
      );
    } catch (error) {
      debugPrint('ZYRA dev Introductions failed — $error');
      await _syncServerMirrors();
      _showNotice(
        'Introductions did not change. Check the console and retry.',
        error: true,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setGuardiansOnDecided(int count) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _guardiansOnDecided = count;
    });
    try {
      final res = await supabase.rpc(
        'zyra_dev_set_guardians_on_decided',
        params: {'p_count': count},
      );
      final map = (res as Map?)?.cast<String, dynamic>();
      final targets = (map?['targets'] as num?)?.toInt() ?? 0;
      _showNotice(
        targets == 0
            ? 'Decide on a profile first, then return to this control.'
            : count == 0
            ? 'Test Guardians cleared from $targets profile${targets == 1 ? '' : 's'}.'
            : '$count Guardian${count == 1 ? '' : 's'} added to $targets decided profile${targets == 1 ? '' : 's'}.',
        error: targets == 0,
      );
    } catch (error) {
      debugPrint('ZYRA dev profile Guardians failed — $error');
      await _syncServerMirrors();
      _showNotice(
        'Guardian staging did not change. Check the console and retry.',
        error: true,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _grantCredits(UnlockTier tier, int count) async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await ZyraUnlockService.debugGrant(tier, count);
    if (!mounted) return;
    setState(() => _busy = false);
    _showNotice(
      ok
          ? '$count ${tier == UnlockTier.plus ? 'Unlock+' : 'Unlock'} credit${count == 1 ? '' : 's'} added.'
          : 'Credits were not added. Use a seeded test account.',
      error: !ok,
    );
  }

  void _showBrowsePopup(DevPopup popup) {
    setState(() {
      _open = false;
      _notice = null;
    });
    _scenario.requestPopup(popup);
  }

  Future<List<JourneyMatch>?> _liveJourneys() async {
    final rows = await ZyraJourneyService.fetchJourneyMatches(
      statuses: const ['active'],
    );
    return rows?.where((journey) => !journey.isMock).toList();
  }

  Future<void> _openLiveJourney() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _notice = 'Finding a live Journey…';
      _noticeError = false;
    });

    String? seedResult;
    try {
      var journeys = await _liveJourneys();
      if (journeys == null) {
        _showNotice(
          'Journeys could not be read. Check the connection.',
          error: true,
        );
        return;
      }
      var running = journeys.where((journey) => !journey.isSuspended).toList();
      if (running.isEmpty) {
        seedResult = await ZyraJourneyService.devSeedJourney();
        journeys = await _liveJourneys();
        if (journeys == null) {
          _showNotice(
            'The seeded Journey could not be read back.',
            error: true,
          );
          return;
        }
        running = journeys.where((journey) => !journey.isSuspended).toList();
      }

      final journey = running.isNotEmpty
          ? running.first
          : journeys.isNotEmpty
          ? journeys.first
          : null;
      if (journey == null) {
        _showNotice(
          seedResult ?? 'No live Journey is available for this test account.',
          error: true,
        );
        return;
      }

      _scenario.refreshJourneys();
      if (!mounted) return;
      setState(() {
        _open = false;
        _notice = null;
      });
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => JourneyFlowScreen(
            matchId: journey.matchId,
            profile: journey.profile,
          ),
        ),
      );
    } catch (error) {
      debugPrint('ZYRA dev open Journey failed — $error');
      _showNotice(
        'A live Journey could not be opened. Check the console.',
        error: true,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetEverything() async {
    if (_busy) return;
    final confirmed = await showZyraGlassChoice(
      context: context,
      icon: Icons.restart_alt,
      title: 'Reset developer state?',
      body:
          'Clears staged previews and supported test rows, returns '
          'membership to ZYRA Basic, and rewinds test Journeys to their '
          'first stage.\n\nYour profile, photos, consent, Chapter 2 answers, '
          'real Guardian links and Journey history are kept.',
      primaryLabel: 'Reset',
      secondaryLabel: 'Cancel',
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _busy = true;
      _notice = 'Resetting developer state…';
      _noticeError = false;
    });
    _scenario.reset();

    if (ZyraAuth.currentUser == null) {
      setState(() {
        _busy = false;
        _guardianSuggestions = 0;
        _guardiansOnDecided = 0;
      });
      _showNotice('Preview state cleared. No signed-in server state existed.');
      return;
    }

    final failures = <String>[];
    try {
      await supabase.rpc('zyra_dev_reset_account');
    } catch (error) {
      debugPrint('ZYRA dev reset account rows failed — $error');
      failures.add('account data');
    }
    try {
      await ZyraJourneyService.devRewindJourney();
    } catch (error) {
      debugPrint('ZYRA dev reset Journey failed — $error');
      failures.add('Journey rewind');
    }
    try {
      await supabase.rpc(
        'zyra_dev_set_guardian_suggestions',
        params: {'p_count': 0},
      );
      AppState.instance.bumpSuggestions();
    } catch (error) {
      debugPrint('ZYRA dev reset Introductions failed — $error');
      failures.add('Introductions');
    }
    try {
      await supabase.rpc(
        'zyra_dev_set_guardians_on_decided',
        params: {'p_count': 0},
      );
    } catch (error) {
      debugPrint('ZYRA dev reset Guardians failed — $error');
      failures.add('test Guardians');
    }
    try {
      await supabase.rpc(
        'zyra_dev_set_seeker_plan',
        params: {'p_plan': ZyraSubscriptionPlanType.seekerBasic.dbValue},
      );
      AppState.instance.setPlan(ZyraPlan.basic);
    } catch (error) {
      debugPrint('ZYRA dev reset membership failed — $error');
      failures.add('membership');
    }

    AppState.instance.clearDecisionsForReset();
    ZyraUnlockService.clearForSignOut();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _guardianSuggestions = 0;
      _guardiansOnDecided = 0;
    });
    _showNotice(
      failures.isEmpty
          ? 'Developer state reset.'
          : 'Reset finished, but ${failures.join(', ')} did not clear.',
      error: failures.isNotEmpty,
    );
  }

  List<Widget> _browseTools() => [
    const _SectionIntro(
      'Open the real ZYRA limit or advert experience. These are one-shot '
      'previews and do not leave a hidden switch behind.',
    ),
    _ToolAction(
      icon: Icons.bookmark_outline,
      title: 'Save limit',
      detail: 'Basic $zyraBasicSaveLimit · ZYRA One $zyraOneSaveLimit',
      onTap: () => _showBrowsePopup(DevPopup.saveLimit),
    ),
    if (!_isOne)
      _ToolAction(
        icon: Icons.favorite_border,
        title: 'Consider limit',
        detail: 'Basic $zyraBasicConsiderLimit · unlimited on ZYRA One',
        onTap: () => _showBrowsePopup(DevPopup.considerLimit),
      ),
    if (!_isOne)
      _ToolAction(
        icon: Icons.schedule,
        title: 'Browsing limit',
        detail: 'Show the real four-hour limit experience',
        onTap: () => _showBrowsePopup(DevPopup.dailyLimit),
      ),
    if (!_isOne)
      _ToolAction(
        icon: Icons.campaign_outlined,
        title: 'Sponsored card',
        detail: 'Show once on the next Browse card',
        onTap: () => _showBrowsePopup(DevPopup.sponsoredCard),
      ),
  ];

  List<Widget> _connectionsTools() => [
    const _Subheading('Journey lab'),
    _PrimaryToolAction(
      icon: Icons.route_outlined,
      label: _busy ? 'Working…' : 'Open live Journey',
      onTap: _busy ? null : _openLiveJourney,
    ),
    const _SectionIntro(
      'This opens a real server-backed Journey. Preview cards below are for '
      'Connections layouts only and never replace real rows.',
    ),
    const _Subheading('Preview cards'),
    _ToolCount(
      label: 'Potential',
      detail: 'Extra preview cards',
      value: _scenario.queuedJourneys,
      max: ZyraEntitlements.devMaxFor(_limits.potential),
      onChanged: _scenario.setQueuedJourneys,
    ),
    _ToolCount(
      label: 'Paused',
      detail: 'Extra preview cards',
      value: _scenario.pausedJourneys.clamp(0, _limits.paused),
      max: ZyraEntitlements.devMaxFor(_limits.paused),
      onChanged: _scenario.setPausedJourneys,
    ),
    if (_scenario.pausedJourneys > 0)
      _ToolSegment(
        label: 'First paused card',
        options: const ['Them', 'You', 'Both'],
        index: _scenario.pausePreviewOwner,
        onChanged: _scenario.setPausePreviewOwner,
      ),
    _ToolCount(
      label: 'Ended',
      detail: 'Extra preview cards',
      value: _scenario.endedJourneys.clamp(0, _limits.ended),
      max: ZyraEntitlements.devMaxFor(_limits.ended),
      onChanged: _scenario.setEndedJourneys,
    ),
    const _Subheading('Compatibility data'),
    _ToolGrant(
      label: 'Unlock credits',
      onGrant: (count) => _grantCredits(UnlockTier.standard, count),
    ),
    _ToolGrant(
      label: 'Unlock+ credits',
      onGrant: (count) => _grantCredits(UnlockTier.plus, count),
    ),
    _ToolCount(
      label: 'Guardians on decided profiles',
      detail: 'Real test rows · 0 clears',
      value: _guardiansOnDecided,
      max: 3,
      onChanged: _setGuardiansOnDecided,
    ),
    const _Subheading('Introductions'),
    _ToolCount(
      label: 'Test Introductions',
      detail: 'Real test rows · 0 clears',
      value: _guardianSuggestions,
      max: 5,
      onChanged: _setGuardianSuggestions,
    ),
  ];

  List<Widget> _guardianTools() => [
    const _SectionIntro(
      'Use preview data for visual states or Live to read this account’s '
      'real Guardian links.',
    ),
    _ToolSegment(
      label: 'Data source',
      options: const ['Preview', 'Live'],
      index: _scenario.useLiveGuardianData ? 1 : 0,
      onChanged: (index) => _scenario.setUseLiveGuardianData(index == 1),
    ),
    if (!_scenario.useLiveGuardianData) ...[
      _ToolSegment(
        label: 'Main Guardian',
        options: const ['None', 'Linked'],
        index: _scenario.mainGuardian ? 1 : 0,
        onChanged: (index) => _scenario.setMainGuardian(index == 1),
      ),
      _ToolCount(
        label: 'Additional Guardians',
        detail: 'Preview cards',
        value: _scenario.additionalGuardianCount,
        max: 5,
        onChanged: _scenario.setAdditionalGuardians,
      ),
      _ToolCount(
        label: 'Invitations received',
        detail: 'Preview only',
        value: _scenario.receivedInviteCount,
        max: 5,
        onChanged: _scenario.setReceivedInvites,
      ),
      _ToolCount(
        label: 'Pending invitations',
        detail: 'Preview cards',
        value: _scenario.pendingInviteCount,
        max: 5,
        onChanged: _scenario.setPendingInvites,
      ),
    ],
  ];

  List<Widget> _pageTools() => switch (_scenario.currentPage) {
    DevPage.browse => _browseTools(),
    DevPage.connections => _connectionsTools(),
    DevPage.guardian => _guardianTools(),
    DevPage.notifications => const [
      _SectionIntro(
        'No synthetic notification switch is retained. Test notifications '
        'come from real actions so badges and read state stay trustworthy.',
      ),
    ],
    DevPage.profile => const [
      _SectionIntro(
        'No fake Profile state is retained. Membership is available below; '
        'all other Profile flows use the real account.',
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) return const SizedBox.shrink();

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      top: 0,
      bottom: 0,
      right: _open ? 0 : -_panelWidth,
      width: _panelWidth + _tabWidth,
      child: Row(
        children: [
          _EdgeTab(open: _open, onTap: () => setState(() => _open = !_open)),
          Expanded(
            child: Material(
              color: const Color(0xFF151119),
              child: SafeArea(
                left: false,
                child: Column(
                  children: [
                    _PanelHeader(
                      page: _scenario.currentPage,
                      busy: _busy,
                      onReset: _busy ? null : _resetEverything,
                      onClose: () => setState(() => _open = false),
                    ),
                    const Divider(height: 1, color: Colors.white12),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
                        children: [
                          const _PanelHeading('Open'),
                          _DestinationGrid(
                            current: _scenario.currentPage,
                            onOpen: _openPage,
                          ),
                          const SizedBox(height: 18),
                          const _PanelHeading('Home'),
                          _ToolCard(
                            children: [
                              _ToolAction(
                                icon: Icons.home_outlined,
                                title: 'Open Home',
                                detail:
                                    'Replay the splash and restart app routing',
                                onTap: _goHome,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const _PanelHeading('Sign Up'),
                          _ToolCard(
                            children: [
                              const _SectionIntro(
                                'Run the real onboarding questions from a blank '
                                'mock state. Backing out returns to this account.',
                              ),
                              _ToolAction(
                                icon: Icons.person_add_alt_outlined,
                                title: 'Sign Up — Seeker',
                                detail: 'About You through Profile Ready',
                                onTap: () => _startSignUp(isWali: false),
                              ),
                              _ToolAction(
                                icon: Icons.family_restroom_outlined,
                                title: 'Sign Up — Guardian',
                                detail: 'Identity, relationship and invitation',
                                onTap: () => _startSignUp(isWali: true),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const _PanelHeading('Error pages'),
                          _ToolCard(
                            children: [
                              const _SectionIntro(
                                'Preview the real full-screen recovery states. '
                                'Either action returns to this live account.',
                              ),
                              _ToolAction(
                                icon: Icons.broken_image_outlined,
                                title: 'Page error',
                                detail: 'A screen could not be opened',
                                onTap: () => _previewError(ZyraErrorKind.page),
                              ),
                              _ToolAction(
                                icon: Icons.wifi_off_rounded,
                                title: 'Offline',
                                detail: 'The connection is unavailable',
                                onTap: () =>
                                    _previewError(ZyraErrorKind.offline),
                              ),
                              _ToolAction(
                                icon: Icons.cloud_off_outlined,
                                title: 'ZYRA unavailable',
                                detail:
                                    'The service is temporarily unavailable',
                                onTap: () => _previewError(
                                  ZyraErrorKind.serviceUnavailable,
                                ),
                              ),
                              _ToolAction(
                                icon: Icons.lock_clock_outlined,
                                title: 'Session expired',
                                detail: 'The member needs to sign in again',
                                onTap: () =>
                                    _previewError(ZyraErrorKind.sessionExpired),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          if (_notice != null) ...[
                            _InlineNotice(
                              message: _notice!,
                              error: _noticeError,
                              onDismiss: () => setState(() => _notice = null),
                            ),
                            const SizedBox(height: 14),
                          ],
                          _PanelHeading('${_scenario.currentPage.label} tools'),
                          _ToolCard(children: _pageTools()),
                          const SizedBox(height: 18),
                          const _PanelHeading('Account'),
                          _ToolCard(
                            children: [
                              _ToolSegment(
                                label: 'Membership',
                                options: const ['Basic', 'ZYRA One'],
                                index: _isOne ? 1 : 0,
                                onChanged: _busy
                                    ? null
                                    : (index) => _setMembership(index == 1),
                              ),
                              const _SectionIntro(
                                'Membership changes the client and the seeded '
                                'test account together.',
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Debug and profile builds only.',
                            textAlign: TextAlign.center,
                            style: ZyraText.subtext(
                              size: 10,
                              color: Colors.white24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Panel presentation -------------------------------------------------

class _PanelHeader extends StatelessWidget {
  final DevPage page;
  final bool busy;
  final VoidCallback? onReset;
  final VoidCallback onClose;

  const _PanelHeader({
    required this.page,
    required this.busy,
    required this.onReset,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ZYRA DEV',
                  style: ZyraText.chapterLabel(color: Colors.white54),
                ),
                const SizedBox(height: 2),
                Text(page.label, style: ZyraText.heading(size: 18)),
              ],
            ),
          ),
          TextButton(
            onPressed: onReset,
            child: Text(
              busy ? 'Working…' : 'Reset',
              style: ZyraText.subtext(
                size: 11.5,
                color: const Color(0xFFDF7D82),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Close developer tools',
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 18, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class _PanelHeading extends StatelessWidget {
  final String label;
  const _PanelHeading(this.label);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 2, bottom: 8),
    child: Text(
      label.toUpperCase(),
      style: ZyraText.chapterLabel(color: Colors.white38),
    ),
  );
}

class _DestinationGrid extends StatelessWidget {
  final DevPage current;
  final ValueChanged<DevPage> onOpen;
  const _DestinationGrid({required this.current, required this.onOpen});

  static const _items = [
    (DevPage.browse, Icons.search, 'Browse'),
    (DevPage.connections, Icons.bookmark_border, 'Connections'),
    (DevPage.guardian, Icons.gpp_good_outlined, 'Guardian'),
    (DevPage.notifications, Icons.notifications_none, 'Alerts'),
    (DevPage.profile, Icons.person_outline, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 7,
    runSpacing: 7,
    children: [
      for (final item in _items)
        _Destination(
          icon: item.$2,
          label: item.$3,
          selected: current == item.$1,
          onTap: () => onOpen(item.$1),
        ),
    ],
  );
}

class _Destination extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Destination({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 87,
    height: 54,
    child: Material(
      color: selected ? const Color(0xFF3A2D43) : const Color(0xFF211A26),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? Colors.white : Colors.white54,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ZyraText.subtext(
                size: 9.5,
                color: selected ? Colors.white : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ToolCard extends StatelessWidget {
  final List<Widget> children;
  const _ToolCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
    decoration: BoxDecoration(
      color: const Color(0xFF211A26),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white10, width: 0.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

class _SectionIntro extends StatelessWidget {
  final String text;
  const _SectionIntro(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: ZyraText.subtext(size: 10.5, color: Colors.white38),
    ),
  );
}

class _Subheading extends StatelessWidget {
  final String label;
  const _Subheading(this.label);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
    child: Row(
      children: [
        Text(
          label.toUpperCase(),
          style: ZyraText.subtext(size: 9.5, color: Colors.white38),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider(height: 1, color: Colors.white10)),
      ],
    ),
  );
}

class _ToolAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;
  const _ToolAction({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(9),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 17, color: Colors.white54),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ZyraText.body(size: 12.5)),
                Text(
                  detail,
                  style: ZyraText.subtext(size: 9.5, color: Colors.white38),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 17, color: Colors.white24),
        ],
      ),
    ),
  );
}

class _PrimaryToolAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _PrimaryToolAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: const Color(0xFF3A2D43),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: Colors.white),
              const SizedBox(width: 8),
              Text(label, style: ZyraText.button(size: 12.5)),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ToolCount extends StatelessWidget {
  final String label;
  final String detail;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;
  const _ToolCount({
    required this.label,
    required this.detail,
    required this.value,
    required this.max,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: ZyraText.body(size: 12)),
              Text(
                detail,
                style: ZyraText.subtext(size: 9.5, color: Colors.white38),
              ),
            ],
          ),
        ),
        _Stepper(value: value, max: max, onChanged: onChanged),
      ],
    ),
  );
}

class _ToolSegment extends StatelessWidget {
  final String label;
  final List<String> options;
  final int index;
  final ValueChanged<int>? onChanged;
  const _ToolSegment({
    required this.label,
    required this.options,
    required this.index,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ZyraText.body(size: 12)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              for (var i = 0; i < options.length; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: onChanged == null ? null : () => onChanged!(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: i == index
                            ? Colors.white.withValues(alpha: 0.17)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        options[i],
                        style: ZyraText.subtext(
                          size: 10.5,
                          color: Colors.white.withValues(
                            alpha: i == index ? 1 : 0.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ToolGrant extends StatelessWidget {
  final String label;
  final ValueChanged<int> onGrant;
  const _ToolGrant({required this.label, required this.onGrant});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Row(
      children: [
        Expanded(child: Text(label, style: ZyraText.body(size: 12))),
        _SmallButton(label: '+1', onTap: () => onGrant(1)),
        const SizedBox(width: 6),
        _SmallButton(label: '+5', onTap: () => onGrant(5)),
      ],
    ),
  );
}

class _SmallButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SmallButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(7),
    child: InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(label, style: ZyraText.button(size: 11.5)),
      ),
    ),
  );
}

class _Stepper extends StatefulWidget {
  final int value;
  final int max;
  final ValueChanged<int> onChanged;
  const _Stepper({
    required this.value,
    required this.max,
    required this.onChanged,
  });
  @override
  State<_Stepper> createState() => _StepperState();
}

class _StepperState extends State<_Stepper> {
  Timer? _repeat;
  @override
  void dispose() {
    _repeat?.cancel();
    super.dispose();
  }

  void _step(int amount) {
    final next = (widget.value + amount).clamp(0, widget.max);
    if (next != widget.value) widget.onChanged(next);
  }

  void _repeatStep(int amount) {
    _repeat?.cancel();
    _repeat = Timer.periodic(const Duration(milliseconds: 150), (_) {
      final next = (widget.value + amount).clamp(0, widget.max);
      if (next == widget.value) {
        _repeat?.cancel();
      } else {
        widget.onChanged(next);
      }
    });
  }

  Widget _button(IconData icon, int amount, bool enabled) => GestureDetector(
    onTap: enabled ? () => _step(amount) : null,
    onLongPressStart: enabled ? (_) => _repeatStep(amount) : null,
    onLongPressEnd: (_) => _repeat?.cancel(),
    onLongPressCancel: () => _repeat?.cancel(),
    child: SizedBox(
      width: 28,
      height: 30,
      child: Icon(
        icon,
        size: 15,
        color: Colors.white.withValues(alpha: enabled ? 0.75 : 0.18),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _button(Icons.remove, -1, widget.value > 0),
        SizedBox(
          width: 28,
          child: Text(
            '${widget.value}',
            textAlign: TextAlign.center,
            style: ZyraText.body(size: 12),
          ),
        ),
        _button(Icons.add, 1, widget.value < widget.max),
      ],
    ),
  );
}

class _InlineNotice extends StatelessWidget {
  final String message;
  final bool error;
  final VoidCallback onDismiss;
  const _InlineNotice({
    required this.message,
    required this.error,
    required this.onDismiss,
  });
  @override
  Widget build(BuildContext context) {
    final color = error ? const Color(0xFFDF7D82) : const Color(0xFF78C69D);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 4, 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: ZyraText.subtext(size: 10.5, color: Colors.white70),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onDismiss,
            icon: const Icon(Icons.close, size: 15, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}

class _EdgeTab extends StatelessWidget {
  final bool open;
  final VoidCallback onTap;
  const _EdgeTab({required this.open, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Center(
      child: Container(
        width: _DevScenarioPanelV2State._tabWidth,
        height: 86,
        decoration: BoxDecoration(
          color: const Color(0xFF151119),
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
          border: Border.all(color: Colors.white12, width: 0.5),
        ),
        child: RotatedBox(
          quarterTurns: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                open ? Icons.close : Icons.tune,
                size: 13,
                color: Colors.white60,
              ),
              const SizedBox(width: 5),
              Text(
                open ? 'CLOSE' : 'OPEN',
                style: ZyraText.subtext(size: 9, color: Colors.white60),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
