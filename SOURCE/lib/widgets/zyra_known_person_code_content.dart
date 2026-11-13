import '../models/zyra_code_format.dart';
import 'zyra_tap_feedback.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

/// Retained code-entry presentation with all lookup and action authority owned
/// by its caller. This widget does not resolve codes or create connections.
class ZyraKnownPersonCodePill extends StatelessWidget {
  const ZyraKnownPersonCodePill({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: ZyraColors.accentBg,
    borderRadius: BorderRadius.circular(999),
    child: InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: ZyraTapFeedback.onTap(context, onTap),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          border: Border.all(color: ZyraColors.accentBorder),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: ZyraColors.surfaceSignal),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: MediaQuery.textScalerOf(context).scale(12.5) > 18.75
                    ? null
                    : 1,
                overflow: MediaQuery.textScalerOf(context).scale(12.5) > 18.75
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: ZyraText.body(size: 12.5, color: ZyraColors.goldText),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Native camera capture only. Code lookup, admission and any result action
/// remain caller-owned; a captured prefix is not validation or payment proof.
///
/// Hosts must give this inline widget bounded camera-preview constraints and
/// rebuild or remove it when their capture authority changes.
class ZyraCodeCapture extends StatefulWidget {
  const ZyraCodeCapture({
    super.key,
    required this.canCapture,
    required this.onCode,
    required this.onManualEntry,
    this.framed = false,
    this.onRunningChanged,
    this.onRejected,
    this.unavailableMessage = 'Camera unavailable. Enter the code instead.',
  });

  final String unavailableMessage;
  final bool framed;
  final ValueChanged<bool>? onRunningChanged;
  final VoidCallback? onRejected;
  final bool Function() canCapture;
  final ValueChanged<String> onCode;
  final VoidCallback onManualEntry;

  @override
  State<ZyraCodeCapture> createState() => _ZyraCodeCaptureState();
}

class _ZyraCodeCaptureState extends State<ZyraCodeCapture>
    with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    autoStart: false,
    formats: const [BarcodeFormat.qrCode],
  );
  Future<void> _cameraWork = Future<void>.value();
  ModalRoute<dynamic>? _route;
  AppLifecycleState? _lifecycleState;
  bool _handled = false;
  bool _cameraFailed = false;
  bool? _reportedRunning;
  bool _disposed = false;
  bool _admissionRevoked = false;

  bool get _canAccept {
    if (!mounted ||
        _disposed ||
        _handled ||
        _admissionRevoked ||
        (_lifecycleState != null &&
            _lifecycleState != AppLifecycleState.resumed) ||
        !(_route?.isCurrent ?? false)) {
      return false;
    }
    try {
      if (widget.canCapture()) return true;
    } catch (_) {
      // A failed caller guard is a denial, never camera admission.
    }
    _admissionRevoked = true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    _lifecycleState = WidgetsBinding.instance.lifecycleState;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
    _scheduleCameraSync();
  }

  @override
  void didUpdateWidget(covariant ZyraCodeCapture oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleCameraSync();
  }

  void _scheduleCameraSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_disposed) _queueCameraSync();
    });
  }

  void _queueCameraSync() {
    if (_disposed) return;
    _cameraWork = _cameraWork.then((_) => _syncCamera());
  }

  Future<void> _syncCamera() async {
    if (_disposed || !mounted) return;
    try {
      if (_cameraFailed && widget.framed) {
        // Retrying mounts a new controller. Finish releasing this session
        // before the frame admits another tap.
        await _releaseController();
        if (!_disposed && mounted) _reportRunning(false);
        return;
      }
      if (!_canAccept || _cameraFailed) {
        _reportRunning(false);
        await _controller.stop();
        return;
      }
      await _controller.start();
      if (_disposed || !mounted) return;
      if (!_canAccept) {
        _reportRunning(false);
        await _controller.stop();
      } else if (_controller.value.error != null) {
        _showCameraFailure();
      } else {
        _reportRunning(_controller.value.isRunning);
      }
    } catch (_) {
      if (_canAccept) _showCameraFailure();
    }
  }

  void _showCameraFailure() {
    if (!mounted || _disposed || _cameraFailed) return;
    setState(() => _cameraFailed = true);
    _queueCameraSync();
  }

  void _reportRunning(bool running) {
    if (!widget.framed || _reportedRunning == running) return;
    _reportedRunning = running;
    widget.onRunningChanged?.call(running);
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_canAccept || _cameraFailed) return;
    var rejected = false;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.isEmpty) continue;
      final code = raw.length <= 200 ? ZyraCodeFormat.scanned(raw) : null;
      if (code == null) {
        rejected = true;
        continue;
      }
      _handled = true;
      _queueCameraSync();
      widget.onCode(code);
      return;
    }
    if (rejected) widget.onRejected?.call();
  }

  void _onManualEntry() {
    if (!_canAccept) return;
    _handled = true;
    _queueCameraSync();
    widget.onManualEntry();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.framed) _reportedRunning = null;
    _lifecycleState = state;
    _queueCameraSync();
  }

  Future<void> _disposeCamera() async {
    try {
      await _cameraWork;
    } catch (_) {
      // Disposal still releases the controller if queued camera work failed.
    }
    await _releaseController();
  }

  Future<void> _releaseController() async {
    try {
      await _controller.stop();
    } catch (_) {
      // A denied or detached camera may already be stopped.
    }
    try {
      await _controller.dispose();
    } catch (_) {
      // No camera failure may escape an already-disposed page.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_disposeCamera());
    super.dispose();
  }

  Widget _cameraFallback() => widget.framed
      ? const SizedBox.shrink()
      : ColoredBox(
          color: Colors.black,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.qr_code_scanner_rounded,
                    color: ZyraColors.surfaceSignal,
                    size: 30,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.unavailableMessage,
                    textAlign: TextAlign.center,
                    style: ZyraText.subtext(size: 12.5),
                  ),
                ],
              ),
            ),
          ),
        );

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      if (_cameraFailed)
        _cameraFallback()
      else
        MobileScanner(
          controller: _controller,
          useAppLifecycleState: false,
          onDetect: _onDetect,
          onDetectError: (_, _) {
            if (_canAccept) _showCameraFailure();
          },
          errorBuilder: (_, _) => _cameraFallback(),
        ),
      if (!widget.framed)
        Positioned(
          left: 24,
          right: 24,
          bottom: 24,
          child: SafeArea(
            top: false,
            child: ZyraKnownPersonCodePill(
              key: const ValueKey('known-person-camera-manual-entry'),
              icon: Icons.keyboard_outlined,
              label: 'Enter code instead',
              onTap: _canAccept ? _onManualEntry : null,
            ),
          ),
        ),
    ],
  );
}
