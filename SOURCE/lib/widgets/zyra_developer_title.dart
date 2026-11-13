import 'dart:async';

import 'package:flutter/material.dart';

import '../data/zyra_entitlements.dart';
import '../data/zyra_membership_catalog.dart';
import '../services/zyra_account_state.dart';
import '../services/zyra_app_lock.dart';
import '../services/zyra_developer_access.dart';
import '../state/app_state.dart';
import '../state/zyra_developer_samples.dart';
import 'zyra_developer_panel.dart';

/// Explicit hook on an existing Seeker heading. Without panel authority
/// the heading is returned as-is, including its normal accessibility.
class ZyraDeveloperTitle extends StatefulWidget {
  const ZyraDeveloperTitle({
    super.key,
    required this.child,
    this.tab,
    this.enabled = true,
    this.hideWhenUnavailable = false,
  });

  final Widget child;
  final int? tab;
  final bool enabled;
  final bool hideWhenUnavailable;

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
    if (widget.tab != oldWidget.tab || widget.enabled != oldWidget.enabled) {
      _revision++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final host = _DeveloperPanelScope.maybeOf(context);
    final tabScope = context
        .dependOnInheritedWidgetOfExactType<ZyraDeveloperSeekerTab>();
    final route = ModalRoute.of(context);
    final revision = _revision;
    bool foreground() =>
        mounted &&
        revision == _revision &&
        route?.isCurrent == true &&
        (widget.tab == null || tabScope?.isSelected(widget.tab!) == true);

    final child = widget.child;
    if (host == null || !widget.enabled) {
      return widget.hideWhenUnavailable ? const SizedBox.shrink() : child;
    }
    return ListenableBuilder(
      listenable: host.access,
      child: child,
      builder: (context, heading) {
        if (!foreground() || !host.availableOn(route!)) {
          return widget.hideWhenUnavailable
              ? const SizedBox.shrink()
              : heading!;
        }
        final proof = host.access.proofRevision;
        return Semantics(
          button: true,
          child: GestureDetector(
            key: const ValueKey('dev_page_title'),
            behavior: HitTestBehavior.deferToChild,
            onTap: () {
              if (host.access.proofRevision == proof) {
                unawaited(host.open(context, route, foreground));
              }
            },
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

/// Mounted only at entry to the authenticated ordinary Seeker shell.
class ZyraDeveloperSeekerScope extends StatefulWidget {
  const ZyraDeveloperSeekerScope({super.key, required this.child});

  final Widget child;

  @override
  State<ZyraDeveloperSeekerScope> createState() =>
      _ZyraDeveloperSeekerScopeState();
}

class _ZyraDeveloperSeekerScopeState extends State<ZyraDeveloperSeekerScope> {
  _ZyraDeveloperPanelHostState? _host;
  ModalRoute<dynamic>? _route;
  bool _registered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final host = _DeveloperPanelScope.maybeOf(context);
    final route = ModalRoute.of(context);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
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

  bool availableOn(ModalRoute<dynamic> route) =>
      _seekerCurrent &&
      _foreground &&
      route.navigator == _seekerRoute?.navigator &&
      access.email != null;

  @override
  void initState() {
    super.initState();
    final lock = ZyraAppLock.instance;
    _lockUnavailable = lock.isLocked || lock.isObscured;
    access.addListener(_accessChanged);
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
      isSeekerOne: () => AppState.instance.verifiedSeekerPlan == ZyraPlan.one,
    );
  }

  void _release() {
    _samples.unbind(binding: _binding);
    _closeSheet();
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

  static int _places() {
    final plan = AppState.instance.verifiedSeekerPlan;
    return plan == null ? 0 : ZyraEntitlements.of(plan).active;
  }

  static String _planName() => switch (AppState.instance.verifiedSeekerPlan) {
    ZyraPlan.one => ZyraMembershipCatalog.seekerOneTitle,
    ZyraPlan.basic => ZyraMembershipCatalog.title(
      ZyraMembershipProduct.seekerBasic,
    ),
    null => 'No active membership',
  };

  ZyraDeveloperPanelValues _values() => ZyraDeveloperPanelValues(
    active: _samples.placesUsed,
    ended: _samples.endedCount,
    received: _samples.received ?? 0,
    sent: _samples.sent ?? 0,
    past: _samples.past ?? ZyraDeveloperPast.none,
    introductions: _samples.introductions ?? _samples.realIntroductions,
  );

  Future<void> open(
    BuildContext context,
    ModalRoute<dynamic> openingRoute,
    bool Function() titleForeground,
  ) async {
    if (_opening ||
        _sheet != null ||
        !_foreground ||
        !titleForeground() ||
        !availableOn(openingRoute)) {
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
          !availableOn(openingRoute)) {
        return;
      }
      final email = access.email!;
      final owner = _owner;
      final places = _places();
      final lease = _sheetRevision;
      final values = ValueNotifier(_values());
      void updateValues() {
        if (places != _places() || email != access.email) {
          _closeSheet();
        } else {
          values.value = _values();
        }
      }

      _samples.addListener(updateValues);
      AppState.instance.addListener(updateValues);
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

      route = zyraDeveloperPanelRoute(
        context,
        email: email,
        planName: _planName(),
        journeyPlaces: places,
        values: values,
        visibilityListenable: _samples,
        isVisible: visibleSheet,
        onActive: allowed((value) {
          if (value <= _places()) _samples.setActive(value);
        }),
        onEnded: allowed(_samples.setEnded),
        onReceived: allowed(_samples.setReceived),
        onSent: allowed(_samples.setSent),
        onPast: allowed(_samples.setPast),
        onIntroductions: allowed(_samples.setIntroductions),
        onClear: () {
          if (currentSheet()) _samples.clear();
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
        values.dispose();
      }
    } finally {
      _opening = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    access.removeListener(_accessChanged);
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
