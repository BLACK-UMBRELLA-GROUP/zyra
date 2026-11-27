import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../data/zyra_entitlements.dart';
import '../data/zyra_membership_catalog.dart';
import '../data/zyra_journey_stages.dart';
import '../dev/zyra_concept_preview_boundary.dart';
import '../dev/zyra_preview_navigation_checkpoint.dart';
import '../dev/zyra_one_journey_concept_shell.dart';
import '../models/zyra_developer_preview.dart';
import '../models/zyra_error_state.dart';
import '../services/zyra_account_state.dart';
import '../services/zyra_app_lock.dart';
import '../services/zyra_developer_access.dart';
import '../state/app_state.dart';
import '../state/zyra_developer_samples.dart';
import '../theme/zyra_colors.dart';
import 'zyra_developer_panel.dart';
import 'zyra_full_screen_error.dart';

/// Explicit hook on an existing Seeker heading. Without panel authority
/// the heading is returned as-is, including its normal accessibility.
class ZyraDeveloperTitle extends StatefulWidget {
  const ZyraDeveloperTitle({
    super.key,
    required this.child,
    this.tab,
    this.enabled = true,
    this.hideWhenUnavailable = false,
    this.longPress = false,
  });

  final Widget child;
  final int? tab;
  final bool enabled;
  final bool hideWhenUnavailable;
  final bool longPress;

  @override
  State<ZyraDeveloperTitle> createState() => _ZyraDeveloperTitleState();
}

class _ZyraDeveloperTitleState extends State<ZyraDeveloperTitle> {
  int _revision = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _revision++;
  }

  @override
  void didUpdateWidget(covariant ZyraDeveloperTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tab != oldWidget.tab ||
        widget.enabled != oldWidget.enabled ||
        widget.longPress != oldWidget.longPress) {
      _revision++;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (context.findAncestorWidgetOfExactType<ZyraDeveloperTitle>() != null) {
      return widget.child;
    }
    final host = _DeveloperPanelScope.maybeOf(context);
    final tabScope = context
        .dependOnInheritedWidgetOfExactType<ZyraDeveloperSeekerTab>();
    final visibility = context
        .dependOnInheritedWidgetOfExactType<_DeveloperTitleVisibility>();
    final ownedNavigator = context
        .dependOnInheritedWidgetOfExactType<ZyraDeveloperOwnedNavigatorScope>();
    final route = ModalRoute.of(context);
    final revision = _revision;
    bool foreground() =>
        mounted &&
        revision == _revision &&
        visibility?.visible != false &&
        route?.isCurrent == true &&
        (widget.tab == null || tabScope?.isSelected(widget.tab!) == true);

    final child = widget.child;
    if (host == null) {
      return widget.hideWhenUnavailable ? const SizedBox.shrink() : child;
    }
    return ListenableBuilder(
      listenable: Listenable.merge([
        host.access,
        ?ownedNavigator?.bridge,
        ZyraPreviewRouteObserver.navigationChanges,
      ]),
      child: child,
      builder: (context, heading) {
        if ((!widget.enabled && !host._previewTitlesEnabled) ||
            !foreground() ||
            !host.availableOn(route!, ownedNavigator: ownedNavigator)) {
          return widget.hideWhenUnavailable
              ? const SizedBox.shrink()
              : heading!;
        }
        final proof = host.access.proofRevision;
        void openPanel() {
          if (host.access.proofRevision == proof) {
            unawaited(
              host.open(
                context,
                route,
                foreground,
                ownedNavigator: ownedNavigator,
              ),
            );
          }
        }

        return Semantics(
          button: true,
          child: GestureDetector(
            key: const ValueKey('dev_page_title'),
            behavior: HitTestBehavior.deferToChild,
            onTap: widget.longPress ? null : openPanel,
            onLongPress: widget.longPress ? openPanel : null,
            child: heading,
          ),
        );
      },
    );
  }
}

