import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/zyra_code_link.dart';
import 'zyra_code_link_service.dart';

enum ZyraCodeLinkMemberRole { seeker, guardian }

typedef ZyraResolveCodeLink =
    Future<ZyraCodeLinkResult> Function(
      String code, {
      required bool Function() isCurrent,
    });

typedef ZyraOpenCodeLink =
    void Function(
      ZyraCodeLinkMemberRole role,
      String code,
      ZyraCodeLinkResult result,
    );

/// Holds a single incoming code in memory through sign-in and App Lock.
class ZyraCodeLinkCoordinator {
  ZyraCodeLinkCoordinator({this.resolve = ZyraCodeLinkService.resolve});

  static final instance = ZyraCodeLinkCoordinator();
  static const _channel = MethodChannel('app.zyraconnect.zyra/code_links');

  final ZyraResolveCodeLink resolve;
  String? Function()? _currentUser;
  bool Function()? _canPresent;
  VoidCallback? _showBadLink;
  ZyraOpenCodeLink? _open;
  _PendingCodeLink? _pending;
  bool _badLink = false;
  bool _scheduled = false;
  final _memberSurfaces = <Object, _MemberSurface>{};
  final _guardianSignups = <Object, _GuardianSignup>{};
  final _founderPreviews = <Object, _FounderPreview>{};

  void configure({
    required String? Function() currentUser,
    required bool Function() canPresent,
    required VoidCallback showBadLink,
    required ZyraOpenCodeLink open,
  }) {
    _currentUser = currentUser;
    _canPresent = canPresent;
    _showBadLink = showBadLink;
    _open = open;
    presentationChanged();
  }

  Future<void> listenToNative() async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openCodeLink' && call.arguments is String) {
        receive(call.arguments as String);
      }
    });
    try {
      final initial = await _channel.invokeMethod<String>(
        'takePendingCodeLink',
      );
      if (initial != null) receive(initial);
    } on MissingPluginException {
      // The code channel is available on iOS only.
    } on PlatformException {
      // The input is private. No platform payload goes to diagnostics.
    }
  }

  void receive(String link) {
    final code = parseZyraCodeLink(link);
    _pending = code == null
        ? null
        : _PendingCodeLink(code, _currentUser?.call());
    _badLink = code == null;
    presentationChanged();
  }

  void memberMounted(
    Object surface, {
    required ZyraCodeLinkMemberRole role,
    required String userId,
    required bool Function() isCurrent,
  }) {
    _memberSurfaces[surface] = (
      role: role,
      userId: userId,
      isCurrent: isCurrent,
    );
    presentationChanged();
  }

  void memberUnmounted(Object surface) {
    _memberSurfaces.remove(surface);
    presentationChanged();
  }

  void accountChanged(String? userId) {
    final pending = _pending;
    if (pending != null) {
      if (pending.userId == null) {
        pending.userId = userId;
      } else if (pending.userId != userId) {
        _pending = null;
      }
    }
    presentationChanged();
  }

  void guardianSignupMounted(
    Object surface, {
    required String userId,
    required bool Function() isCurrent,
    required void Function(String, ZyraCodeLinkResult) open,
  }) {
    _guardianSignups[surface] = (
      userId: userId,
      isCurrent: isCurrent,
      open: open,
    );
    presentationChanged();
  }

  void guardianSignupUnmounted(Object surface) {
    _guardianSignups.remove(surface);
    presentationChanged();
  }

  void founderPreviewMounted(
    Object surface, {
    required String userId,
    required bool Function() isCurrent,
    required ValueChanged<String> openUnknownCode,
  }) {
    _founderPreviews[surface] = (
      userId: userId,
      isCurrent: isCurrent,
      openUnknownCode: openUnknownCode,
    );
    presentationChanged();
  }

  void founderPreviewUnmounted(Object surface) {
    _founderPreviews.remove(surface);
    presentationChanged();
  }

  void presentationChanged() {
    if (_scheduled || (_pending == null && !_badLink)) return;
    _scheduled = true;
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      _scheduled = false;
      unawaited(_present());
    });
    binding.ensureVisualUpdate();
  }

  Future<void> _present() async {
    if (_canPresent?.call() != true) return;
    if (_badLink) {
      _badLink = false;
      _showBadLink?.call();
      return;
    }

    final pending = _pending;
    final user = _currentUser?.call();
    if (pending == null || user == null) return;
    if (pending.userId != null && pending.userId != user) {
      _pending = null;
      return;
    }
    final preview = _founderPreviews.values
        .where((surface) => surface.userId == user && surface.isCurrent())
        .lastOrNull;
    if (preview != null) {
      _pending = null;
      preview.openUnknownCode(pending.code);
      return;
    }
    final signup = _guardianSignups.values
        .where((surface) => surface.userId == user && surface.isCurrent())
        .lastOrNull;
    final member = _memberSurfaces.values
        .where((surface) => surface.userId == user && surface.isCurrent())
        .lastOrNull;
    final role = signup == null
        ? member?.role
        : ZyraCodeLinkMemberRole.guardian;
    if (role == null) return;

    bool isCurrent() =>
        identical(_pending, pending) && _currentUser?.call() == user;

    if (pending.checkedRole == null) {
      pending.checkedRole = role;
      pending.userId = user;
      final result = await resolve(pending.code, isCurrent: isCurrent);
      if (!isCurrent()) {
        if (identical(_pending, pending)) _pending = null;
        return;
      }
      pending.result = result;
      presentationChanged();
      return;
    }
    final result = pending.result;
    if (result == null || pending.checkedRole != role) return;

    _pending = null;
    if (signup != null) {
      signup.open(pending.code, result);
    } else {
      _open?.call(role, pending.code, result);
    }
  }
}

typedef _MemberSurface = ({
  ZyraCodeLinkMemberRole role,
  String userId,
  bool Function() isCurrent,
});

typedef _GuardianSignup = ({
  String userId,
  bool Function() isCurrent,
  void Function(String, ZyraCodeLinkResult) open,
});

typedef _FounderPreview = ({
  String userId,
  bool Function() isCurrent,
  ValueChanged<String> openUnknownCode,
});

class _PendingCodeLink {
  _PendingCodeLink(this.code, this.userId);

  final String code;
  String? userId;
  ZyraCodeLinkMemberRole? checkedRole;
  ZyraCodeLinkResult? result;
}
