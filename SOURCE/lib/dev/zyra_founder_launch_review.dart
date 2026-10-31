// Internal launch attention, not a theme, approval or access-control service.
// Durable requirements and resolution evidence live in the governed files.
// Remove a current requirement only after its real deliverable is verified;
// never infer completion from typed text or expose a member-facing switch.
import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';

enum ZyraFounderLaunchRequirement {
  privacyPolicy,
  terms,
  resetSpecification,
  deletionSpecification,
}

class ZyraFounderLaunchReview {
  const ZyraFounderLaunchReview({
    this.outstanding = const {
      ZyraFounderLaunchRequirement.privacyPolicy,
      ZyraFounderLaunchRequirement.terms,
      ZyraFounderLaunchRequirement.resetSpecification,
      ZyraFounderLaunchRequirement.deletionSpecification,
    },
  });

  final Set<ZyraFounderLaunchRequirement> outstanding;

  // Explicit page metadata. Generic errors, held engineering work and optional
  // design proposals are not Founder-before-launch requirements.
  Set<ZyraFounderLaunchRequirement> pendingFor(
    String? pageId, {
    required bool internalReview,
  }) {
    if (!internalReview) return const {};
    final dependencies = switch (pageId) {
      'overview_privacyData' => const {
        ZyraFounderLaunchRequirement.privacyPolicy,
        ZyraFounderLaunchRequirement.terms,
      },
      'detail_privacyPolicy' => const {
        ZyraFounderLaunchRequirement.privacyPolicy,
      },
      'detail_terms' => const {ZyraFounderLaunchRequirement.terms},
      'overview_advanced' => const {
        ZyraFounderLaunchRequirement.resetSpecification,
        ZyraFounderLaunchRequirement.deletionSpecification,
      },
      'detail_resetProfile' => const {
        ZyraFounderLaunchRequirement.resetSpecification,
      },
      'detail_deleteAccount' => const {
        ZyraFounderLaunchRequirement.deletionSpecification,
      },
      _ => const <ZyraFounderLaunchRequirement>{},
    };
    return Set.unmodifiable(dependencies.intersection(outstanding));
  }
}

/// Only the admitted protected caller supplies pending metadata. Absence of
/// this scope preserves the normal selected app colours and shows no note.
/// No global palette or member preference is mutated, including on exit.
class ZyraFounderLaunchPageStyle extends InheritedWidget {
  const ZyraFounderLaunchPageStyle({
    super.key,
    required this.pending,
    required super.child,
  });

  final Set<ZyraFounderLaunchRequirement> pending;
  static const darkInk = ZyraColors.espresso;
  static const darkSecondaryInk = ZyraColors.secondaryText;
  static const darkGoldInk = Color(0xFF725A25);

  static Set<ZyraFounderLaunchRequirement> pendingOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ZyraFounderLaunchPageStyle>()
          ?.pending ??
      const {};
  static bool activeOf(BuildContext context) => pendingOf(context).isNotEmpty;
  static Color inkOf(BuildContext context) =>
      activeOf(context) ? darkInk : ZyraColors.foreground;
  static Color secondaryOf(BuildContext context) =>
      activeOf(context) ? darkSecondaryInk : ZyraColors.foregroundSecondary;
  static Color bodyOf(BuildContext context) =>
      activeOf(context) ? darkInk : ZyraColors.foregroundBody;
  static Color goldOf(BuildContext context) =>
      activeOf(context) ? darkGoldInk : ZyraColors.journeyGold;
  static Color surfaceOf(BuildContext context) =>
      activeOf(context) ? const Color(0xFFF5F3EF) : ZyraColors.surfaceFill;
  static Color borderOf(BuildContext context) =>
      activeOf(context) ? const Color(0xFFC3BBAE) : ZyraColors.surfaceBorder;

  static String noteFor(Set<ZyraFounderLaunchRequirement> pending) {
    final notes = <String>[];
    if (pending.contains(ZyraFounderLaunchRequirement.privacyPolicy)) {
      notes.add(
        'Provide the approved member Privacy Policy and its published link.',
      );
    }
    if (pending.contains(ZyraFounderLaunchRequirement.terms)) {
      notes.add('Provide the approved member Terms and their published link.');
    }
    if (pending.contains(ZyraFounderLaunchRequirement.resetSpecification)) {
      notes.add(
        'Approve the written Reset Profile specification, including shared history, retained data and recovery. Execution remains on hold.',
      );
    }
    if (pending.contains(ZyraFounderLaunchRequirement.deletionSpecification)) {
      notes.add(
        'Approve the written Delete Account specification, including relationships, retention, recovery and what others see. Execution remains on hold.',
      );
    }
    return notes.join(' ');
  }

  @override
  bool updateShouldNotify(ZyraFounderLaunchPageStyle oldWidget) =>
      pending.length != oldWidget.pending.length ||
      !pending.containsAll(oldWidget.pending);
}