/// HomeShell supplies the live selection since IndexedStack retains inactive tabs.
class ZyraDeveloperSeekerTab extends InheritedWidget {
  const ZyraDeveloperSeekerTab({
    super.key,
    required this.selected,
    required this.isSelected,
    required super.child,
  });

  final int selected;
  final bool Function(int) isSelected;

  @override
  bool updateShouldNotify(ZyraDeveloperSeekerTab oldWidget) =>
      selected != oldWidget.selected;
}

/// Admission for a Navigator owned by the current local preview page.
/// The exact bridge/key and the parent foreground predicate must all match.
class ZyraDeveloperOwnedNavigatorScope extends InheritedWidget {
  const ZyraDeveloperOwnedNavigatorScope({
    super.key,
    required this.bridge,
    required this.navigatorKey,
    required this.canPresent,
    required super.child,
  });
  final ZyraDeveloperPreviewBridge? bridge;
  final GlobalKey<NavigatorState> navigatorKey;
  final bool Function() canPresent;

  bool admits(ZyraDeveloperPreviewBridge? owner, ModalRoute<dynamic> route) =>
      bridge != null &&
      identical(owner, bridge) &&
      bridge!.canPresent &&
      route.navigator == navigatorKey.currentState &&
      canPresent();

  @override
  bool updateShouldNotify(ZyraDeveloperOwnedNavigatorScope oldWidget) =>
      !identical(bridge, oldWidget.bridge) ||
      navigatorKey != oldWidget.navigatorKey ||
      !identical(canPresent, oldWidget.canPresent);
}

class _DeveloperTitleVisibility extends InheritedWidget {
  const _DeveloperTitleVisibility({
    required this.visible,
    required super.child,
  });
  final bool visible;
  @override
  bool updateShouldNotify(_DeveloperTitleVisibility oldWidget) =>
      visible != oldWidget.visible;
}

/// A local presentation bridge owned by one already-verified panel scope.
/// It never verifies an account or publishes legacy developer authority.
class ZyraDeveloperPreviewBridge extends ChangeNotifier {
  ZyraDeveloperPreviewBridge._(
    this._canPresent,
    this._access,
    this._viewAs,
    this._journeyPlaces,
    this._realPlanName,
  );

  final bool Function() _canPresent;
  final ZyraDeveloperPanelAccess? Function() _access;
  final ZyraDeveloperViewAs? Function() _viewAs;
  final int Function() _journeyPlaces;
  final String Function() _realPlanName;
  Object? _attachedOwner;
  VoidCallback? _samplesChanged;
  bool Function()? _canSendRequest;
  Future<void> Function(ZyraErrorKind)? _showError;
  Future<void> Function()? _continueSetup;
  Future<void> Function()? _startSignup;
  int _journeyNavigationEpoch = 0;
  int _noticeNavigationEpoch = 0, _presetSelectionEpoch = 0;
  int _selectionDepth = 0;
  bool _disposed = false, _notificationScheduled = false;

  bool get canPresent => !_disposed && _canPresent();
  bool get canSendRequest => canPresent && (_canSendRequest?.call() ?? true);
  ZyraDeveloperPanelAccess? get access => canPresent ? _access() : null;
  Object? get verifiedLifetime => access?.verifiedLifetime;
  ZyraDeveloperViewAs? get viewAs => canPresent ? _viewAs() : null;
  int get journeyPlaces => canPresent ? _journeyPlaces() : 0;
  String get realPlanName => _realPlanName();
  int get journeyNavigationEpoch => _journeyNavigationEpoch;
  int get noticeNavigationEpoch => _noticeNavigationEpoch;
  int get presetSelectionEpoch => _presetSelectionEpoch;
  bool get hasSetupContinuation => canPresent && _continueSetup != null;

  Future<void> startSignup() async {
    final action = _startSignup;
    if (canPresent && action != null) await action();
  }

  Future<void> continueSetup() async {
    final action = _continueSetup;
    if (canPresent && action != null) await action();
  }

