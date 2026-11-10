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

  const ZyraErrorContent(this.title, this.message);
}

extension ZyraErrorKindContent on ZyraErrorKind {
  bool get needsSignIn =>
      this == ZyraErrorKind.sessionExpired ||
      this == ZyraErrorKind.previewAccess;

  ZyraErrorContent get content => switch (this) {
    ZyraErrorKind.page => const ZyraErrorContent(
      'We couldn’t open this page.',
      'Something didn’t load correctly.',
    ),
    ZyraErrorKind.offline => const ZyraErrorContent(
      'You’re offline.',
      'ZYRA needs an internet connection to open.',
    ),
    ZyraErrorKind.serviceUnavailable => const ZyraErrorContent(
      'ZYRA is taking a moment.',
      'This is on our side, not yours. Your account is safe.',
    ),
    ZyraErrorKind.sessionExpired ||
    ZyraErrorKind.previewAccess => const ZyraErrorContent(
      'Please sign in again.',
      'For your security, your session has ended.',
    ),
  };
}

/// Welcome's inline errors keep their established wording and classification.
String zyraInlineErrorMessageFor(Object error) => switch (_classify(
  error,
  inline: true,
)) {
  ZyraErrorKind.page => 'Something didn’t load correctly. Please try again.',
  ZyraErrorKind.offline => 'Check your connection, or try again shortly.',
  ZyraErrorKind.serviceUnavailable =>
    'We’re temporarily unavailable. Please try again shortly.',
  ZyraErrorKind.sessionExpired => 'For your security, please sign in again.',
  ZyraErrorKind.previewAccess =>
    'Please try again, or sign out to return to the welcome page.',
};

/// Maps internal failures without putting raw exceptions on screen.
ZyraErrorKind zyraErrorKindFor(Object error) => _classify(error);

ZyraErrorKind _classify(Object error, {bool inline = false}) {
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
  if (text.contains('network is unreachable') ||
      (!inline &&
          _containsAny(text, const [
            'not connected to the internet',
            'internet connection appears to be offline',
            'network is down',
          ]))) {
    return ZyraErrorKind.offline;
  }
  if (_containsAny(text, const [
    'socketexception',
    'failed host lookup',
    'network request failed',
    'connection refused',
    'connection reset',
    'connection closed',
    'no address associated',
  ])) {
    return inline ? ZyraErrorKind.offline : ZyraErrorKind.serviceUnavailable;
  }
  if (!inline && text.contains('handshakeexception')) {
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
