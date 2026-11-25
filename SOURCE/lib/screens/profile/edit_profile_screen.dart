import '../../widgets/zyra_edit_profile_presentation.dart';
import '../../widgets/zyra_developer_title.dart';
// LOCK 45 Edit profile hub; retained Partner preferences owns its existing drafts.
import '../../widgets/zyra_tap_feedback.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState, Supabase;
import '../../dev/zyra_app_gold_preview.dart';

import '../../main.dart';
import '../../models/onboarding_question.dart';
import '../../services/zyra_account_state.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_internal_preview_client.dart';
import '../../services/zyra_onboarding_answers_service.dart';
import '../../services/zyra_seeker_details_service.dart';
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

abstract interface class ZyraPreferenceQuickCheckRepository {
  Future<ZyraVisiblePreferenceChecks> visiblePreferenceChecks(String userId);
  Future<ZyraSetupPreferenceLights?> loadSetupPreferenceLights(String userId);
  Future<void> confirmPreferenceLight(
    String userId,
    ZyraPreferenceOption option,
    TrafficLight light,
  );
}

class _ServerCompatibilityEditorRepository
    implements
        ZyraCompatibilityEditorRepository,
        ZyraPreferenceQuickCheckRepository {
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
  Future<bool> save(
    String userId,
    ZyraCompatibilityDraft draft, {
    CompatibilityEditorKind? kind,
  }) {
    final editsLights =
        kind == null || kind == CompatibilityEditorKind.trafficLights;
    final editsHardRequirements =
        editsLights || kind == CompatibilityEditorKind.hardRequirements;
    final editsAnswers = kind == null || !editsHardRequirements;
    return ZyraOnboardingAnswersService.syncAnswers(
      expectedUserId: userId,
      ch3Answers: editsAnswers ? draft.answers : null,
      ch4Preferences: editsLights ? draft.preferences : null,
      ch4HardRequirements: editsHardRequirements
          ? draft.hardRequirements
          : null,
      canonicalAmberOptions: draft.canonicalAmberOptions,
    );
  }

  @override
  Future<ZyraVisiblePreferenceChecks> visiblePreferenceChecks(String userId) =>
      ZyraOnboardingAnswersService.visiblePreferenceChecks(
        expectedUserId: userId,
      );

  @override
  Future<ZyraSetupPreferenceLights?> loadSetupPreferenceLights(
    String userId,
  ) async {
    final details = await ZyraSeekerDetailsService.fetchOwn(
      expectedUserId: userId,
      throwOnError: true,
    );
    if (details == null) return null;
    final sect = details.preferences['sect'];
    final matrix = sect is Map ? sect['matrix'] : null;
    final revert = details.preferences['revert'];
    TrafficLight? light(Object? value) => switch (value) {
      'green' => TrafficLight.green,
      'yellow' || 'amber' => TrafficLight.yellow,
      'red' => TrafficLight.red,
      _ => null,
    };
    return ZyraSetupPreferenceLights(
      otherSect: details.thirdSectKey,
      lights: {
        if (matrix is Map)
          for (final entry in matrix.entries)
            if (entry.key is String)
              if (light(entry.value) case final TrafficLight value)
                (
                  questionId: 'ch2.sect.matrix',
                  optionValue: entry.key as String,
                ): value,
        if (light(sect is Map ? sect['outside_flexibility'] : null)
            case final TrafficLight outside)
          (questionId: 'ch2.sect.outside_flexibility', optionValue: '*'):
              outside,
        if (light(revert is Map ? revert['flexibility'] : null)
            case final TrafficLight flexibility)
          (questionId: 'ch2.revert.flexibility', optionValue: '*'): flexibility,
      },
    );
  }

  @override
  Future<void> confirmPreferenceLight(
    String userId,
    ZyraPreferenceOption option,
    TrafficLight light,
  ) => ZyraOnboardingAnswersService.confirmPreferenceLight(
    expectedUserId: userId,
    option: option,
    light: light,
  );
}

