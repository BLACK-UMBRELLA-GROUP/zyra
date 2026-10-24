// ARCHIVED COPY — RETIRED MODULE (OA-ZYRA-251, 2026-08-23).
//
// This file was retired when the D14 Guardian Network replaced the
// 2026-08-22 first-draft preview model (see ZYRA_GUARDIAN_NETWORK_
// CURRENT_VERSION_V2.md §D14 and ZYRA_GN_HANDOVER_CURRENT_VERSION_V1.md).
// Its "suggested/passed" vocabulary and plan/scene enums are SUPERSEDED
// by GNContext / GNScene / GNStage in lib/screens/wali/wali_gn_shared.dart.
//
// PROVENANCE NOTE: the live module was deleted from lib/dev/ during the
// 2026-08-23 concurrent cleanup (Codex side) before Fable's archive move
// ran; this copy is a byte-faithful reconstruction from Fable's same-day
// read of the file. Its companion test (guardian_network_preview_test.dart,
// 115 lines) was deleted in the same cleanup before it could be read —
// recoverable from git history if ever needed; it covered only this
// retired module. Nothing below is current.
// ─────────────────────────────────────────────────────────────────────────

/// Reversible Guardian Network design states.
///
/// These types deliberately live under `dev/`: the Founder can walk the
/// proposed experience before Guardian Network eligibility, visibility and
/// action authority are ratified. Nothing in this file is a database rule,
/// entitlement grant or production permission.

library;

enum GuardianNetworkPreviewPlan { basic, one }

extension GuardianNetworkPreviewPlanX on GuardianNetworkPreviewPlan {
  String get label => switch (this) {
    GuardianNetworkPreviewPlan.basic => 'Basic',
    GuardianNetworkPreviewPlan.one => 'ZYRA One',
  };
}

enum GuardianNetworkPreviewScene {
  recommendations,
  empty,
  suggested,
  passed,
  capacity,
  loading,
  error,
}

extension GuardianNetworkPreviewSceneX on GuardianNetworkPreviewScene {
  String get label => switch (this) {
    GuardianNetworkPreviewScene.recommendations => 'Recommendations',
    GuardianNetworkPreviewScene.empty => 'Empty',
    GuardianNetworkPreviewScene.suggested => 'Suggested',
    GuardianNetworkPreviewScene.passed => 'Passed',
    GuardianNetworkPreviewScene.capacity => 'At capacity',
    GuardianNetworkPreviewScene.loading => 'Loading',
    GuardianNetworkPreviewScene.error => 'Error',
  };
}

enum GuardianNetworkCardDecision { undecided, suggested, passed }

/// Mock information chosen to exercise hierarchy and privacy restraint.
///
/// The values are not a claim that these exact fields will be disclosed in
/// production. The preview screen labels them as provisional and never sends
/// them to a service.
class GuardianNetworkPreviewRecommendation {
  final String id;
  final String firstName;
  final int age;
  final String region;
  final String familyContext;
  final List<String> reasons;

  const GuardianNetworkPreviewRecommendation({
    required this.id,
    required this.firstName,
    required this.age,
    required this.region,
    required this.familyContext,
    required this.reasons,
  });
}

const guardianNetworkPreviewRecommendations = [
  GuardianNetworkPreviewRecommendation(
    id: 'network-bilal',
    firstName: 'Bilal',
    age: 29,
    region: 'West Midlands',
    familyContext: 'Guardian represented',
    reasons: [
      'Within current preferences',
      'Eligible to be introduced',
      'Strong overall alignment',
    ],
  ),
  GuardianNetworkPreviewRecommendation(
    id: 'network-maryam',
    firstName: 'Maryam',
    age: 27,
    region: 'Greater London',
    familyContext: 'Guardian represented',
    reasons: [
      'Within current preferences',
      'Eligible to be introduced',
      'Currently available',
    ],
  ),
  GuardianNetworkPreviewRecommendation(
    id: 'network-idris',
    firstName: 'Idris',
    age: 31,
    region: 'North West',
    familyContext: 'Guardian represented',
    reasons: [
      'Within current preferences',
      'Eligible to be introduced',
      'Strong overall alignment',
    ],
  ),
  GuardianNetworkPreviewRecommendation(
    id: 'network-safiya',
    firstName: 'Safiya',
    age: 26,
    region: 'Yorkshire',
    familyContext: 'Guardian represented',
    reasons: [
      'Within current preferences',
      'Eligible to be introduced',
      'Currently available',
    ],
  ),
  GuardianNetworkPreviewRecommendation(
    id: 'network-yusuf',
    firstName: 'Yusuf',
    age: 30,
    region: 'East Midlands',
    familyContext: 'Guardian represented',
    reasons: [
      'Within current preferences',
      'Eligible to be introduced',
      'Strong overall alignment',
    ],
  ),
  GuardianNetworkPreviewRecommendation(
    id: 'network-khadija',
    firstName: 'Khadija',
    age: 28,
    region: 'South East',
    familyContext: 'Guardian represented',
    reasons: [
      'Within current preferences',
      'Eligible to be introduced',
      'Currently available',
    ],
  ),
];
