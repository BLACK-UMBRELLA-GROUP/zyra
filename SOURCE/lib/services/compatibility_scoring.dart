// Compatibility scoring — v1 DRAFT PROPOSAL, not a ratified product
// decision.
//
// ZYRA's own docs flag this as an open dependency: References.md lists
// "Compatibility scoring algorithm not yet designed" and "Green / Amber
// / Red compatibility rating system not yet built." There is no
// approved design to implement faithfully, unlike the rest of this
// build (which transcribes real specs). This file is a reasonable
// starting point so Matches/Browse have *something* real to rank
// candidates by, but it should be reviewed and either ratified,
// amended, or replaced via a real Decision Record before being treated
// as final — see DR-ZYRA-079 (drafted alongside this file).
//
// MODEL
// Score is computed per Chapter 4 category from the Seeker's own
// traffic-light preferences (Ch4) against a candidate's Chapter 3
// "About You" answers for the same questions:
//   - Candidate's answer falls under the Seeker's 🟢 (Open) options -> +2
//   - Falls under 🟡 (Flexible) -> +1
//   - Falls under 🔴 (Not Preferred) -> -3, and if the Seeker marked
//     that question as a Hard Requirement, the candidate is EXCLUDED
//     entirely (score = null) rather than merely penalised.
//   - No preference recorded for that option -> 0 (neutral)
// Final score is the sum across all mutually-answered questions,
// normalised to 0-100 for display. A candidate excluded by any Hard
// Requirement returns null (never shown), regardless of their raw sum.
//
// This deliberately does NOT attempt full bidirectional matching
// (scoring both directions and combining) in v1 — that's a reasonable
// next iteration once this basic model is validated.

import '../models/onboarding_question.dart';

/// Returns a 0-100 compatibility score, or null if the candidate is
/// excluded by one of the Seeker's Hard Requirements.
double? scoreCandidate({
  required Map<String, dynamic> candidateCh3Answers,
  required Map<String, Map<String, TrafficLight>> seekerCh4Preferences,
  required Map<String, bool> seekerHardRequirements,
}) {
  int total = 0;
  int maxPossible = 0;

  for (final entry in seekerCh4Preferences.entries) {
    final questionId = entry.key;
    final preferences = entry.value;
    final candidateAnswer = candidateCh3Answers[questionId];
    if (candidateAnswer == null) continue;

    // Multi-select answers: score each selected option independently.
    final candidateValues = candidateAnswer is List ? candidateAnswer : [candidateAnswer.toString()];

    for (final value in candidateValues) {
      final light = preferences[value];
      if (light == null) continue;
      maxPossible += 2;
      switch (light) {
        case TrafficLight.green:
          total += 2;
          break;
        case TrafficLight.yellow:
          total += 1;
          break;
        case TrafficLight.red:
          if (seekerHardRequirements[questionId] == true) {
            return null; // Excluded — Hard Requirement violated.
          }
          total -= 3;
          break;
      }
    }
  }

  if (maxPossible == 0) return 50.0; // No comparable data yet — neutral default.
  final normalised = ((total / maxPossible) * 50) + 50; // maps [-1.5x, 1x] range roughly onto [0,100]
  return normalised.clamp(0, 100).toDouble();
}
