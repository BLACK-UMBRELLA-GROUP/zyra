import '../../widgets/zyra_floating_surface.dart';
// Edit Profile — everything that changes what is ON your profile.
//
// NEW 2026-08-07. Founder: "in settings if the compatibility section is the
// same as edit profile then you gotta maybe move that section into edit
// profile part."
//
// It was. Settings had a COMPATIBILITY section — About you, Lifestyle,
// Marriage preferences, Green/Yellow/Red, Hard requirements — and Profile
// had an "Edit Profile" button pointing at nothing. Two routes to the same
// intention, one of which did not exist yet.
//
// This resolves it against the Founder's own principle, the one that moved
// Connections out of Settings in the first place: "Settings should
// configure the account, not become a duplicate navigation hub." Your sect,
// your lifestyle, what you are looking for in a marriage — none of those
// are account configuration. They are the profile.
//
// SO THE DIVISION IS NOW:
//   Profile → Edit Profile   what you look like to other people
//   Settings                 the account, privacy, notifications, support
//   Connections              relationships
//   Guardian page            Guardians
//
// which supersedes the line in settings_screen.dart's header giving
// compatibility to Settings.
//
// NOT INCLUDED YET, deliberately: name, About Me and location are all
// genuinely writable today (they hold column grants on profiles), so a
// Basics section belongs here and would work. It is not written because it
// was not asked for, and inventing a text editor inside a structural move
// is how a move becomes a rewrite. It is the obvious next piece.

import '../../widgets/zyra_tap_feedback.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState, Supabase;
import '../../dev/zyra_app_gold_preview.dart';

import '../../main.dart';
import '../../models/zyra_gender.dart';
import '../../services/zyra_account_state.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_internal_preview_client.dart';
import '../../services/zyra_onboarding_answers_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_loading.dart';
import '../../widgets/zyra_pull_down_back_scope.dart';
import '../settings/help_support_screen.dart';
import 'compatibility_editors.dart';

abstract interface class ZyraCompatibilityEditorRepository {
  String? get currentUserId;
  int get accountGeneration;
  bool isCurrentOwner(String userId, int generation);
  Future<ZyraOnboardingAnswersSnapshot?> load(String userId);
  Future<bool> save(String userId, ZyraCompatibilityDraft draft);
}

class _ServerCompatibilityEditorRepository
    implements ZyraCompatibilityEditorRepository {
  const _ServerCompatibilityEditorRepository();

  @override
  String? get currentUserId => supabaseReady ? ZyraAuth.currentUser?.id : null;
  @override
  int get accountGeneration => ZyraAccountState.generation;
  @override
  bool isCurrentOwner(String userId, int generation) =>
      supabaseReady &&
      !ZyraInternalPreviewClient.isActive &&
      ZyraAuth.currentUser?.id == userId &&
      ZyraAccountState.isCurrent(userId, generation);
  @override
  Future<ZyraOnboardingAnswersSnapshot?> load(String userId) =>
      ZyraOnboardingAnswersService.fetchOwn(
        expectedUserId: userId,
        throwOnError: true,
      );
  @override
  Future<bool> save(String userId, ZyraCompatibilityDraft draft) =>
      ZyraOnboardingAnswersService.syncAnswers(
        expectedUserId: userId,
        ch3Answers: draft.answers,
        ch4Preferences: draft.preferences,
        ch4HardRequirements: draft.hardRequirements,
      );
}

class EditProfileScreen extends StatefulWidget {
  final ZyraCompatibilityEditorRepository? repository;
  final bool _preview;
  final bool Function()? _previewCanAct;
  final String? _previewGender;
  final int? _previewAge;

  /// Preview-only destination owned by the admitted caller. Ordinary Help
  /// navigation is not injectable and can never be a preview fallback.
  final VoidCallback? onSupport;
  final bool embedded;
  const EditProfileScreen({super.key, this.repository})
    : _preview = false,
      _previewCanAct = null,
      _previewGender = null,
      _previewAge = null,
      onSupport = null,
      embedded = false;

