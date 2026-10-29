import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState, Supabase;

import '../../models/seeker_profile.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_account_state.dart';
import '../../services/zyra_internal_preview_client.dart';
import '../../services/zyra_photo_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_interaction_style.dart';
import '../../widgets/zyra_browse_designs.dart';
import '../../widgets/floating_nav_bar.dart';
import '../../widgets/zyra_profile_image.dart';
import '../../widgets/zyra_pull_down_back_scope.dart';

/// Read-only owner preview using the current bounded Portrait Browse card.
/// It never joins the feed or exposes a decision/action against oneself.
class MyProfilePreviewScreen extends StatefulWidget {
  const MyProfilePreviewScreen({super.key})
    : _preview = false,
      _profile = null,
      _canAct = null,
      _onBack = null,
      _hapticLevel = null;

  /// Public argument names intentionally initialize private preview fields.
  const MyProfilePreviewScreen.preview({
    super.key,
    required SeekerProfile profile,
    required bool Function() canAct,
    required VoidCallback onBack,
    ZyraHapticLevel? hapticLevel,
  }) : _preview = true,
       // ignore: prefer_initializing_formals
       _profile = profile,
       // ignore: prefer_initializing_formals
       _canAct = canAct,
       // ignore: prefer_initializing_formals
       _onBack = onBack,
       // ignore: prefer_initializing_formals
       _hapticLevel = hapticLevel;

  final bool _preview;
  final SeekerProfile? _profile;
  final bool Function()? _canAct;
  final VoidCallback? _onBack;
  final ZyraHapticLevel? _hapticLevel;

  @override
  State<MyProfilePreviewScreen> createState() => _MyProfilePreviewScreenState();
}

class _MyProfilePreviewScreenState extends State<MyProfilePreviewScreen> {
  late List<String> _photos;
  late final bool _previewMode;
  late final SeekerProfile? _previewProfile;
  late final bool Function()? _ownerGuard;
  late final VoidCallback? _onBack;
  late final (String?, int) _ordinaryOwner;
  late final (bool, String?) _sdkOwner;
  String? _initialAccessToken;
  StreamSubscription<AuthState>? _authSubscription;
  int _sdkGeneration = 0;
  ModalRoute<dynamic>? _ordinaryRoute;
  int _photoRequest = 0;
  bool _revoked = false;
  late final VoidCallback _returnAction = _returnToOwner;

  bool get _ordinaryOwnerCurrent =>
      mounted &&
      !_revoked &&
      !_previewMode &&
      !widget._preview &&
      _sdkGeneration == 0 &&
      _sdkOwner == _readSdkOwner() &&
      !ZyraAccountState.isSigningOut &&
      _ordinaryOwner == (ZyraAccountState.userId, ZyraAccountState.generation);

  (bool, String?) _readSdkOwner() {
    try {
      return (true, ZyraAuth.currentUser?.id);
    } catch (_) {
      // An unconfigured, local fixture is distinct from an initialized
      // signed-out SDK. Neither may later borrow a newly authenticated owner.
      return (false, null);
    }
  }

  void _watchSdkOwner() {
    _sdkOwner = _readSdkOwner();
    if (!_sdkOwner.$1) return;
    _initialAccessToken =
        Supabase.instance.client.auth.currentSession?.accessToken;
    _authSubscription = ZyraAuth.authStateChanges.listen(
      (state) {
        if (!mounted || _revoked) return;
        if (_sdkOwner != _readSdkOwner() ||
            state.event == AuthChangeEvent.signedIn ||
            state.event == AuthChangeEvent.signedOut ||
            state.event == AuthChangeEvent.passwordRecovery ||
            (state.event == AuthChangeEvent.initialSession &&
                state.session?.accessToken != _initialAccessToken)) {
          ++_sdkGeneration;
          _withdrawOrdinaryOwner();
        }
      },
      onError: (Object error, StackTrace stack) {
        ++_sdkGeneration;
        _withdrawOrdinaryOwner();
      },
    );
  }

