// App-stopping error states shared by routing, startup and presentation.
//
// These are deliberately separate from inline field errors, banners and
// honest empty states. A full-screen error is reserved for a route or app
// surface that cannot be opened at all.

import 'dart:async';

import 'package:flutter/foundation.dart';

enum ZyraErrorKind { page, offline, serviceUnavailable, sessionExpired }

@immutable
class ZyraErrorContent {
  final String title;
  final String message;
  final String primaryLabel;
  final String secondaryLabel;

  const ZyraErrorContent({
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.secondaryLabel,
  });
}

extension ZyraErrorKindContent on ZyraErrorKind {
  ZyraErrorContent get content => switch (this) {
    ZyraErrorKind.page => const ZyraErrorContent(
      title: 'We couldn’t open this page.',
      message: 'Something didn’t load correctly. Please try again.',
      primaryLabel: 'Try again',
      secondaryLabel: 'Return home',
    ),
    ZyraErrorKind.offline => const ZyraErrorContent(
      title: 'You appear to be offline.',
      message: 'Check your connection, then try again.',
      primaryLabel: 'Try again',
      secondaryLabel: 'Return home',
    ),
    ZyraErrorKind.serviceUnavailable => const ZyraErrorContent(
      title: 'ZYRA is taking a moment.',
      message: 'We’re temporarily unavailable. Please try again shortly.',
      primaryLabel: 'Try again',
      secondaryLabel: 'Return home',
    ),
    ZyraErrorKind.sessionExpired => const ZyraErrorContent(
      title: 'Your session has ended.',
      message: 'For your security, please sign in again.',
      primaryLabel: 'Sign in again',
      secondaryLabel: 'Return to welcome',
    ),
  };
}

/// Maps an internal failure to one of the four user-facing states without
/// ever putting the raw exception on screen.
ZyraErrorKind zyraErrorKindFor(Object error) {
  if (error is TimeoutException) return ZyraErrorKind.offline;

  final text = '${error.runtimeType}: $error'.toLowerCase();
  if (_containsAny(text, const [
    'refresh token',
    'invalid jwt',
    'jwt expired',
    'token has expired',
    'session expired',
    'statuscode: 401',
    'status: 401',
  ])) {
    return ZyraErrorKind.sessionExpired;
  }
  if (_containsAny(text, const [
    'socketexception',
    'failed host lookup',
    'network is unreachable',
    'network request failed',
    'connection refused',
    'connection reset',
    'connection closed',
    'no address associated',
    'clientexception',
  ])) {
    return ZyraErrorKind.offline;
  }
  if (_containsAny(text, const [
    'service unavailable',
    'bad gateway',
    'gateway timeout',
    'internal server error',
    'statuscode: 502',
    'statuscode: 503',
    'statuscode: 504',
    'status: 502',
    'status: 503',
    'status: 504',
  ])) {
    return ZyraErrorKind.serviceUnavailable;
  }
  return ZyraErrorKind.page;
}

bool _containsAny(String text, List<String> needles) =>
    needles.any(text.contains);

/// An opaque, non-sensitive code the member can quote to support. The same
/// error object produces the same code while its screen remains mounted.
String zyraErrorReference(Object error) {
  final value = Object.hash(error.runtimeType, error.hashCode) & 0xFFFFF;
  return 'ZY-${value.toRadixString(36).toUpperCase().padLeft(4, '0')}';
}
