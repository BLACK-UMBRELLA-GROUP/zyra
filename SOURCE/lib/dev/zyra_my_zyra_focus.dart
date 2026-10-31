// LOCK15 V2: local Focus event presentation and a status-only permission read.
import 'dart:async';
import 'package:flutter/material.dart';
import 'zyra_one_journey_phone_access.dart';

class ZyraFocusEvent {
  const ZyraFocusEvent({
    required this.tokens,
    required this.target,
    required this.title,
    required this.detail,
    required this.action,
    required this.icon,
    required this.occurredAt,
    this.personId,
    this.order = 0,
  });
  final List<String> tokens;
  final String target, title, detail, action;
  final String? personId;
  final IconData icon;
  final DateTime occurredAt;
  final int order;
}

String zyraFocusRequestNames(List<String> names) => switch (names.length) {
  0 => '',
  1 => names.first,
  2 => '${names[0]} and ${names[1]}',
  3 => '${names[0]}, ${names[1]} and ${names[2]}',
  _ => '${names[0]}, ${names[1]} and ${names.length - 2} others',
};

/// This observer never requests a permission or opens Settings. It releases
/// its controller on navigation so the Phone access page retains ownership.
class ZyraFocusPermissionStatus extends StatefulWidget {
  const ZyraFocusPermissionStatus({
    super.key,
    required this.canAct,
    required this.builder,
  });
  final bool Function() canAct;
  final Widget Function(bool? notificationsAllowed) builder;
  @override
  State<ZyraFocusPermissionStatus> createState() =>
      _ZyraFocusPermissionStatusState();
}

class _ZyraFocusPermissionStatusState extends State<ZyraFocusPermissionStatus> {
  late final ZyraPhoneAccessController _controller;
  @override
  void initState() {
    super.initState();
    _controller = ZyraPhoneAccessController(
      canAct: () => mounted && widget.canAct(),
    )..addListener(_changed);
    unawaited(_controller.refresh());
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(_controller.notificationPermissionAllowed);
}