class EditProfileScreen extends StatefulWidget {
  final ZyraCompatibilityEditorRepository? repository;
  final bool _preview;
  final bool Function()? _previewCanAct;
  final bool Function()? _previewCanRetain;
  final String? _previewGender;
  final int? _previewAge;

  /// Preview-only destination owned by the admitted caller. Ordinary Help
  /// navigation is not injectable and can never be a preview fallback.
  final VoidCallback? onSupport;
  final Widget Function(
    ZyraCompatibilityDraft draft,
    VoidCallback preferences,
    VoidCallback refresh,
  )?
  profileBuilder;
  final bool embedded;
  final bool openPreferenceQuickCheck;
  const EditProfileScreen({
    super.key,
    this.repository,
    this.openPreferenceQuickCheck = false,
  }) : _preview = false,
       _previewCanAct = null,
       _previewCanRetain = null,
       _previewGender = null,
       _previewAge = null,
       onSupport = null,
       profileBuilder = null,
       embedded = false;

  /// The existing editor with caller-owned local storage and account facts.
  /// This mode cannot fall through to a live repository or global AppState.
  const EditProfileScreen.preview({
    super.key,
    required ZyraCompatibilityEditorRepository this.repository,
    required bool Function() canAct,
    bool Function()? canRetain,
    required String? gender,
    required int? age,
    this.onSupport,
    this.profileBuilder,
    this.embedded = true,
    this.openPreferenceQuickCheck = false,
  }) : _preview = true,
       _previewCanAct = canAct,
       _previewCanRetain = canRetain ?? canAct,
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
  late final bool Function()? _previewRetention;
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
  bool _openQuickCheckOnLoad = false;
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
          widget._previewCanRetain != _previewRetention ||
          widget._previewGender != _previewGender ||
          widget._previewAge != _previewAge ||
          widget.onSupport != _previewSupport ||
          _previewRetention?.call() != true ||
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
    if (_explicitPreview) {
      return _previewAvailable && _previewOwner?.call() == true;
    }
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
    _openQuickCheckOnLoad = widget.openPreferenceQuickCheck;
    _embeddedPreview = widget.embedded;
    _previewOwner = widget._previewCanAct;
    _previewRetention = widget._previewCanRetain;
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
    final available = _explicitPreview ? _previewAvailable : _canUse;
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
      if (_openQuickCheckOnLoad) {
        _openQuickCheckOnLoad = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _open(CompatibilityEditorKind.trafficLights, checkNow: true);
          }
        });
      }
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

  Future<bool> _persist(
    CompatibilityEditorKind kind,
    ZyraCompatibilityDraft candidate,
  ) async {
    if (_localPreview || !_canUse) return false;
    try {
      final repository = _repository;
      final draft = candidate.copy();
      final write = repository is _ServerCompatibilityEditorRepository
          ? repository.save(_owner!, draft, kind: kind)
          : repository.save(_owner!, draft);
      final saved = await write.timeout(const Duration(seconds: 10));
      return _canUse && saved;
    } catch (_) {
      return false;
    }
  }

  Future<void> _open(
    CompatibilityEditorKind kind, {
    bool checkNow = false,
  }) async {
    final draft = _draft;
    if (draft == null ||
        !_canUse ||
        !(ModalRoute.of(context)?.isCurrent ?? true)) {
      return;
    }
    bool canEdit() => _canUse;
    bool canRetain() => _previewAvailable;
    Future<bool> persist(ZyraCompatibilityDraft candidate) =>
        _persist(kind, candidate);
    ZyraPreferenceQuickCheck? quickCheck;
    final repository = _repository;
    final userId = _owner;
    if (kind == CompatibilityEditorKind.trafficLights &&
        repository is ZyraPreferenceQuickCheckRepository &&
        userId != null) {
      final checkRepository = repository as ZyraPreferenceQuickCheckRepository;
      try {
        final checks = await checkRepository
            .visiblePreferenceChecks(userId)
            .timeout(const Duration(seconds: 10));
        final setup = await checkRepository
            .loadSetupPreferenceLights(userId)
            .timeout(const Duration(seconds: 10));
        quickCheck = ZyraPreferenceQuickCheck(
          items: checks.legacyAmber,
          missing: checks.missing,
          setup: setup,
          confirm: (option, light) async {
            if (!canEdit()) throw StateError('The profile account changed.');
            await checkRepository.confirmPreferenceLight(userId, option, light);
            if (!canEdit()) throw StateError('The profile account changed.');
          },
          onConfirmed: draft.applyConfirmedPreference,
        );
      } catch (_) {
        // The previous server can still serve the ordinary editor.
      }
      if (!mounted ||
          !_canUse ||
          !(ModalRoute.of(context)?.isCurrent ?? true)) {
        return;
      }
    }
    final updated = await Navigator.of(context).push<ZyraCompatibilityDraft>(
      MaterialPageRoute(
        builder: (_) => _explicitPreview
            ? CompatibilityEditorScreen.preview(
                kind: kind,
                initialDraft: draft,
                onPersist: persist,
                canAct: canEdit,
                canRetain: canRetain,
                canActChanges: _ownerChanges,
                quickCheck: quickCheck,
                openQuickCheck: checkNow,
              )
            : CompatibilityEditorScreen(
                kind: kind,
                initialDraft: draft,
                onPersist: persist,
                canAct: canEdit,
                canActChanges: _ownerChanges,
                quickCheck: quickCheck,
                openQuickCheck: checkNow,
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
        // LOCK45's full-page scroll owns the measured bottom reading margin.
        child: SafeArea(bottom: false, child: content),
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
        title: ZyraDeveloperTitle(
          child: Text('Edit profile', style: ZyraText.heading(size: 28)),
        ),
        centerTitle: false,
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

  Widget _content() {
    final draft = _draft;
    final VoidCallback? preferences = draft != null && _canUse
        ? () => _open(CompatibilityEditorKind.trafficLights)
        : null;
    if (draft != null && widget.profileBuilder != null) {
      return widget.profileBuilder!(
        draft,
        () {
          if (_canUse) _open(CompatibilityEditorKind.trafficLights);
        },
        () {
          if (_canUse) _load();
        },
      );
    }
    return ZyraEditProfilePresentation(
      showTitle: _explicitPreview,
      name: _explicitPreview
          ? '—'
          : [
              AppState.instance.name,
              AppState.instance.surnameLine,
            ].whereType<String>().join(' '),
      age: _age,
      gender: _gender == 'female'
          ? 'Female'
          : _gender == 'male'
          ? 'Male'
          : '—',
      photoCount: _explicitPreview ? 0 : AppState.instance.photos.length,
      about: '',
      location: _explicitPreview ? '—' : AppState.instance.location ?? '—',
      nationality: '—',
      ethnicity: '—',
      bioProgress: const ['0 of 4', '0 of 4', '0 of 4'],
      preferencesProgress:
          '${draft?.preferenceAnswerCount ?? 0} of ${draft?.preferenceOptionCount ?? 0}',
      onPreferences: preferences,
      onSupport: _supportCanAct ? _openSupport : null,
      leading: _loading
          ? const ZyraLoading()
          : _loadError == null
          ? null
          : Column(
              children: [
                Text(
                  _loadError!,
                  key: const ValueKey('edit_profile_load_error'),
                  style: ZyraText.body(size: 14),
                ),
                if (_currentOwner)
                  TextButton(
                    key: const ValueKey('edit_profile_restore_retry'),
                    onPressed: ZyraTapFeedback.onTap(context, () {
                      if (_canUse &&
                          (ModalRoute.of(context)?.isCurrent ?? false)) {
                        _load();
                      }
                    }),
                    child: Text('Try again', style: ZyraText.button(size: 14)),
                  ),
              ],
            ),
    );
  }
}
