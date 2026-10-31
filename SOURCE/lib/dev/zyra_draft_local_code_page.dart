import '../widgets/zyra_floating_surface.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    );

/// LOCK 9's shared local presentation. It owns no service, invitation, link,
/// profile navigation or Main Guardian callback. Lookup receives only a
/// canonical fictional code from the explicit context-specific alias table.
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
    this.onQr,
    this.onShare,
    this.extra,
    this.captureBuilder,
  });
  final ZyraLocalCodeContext mode;
  final bool Function() canAct;
  final bool Function()? canInteract;
  final Object Function()? interactionEpoch;
  final Object ownerKey;
  final Future<ZyraLocalCodeIdentity?> Function(String) lookupCode;
  final String? personalCode;
  final VoidCallback? onCopy, onQr, onShare;
  final Widget? extra;
  final ZyraLocalCaptureBuilder? captureBuilder;

  @override
  State<ZyraLocalCodePage> createState() => _ZyraLocalCodePageState();
}

class _ZyraLocalCodePageState extends State<ZyraLocalCodePage>
    with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _resultKey = GlobalKey();
  ZyraLocalCodeIdentity? _person;
  String? _error;
  bool _busy = false, _sent = false, _closed = false, _camera = false;
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
    ++_cameraRevision;
    _person = null;
    _busy = _sent = _camera = false;
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
          _person = null;
          _busy = _sent = false;
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
      _busy = _sent = false;
    });
  }

  Future<void> _checkLocal() async {
    if (!_current() || _busy) return;
    final entry = _controller.text;
    if (entry.length != 20) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter all 20 characters.')));
      return;
    }
    final epoch = _epoch();
    final revision = ++_revision;
    final canonical = ZyraLocalCodeAliases.canonical(widget.mode, entry);
    setState(() {
      _busy = true;
      _person = null;
      _sent = false;
      _error = null;
    });
    ZyraLocalCodeIdentity? person;
    bool failed = false;
    try {
      if (canonical != null) {
        person = await widget
            .lookupCode(canonical)
            .timeout(const Duration(seconds: 10));
      }
    } catch (_) {
      failed = true;
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
        _error = failed
            ? "The code couldn't be checked. Please try again."
            : widget.mode == ZyraLocalCodeContext.scan
            ? 'That code is not available.'
            : 'Invalid code. Please try again.';
      }
    });
    _focus.unfocus();
    _reveal();
  }

  void _reveal() => WidgetsBinding.instance.addPostFrameCallback((_) {
    final target = _resultKey.currentContext;
    if (_current() && target != null) {
      Scrollable.ensureVisible(
        target,
        alignment: 1,
        duration: const Duration(milliseconds: 220),
      );
    }
  });

  void _send(int revision, Object? epoch) {
    if (!_current(epoch) || revision != _revision || _person == null || _sent) {
      return;
    }
    setState(() => _sent = true);
    _reveal();
  }

  Widget? _capture() {
    if (!_camera || widget.captureBuilder == null) return null;
    final revision = _cameraRevision;
    final epoch = _epoch();
    bool current() => _current(epoch) && _camera && revision == _cameraRevision;
    return widget.captureBuilder!(
      context,
      current,
      (raw) {
        if (!current()) return;
        final entry = ZyraLocalCodeAliases.entry(widget.mode, raw);
        setState(() {
          ++_cameraRevision;
          _camera = false;
          _controller.text = entry ?? '';
          _invalidate();
        });
        if (entry == null) {
          setState(() => _error = 'That code is not available.');
        } else {
          _checkLocal();
        }
      },
      () {
        if (!current()) return;
        setState(() {
          ++_cameraRevision;
          _camera = false;
        });
        _focus.requestFocus();
      },
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

  @override
  Widget build(BuildContext context) {
    if (!_ownerAllows()) return const SizedBox.shrink();
    final scan = widget.mode == ZyraLocalCodeContext.scan;
    final person = _person;
    return SafeArea(
      child: ZyraShadowScrollView(
        key: const ValueKey('local-code-scroll'),
        padding: EdgeInsets.fromLTRB(21, scan ? 18 : 18, 21, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              scan
                  ? 'Scan'
                  : widget.mode == ZyraLocalCodeContext.addGuardian
                  ? 'Add a Guardian'
                  : 'Add a Seeker',
              textAlign: scan ? TextAlign.left : TextAlign.center,
              style: ZyraText.heading(size: scan ? 28 : 18),
            ),
            SizedBox(height: scan ? 20 : 16),
            if (scan) ...[
              Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ZyraColors.journeyGold.withValues(alpha: .6),
                    ),
                  ),
                  child: Icon(
                    Icons.person_search_outlined,
                    size: 27,
                    color: ZyraColors.journeyGold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Already know someone?',
                textAlign: TextAlign.center,
                style: ZyraText.heading(size: 22),
              ),
              const SizedBox(height: 5),
              Text(
                'Scan or enter their ZYRA Code to find their profile.',
                textAlign: TextAlign.center,
                style: ZyraText.subtext(size: 12),
              ),
              const SizedBox(height: 20),
            ] else ...[
              _CodeGlass(
                child: Column(
                  children: [
                    Text(
                      'YOUR ZYRA CODE',
                      style: ZyraText.subtext(
                        size: 10,
                      ).copyWith(letterSpacing: .8),
                    ),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.personalCode ?? '',
                        style: ZyraText.heading(size: 20).copyWith(height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'They can send a request. You still choose whether to link.',
                      textAlign: TextAlign.center,
                      style: ZyraText.subtext(size: 12),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        for (final action in [
                          ('Copy', widget.onCopy),
                          ('QR', widget.onQr),
                          ('Share', widget.onShare),
                        ]) ...[
                          if (action.$1 != 'Copy') const SizedBox(width: 8),
                          Expanded(
                            child: _CodeAction(
                              key: ValueKey(
                                'local-code-${action.$1.toLowerCase()}',
                              ),
                              label: action.$1,
                              gold: false,
                              onTap: action.$2 == null
                                  ? null
                                  : _bound(action.$2!),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const _CodeDivider('OR USE THEIR CODE'),
              const SizedBox(height: 14),
            ],
            Center(
              child: LayoutBuilder(
                builder: (context, constraints) => _CodeCameraFrame(
                  side: math.min(
                    math.max(
                      160,
                      (scan ? 250 : 190) /
                          MediaQuery.textScalerOf(
                            context,
                          ).scale(1).clamp(1, 1.5),
                    ),
                    constraints.maxWidth,
                  ),
                  capture: _capture(),
                  onTap: widget.captureBuilder == null
                      ? null
                      : _bound(
                          () => setState(() {
                            ++_cameraRevision;
                            _camera = true;
                          }),
                        ),
                ),
              ),
            ),
            SizedBox(height: scan ? 17 : 14),
            _CodeDivider(scan ? 'OR ENTER THEIR CODE' : 'OR ENTER IT'),
            const SizedBox(height: 9),
            _CodeBoxes(
              controller: _controller,
              focus: _focus,
              mode: widget.mode,
              onChanged: _changed,
              onCheck: _bound(_checkLocal),
              onFocus: _bound(_focus.requestFocus),
            ),
            const SizedBox(height: 18),
            _CodeAction(
              key: const ValueKey('local-code-check'),
              label: _busy ? 'Checking…' : 'Check code',
              onTap: _busy ? null : _bound(_checkLocal),
            ),
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
                                  'Request sent',
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
                      if (_sent)
                        Text(
                          '${person.firstName} chooses whether to link. You’ll see them in ${widget.mode == ZyraLocalCodeContext.addGuardian ? 'Guardians' : 'Seekers'} once they accept.',
                          style: ZyraText.subtext(
                            size: 12,
                          ).copyWith(height: 1.5),
                        )
                      else
                        _CodeAction(
                          key: const ValueKey('local-code-send'),
                          label: 'Send request',
                          onTap: _bound(() => _send(_revision, _epoch())),
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
                  key: _resultKey,
                  style: ZyraText.subtext(size: 12),
                ),
              ),
            if (widget.extra != null) widget.extra!,
          ],
        ),
      ),
    );
  }
}

class _LocalCodeFormatter extends TextInputFormatter {
  const _LocalCodeFormatter(this.mode);
  final ZyraLocalCodeContext mode;
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final known = ZyraLocalCodeAliases.entry(mode, newValue.text);
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
    required this.mode,
    required this.onChanged,
    required this.onCheck,
    required this.onFocus,
  });
  final TextEditingController controller;
  final FocusNode focus;
  final ZyraLocalCodeContext mode;
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
              inputFormatters: [_LocalCodeFormatter(mode)],
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
                  const SizedBox(width: 18),
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
                  const SizedBox(width: 18),
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
          constraints: BoxConstraints(minHeight: gold ? 52 : 42),
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
  const _CodeGlass({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ZyraFloatingSurface(
    radius: 22,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ZyraColors.surfaceFill,
        border: Border.all(
          color: ZyraColors.warmOverlay.withValues(alpha: .16),
        ),
        borderRadius: BorderRadius.circular(22),
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
    this.capture,
  });
  final double side;
  final VoidCallback? onTap;
  final Widget? capture;
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
            color: ZyraColors.avatarWarmSand,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.capture != null)
                  widget.capture!
                else
                  Center(
                    child: Text(
                      'Point at their ZYRA Code',
                      textAlign: TextAlign.center,
                      style: ZyraText.body(size: 12),
                    ),
                  ),
                IgnorePointer(
                  child: CustomPaint(
                    painter: _CodeCorners(ZyraColors.journeyGold),
                  ),
                ),
                if (widget.capture == null)
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
