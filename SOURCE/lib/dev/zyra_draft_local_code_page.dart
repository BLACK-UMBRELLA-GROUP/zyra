import '../widgets/zyra_floating_surface.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/zyra_code_format.dart';
import '../widgets/zyra_known_person_code_content.dart';
import '../widgets/zyra_request_tab_pill.dart';
import '../widgets/zyra_tab_title.dart';
import '../widgets/zyra_developer_title.dart';

import '../theme/zyra_motion.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_interaction_style.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_tap_feedback.dart';
import 'zyra_draft_local_code_aliases.dart';

@immutable
class ZyraLocalCodeIdentity {
  const ZyraLocalCodeIdentity(this.firstName, this.role);
  final String firstName;
  final String role;
}

typedef ZyraLocalCaptureBuilder =
    Widget Function(
      BuildContext context,
      bool Function() canCapture,
      ValueChanged<String> onCode,
      VoidCallback onManualEntry,
      ValueChanged<bool> onRunningChanged,
    );

/// Shared LOCK 9 presentation. Hosts own account admission and any RPC.
/// A local host resolves only its explicit fictional aliases and simulates
/// Send; it cannot fall through to the member host.
class ZyraLocalCodePage extends StatefulWidget {
  const ZyraLocalCodePage({
    super.key,
    required this.mode,
    required this.canAct,
    required this.lookupCode,
    required this.ownerKey,
    this.canInteract,
    this.interactionEpoch,
    this.personalCode,
    this.onCopy,
    this.onRotate,
    this.onMemberSend,
    this.onLocalSend,
    this.foundExtra,
    this.onMemberScanAction,
    this.manualAlias,
    this.isLocal = true,
    this.copyLabel = 'Copy code',
    this.myCodeStatus,
    this.legacyEntry,
    this.simulatedCamera = false,
    this.onShare,
    this.extra,
    this.captureBuilder,
    this.cameraEnabled = true,
  });
  final ZyraLocalCodeContext mode;
  final bool Function() canAct;
  final bool Function()? canInteract;
  final Object Function()? interactionEpoch;
  final Object ownerKey;
  final Future<ZyraLocalCodeIdentity?> Function(String) lookupCode;
  final String? personalCode;
  final VoidCallback? onCopy, onRotate;
  final ValueChanged<BuildContext>? onShare;
  final bool isLocal, cameraEnabled;
  final String copyLabel;
  final Widget? myCodeStatus, legacyEntry;
  final bool simulatedCamera;
  final String? Function(String)? manualAlias;
  final Future<String?> Function(
    String code,
    ZyraLocalCodeIdentity person,
    bool Function() isCurrent,
  )?
  onMemberSend;
  final bool Function()? onLocalSend;
  final Widget Function(bool Function() isCurrent)? foundExtra;
  final Widget Function(
    String code,
    ZyraLocalCodeIdentity person,
    bool Function() isCurrent,
  )?
  onMemberScanAction;
  final Widget? extra;
  final ZyraLocalCaptureBuilder? captureBuilder;

  @override
  State<ZyraLocalCodePage> createState() => _ZyraLocalCodePageState();
}

enum _CameraMode { off, starting, live, refused }