  bool get _canAct {
    if (!mounted || _revoked || widget._preview != _previewMode) return false;
    if (!_previewMode) {
      if (_ordinaryOwnerCurrent) return true;
      _withdrawOrdinaryOwner();
      return false;
    }
    try {
      if (_ownerGuard?.call() != true || widget._canAct?.call() != true) {
        _withdrawPreviewOwner();
        return false;
      }
      return true;
    } catch (_) {
      _withdrawPreviewOwner();
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _previewMode = widget._preview;
    _ordinaryOwner = (ZyraAccountState.userId, ZyraAccountState.generation);
    _ownerGuard = widget._canAct;
    _onBack = widget._onBack;
    final p = widget._profile;
    _previewProfile = p == null
        ? null
        : SeekerProfile(
            id: p.id,
            firstName: p.firstName,
            surnameLine: p.surnameLine,
            age: p.age,
            city: p.city,
            gender: p.gender,
            photos: List<String>.unmodifiable(p.photos),
            publicNationality: p.publicNationality,
            publicEthnicity: p.publicEthnicity,
          );
    if (_previewMode) {
      _photos = _previewProfile!.photos;
      _revoked = _photos.any((photo) {
        if (photo.startsWith('data:image/') && photo.contains(';base64,')) {
          return false;
        }
        final uri = Uri.tryParse(photo);
        return !photo.startsWith('assets/') ||
            uri == null ||
            uri.hasScheme ||
            uri.hasAuthority ||
            uri.hasQuery ||
            uri.hasFragment ||
            photo.contains('..') ||
            photo.contains('\\');
      });
      return;
    }
    _photos = List<String>.of(AppState.instance.photos);
    AppState.instance.addListener(_ordinaryAccountChanged);
    _watchSdkOwner();
    if (_photos.isEmpty &&
        !ZyraInternalPreviewClient.isActive &&
        _sdkOwner.$2 != null) {
      _restoreOwnPhotos();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_previewMode) {
      _ordinaryRoute = ModalRoute.of(context);
      if (!_ordinaryOwnerCurrent) _withdrawOrdinaryOwner();
    }
  }

  void _ordinaryAccountChanged() {
    if (!_ordinaryOwnerCurrent) _withdrawOrdinaryOwner();
  }

  void _withdrawPreviewOwner() {
    if (!mounted || !_previewMode || _revoked) return;
    _revoked = true;
    _photos = const [];
    final binding = WidgetsBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      binding.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      binding.ensureVisualUpdate();
    } else {
      setState(() {});
    }
  }