  void attach({
    required Object owner,
    required VoidCallback samplesChanged,
    bool Function()? canSendRequest,
    required Future<void> Function(ZyraErrorKind) showError,
    Future<void> Function()? continueSetup,
    Future<void> Function()? startSignup,
  }) {
    if (_disposed) return;
    final changed =
        !identical(_attachedOwner, owner) ||
        (_continueSetup == null) != (continueSetup == null);
    _attachedOwner = owner;
    _samplesChanged = samplesChanged;
    _canSendRequest = canSendRequest;
    _showError = showError;
    _continueSetup = continueSetup;
    _startSignup = startSignup;
    if (changed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed && identical(_attachedOwner, owner)) _publish();
      });
      WidgetsBinding.instance.scheduleFrame();
    }
  }

  void detach(Object owner) {
    if (!identical(_attachedOwner, owner)) return;
    final hadContinuation = _continueSetup != null;
    _attachedOwner = null;
    _samplesChanged = null;
    _canSendRequest = () => false;
    _showError = null;
    _continueSetup = null;
    _startSignup = null;
    if (hadContinuation) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _publish());
      WidgetsBinding.instance.scheduleFrame();
    }
  }

  void _publish() {
    if (_disposed || _selectionDepth > 0) return;
    final binding = WidgetsBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      if (_notificationScheduled) return;
      _notificationScheduled = true;
      binding.addPostFrameCallback((_) {
        _notificationScheduled = false;
        _publish();
      });
      binding.scheduleFrame();
      return;
    }
    if (canPresent) _samplesChanged?.call();
    if (!_disposed) notifyListeners();
  }

  void _dispatchSelection(VoidCallback update) {
    ++_selectionDepth;
    try {
      update();
    } finally {
      --_selectionDepth;
      _publish();
    }
  }

  void _requestJourney(VoidCallback update) {
    if (!canPresent) return;
    ++_journeyNavigationEpoch;
    _dispatchSelection(update);
  }

  void _requestNotice(VoidCallback update) {
    if (!canPresent) return;
    ++_noticeNavigationEpoch;
    _dispatchSelection(update);
  }

  void _requestPreset(VoidCallback update) {
    if (!canPresent) return;
    ++_presetSelectionEpoch;
    _dispatchSelection(update);
  }

  @override
  void dispose() {
    _disposed = true;
    _attachedOwner = null;
    _samplesChanged = null;
    _showError = null;
    _continueSetup = null;
    _startSignup = null;
    super.dispose();
  }
}

class _DeveloperPreviewBridgeScope extends InheritedWidget {
  const _DeveloperPreviewBridgeScope({
    required this.bridge,
    required super.child,
  });

  final ZyraDeveloperPreviewBridge bridge;

  @override
  bool updateShouldNotify(_DeveloperPreviewBridgeScope oldWidget) =>
      !identical(oldWidget.bridge, bridge);
}

/// A stable authenticated route owner for ordinary and existing previews.
class ZyraDeveloperSeekerScope extends StatefulWidget {
  const ZyraDeveloperSeekerScope({
    super.key,
    required this.child,
    this.preview = false,
    this.initialTab,
  });

  final Widget child;
  final bool preview;
  final int? initialTab;

  static ZyraDeveloperPreviewBridge? bridgeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_DeveloperPreviewBridgeScope>()
      ?.bridge;

  @override
  State<ZyraDeveloperSeekerScope> createState() =>
      _ZyraDeveloperSeekerScopeState();
}

