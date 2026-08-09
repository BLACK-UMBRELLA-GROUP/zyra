// REMOVED 2026-08-01 — superseded by `zyra_reference_data.dart`.
//
// This file held 30 countries, 20 languages and 12 ethnicities. Its own
// header called them a stand-in "which need a real backend/API to back
// properly". They were never replaced, and Chapter 2 was about to be given
// permanent database storage on top of them.
//
// Why the lists were a blocker and not a detail: persisting an answer
// commits to a TAXONOMY. Had 200 Seekers picked a birth country from 30
// options, growing that list to 197 later would have meant re-mapping every
// stored value — and anyone who picked the nearest wrong answer because
// theirs was absent could not have been recovered. A Muslim Seeker from
// Kenya, Kosovo, Uzbekistan, the Philippines or Sri Lanka could not answer
// the question at all: no Other, no free-text fallback.
//
// `nationality` was also typed wrong at source. It used this country list,
// so it stored "Pakistan" where a nationality is "Pakistani".
//
// The file is kept as a deliberately empty tombstone rather than deleted so
// that any missed import fails loudly at compile time instead of quietly
// resolving to a short list. Delete it once the tree is clean.
//
// Replacement: ZYRA/SOURCE/lib/data/zyra_reference_data.dart
//   197 countries  ISO 3166-1 alpha-2, each with a demonym
//   184 languages  ISO 639-1
//    29 ethnicities  ZYRA codes (no ISO standard exists)
//     4 location preferences
//
// And the rule that came with it: STORE THE CODE, NEVER THE LABEL.
