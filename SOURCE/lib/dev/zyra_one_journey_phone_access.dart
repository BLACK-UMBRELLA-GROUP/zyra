import '../widgets/zyra_floating_surface.dart';
// LOCK12 V2: real device permissions inside the admitted Founder shell.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/zyra_account_state.dart';
import '../services/zyra_app_lock.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_tap_feedback.dart';

const zyraPhoneAccessChannel = MethodChannel(
  'app.zyraconnect.zyra/phone_access',
);

enum ZyraPhonePermission { location, notifications, photos, camera, faceID }

class ZyraPhoneAccessController extends ChangeNotifier
    with WidgetsBindingObserver {
  ZyraPhoneAccessController({required this.canAct, ZyraAppLock? appLock})
    : _lock = appLock ?? ZyraAppLock.instance,
      _owner = (ZyraAccountState.userId, ZyraAccountState.generation) {
    _channelOwner?._cancel();
    _channelOwner = this;
    WidgetsBinding.instance.addObserver(this);
    _lock.addListener(_lockChanged);
  }
  static ZyraPhoneAccessController? _channelOwner;
  final bool Function() canAct;
  final ZyraAppLock _lock;
  final (String?, int) _owner;
  final _statuses = <String, String>{};
  bool _disposed = false,
      _revoked = false,
      _foreground = true,
      _inactive = false;
  bool _busy = false;
  int _epoch = 0;
  bool get busy => _busy;
  bool get _current {
    if (_disposed || _revoked || _channelOwner != this) return false;
    if (!canAct() ||
        ZyraAccountState.isSigningOut ||
        _owner != (ZyraAccountState.userId, ZyraAccountState.generation)) {
      _revoked = true;
      _cancel();
      return false;
    }
    return true;
  }

  void _lockChanged() {
    if (!_disposed && _current) notifyListeners();
  }

  Future<Object?> _call(String method, [Object? arguments]) async {
    try {
      return await zyraPhoneAccessChannel.invokeMethod<Object?>(
        method,
        arguments,
      );
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  bool _valid(int epoch) => _current && _foreground && epoch == _epoch;
  Future<void> refresh() async {
    if (!_current || !_foreground || _inactive || _busy) return;
    final epoch = ++_epoch;
    final result = await _call('status', {'appLockEnabled': _lock.enabled});
    if (!_valid(epoch) || _inactive) return;
    _statuses.clear();
    if (result is Map) {
      for (final permission in ZyraPhonePermission.values) {
        final value = result[permission.name];
        if (value is String) _statuses[permission.name] = value;
      }
    }
    notifyListeners();
  }

  String label(ZyraPhonePermission permission) {
    if (!_current || !_foreground) {
      return permission == ZyraPhonePermission.faceID ? 'Off' : 'Ask first';
    }
    if (permission == ZyraPhonePermission.faceID) {
      return _lock.enabled ? 'On' : 'Off';
    }
    return switch (_statuses[permission.name]) {
      'allowed' =>
        permission == ZyraPhonePermission.location
            ? 'While using'
            : permission == ZyraPhonePermission.photos
            ? 'All photos'
            : 'Allowed',
      'limited' => 'Selected photos',
      'denied' || 'restricted' => 'Off',
      _ => 'Ask first',
    };
  }

  bool allowed(ZyraPhonePermission permission) =>
      _current &&
      _foreground &&
      (permission == ZyraPhonePermission.faceID
          ? _lock.enabled
          : const ['allowed', 'limited'].contains(_statuses[permission.name]));

  // Unknown or unavailable platform status is not reported as "off".
  bool? get notificationPermissionAllowed {
    if (!_current || !_foreground) return null;
    final status = _statuses['notifications'];
    return switch (status) {
      'allowed' || 'limited' => true,
      'denied' || 'restricted' || 'notDetermined' => false,
      _ => null,
    };
  }

  Future<void> activate(ZyraPhonePermission permission) async {
    if (!_current || !_foreground || _inactive || _busy) return;
    final epoch = ++_epoch;
    _busy = true;
    notifyListeners();
    try {
      // Re-read immediately before every action. Never trust a saved UI pill.
      final result = await _call('status', {'appLockEnabled': _lock.enabled});
      if (!_valid(epoch) || _inactive || result is! Map) return;
      final status = result[permission.name];
      if (status == 'notDetermined') {
        await _call('request', {'permission': permission.name});
      } else if (status != null && status != 'unavailable') {
        await _call('openSettings');
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        _busy = false;
        if (_current) notifyListeners();
        // A system prompt can finish while inactive; resumed performs the read.
        if (_current && _foreground && !_inactive) await refresh();
      }
    }
  }

  void _cancel() {
    _epoch++;
    _statuses.clear();
    _busy = false;
    if (_channelOwner == this) unawaited(_call('cancel'));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;
    if (state == AppLifecycleState.inactive) {
      _inactive = true;
    } else if (state == AppLifecycleState.resumed) {
      _inactive = false;
      _foreground = true;
      unawaited(refresh());
    } else {
      _inactive = false;
      _foreground = false;
      _cancel();
    }
  }

  @override
  void dispose() {
    _cancel();
    _disposed = true;
    if (_channelOwner == this) _channelOwner = null;
    _lock.removeListener(_lockChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class ZyraPhoneAccessPage extends StatefulWidget {
  const ZyraPhoneAccessPage({
    super.key,
    required this.canAct,
    required this.onBack,
  });
  final bool Function() canAct;
  final VoidCallback onBack;
  @override
  State<ZyraPhoneAccessPage> createState() => _ZyraPhoneAccessPageState();
}

class _ZyraPhoneAccessPageState extends State<ZyraPhoneAccessPage> {
  late final ZyraPhoneAccessController _controller;
  @override
  void initState() {
    super.initState();
    _controller = ZyraPhoneAccessController(
      canAct: () => mounted && widget.canAct(),
    );
    unawaited(_controller.refresh());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ZyraPhoneAccessPresentation(
    controller: _controller,
    onBack: widget.onBack,
  );
}

class ZyraPhoneAccessPresentation extends StatelessWidget {
  const ZyraPhoneAccessPresentation({
    super.key,
    required this.controller,
    required this.onBack,
  });
  final ZyraPhoneAccessController controller;
  final VoidCallback onBack;
  static const rows =
      <
        ({
          ZyraPhonePermission permission,
          IconData icon,
          String name,
          String why,
        })
      >[
        (
          permission: ZyraPhonePermission.location,
          icon: Icons.location_on_outlined,
          name: 'Location',
          why:
              'Distance in Filters. Only your approximate area is used — never shown to anyone.',
        ),
        (
          permission: ZyraPhonePermission.notifications,
          icon: Icons.notifications_outlined,
          name: 'Notifications',
          why: 'Requests, Journey and Guardian updates.',
        ),
        (
          permission: ZyraPhonePermission.photos,
          icon: Icons.photo_library_outlined,
          name: 'Photos',
          why:
              'Choosing your profile photos. ZYRA only sees the ones you pick.',
        ),
        (
          permission: ZyraPhonePermission.camera,
          icon: Icons.photo_camera_outlined,
          name: 'Camera',
          why: 'Scanning ZYRA Codes, taking photos and the identity check.',
        ),
        (
          permission: ZyraPhonePermission.faceID,
          icon: Icons.face_outlined,
          name: 'Face ID',
          why: 'Opening ZYRA when App lock is on.',
        ),
      ];
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: SafeArea(
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => ListView(
          key: const ValueKey('phone_access_scroll'),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text('Phone access', style: ZyraText.heading(size: 28)),
            const SizedBox(height: 16),
            Text(
              'What ZYRA can use on this phone.',
              style: ZyraText.heading(size: 22),
            ),
            const SizedBox(height: 18),
            ZyraFloatingSurface(
              radius: 20,
              child: Container(
                key: const ValueKey('phone_access_card'),
                decoration: BoxDecoration(
                  color: ZyraColors.surfaceFill,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ZyraColors.surfaceBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < rows.length; i++) ...[
                      if (i > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Divider(
                            height: 1,
                            color: ZyraColors.foreground.withValues(alpha: .08),
                          ),
                        ),
                      _row(context, rows[i]),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                "Your phone decides these. Tap one to change it in your phone's Settings. ZYRA asks for each one only when you first need it.",
                style: ZyraText.subtext(size: 12, color: ZyraColors.ink(.65)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _row(
    BuildContext context,
    ({ZyraPhonePermission permission, IconData icon, String name, String why})
    row,
  ) {
    final gold = controller.allowed(row.permission);
    final color = gold ? ZyraColors.journeyGold : ZyraColors.ink(.65);
    return InkWell(
      key: ValueKey('phone_access_${row.permission.name}'),
      onTap: controller.busy
          ? null
          : ZyraTapFeedback.onTap(
              context,
              () => controller.activate(row.permission),
            ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(row.icon, size: 22, color: ZyraColors.journeyGold),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row.name, style: ZyraText.body(size: 15)),
                  const SizedBox(height: 4),
                  Text(
                    row.why,
                    style: ZyraText.subtext(
                      size: 12,
                      color: ZyraColors.ink(.70),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              key: ValueKey('phone_access_status_${row.permission.name}'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withValues(alpha: gold ? .65 : .25),
                ),
              ),
              child: Text(
                controller.label(row.permission),
                style: ZyraText.body(
                  size: 11.5,
                  color: gold ? ZyraColors.goldText : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