class _ZyraDeveloperSeekerScopeState extends State<ZyraDeveloperSeekerScope> {
  _ZyraDeveloperPanelHostState? _host;
  ModalRoute<dynamic>? _route;
  bool _registered = false;
  bool? _parentCurrent;
  Widget? _retainedPreview;
  late final _bridge = ZyraDeveloperPreviewBridge._(
    () => mounted && (_host?._canPresent(this) ?? false),
    () => _host?.access,
    () => _host?._viewAs(),
    () => _host?._places() ?? 0,
    () => _ZyraDeveloperPanelHostState._planName(),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final host = _DeveloperPanelScope.maybeOf(context);
    final route = ModalRoute.of(context);
    if (_parentCurrent != route?.isCurrent) {
      _parentCurrent = route?.isCurrent;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && identical(route, _route)) _bridge._publish();
      });
      WidgetsBinding.instance.scheduleFrame();
    }
    if (!identical(host, _host) || !identical(route, _route)) {
      _registered = false;
      _host = host;
      _route = route;
    }
    if (_registered || host == null || route?.isCurrent != true) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          !_registered &&
          identical(host, _host) &&
          identical(route, _route) &&
          route?.isCurrent == true) {
        _registered = true;
        host.register(this, route!);
      }
    });
  }

  @override
  void dispose() {
    _host?.unregister(this);
    _bridge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _DeveloperPreviewBridgeScope(
    bridge: _bridge,
    child: ListenableBuilder(
      listenable: _bridge,
      builder: (context, _) {
        final host = _host;
        final view = _bridge.viewAs;
        if (widget.preview) return widget.child;
        final show =
            host != null &&
            _bridge.canPresent &&
            view != null &&
            host._samples.hasSamples;
        bool currentPreview() =>
            mounted &&
            _bridge.canPresent &&
            _bridge.viewAs != null &&
            host?._samples.hasSamples == true;
        if (show) {
          _retainedPreview = KeyedSubtree(
            key: ValueKey((
              'developer-preview-lifetime',
              _bridge.verifiedLifetime,
            )),
            child: ZyraConceptPreviewBoundary(
              child: ZyraOneJourneyConceptShell(
                key: const ValueKey('dev_founder_preview'),
                canAct: () => currentPreview() && _route?.isCurrent == true,
                canActInOwnedDialog: currentPreview,
                onExit: () {
                  if (currentPreview() && _route?.isCurrent == true) {
                    host._samples.clear();
                  }
                },
                initialTab: widget.initialTab,
                initialGuardianRole: view.guardian,
                initialSeekerBasic: _bridge.journeyPlaces == 1,
                initialGuardianBasic: view == ZyraDeveloperViewAs.guardianBasic,
              ),
            ),
          );
        } else if (_bridge.canPresent) {
          _retainedPreview = null;
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            Offstage(
              offstage: show,
              child: TickerMode(
                enabled: !show,
                child: _DeveloperTitleVisibility(
                  visible: !show,
                  child: widget.child,
                ),
              ),
            ),
            if (_retainedPreview != null)
              Offstage(
                offstage: !show,
                child: TickerMode(
                  enabled: show,
                  child: _DeveloperTitleVisibility(
                    visible: show,
                    child: _retainedPreview!,
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class ZyraDeveloperPanelHost extends StatefulWidget {
  const ZyraDeveloperPanelHost({
    super.key,
    required this.access,
    required this.child,
  });

  final ZyraDeveloperPanelAccess access;
  final Widget child;

  @override
  State<ZyraDeveloperPanelHost> createState() => _ZyraDeveloperPanelHostState();
}

class _ZyraDeveloperPanelHostState extends State<ZyraDeveloperPanelHost>
    with WidgetsBindingObserver {
  final _samples = ZyraDeveloperSamples.instance;
  _ZyraDeveloperSeekerScopeState? _owner;
  ModalRoute<dynamic>? _seekerRoute;
  ModalBottomSheetRoute<void>? _sheet;
  MaterialPageRoute<void>? _previewErrorRoute;
  int? _generation;
  final _binding = Object();
  bool _opening = false;
  int _presentationRevision = 0;
  int _sheetRevision = 0;
  late bool _lockUnavailable;

  ZyraDeveloperPanelAccess get access => widget.access;

  bool get _seekerCurrent =>
      mounted &&
      _owner?.mounted == true &&
      _seekerRoute?.isActive == true &&
      _generation == ZyraAccountState.generation;

  bool get _foreground {
    final state = WidgetsBinding.instance.lifecycleState;
    final lock = ZyraAppLock.instance;
    return (state == null || state == AppLifecycleState.resumed) &&
        !lock.isLocked &&
        !lock.isObscured;
  }

  bool get _previewTitlesEnabled =>
      _owner != null &&
      _canPresent(_owner!) &&
      (_owner!.widget.preview || _samples.viewAs != null);

  bool availableOn(
    ModalRoute<dynamic> route, {
    ZyraDeveloperOwnedNavigatorScope? ownedNavigator,
  }) =>
      _seekerCurrent &&
      _foreground &&
      (route.navigator == _seekerRoute?.navigator ||
          (_seekerRoute?.isCurrent == true &&
              ownedNavigator?.admits(_owner?._bridge, route) == true)) &&
      access.email != null;

  @override
  void initState() {
    super.initState();
    final lock = ZyraAppLock.instance;
    _lockUnavailable = lock.isLocked || lock.isObscured;
    access.addListener(_accessChanged);
    _samples.addListener(_samplesChanged);
    AppState.instance.addListener(_accountOrPlanChanged);
    ZyraAppLock.instance.addListener(_lockChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  void register(
    _ZyraDeveloperSeekerScopeState owner,
    ModalRoute<dynamic> route,
  ) {
    if (!mounted || !owner.mounted) return;
    if (_owner != owner) {
      _release();
      access.suspend();
    }
    _owner = owner;
    _seekerRoute = route;
    _generation = ZyraAccountState.generation;
    if (_foreground) unawaited(access.verify());
  }

  void unregister(_ZyraDeveloperSeekerScopeState owner) {
    if (_owner != owner) return;
    _owner = null;
    _seekerRoute = null;
    _generation = null;
    // Navigator teardown may be in progress; retire the presentation
    // before the next frame, then notify once teardown has finished.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _owner == null) {
        access.suspend();
        _release();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _presentationRevision++;
    if (!_foreground) {
      access.suspend();
      _release();
    } else if (state == AppLifecycleState.resumed && _seekerCurrent) {
      unawaited(access.verify());
    }
  }

  void _lockChanged() {
    final lock = ZyraAppLock.instance;
    final unavailable = lock.isLocked || lock.isObscured;
    if (unavailable == _lockUnavailable) return;
    _lockUnavailable = unavailable;
    _presentationRevision++;
    if (!_foreground) {
      access.suspend();
      _release();
    } else if (_seekerCurrent) {
      unawaited(access.verify());
    }
  }

  void _accountOrPlanChanged() {
    if (_generation != null && !_seekerCurrent) {
      access.suspend();
      _release();
    } else {
      _owner?._bridge._publish();
    }
  }

  void _accessChanged() {
    final lifetime = access.verifiedLifetime;
    if (!_seekerCurrent || !_foreground || lifetime == null) {
      _release();
      return;
    }
    _samples.bind(
      lifetime: lifetime,
      binding: _binding,
      authorized: () =>
          _seekerCurrent && _foreground && access.verifiedLifetime == lifetime,
      capacity: _places,
      isSeekerOne: _viewedSeekerOne,
      canSendRequest: () => _owner?._bridge.canSendRequest ?? false,
    );
    if (AppState.instance.verifiedSeekerPlan == null &&
        _samples.viewAs == null) {
      _samples.setViewAs(ZyraDeveloperViewAs.seekerOne);
    }
  }

  void _release() {
    _samples.unbind(binding: _binding);
    _owner?._bridge._publish();
    _closeSheet();
    _closePreviewError();
  }

  void _closeSheet() {
    final sheet = _sheet;
    if (sheet == null) return;
    ++_sheetRevision;
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      if (sheet.isActive) sheet.navigator?.removeRoute(sheet);
    });
    binding.scheduleFrame();
  }

  int _places() => _samples.viewedSeekerPlaces ?? _realPlaces();

  static int _realPlaces() {
    final plan = AppState.instance.verifiedSeekerPlan;
    return plan == null ? 3 : ZyraEntitlements.of(plan).active;
  }

  static String _planName() => switch (AppState.instance.verifiedSeekerPlan) {
    ZyraPlan.one => ZyraMembershipCatalog.seekerOneTitle,
    ZyraPlan.basic => ZyraMembershipCatalog.title(
      ZyraMembershipProduct.seekerBasic,
    ),
    null => 'none',
  };

  bool _canPresent(_ZyraDeveloperSeekerScopeState owner) =>
      identical(_owner, owner) &&
      _seekerCurrent &&
      _foreground &&
      access.verifiedLifetime != null &&
      _samples.isAuthorized;

  void _samplesChanged() => _owner?._bridge._publish();

  ZyraDeveloperViewAs? _viewAs() =>
      _samples.viewAs ??
      switch (AppState.instance.verifiedSeekerPlan) {
        ZyraPlan.one => ZyraDeveloperViewAs.seekerOne,
        ZyraPlan.basic => ZyraDeveloperViewAs.seekerBasic,
        null => ZyraDeveloperViewAs.seekerOne,
      };

  bool _activatePreview() {
    final view = _viewAs();
    if (!_samples.isAuthorized || view == null) return false;
    if (_samples.viewAs == null) _samples.setViewAs(view);
    return true;
  }

  bool _viewedSeekerOne() =>
      (_samples.viewedSeekerPlaces ?? _realPlaces()) == 3;

  ZyraDeveloperPanelValues _values() {
    final places = _places();
    return ZyraDeveloperPanelValues(
      active: _samples.viewAs == null
          ? _samples.placesUsed
          : _samples.placesUsed.clamp(0, places),
      ended: _samples.endedCount,
      received: _samples.received ?? 0,
      sent: _samples.sent ?? 0,
      past: _samples.past ?? ZyraDeveloperPast.none,
      introductions: _samples.introductions ?? _samples.realIntroductions,
      preview: ZyraDeveloperPreviewValues(
        viewAs: _viewAs(),
        realPlanName: _planName(),
        journeyPlaces: places,
        canActivate: _viewAs() != null,
        setupAvailable: true,
        signupAvailable: true,
        unverified: _samples.unverified,
        setupUnfinished: _samples.setupUnfinished,
        journeys: [
          for (final row in _samples.activeRows ?? const <ZyraSampleJourney>[])
            (id: row.id, name: row.person.firstName, stage: row.stage ?? ''),
        ],
        selectedJourneyId: _samples.selectedJourneyId,
        preset: _samples.preset,
        notice: _samples.notice,
        offers: _samples.offers,
      ),
    );
  }

  Future<void> open(
    BuildContext context,
    ModalRoute<dynamic> openingRoute,
    bool Function() titleForeground, {
    ZyraDeveloperOwnedNavigatorScope? ownedNavigator,
  }) async {
    if (_opening ||
        _sheet != null ||
        !_foreground ||
        !titleForeground() ||
        !availableOn(openingRoute, ownedNavigator: ownedNavigator)) {
      return;
    }
    _opening = true;
    final presentation = _presentationRevision;
    try {
      if (!await access.refreshForTitle() ||
          !mounted ||
          !context.mounted ||
          presentation != _presentationRevision ||
          !_foreground ||
          !titleForeground() ||
          !availableOn(openingRoute, ownedNavigator: ownedNavigator)) {
        return;
      }
      final email = access.email!;
      final owner = _owner;
      final realPlan = AppState.instance.verifiedSeekerPlan;
      final lease = _sheetRevision;
      final values = ValueNotifier(_values());
      void updateValues() {
        if (realPlan != AppState.instance.verifiedSeekerPlan ||
            email != access.email) {
          _closeSheet();
        } else {
          values.value = _values();
        }
      }

      _samples.addListener(updateValues);
      AppState.instance.addListener(updateValues);
      owner?._bridge.addListener(updateValues);
      late final ModalBottomSheetRoute<void> route;
      bool visibleSheet() =>
          identical(_sheet, route) &&
          identical(_owner, owner) &&
          _seekerCurrent &&
          _foreground &&
          _sheetRevision == lease &&
          _samples.isAuthorized;
      bool currentSheet() => visibleSheet() && route.isCurrent;

      void Function(T) allowed<T>(void Function(T) action) => (value) {
        if (currentSheet()) action(value);
      };
      void Function(T) preview<T>(void Function(T) action) =>
          allowed<T>((value) {
            if (_activatePreview()) {
              if (owner case final scope?) {
                scope._bridge._dispatchSelection(() {
                  _samples.clearProfileSmallPage();
                  action(value);
                });
              } else {
                _samples.clearProfileSmallPage();
                action(value);
              }
            }
          });

      route = zyraDeveloperPanelRoute(
        context,
        email: email,
        planName: _planName(),
        journeyPlaces: _places(),
        values: values,
        visibilityListenable: _samples,
        isVisible: visibleSheet,
        previewActions: ZyraDeveloperPreviewActions(
          onViewAs: allowed(_samples.setViewAs),
          onStartSignup: () {
            if (currentSheet() && _activatePreview() && owner != null) {
              _samples.clearProfileSmallPage();
              unawaited(_startSignupPreview(route, owner));
            }
          },
          onUnverified: preview(_samples.setUnverified),
          onSetupUnfinished: preview(_samples.setSetupUnfinished),
          onJourney: preview((String attemptId) {
            if (!(_samples.activeRows?.any((row) => row.id == attemptId) ??
                false)) {
              return;
            }
            owner?._bridge._requestJourney(
              () => _samples.setSelectedJourney(attemptId),
            );
          }),
          onStage: preview((String stage) {
            final attemptId = _samples.selectedJourneyId;
            if (attemptId == null ||
                !ZyraJourneyStages.previewAll.any(
                  (value) => value.value == stage,
                )) {
              return;
            }
            owner?._bridge._requestJourney(
              () => _samples.setJourneyStage(attemptId, stage),
            );
          }),
          onPreset: allowed((ZyraDeveloperPreset value) {
            if (_activatePreview()) {
              owner?._bridge._requestPreset(() {
                _samples.clearProfileSmallPage();
                _samples.setPreset(value);
              });
            }
          }),
          onProfileSmallPage: allowed((ZyraProfileSmallPageSample value) {
            if (owner case final scope?) {
              scope._bridge._dispatchSelection(
                () => _samples.setProfileSmallPage(value),
              );
            }
          }),
          onNotice: preview((int value) {
            if (_viewAs()?.guardian == true) return;
            if (value < 0 || value > 6) return;
            owner?._bridge._requestNotice(() => _samples.setNotice(value));
          }),
          onRetentionMode: preview(_samples.setRetentionMode),
          onEid: preview(_samples.setEid),
          onRamadan: preview(_samples.setRamadan),
          onError: allowed((kind) {
            if (owner != null) {
              _samples.clearProfileSmallPage();
              unawaited(_showPreviewError(kind, route, owner));
            }
          }),
        ),
        onActive: preview((int value) {
          if (value <= _places()) _samples.setPreviewActive(value);
        }),
        onEnded: preview(_samples.setEnded),
        onReceived: preview(_samples.setReceived),
        onSent: preview(_samples.setSent),
        onPast: preview(_samples.setPast),
        onIntroductions: preview(_samples.setIntroductions),
        onClear: () {
          if (currentSheet()) {
            _samples.clear(
              previewDefault: AppState.instance.verifiedSeekerPlan == null
                  ? ZyraDeveloperViewAs.seekerOne
                  : null,
            );
          }
        },
      );
      _sheet = route;
      try {
        await Navigator.of(context, rootNavigator: true).push(route);
        await route.completed;
      } finally {
        _sheet = null;
        _samples.removeListener(updateValues);
        AppState.instance.removeListener(updateValues);
        owner?._bridge.removeListener(updateValues);
        values.dispose();
      }
    } finally {
      _opening = false;
    }
  }

  Future<void> _startSignupPreview(
    ModalBottomSheetRoute<void> sheet,
    _ZyraDeveloperSeekerScopeState owner,
  ) async {
    if (!_canPresent(owner) || !identical(_sheet, sheet) || !sheet.isCurrent) {
      return;
    }
    final lifetime = access.verifiedLifetime;
    final presentation = _presentationRevision;
    bool current() =>
        mounted &&
        _canPresent(owner) &&
        access.verifiedLifetime == lifetime &&
        presentation == _presentationRevision;
    _closeSheet();
    await sheet.completed;
    await WidgetsBinding.instance.endOfFrame;
    if (!current() || _seekerRoute?.isCurrent != true) return;
    if (!await access.refreshForTitle() ||
        !current() ||
        _seekerRoute?.isCurrent != true) {
      return;
    }
    await owner._bridge.startSignup();
  }

  Future<void> _showPreviewError(
    ZyraErrorKind kind,
    ModalBottomSheetRoute<void> sheet,
    _ZyraDeveloperSeekerScopeState owner,
  ) async {
    if (!_canPresent(owner) || !identical(_sheet, sheet) || !sheet.isCurrent) {
      return;
    }
    final lifetime = access.verifiedLifetime;
    final presentation = _presentationRevision;
    bool current() =>
        mounted &&
        _canPresent(owner) &&
        access.verifiedLifetime == lifetime &&
        presentation == _presentationRevision;
    _closeSheet();
    await sheet.completed;
    if (!current() || _seekerRoute?.isCurrent != true) return;
    if (!await access.refreshForTitle() ||
        !current() ||
        _seekerRoute?.isCurrent != true) {
      return;
    }
    final showError = owner._bridge._showError;
    if (showError != null) {
      await showError(kind);
      return;
    }
    // This sample does not need membership or a planned-app Shell. It only
    // shows the existing shared page and returns to its original route.
    if (_previewErrorRoute != null) return;
    final navigator = _seekerRoute?.navigator;
    if (navigator == null) return;
    late final MaterialPageRoute<void> errorRoute;
    bool owned() =>
        current() &&
        identical(_previewErrorRoute, errorRoute) &&
        errorRoute.isActive;
    errorRoute = MaterialPageRoute<void>(
      builder: (context) => ListenableBuilder(
        listenable: Listenable.merge([access, _samples, ZyraAppLock.instance]),
        builder: (context, _) => !owned()
            ? ColoredBox(
                color: ZyraColors.modalSheetSurface,
                child: const SizedBox.expand(),
              )
            : ZyraFullScreenError(
                kind: kind,
                referenceCode: zyraErrorReference(kind),
                onPrimary: () async {
                  if (owned() && errorRoute.isCurrent) navigator.pop();
                },
              ),
      ),
    );
    _previewErrorRoute = errorRoute;
    try {
      await navigator.push(errorRoute);
      await errorRoute.completed;
    } finally {
      if (identical(_previewErrorRoute, errorRoute)) _previewErrorRoute = null;
    }
  }

  void _closePreviewError() {
    final route = _previewErrorRoute;
    if (route == null) return;
    _previewErrorRoute = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (route.isActive) route.navigator?.removeRoute(route);
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    access.removeListener(_accessChanged);
    _samples.removeListener(_samplesChanged);
    AppState.instance.removeListener(_accountOrPlanChanged);
    ZyraAppLock.instance.removeListener(_lockChanged);
    // The real App Lock and lifecycle callbacks suspend before teardown.
    // Do not notify sibling routes synchronously during a widget dispose.
    final panelAccess = access;
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      if (_samples.unbind(binding: _binding)) panelAccess.suspend();
    });
    _closeSheet();
    _closePreviewError();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _DeveloperPanelScope(host: this, child: widget.child);
}

class _DeveloperPanelScope extends InheritedWidget {
  const _DeveloperPanelScope({required this.host, required super.child});

  final _ZyraDeveloperPanelHostState host;

  static _ZyraDeveloperPanelHostState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_DeveloperPanelScope>()?.host;

  @override
  bool updateShouldNotify(_DeveloperPanelScope oldWidget) =>
      host != oldWidget.host;
}
