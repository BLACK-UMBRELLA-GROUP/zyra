// App-stopping error states shared by routing, startup and presentation.
//
// These are deliberately separate from inline field errors, banners and
// honest empty states. A full-screen error is reserved for a route or app
// surface that cannot be opened at all.

import 'dart:async';

import 'package:flutter/foundation.dart';

enum ZyraErrorKind {
  page,
  offline,
  serviceUnavailable,
  sessionExpired,
  previewAccess,
}

/// A protected preview must never fall through to ordinary member data when
/// fresh authorization is unavailable. This error offers an explicit recovery.
class ZyraPreviewAuthorizationException implements Exception {
  const ZyraPreviewAuthorizationException();

  @override
  String toString() => 'Local preview authorization could not be verified.';
}

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
      title: 'We couldn’t connect to ZYRA.',
      message: 'Check your connection, or try again shortly.',
      primaryLabel: 'Try again',
      secondaryLabel: 'Return to welcome',
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
    ZyraErrorKind.previewAccess => const ZyraErrorContent(
      title: 'Couldn’t open this page.',
      message: 'Please try again, or sign out to return to the welcome page.',
      primaryLabel: 'Try again',
      secondaryLabel: 'Sign out',
    ),
  };
}

/// Maps an internal failure to one of the four user-facing states without
/// ever putting the raw exception on screen.
ZyraErrorKind zyraErrorKindFor(Object error) {
  if (error is ZyraPreviewAuthorizationException) {
    return ZyraErrorKind.previewAccess;
  }
  // A timed-out operation can be local storage or a slow service. It is not
  // evidence that the member's device is offline.
  if (error is TimeoutException) return ZyraErrorKind.serviceUnavailable;

  final text = '${error.runtimeType}: $error'.toLowerCase();
  if (_containsAny(text, const [
    'invalid refresh token',
    'refresh token is invalid',
    'refresh token has expired',
    'refresh token is expired',
    'refresh token expired',
    'refresh token not found',
    'refresh token was not found',
    'refresh token already used',
    'refresh token has already been used',
    'refresh token has been reused',
    'refresh_token_not_found',
    'refresh_token_already_used',
    'refresh_token_invalid',
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
    'service unavailable',
    'bad gateway',
    'gateway timeout',
    'internal server error',
    'statuscode: 500',
    'statuscode: 502',
    'statuscode: 503',
    'statuscode: 504',
    'status: 500',
    'status: 502',
    'status: 503',
    'status: 504',
  ])) {
    return ZyraErrorKind.serviceUnavailable;
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
  ])) {
    return ZyraErrorKind.offline;
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