  /// The existing editor with caller-owned local storage and account facts.
  /// This mode cannot fall through to a live repository or global AppState.
  const EditProfileScreen.preview({
    super.key,
    required ZyraCompatibilityEditorRepository this.repository,
    required bool Function() canAct,
    required String? gender,
    required int? age,
    this.onSupport,
    this.embedded = true,
  }) : _preview = true,
       _previewCanAct = canAct,
       _previewGender = gender,
       _previewAge = age;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  ZyraCompatibilityDraft? _draft;
  late final ZyraCompatibilityEditorRepository _repository;
  late final bool _localPreview;
  late final bool _explicitPreview;
  late final bool _embeddedPreview;
  late final bool Function()? _previewOwner;
  late final String? _previewGender;
  late final int? _previewAge;
  late final VoidCallback? _previewSupport;
  bool _supportRevoked = false;
  bool _previewRevoked = false;
  bool _ordinaryRevoked = false;
  late final ZyraCompatibilityEditorRepository? _suppliedRepository;
  late final (bool, String?) _openingSdk;
  late final (bool, int) _openingPreview;
  String? _initialAccessToken;
  StreamSubscription<AuthState>? _authSubscription;
  final ValueNotifier<int> _ownerChanges = ValueNotifier(0);
  int _loadEpoch = 0;
  String? _owner;
  int _ownerGeneration = 0;
  bool _loading = false;
  String? _loadError;

  bool get _currentOwner {
    try {
      return _owner != null &&
          _repository.isCurrentOwner(_owner!, _ownerGeneration);
    } catch (_) {
      if (_explicitPreview) _previewRevoked = true;
      return false;
    }
  }

  bool get _previewAvailable {
    if (!mounted || _previewRevoked) return false;
    try {
      if (!widget._preview ||
          widget.repository != _repository ||
          widget._previewCanAct != _previewOwner ||
          widget._previewGender != _previewGender ||
          widget._previewAge != _previewAge ||
          widget.onSupport != _previewSupport ||
          _previewOwner?.call() != true ||
          widget._previewCanAct?.call() != true ||
          !_currentOwner) {
        _previewRevoked = true;
        return false;
      }
    } catch (_) {
      _previewRevoked = true;
      return false;
    }
    return true;
  }

  (bool, String?) _sdkOwner() {
    try {
      return (true, ZyraAuth.currentUser?.id);
    } catch (_) {
      return (false, null);
    }
  }

  bool get _canUse {
    if (!mounted) return false;
    if (_explicitPreview) return _previewAvailable;
    if (_ordinaryRevoked) return false;
    final preview = (
      ZyraInternalPreviewClient.isActive,
      ZyraInternalPreviewClient.previewSession,
    );
    if (widget._preview ||
        !identical(widget.repository, _suppliedRepository) ||
        _sdkOwner() != _openingSdk ||
        preview != _openingPreview ||
        (!_localPreview && !_currentOwner)) {
      _ordinaryRevoked = true;
      return false;
    }
    return !_localPreview || ZyraInternalPreviewClient.isActive;
  }

  String? get _gender =>
      _explicitPreview ? _previewGender : AppState.instance.gender;
  int? get _age => _explicitPreview ? _previewAge : AppState.instance.age;