  void _withdrawOrdinaryOwner() {
    if (!mounted || _previewMode || _revoked) return;
    _revoked = true;
    _authSubscription?.cancel();
    ++_photoRequest;
    _photos = const [];
    final binding = WidgetsBinding.instance;
    if (binding.schedulerPhase != SchedulerPhase.persistentCallbacks) {
      setState(() {});
    }
    // An independently covering page must remain untouched. Only remove
    // this obsolete preview, never pop whichever route is currently on top.
    binding.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = _ordinaryRoute;
      if (route != null && !route.isFirst && route.navigator != null) {
        route.navigator!.removeRoute(route);
      } else {
        setState(() {});
      }
    });
    binding.ensureVisualUpdate();
  }

  void _returnOrdinary() {
    if (!_canAct || !(_ordinaryRoute?.isCurrent ?? false)) return;
    Navigator.of(context).maybePop();
  }

  void _returnToOwner() {
    if (!_canAct || ModalRoute.of(context)?.isCurrent == false) return;
    if (_previewMode) {
      _onBack?.call();
    } else {
      _returnOrdinary();
    }
  }

  Widget _photo(
    BuildContext context,
    String photo, {
    required double width,
    required double height,
    required Alignment alignment,
  }) {
    if (!_canAct) return SizedBox(width: width, height: height);
    if (photo.isEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: _OwnProfileEmptyPhoto(
          gender: _previewMode
              ? _previewProfile?.gender
              : AppState.instance.gender,
        ),
      );
    }
    if (_previewMode && photo.startsWith('assets/')) {
      return Image.asset(
        photo,
        width: width,
        height: height,
        fit: BoxFit.cover,
        alignment: alignment,
        errorBuilder: (_, _, _) => SizedBox(
          width: width,
          height: height,
          child: _OwnProfileEmptyPhoto(gender: _previewProfile?.gender),
        ),
      );
    }
    return ZyraProfileImage(
      photo,
      width: width,
      height: height,
      alignment: alignment,
    );
  }

  Widget _browsePreview(SeekerProfile profile) {
    final page = ZyraPullDownBackScope(
      key: const ValueKey('concept_pull_down_back_scope'),
      routeIdentity: (
        'own-browse-preview',
        _ordinaryOwner,
        _previewProfile?.id,
      ),
      enabled: _canAct,
      inlineBackHeader: true,
      onBack: _returnAction,
      child: Stack(
        children: [
          ZyraBrowseDesigns(
            key: const ValueKey('my-profile-browse-preview'),
            profiles: [profile],
            selectedIndex: 0,
            design: ZyraOneJourneyBrowseDesign.portraitCard,
            photoBuilder: _photo,
            readOnlyPreview: true,
            hapticLevel: widget._hapticLevel,
          ),
          Positioned.fill(
            child: IgnorePointer(
              key: const ValueKey('own-profile-preview-inert-navigation'),
              child: ExcludeSemantics(
                child: ExcludeFocus(
                  child: Stack(
                    children: [
                      FloatingNavBar(
                        items: const [
                          FloatingNavItem(
                            icon: Icons.search,
                            label: 'Profiles',
                          ),
                          FloatingNavItem(
                            icon: Icons.route_outlined,
                            label: 'Journey',
                            useJourneyGlyph: true,
                          ),
                          FloatingNavItem(
                            icon: Icons.dashboard_outlined,
                            label: 'My ZYRA',
                          ),
                          FloatingNavItem(
                            icon: Icons.gpp_good_outlined,
                            label: 'Guardian',
                          ),
                          FloatingNavItem(
                            icon: Icons.person_outline,
                            label: 'Profile',
                          ),
                        ],
                        currentIndex: 0,
                        contentEdgeInset: 20,
                        hapticLevel: ZyraHapticLevel.off,
                        onTap: _ignorePreviewNavigation,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
        child: page,
      ),
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    if (!_previewMode) {
      AppState.instance.removeListener(_ordinaryAccountChanged);
    }
    _revoked = true;
    ++_photoRequest;
    _photos = const [];
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MyProfilePreviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_previewMode &&
        (!widget._preview || !identical(widget._onBack, _onBack))) {
      _revoked = true;
    } else if (!_previewMode && widget._preview) {
      _withdrawOrdinaryOwner();
    }
  }

  Future<void> _restoreOwnPhotos() async {
    if (!_ordinaryOwnerCurrent) return;
    final request = ++_photoRequest;
    final photos = await ZyraPhotoService.fetchOwnPhotos(
      expectedUserId: _sdkOwner.$2,
    );
    if (!_ordinaryOwnerCurrent || request != _photoRequest || photos.isEmpty) {
      return;
    }
    setState(() => _photos = photos);
  }

  int _age(AppState state) {
    if (state.age != null) return state.age!;
    final dob = state.dob;
    if (dob == null) return 0;
    final now = DateTime.now();
    var age = now.year - dob.year;
    final birthdayPassed =
        now.month > dob.month || (now.month == dob.month && now.day >= dob.day);
    if (!birthdayPassed) age -= 1;
    return age;
  }

  @override
  Widget build(BuildContext context) {
    if (widget._preview != _previewMode || !_canAct) {
      return const SizedBox.expand(
        key: ValueKey('my-profile-preview-unavailable'),
      );
    }
    if (_previewMode) {
      return _browsePreview(_previewProfile!);
    }
    final state = AppState.instance;
    final name = state.name?.trim();
    final profile = SeekerProfile(
      id: 'my-profile-preview',
      firstName: name == null || name.isEmpty ? 'Your Profile' : name,
      surnameLine: state.surnameLine,
      age: _age(state),
      city: state.location?.trim() ?? '',
      photos: List<String>.unmodifiable(_photos),
      gender: state.gender ?? '',
    );

    return _browsePreview(profile);
  }
}

// Display-only navigation: no owner, tab, notification or destination action.
void _ignorePreviewNavigation(int _) {}

class _OwnProfileEmptyPhoto extends StatelessWidget {
  const _OwnProfileEmptyPhoto({required this.gender});

  final String? gender;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(gradient: ZyraColors.genderGradient(gender)),
    child: Center(
      child: Icon(
        Icons.person_outline,
        size: 104,
        color: Colors.white.withValues(alpha: 0.16),
      ),
    ),
  );
}