class _ZyraLocalCodePageState extends State<ZyraLocalCodePage>
    with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _resultKey = GlobalKey();
  final _errorKey = GlobalKey();
  ZyraLocalCodeIdentity? _person;
  String? _error;
  bool _theirCode = false, _invalidScan = false, _showLegacy = false;
  Timer? _invalidScanTimer;
  bool _busy = false, _sent = false, _closed = false;
  bool _expired = false;
  Timer? _requestExpiry;
  static const _requestLifetime = Duration(days: 14);
  _CameraMode _camera = _CameraMode.off;
  bool get _cameraLive => _camera == _CameraMode.live;
  int _revision = 0, _cameraRevision = 0;
  Object? _seenEpoch;
  AppLifecycleState? _lifecycle;

  bool _ownerAllows() {
    if (!mounted || _closed) return false;
    try {
      if (widget.canAct()) return true;
    } catch (_) {
      /* A failed local guard never admits a live fallback. */
    }
    _closed = true;
    _invalidate();
    return false;
  }

  Object? _epoch() {
    try {
      return widget.interactionEpoch?.call();
    } catch (_) {
      _closed = true;
      _invalidate();
      return null;
    }
  }

  bool _current([Object? epoch]) {
    if (!_ownerAllows()) return false;
    try {
      return (epoch == null || epoch == _epoch()) &&
          (widget.canInteract?.call() ?? true) &&
          (ModalRoute.of(context)?.isCurrent ?? true) &&
          (_lifecycle == null || _lifecycle == AppLifecycleState.resumed);
    } catch (_) {
      return false;
    }
  }

  void _invalidate() {
    ++_revision;
    _stopCapture();
    _person = null;
    _busy = false;
    _clearRequest();
    _error = null;
  }

  @override
  void initState() {
    super.initState();
    _lifecycle = WidgetsBinding.instance.lifecycleState;
    _seenEpoch = _epoch();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant ZyraLocalCodePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ownerKey != widget.ownerKey ||
        oldWidget.mode != widget.mode) {
      _closed = true;
      _invalidate();
      return;
    }
    if (_seenEpoch != _epoch()) {
      _seenEpoch = _epoch();
      _invalidate();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) _invalidate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    if (mounted && state != AppLifecycleState.resumed) {
      if (state == AppLifecycleState.inactive) {
        // A first-use permission prompt is inactive-only. Keep its capture
        // session, while retiring any lookup/result callbacks from before it.
        setState(() {
          ++_revision;
          if (_cameraLive) _camera = _CameraMode.starting;
          _person = null;
          _busy = false;
          _clearRequest();
          _error = null;
        });
      } else {
        setState(_invalidate);
      }
    }
  }

  @override
  void dispose() {
    ++_revision;
    ++_cameraRevision;
    WidgetsBinding.instance.removeObserver(this);
    _requestExpiry?.cancel();
    _invalidScanTimer?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _changed(String _) {
    if (!_current()) return;
    setState(() {
      ++_revision;
      _person = null;
      _error = null;
      _busy = false;
      _clearRequest();
    });
  }

  Future<void> _checkLocal() async {
    if (!_current() || _busy) return;
    final entry = _controller.text;
    if (entry.length != 20) {
      if (widget.legacyEntry != null) setState(() => _showLegacy = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter all 20 characters.')));
      return;
    }
    final epoch = _epoch();
    final revision = ++_revision;
    final canonical = widget.isLocal
        ? ZyraLocalCodeAliases.canonical(widget.mode, entry)
        : ZyraCodeFormat.grouped(entry);
    setState(() {
      _busy = true;
      _person = null;
      _clearRequest();
      _error = null;
    });
    ZyraLocalCodeIdentity? person;
    String? failure;
    try {
      if (canonical != null) {
        person = await widget
            .lookupCode(canonical)
            .timeout(const Duration(seconds: 10));
      }
    } on ZyraCodeCheckFailure catch (e) {
      failure = e.message;
    } catch (_) {
      failure = "The code couldn't be checked. Please try again.";
    }
    if (!mounted || revision != _revision) return;
    if (!_current(epoch) || _controller.text != entry) {
      setState(_invalidate);
      return;
    }
    final role = widget.mode == ZyraLocalCodeContext.addGuardian
        ? 'Guardian'
        : 'Seeker';
    setState(() {
      _busy = false;
      _person =
          person != null &&
              person.firstName.trim().isNotEmpty &&
              person.role == role
          ? ZyraLocalCodeIdentity(person.firstName.trim(), role)
          : null;
      if (_person == null) {
        if (failure == null) _showLegacy = true;
        _error =
            failure ??
            (widget.mode == ZyraLocalCodeContext.scan
                ? 'That code is not available.'
                : 'Invalid code. Please try again.');
      }
    });
    _focus.unfocus();
    _reveal();
  }

  void _reveal() => WidgetsBinding.instance.addPostFrameCallback((_) {
    final target = _errorKey.currentContext ?? _resultKey.currentContext;
    if (_current() && target != null) {
      Scrollable.ensureVisible(
        target,
        alignment: 1,
        duration: ZyraMotion.scrollDuration(context),
        curve: ZyraMotion.curve,
      );
    }
  });

  void _clearRequest() {
    _requestExpiry?.cancel();
    _requestExpiry = null;
    _sent = false;
    _expired = false;
  }

  Future<void> _send(int revision, Object? epoch) async {
    bool current() => _current(epoch) && revision == _revision;
    final person = _person;
    if (!current() || person == null || _sent || _busy) return;
    if (!widget.isLocal) {
      final send = widget.onMemberSend;
      if (send == null) return;
      setState(() {
        _busy = true;
        _error = null;
      });
      String? error;
      try {
        error = await send(
          ZyraCodeFormat.grouped(_controller.text),
          person,
          current,
        );
      } catch (_) {
        error = "That request didn't go through. Please try again.";
      }
      if (!mounted || revision != _revision) return;
      if (!current()) {
        setState(() => _busy = false);
        return;
      }
      setState(() {
        _busy = false;
        _sent = error == null;
        _error = error;
      });
    } else {
      if (!(widget.onLocalSend?.call() ?? true)) return;
      setState(() => _sent = true);
      _requestExpiry = Timer(_requestLifetime, () {
        if (mounted && _sent) setState(() => _expired = true);
      });
    }
    _reveal();
  }

  void _stopCapture() {
    ++_cameraRevision;
    _camera = _CameraMode.off;
    _invalidScan = false;
    _invalidScanTimer?.cancel();
  }

  void _rejectScan() {
    if (_invalidScan) return;
    setState(() => _invalidScan = true);
    _invalidScanTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && _invalidScan) setState(() => _invalidScan = false);
    });
  }

  Widget? _capture() {
    if (_camera == _CameraMode.off || _camera == _CameraMode.refused) {
      return null;
    }
    final revision = _cameraRevision;
    final epoch = _epoch();
    bool current() =>
        _current(epoch) &&
        revision == _cameraRevision &&
        _camera != _CameraMode.off &&
        _camera != _CameraMode.refused;
    void rejected() {
      if (current()) _rejectScan();
    }

    void detected(String raw) {
      if (!current()) return;
      final entry = ZyraCodeFormat.scanEntry(raw);
      if (entry == null) {
        rejected();
        return;
      }
      setState(() {
        _invalidate();
        _controller.text = entry;
      });
      _checkLocal();
    }

    void manual() {
      if (!current()) return;
      setState(_stopCapture);
      _focus.requestFocus();
    }

    void runningChanged(bool running) {
      final mode = running ? _CameraMode.live : _CameraMode.refused;
      if (!current() || mode == _camera) return;
      setState(() => _camera = mode);
    }

    return KeyedSubtree(
      key: ValueKey(revision),
      child:
          widget.captureBuilder?.call(
            context,
            current,
            detected,
            manual,
            runningChanged,
          ) ??
          ZyraCodeCapture(
            canCapture: current,
            onCode: detected,
            onManualEntry: manual,
            framed: true,
            onRunningChanged: runningChanged,
            onRejected: rejected,
          ),
    );
  }

  VoidCallback _bound(VoidCallback action) {
    final revision = _revision;
    final epoch = _epoch();
    return () {
      if (_current(epoch) && revision == _revision) {
        action();
      } else {
        ZyraInteractionStyle.cancelSelectionTap();
      }
    };
  }

  void _selectTab(bool theirCode) {
    if (_theirCode == theirCode) return;
    _focus.unfocus();
    setState(() {
      _theirCode = theirCode;
      _stopCapture();
    });
  }

  Widget _myCode() {
    final code = widget.personalCode;
    final compact = MediaQuery.sizeOf(context).height <= 667;
    final grouped = code == null
        ? null
        : Text(
            code.replaceAll('-', ' · '),
            textAlign: TextAlign.center,
            semanticsLabel: code,
            style: ZyraText.heading(size: 16).copyWith(letterSpacing: 1.6),
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (code != null) ...[
          Center(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF9),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: ZyraColors.journeyGold.withValues(alpha: .35),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A3E2E1E),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: QrImageView(
                key: ValueKey(('zyra-qr', code)),
                data: code,
                size: 196,
                padding: const EdgeInsets.all(16),
                semanticsLabel: 'Your ZYRA Code as a QR code',
              ),
            ),
          ),
          SizedBox(height: compact ? 12 : 18),
          if (compact && MediaQuery.textScalerOf(context).scale(1) <= 1.15)
            FittedBox(fit: BoxFit.scaleDown, child: grouped)
          else
            grouped!,
          const SizedBox(height: 6),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: const _CodeHelper(
                'They can send a request. You still choose whether to link.',
              ),
            ),
          ),
          const SizedBox(height: 18),
          Builder(
            builder: (context) => _CodeAction(
              key: const ValueKey('local-code-share'),
              label: 'Share my code',
              onTap: widget.onShare == null
                  ? null
                  : _bound(() => widget.onShare!(context)),
            ),
          ),
          const SizedBox(height: 8),
          _CodeAction(
            key: const ValueKey('local-code-copy'),
            label: widget.copyLabel,
            onTap: widget.onCopy == null ? null : _bound(widget.onCopy!),
            gold: false,
          ),
          SizedBox(height: compact ? 6 : 12),
          TextButton(
            key: const ValueKey('zyra-code-rotate'),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 44),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: widget.onRotate == null
                ? null
                : ZyraTapFeedback.onTap(context, _bound(widget.onRotate!)),
            child: Text('Get a new code', style: ZyraText.subtext(size: 12.5)),
          ),
        ],
        ?widget.myCodeStatus,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ownerAllows()) return const SizedBox.shrink();
    final scan = widget.mode == ZyraLocalCodeContext.scan;
    final person = _person;
    final title = scan
        ? 'Scan'
        : widget.mode == ZyraLocalCodeContext.addGuardian
        ? 'Add a Guardian'
        : 'Add a Seeker';
    final header = <Widget>[
      ZyraDeveloperTitle(
        enabled: !widget.isLocal && widget.mode == ZyraLocalCodeContext.scan,
        child: ZyraTabTitle(title),
      ),
      const SizedBox(height: 5),
      Text(
        scan
            ? 'Scan or enter their ZYRA Code to find their profile.'
            : 'A code only sends a request. You choose who joins.',
        style: ZyraText.subtext(size: 12.5),
      ),
      const SizedBox(height: 12),
      if (!scan) ...[
        Row(
          children: [
            Expanded(
              child: ZyraRequestTabPill(
                label: 'My code',
                selected: !_theirCode,
                tapKey: const ValueKey('zyra-my-code-tab'),
                onTap: _bound(() => _selectTab(false)),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: ZyraRequestTabPill(
                label: 'Their code',
                selected: _theirCode,
                tapKey: const ValueKey('zyra-their-code-tab'),
                onTap: _bound(() => _selectTab(true)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    ];
    final their = scan || _theirCode;
    return SafeArea(
      child: CustomScrollView(
        key: ValueKey(('local-code-scroll', their)),
        clipBehavior: Clip.none,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(21, 16, 21, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: header,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 21),
            sliver: SliverLayoutBuilder(
              builder: (context, box) => SliverToBoxAdapter(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(
                      0,
                      box.viewportMainAxisExtent -
                          box.precedingScrollExtent -
                          20,
                    ),
                  ),
                  child: _fillCard(
                    their ? _theirEntry(scan, person) : _myCode(),
                    their: their,
                  ),
                ),
              ),
            ),
          ),
          if (widget.extra case final extra?)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 21),
              sliver: SliverToBoxAdapter(child: extra),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  // The finite viewport is owned by the caller. A full-height card can
  // still grow when the keyboard, large type, or a result requires scrolling.
  Widget _fillCard(Widget child, {required bool their}) => _CodeGlass(
    key: const ValueKey('zyra-code-main-card'),
    radius: 24,
    padding: their
        ? const EdgeInsets.fromLTRB(16, 20, 16, 20)
        : EdgeInsets.symmetric(
            horizontal: 18,
            vertical: MediaQuery.sizeOf(context).height <= 667 ? 16 : 22,
          ),
    child: Center(child: child),
  );

  Widget _theirEntry(bool scan, ZyraLocalCodeIdentity? person) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Center(
        child: LayoutBuilder(
          builder: (context, constraints) => _CodeCameraFrame(
            side: math.min(
              math.max(
                160,
                250 / MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.5),
              ),
              constraints.maxWidth,
            ),
            capture: _capture(),
            live: _cameraLive,
            refused: _camera == _CameraMode.refused || !widget.cameraEnabled,
            invalid: _invalidScan,
            onTap:
                !widget.cameraEnabled ||
                    (_camera != _CameraMode.off &&
                        _camera != _CameraMode.refused)
                ? null
                : _bound(
                    () => setState(() {
                      ++_cameraRevision;
                      _camera = widget.simulatedCamera
                          ? _CameraMode.refused
                          : _CameraMode.starting;
                    }),
                  ),
          ),
        ),
      ),
      if (_cameraLive) ...[
        const SizedBox(height: 10),
        Text(
          'Point at their ZYRA Code',
          key: const ValueKey('local-code-camera-caption'),
          textAlign: TextAlign.center,
          style: ZyraText.subtext(size: 12.5),
        ),
      ],
      const SizedBox(height: 18),
      const _CodeDivider('OR ENTER IT'),
      const SizedBox(height: 9),
      _CodeBoxes(
        controller: _controller,
        focus: _focus,
        alias:
            widget.manualAlias ??
            (widget.isLocal
                ? (raw) => ZyraLocalCodeAliases.entry(widget.mode, raw)
                : null),
        onChanged: _changed,
        onCheck: _bound(_checkLocal),
        onFocus: _bound(_focus.requestFocus),
      ),
      const SizedBox(height: 12),
      _CodeAction(
        key: const ValueKey('local-code-check'),
        label: _busy ? 'Checking…' : 'Check code',
        onTap: _busy ? null : _bound(_checkLocal),
      ),
      if (_showLegacy) ?widget.legacyEntry,
      if (person != null) ...[
        const SizedBox(height: 16),
        _CodeGlass(
          key: _resultKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ZyraColors.avatarSand,
                          ZyraColors.avatarDeepSand,
                        ],
                      ),
                    ),
                    child: Text(
                      person.firstName.substring(0, 1).toUpperCase(),
                      style: ZyraText.body(
                        size: 20,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person.firstName,
                          style: ZyraText.heading(size: 18),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${person.role} · first name and role only',
                          style: ZyraText.subtext(size: 12),
                        ),
                        if (_sent) ...[
                          const SizedBox(height: 4),
                          Text(
                            _expired ? 'Expired after 14 days' : 'Request sent',
                            style: ZyraText.body(
                              size: 12,
                              color: ZyraColors.goldText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (!scan) ...[
                const SizedBox(height: 12),
                if (_sent && !_expired)
                  Text(
                    widget.isLocal
                        ? '${person.firstName} has 14 days to accept. You’ll see them in ${widget.mode == ZyraLocalCodeContext.addGuardian ? 'Guardians' : 'Seekers'} once they accept.'
                        : '${person.firstName} chooses whether to link. You’ll see them in ${widget.mode == ZyraLocalCodeContext.addGuardian ? 'Guardians' : 'Seekers'} once they accept.',
                    style: ZyraText.subtext(size: 12).copyWith(height: 1.5),
                  )
                else if (!_sent) ...[
                  if (widget.foundExtra case final extra?) ...[
                    Builder(
                      builder: (context) {
                        final epoch = _epoch();
                        final revision = _revision;
                        return extra(
                          () =>
                              _current(epoch) &&
                              revision == _revision &&
                              !_busy,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  _CodeAction(
                    key: const ValueKey('local-code-send'),
                    label: 'Send request',
                    onTap: _busy
                        ? null
                        : _bound(() => _send(_revision, _epoch())),
                  ),
                ],
              ] else if (widget.onMemberScanAction case final action?) ...[
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final epoch = _epoch();
                    final revision = _revision;
                    return action(
                      ZyraCodeFormat.grouped(_controller.text),
                      person,
                      () => _current(epoch) && revision == _revision,
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            _error!,
            key: _errorKey,
            style: ZyraText.subtext(size: 12),
          ),
        ),
    ],
  );
}

class _LocalCodeFormatter extends TextInputFormatter {
  const _LocalCodeFormatter(this.alias);
  final String? Function(String)? alias;
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final known =
        alias?.call(newValue.text) ?? ZyraCodeFormat.scanEntry(newValue.text);
    if (known != null) {
      return TextEditingValue(
        text: known,
        selection: TextSelection.collapsed(offset: known.length),
      );
    }
    if (newValue.text.contains(RegExp(r'[:/\\]'))) return oldValue;
    final clean = newValue.text.toUpperCase().replaceAll(
      RegExp('[^A-Z0-9]'),
      '',
    );
    if (clean.length > 20) return oldValue;
    return TextEditingValue(
      text: clean,
      selection: TextSelection.collapsed(offset: clean.length),
    );
  }
}

class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({
    required this.controller,
    required this.focus,
    required this.alias,
    required this.onChanged,
    required this.onCheck,
    required this.onFocus,
  });
  final TextEditingController controller;
  final FocusNode focus;
  final String? Function(String)? alias;
  final ValueChanged<String> onChanged;
  final VoidCallback onCheck, onFocus;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'ZYRA Code, 20 characters',
    textField: true,
    child: Stack(
      children: [
        Opacity(
          opacity: 0,
          child: SizedBox(
            height: 56,
            child: TextField(
              key: const ValueKey('local-code-field'),
              controller: controller,
              focusNode: focus,
              inputFormatters: [_LocalCodeFormatter(alias)],
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: onChanged,
              onSubmitted: (_) => onCheck(),
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
        ),
        ExcludeSemantics(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: ZyraTapFeedback.onTap(context, onFocus),
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => Row(
                children: [
                  Text(
                    'ZYRA',
                    style: ZyraText.body(
                      size: 12,
                      color: ZyraColors.goldText,
                    ).copyWith(letterSpacing: 1),
                  ),
                  const SizedBox(width: 10),
                  for (int i = 0; i < 5; i++) ...[
                    if (i != 0) const SizedBox(width: 6),
                    Expanded(
                      child: ZyraFloatingSurface(
                        radius: 22,
                        child: Container(
                          key: ValueKey('local-code-box-$i'),
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: ZyraColors.surfaceFill,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  controller.text.length < 20 &&
                                      controller.text.length ~/ 4 == i
                                  ? ZyraColors.journeyGold
                                  : ZyraColors.warmOverlay.withValues(
                                      alpha: .15,
                                    ),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: Text(
                                controller.text.length <= i * 4
                                    ? '····'
                                    : controller.text.substring(
                                        i * 4,
                                        math.min(
                                          i * 4 + 4,
                                          controller.text.length,
                                        ),
                                      ),
                                style: ZyraText.body(
                                  size: 14,
                                  color: controller.text.length <= i * 4
                                      ? ZyraColors.ink(.6)
                                      : null,
                                ).copyWith(letterSpacing: 1.3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _CodeAction extends StatelessWidget {
  const _CodeAction({
    super.key,
    required this.label,
    required this.onTap,
    this.gold = true,
  });
  final String label;
  final VoidCallback? onTap;
  final bool gold;
  @override
  Widget build(BuildContext context) => ZyraFloatingSurface(
    radius: 999,
    gold: gold,
    child: Material(
      color: gold ? ZyraColors.goldTextFill : ZyraColors.surfaceFill,
      borderRadius: BorderRadius.circular(gold ? 999 : 15),
      child: InkWell(
        enableFeedback: false,
        onTap: ZyraTapFeedback.onTap(context, onTap),
        borderRadius: BorderRadius.circular(gold ? 999 : 15),
        child: Container(
          constraints: BoxConstraints(minHeight: gold ? 52 : 46),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(gold ? 999 : 15),
            border: gold
                ? null
                : Border.all(
                    color: ZyraColors.warmOverlay.withValues(alpha: .17),
                  ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: gold
                ? ZyraText.button(size: 14, color: ZyraColors.espresso)
                : ZyraText.body(size: 13),
          ),
        ),
      ),
    ),
  );
}

class _CodeGlass extends StatelessWidget {
  const _CodeGlass({
    super.key,
    required this.child,
    this.radius = 22,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => ZyraFloatingSurface(
    radius: radius,
    child: Container(
      padding: padding,
      decoration: BoxDecoration(
        color: ZyraColors.surfaceFill,
        border: Border.all(
          color: ZyraColors.warmOverlay.withValues(alpha: .16),
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    ),
  );
}

class _CodeDivider extends StatelessWidget {
  const _CodeDivider(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    final text = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: ZyraText.subtext(size: 10).copyWith(letterSpacing: .8),
      ),
    );
    return Row(
      children: [
        Expanded(
          child: Divider(color: ZyraColors.warmOverlay.withValues(alpha: .13)),
        ),
        if (MediaQuery.textScalerOf(context).scale(10) > 15)
          Flexible(flex: 4, child: text)
        else
          text,
        Expanded(
          child: Divider(color: ZyraColors.warmOverlay.withValues(alpha: .13)),
        ),
      ],
    );
  }
}

class _CodeCameraFrame extends StatefulWidget {
  const _CodeCameraFrame({
    required this.side,
    required this.onTap,
    required this.live,
    required this.refused,
    required this.invalid,
    this.capture,
  });
  final double side;
  final VoidCallback? onTap;
  final Widget? capture;
  final bool live, refused, invalid;
  @override
  State<_CodeCameraFrame> createState() => _CodeCameraFrameState();
}

class _CodeCameraFrameState extends State<_CodeCameraFrame> {
  Timer? _timer;
  double _phase = 0;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final quiet =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context) ||
        !TickerMode.valuesOf(context).enabled;
    _timer?.cancel();
    if (quiet) {
      _phase = 0;
      return;
    }
    _timer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted ||
          !widget.live ||
          !(ModalRoute.of(context)?.isCurrent ?? true) ||
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        return;
      }
      setState(() => _phase = (_phase + .01) % 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey('local-code-camera'),
    label: 'ZYRA Code camera frame',
    button: widget.onTap != null,
    child: GestureDetector(
      onTap: ZyraTapFeedback.onTap(context, widget.onTap),
      child: SizedBox.square(
        dimension: widget.side,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: ColoredBox(
            color: widget.live ? const Color(0xFF1C1712) : ZyraColors.ivoryTop,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.capture != null) widget.capture!,
                if (!widget.live)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: math.max(1, widget.side - 36),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!widget.refused) ...[
                                const Icon(
                                  Icons.photo_camera,
                                  color: ZyraColors.journeyGold,
                                  size: 30,
                                ),
                                const SizedBox(height: 10),
                              ],
                              _CodeHelper(
                                widget.refused
                                    ? 'Camera is off — enter the code below'
                                    : 'Tap to scan their code',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (widget.invalid)
                  Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: ZyraColors.ivoryTop,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: _CodeHelper("This isn't a ZYRA Code"),
                      ),
                    ),
                  ),
                IgnorePointer(
                  child: CustomPaint(
                    painter: _CodeCorners(ZyraColors.journeyGold),
                  ),
                ),
                if (widget.live)
                  Positioned(
                    key: const ValueKey('local-code-scan-line'),
                    top:
                        37 +
                        (widget.side - 74) *
                            (1 - math.cos(_phase * math.pi * 2)) /
                            2,
                    left: 30,
                    right: 30,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ZyraColors.journeyGold.withValues(alpha: 0),
                            ZyraColors.journeyGold.withValues(alpha: .7),
                            ZyraColors.journeyGold.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _CodeCorners extends CustomPainter {
  const _CodeCorners(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    const inset = 15.0, length = 36.0, radius = 14.0;
    for (int i = 0; i < 4; i++) {
      canvas.save();
      canvas.translate(i.isOdd ? size.width : 0, i >= 2 ? size.height : 0);
      canvas.scale(i.isOdd ? -1 : 1, i >= 2 ? -1 : 1);
      canvas.drawPath(
        Path()
          ..moveTo(inset, inset + length)
          ..lineTo(inset, inset + radius)
          ..quadraticBezierTo(inset, inset, inset + radius, inset)
          ..lineTo(inset + length, inset),
        p,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CodeCorners oldDelegate) => oldDelegate.color != color;
}

class _CodeHelper extends StatelessWidget {
  const _CodeHelper(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    textAlign: TextAlign.center,
    style: ZyraText.subtext(size: 12.5),
  );
}