  @override
  void initState() {
    super.initState();
    _explicitPreview = widget._preview;
    _embeddedPreview = widget.embedded;
    _previewOwner = widget._previewCanAct;
    _previewGender = widget._previewGender;
    _previewAge = widget._previewAge;
    _previewSupport = widget.onSupport;
    _suppliedRepository = widget.repository;
    _repository =
        widget.repository ?? const _ServerCompatibilityEditorRepository();
    _localPreview = !_explicitPreview && ZyraInternalPreviewClient.isActive;
    _openingSdk = _sdkOwner();
    _openingPreview = (
      ZyraInternalPreviewClient.isActive,
      ZyraInternalPreviewClient.previewSession,
    );
    AppState.instance.addListener(_admissionChanged);
    ZyraInternalPreviewClient.changes.addListener(_admissionChanged);
    if (!_explicitPreview && _openingSdk.$1) {
      _initialAccessToken =
          Supabase.instance.client.auth.currentSession?.accessToken;
      _authSubscription = ZyraAuth.authStateChanges.listen(
        (state) {
          if (!mounted || _ordinaryRevoked) return;
          if (_sdkOwner() != _openingSdk ||
              (state.session != null &&
                  state.session!.user.id != _openingSdk.$2) ||
              state.event == AuthChangeEvent.signedIn ||
              state.event == AuthChangeEvent.signedOut ||
              state.event == AuthChangeEvent.passwordRecovery ||
              (state.event == AuthChangeEvent.initialSession &&
                  state.session?.accessToken != _initialAccessToken)) {
            _ordinaryRevoked = true;
          }
          _admissionChanged();
        },
        onError: (Object _, StackTrace _) {
          _ordinaryRevoked = true;
          _admissionChanged();
        },
      );
    }
    if (_localPreview) {
      // A sticky, unsaved local draft preserves the protected visual preview.
      // It never reads a member row or becomes a live editor after revocation.
      _draft = ZyraCompatibilityDraft.fromSnapshot(
        gender: AppState.instance.gender,
        snapshot: null,
      );
    } else {
      try {
        _owner = _repository.currentUserId;
        _ownerGeneration = _repository.accountGeneration;
        _load();
      } catch (_) {
        if (_explicitPreview) _previewRevoked = true;
        _loadError = 'Your sign-in has changed. Reopen Profile to continue.';
      }
    }
  }

  void _admissionChanged() {
    if (!mounted) return;
    final available = _canUse;
    if (!available) {
      ++_loadEpoch;
      _loading = false;
      _draft = null;
      _loadError = 'Your sign-in has changed. Reopen Profile to continue.';
    }
    // The parent remains covered while its editor/category/question routes
    // are active. Publish owner changes without requiring the parent's route
    // to become current, so each child can withdraw its own private copy.
    _ownerChanges.value++;
    if (available) return;
    final binding = WidgetsBinding.instance;
    if (binding.schedulerPhase != SchedulerPhase.persistentCallbacks) {
      setState(() {});
    } else {
      binding.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      binding.ensureVisualUpdate();
    }
  }

