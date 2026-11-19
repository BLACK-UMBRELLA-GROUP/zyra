// LOCK 31 V2 / Q171: detached Needs-you examples from prototype V275.
// No account, transport, permission or setup-continuation authority lives here.
import 'package:flutter/material.dart';

import '../models/zyra_developer_preview.dart';
import 'zyra_my_zyra_focus.dart';

/// Only the existing Needs-you routes are addressed. The owning shell supplies
/// admission and the sample records behind each destination. Status chips are
/// separate; the future Finish setting up card is excluded until line 121.
List<ZyraFocusEvent> zyraDeveloperFocusPreset(
  ZyraDeveloperPreset preset, {
  required DateTime now,
}) {
  final keys = switch (preset) {
    ZyraDeveloperPreset.allCaughtUp ||
    ZyraDeveloperPreset.newMember => const <String>[],
    ZyraDeveloperPreset.typicalDay => const ['req', 'circle'],
    ZyraDeveloperPreset.everything => const [
      'leftj',
      'inact',
      'req',
      'reqs',
      'acc',
      'dec',
      'intro',
      'ready',
      'review',
      'mile',
      'circle',
      'gjoin',
      'ginv',
      'ended',
    ],
  };
  return List.unmodifiable([
    for (final (index, key) in keys.indexed)
      ZyraFocusEvent(
        tokens: ['developer-preset:${preset.name}:$key'],
        target: _items[key]!.target,
        title: _items[key]!.title,
        detail: _items[key]!.detail,
        action: _items[key]!.action,
        icon: _items[key]!.icon,
        occurredAt: now.toUtc(),
        order: keys.length - index,
      ),
  ]);
}

typedef _PresetItem = ({
  String target,
  String title,
  String detail,
  String action,
  IconData icon,
});

const Map<String, _PresetItem> _items = {
  'leftj': (
    target: 'journey_tab',
    title: 'One of your Journeys has ended',
    detail:
        'This profile is no longer active. Your place is free for a new Journey.',
    action: 'Open Journey',
    icon: Icons.history,
  ),
  'inact': (
    target: 'welcome_back',
    title: 'Welcome back, Adam',
    detail:
        'You were away for a while. Your Ended Journeys are kept — nothing was removed.',
    action: 'View Ended Journeys',
    icon: Icons.history,
  ),
  'req': (
    target: 'requests',
    title: 'Journey request from Amira',
    detail: 'Amira would like to begin a Journey with you.',
    action: 'View request',
    icon: Icons.mail_outline,
  ),
  'reqs': (
    target: 'requests',
    title: '3 Journey requests',
    detail: 'Amira, Sara and Noor would like to begin a Journey with you.',
    action: 'View requests',
    icon: Icons.mail_outline,
  ),
  'acc': (
    target: 'journey_tab',
    title: 'Sara accepted your Journey request',
    detail: 'Review the next step before beginning together.',
    action: 'View Journey',
    icon: Icons.check,
  ),
  'dec': (
    target: 'requests_past',
    title: 'Aisha declined your Journey request',
    detail: 'The request is closed. No Journey has begun.',
    action: 'View request',
    icon: Icons.close,
  ),
  'intro': (
    target: 'introductions',
    title: 'Hassan introduced Noor',
    detail: 'Review the person your Guardian has put forward.',
    action: 'View introduction',
    icon: Icons.groups_outlined,
  ),
  'ready': (
    target: 'journey_tab',
    title: 'Your Journey with Maryam is ready to continue',
    detail: 'Open the Journey to review its next step together.',
    action: 'Continue Journey',
    icon: Icons.people_outline,
  ),
  'review': (
    target: 'journey_tab',
    title: 'Family Review opened',
    detail: 'Your Guardians are reviewing your Journey with Sara.',
    action: 'View Journey',
    icon: Icons.verified_user_outlined,
  ),
  'mile': (
    target: 'journey_tab',
    title: 'Milestone to confirm',
    detail: 'Confirm the step you and Sara reached.',
    action: 'Open Timeline',
    icon: Icons.check,
  ),
  'circle': (
    target: 'guardian_circle',
    title: 'New message in Guardian Circle',
    detail: 'Hassan has added to your Circle conversation.',
    action: 'Open Circle',
    icon: Icons.forum_outlined,
  ),
  'gjoin': (
    target: 'guardian',
    title: 'Yusuf joined your Guardians',
    detail: 'Review the confirmed Guardian link.',
    action: 'View Guardian',
    icon: Icons.verified_user_outlined,
  ),
  'ginv': (
    target: 'guardian',
    title: 'Guardian invitation expiring',
    detail: 'Your invitation to Yusuf ends soon.',
    action: 'View Guardian',
    icon: Icons.verified_user_outlined,
  ),
  'ended': (
    target: 'ended',
    title: 'Your Journey with Noor has ended',
    detail: 'It stays in your read-only Ended Journeys.',
    action: 'View Ended Journeys',
    icon: Icons.history,
  ),
};