  @override
  void didUpdateWidget(covariant EditProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget._preview != _explicitPreview ||
        widget.onSupport != _previewSupport) {
      _supportRevoked = true;
    }
    if (_explicitPreview && !_previewAvailable) {
      ++_loadEpoch;
      _loading = false;
      _draft = null;
    }
    _admissionChanged();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_explicitPreview && !(ModalRoute.of(context)?.isCurrent ?? true)) {
      ++_loadEpoch;
      if (_loading) {
        _loadError = 'We couldn’t load your saved choices. Please try again.';
      }
      _loading = false;
    }
  }

  @override
  void dispose() {
    ++_loadEpoch;
    _ordinaryRevoked = true;
    _previewRevoked = true;
    AppState.instance.removeListener(_admissionChanged);
    ZyraInternalPreviewClient.changes.removeListener(_admissionChanged);
    _authSubscription?.cancel().ignore();
    _ownerChanges.value++;
    _ownerChanges.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted || _localPreview || _loading) return;
    final epoch = ++_loadEpoch;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      if (!_canUse) throw StateError('The profile account changed.');
      final snapshot = await _repository
          .load(_owner!)
          .timeout(const Duration(seconds: 10));
      if (!mounted || epoch != _loadEpoch) return;
      if (!_canUse) throw StateError('The profile account changed.');
      if (snapshot != null && !_explicitPreview) {
        AppState.instance.saveJourneyBio(snapshot.journeyBio);
      }
      setState(() {
        _draft = ZyraCompatibilityDraft.fromSnapshot(
          gender: _gender,
          snapshot: snapshot,
        );
        _loading = false;
      });
    } catch (_) {
      if (!mounted || epoch != _loadEpoch) return;
      setState(() {
        _loading = false;
        _draft = null;
        _loadError = _canUse
            ? 'We couldn’t load your saved choices. Please try again.'
            : 'Your sign-in has changed. Reopen Profile to continue.';
      });
    }
  }

  Future<bool> _persist(ZyraCompatibilityDraft candidate) async {
    if (_localPreview || !_canUse) return false;
    try {
      final saved = await _repository
          .save(_owner!, candidate.copy())
          .timeout(const Duration(seconds: 10));
      return _canUse && saved;
    } catch (_) {
      return false;
    }
  }

  Future<void> _open(CompatibilityEditorKind kind) async {
    final draft = _draft;
    if (draft == null ||
        !_canUse ||
        !(ModalRoute.of(context)?.isCurrent ?? true)) {
      return;
    }
    bool canEdit() => _canUse;
    final persist = _persist;
    final updated = await Navigator.of(context).push<ZyraCompatibilityDraft>(
      MaterialPageRoute(
        builder: (_) => _explicitPreview
            ? CompatibilityEditorScreen.preview(
                kind: kind,
                initialDraft: draft,
                onPersist: persist,
                canAct: canEdit,
                canActChanges: _ownerChanges,
              )
            : CompatibilityEditorScreen(
                kind: kind,
                initialDraft: draft,
                onPersist: persist,
                canAct: canEdit,
                canActChanges: _ownerChanges,
              ),
      ),
    );
    if (updated == null ||
        !mounted ||
        !_canUse ||
        !(ModalRoute.of(context)?.isCurrent ?? true)) {
      return;
    }
    setState(() => _draft = updated);
  }

  bool get _supportCanAct =>
      mounted &&
      (ModalRoute.of(context)?.isCurrent ?? false) &&
      !_localPreview &&
      !_supportRevoked &&
      widget._preview == _explicitPreview &&
      _canUse &&
      (!_explicitPreview || _previewSupport != null);

  Future<void> _openSupport() async {
    if (!_supportCanAct) return;
    if (_explicitPreview) {
      // The protected caller owns its local destination. Never fall through
      // to ordinary Help, account reports, contact actions or telemetry.
      _previewSupport?.call();
      return;
    }
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
  }

  @override
  Widget build(BuildContext context) {
    if (_explicitPreview && !_previewAvailable) {
      return const SizedBox.shrink(
        key: ValueKey('edit_profile_preview_denied'),
      );
    }
    if (_localPreview && !ZyraInternalPreviewClient.isActive) {
      return const Scaffold(
        key: ValueKey('edit_profile_preview_denied'),
        body: SizedBox.expand(),
      );
    }
    final content = _content();
    if (_explicitPreview) {
      final page = Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(
                  'Profile',
                  key: const ValueKey('edit_profile_preview_title'),
                  style: ZyraText.heading(size: 28),
                ),
              ),
              Expanded(child: content),
            ],
          ),
        ),
      );
      if (_embeddedPreview) return page;
      return ZyraPullDownBackScope(
        routeIdentity: this,
        onBack: () {
          if (_canUse &&
              (ModalRoute.of(context)?.isCurrent ?? true) &&
              Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: ZyraColors.genderGradient(_gender),
            ),
            child: page,
          ),
        ),
      );
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.of(context).canPop()
            ? BackButton(
                onPressed: ZyraTapFeedback.onTap(context, () {
                  if (_canUse &&
                      (ModalRoute.of(context)?.isCurrent ?? false) &&
                      Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                }),
              )
            : null,
        title: Text('Profile', style: ZyraText.heading(size: 17)),
        iconTheme: IconThemeData(color: ZyraColors.ink(0.70)),
      ),
      body: Container(
        decoration: ZyraAppGoldDecoration(
          gradient: ZyraColors.genderGradient(_gender),
        ),
        child: SafeArea(child: content),
      ),
    );
  }

  Widget _content() => ListView(
    key: const ValueKey('edit_profile_content_scroll'),
    physics: const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    ),
    padding: EdgeInsets.fromLTRB(20, 12, 20, _explicitPreview ? 24 : 90),
    children: [
      Text(
        'Your answers stay private. ZYRA uses them to calculate '
        'compatibility and honour your requirements.',
        style: ZyraText.subtext(size: 12.5, color: ZyraColors.ink(0.54)),
      ),
      SizedBox(height: 22),

      Text(
        'COMPATIBILITY',
        style: ZyraText.chapterLabel(color: ZyraColors.ink(0.54)),
      ),
      SizedBox(height: 10),
      if (_loadError != null) ...[
        Text(
          _loadError!,
          key: const ValueKey('edit_profile_load_error'),
          style: ZyraText.body(size: 14),
        ),
        if (_currentOwner)
          TextButton(
            key: const ValueKey('edit_profile_restore_retry'),
            onPressed: ZyraTapFeedback.onTap(context, () {
              if (_canUse && (ModalRoute.of(context)?.isCurrent ?? false)) {
                _load();
              }
            }),
            child: Text('Try again', style: ZyraText.button(size: 14)),
          ),
      ] else if (_loading)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 36),
          child: Center(child: ZyraLoading()),
        )
      else if (_draft != null && _canUse)
        for (final kind in CompatibilityEditorKind.values)
          _CompatibilityRow(
            key: ValueKey('compatibility-editor-${kind.name}'),
            kind: kind,
            status: _statusFor(kind, _draft!),
            onTap: () => _open(kind),
          ),

      SizedBox(height: 30),
      // Said HERE because this is where someone looks for it. A
      // person who wants to correct their birth year opens Edit
      // Profile, not Settings, and finding nothing is worse than
      // finding a plain explanation.
      Text('FIXED', style: ZyraText.chapterLabel(color: ZyraColors.ink(0.54))),
      SizedBox(height: 10),
      _FixedRow(
        label: 'Date of birth',
        value: _age == null ? '—' : 'Age $_age',
      ),
      _FixedRow(label: 'Gender', value: ZyraGender.profileLabel(_gender)),
      SizedBox(height: 10),
      Text(
        'Your date of birth and gender are saved with your account '
        'essentials and cannot be edited here. If either is wrong, '
        'contact Support.',
        style: ZyraText.subtext(size: 12, color: ZyraColors.ink(0.38)),
      ),
      if (_explicitPreview ? _previewSupport != null : !_localPreview) ...[
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const ValueKey('edit_profile_open_support'),
            onPressed: ZyraTapFeedback.onTap(
              context,
              _supportCanAct ? _openSupport : null,
            ),
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 48),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              foregroundColor: ZyraColors.foreground,
            ),
            icon: const Icon(Icons.help_outline_rounded, size: 20),
            label: Text(
              'Open Help & support',
              style: ZyraText.button(size: 13),
            ),
          ),
        ),
      ],
    ],
  );
}

class _CompatibilityRow extends StatelessWidget {
  const _CompatibilityRow({
    super.key,
    required this.kind,
    required this.status,
    required this.onTap,
  });

  final CompatibilityEditorKind kind;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${kind.label}. $status.',
    excludeSemantics: true,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: ZyraTapFeedback.onTap(context, onTap),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          child: Row(
            children: [
              ZyraFloatingSurface(
                radius: 18,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ZyraColors.surfaceFill,
                    border: Border.all(color: ZyraColors.surfaceBorder),
                  ),
                  child: Icon(kind.icon, size: 18, color: ZyraColors.ink(0.68)),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kind.label,
                      style: ZyraText.body(
                        size: 15,
                        color: ZyraColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(status, style: ZyraText.subtext(size: 11.5)),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 19,
                color: ZyraColors.ink(0.45),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _statusFor(CompatibilityEditorKind kind, ZyraCompatibilityDraft draft) =>
    switch (kind) {
      CompatibilityEditorKind.aboutYou ||
      CompatibilityEditorKind.lifestyle ||
      CompatibilityEditorKind.marriagePreferences => () {
        final categories = categoriesForKind(kind);
        return '${draft.answeredIn(categories)} of '
            '${draft.questionsIn(categories)} answered';
      }(),
      CompatibilityEditorKind.trafficLights =>
        '${draft.preferenceAnswerCount} of '
            '${draft.preferenceOptionCount} preferences set',
      CompatibilityEditorKind.hardRequirements =>
        draft.hardRequirementCount == 1
            ? '1 introduction-blocking answer'
            : '${draft.hardRequirementCount} introduction-blocking answers',
    };

class _FixedRow extends StatelessWidget {
  final String label;
  final String value;
  const _FixedRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 13),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: ZyraText.body(size: 15, color: ZyraColors.ink(0.54)),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: ZyraText.subtext(size: 13.5, color: ZyraColors.ink(0.65)),
          ),
        ),
        SizedBox(width: 8),
        Icon(Icons.lock_outline, size: 15, color: ZyraColors.ink(0.24)),
      ],
    ),
  );
}
