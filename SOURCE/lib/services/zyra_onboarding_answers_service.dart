// Chapter 3/4 onboarding answer persistence — DR-ZYRA-082 (PROPOSED,
// awaiting Founder ratification). Syncs ValuesPreferencesFlow's local
// widget state (_ch3Answers/_ch4Preferences/_ch4HardRequirement) to
// the onboarding_answers table so answers survive beyond the widget's
// lifetime — previously they were held only in memory and lost the
// moment the flow was disposed.
//
// Fire-and-forget, best-effort, same pattern as ZyraPhotoService.
// syncPhotos: the flow's own local state remains the source of truth
// for the in-progress session regardless of whether this succeeds, so
// a Supabase hiccup never blocks onboarding progress.

// VERIFIED AGAINST THE LIVE DATABASE 2026-08-04, because the table had
// zero rows and it was not obvious whether that meant "broken" or "nobody
// has got there yet". Everything on the write path checks out:
//
//   PRIMARY KEY (user_id)      the upsert below has a real conflict target,
//                              so a second sync updates rather than
//                              duplicating or failing.
//   RLS insert/select/update   all three `user_id = auth.uid()`. An upsert
//                              needs BOTH insert and update policies to
//                              exist; both do.
//   FK -> profiles(id)         satisfied by Chapter 1, which runs first.
//   Payload shape              a test row carrying all three JSONB
//                              structures — including the nested
//                              question -> option -> traffic-light map —
//                              round-tripped exactly. Test row deleted;
//                              table confirmed back to zero rows.
//   Call site                  values_preferences_flow `_next()` fires this
//                              at every category summary.
//
// So the table is empty because no one has walked Chapter 3 while signed
// in to a real Supabase session — not because this is broken. Recorded so
// the next person does not re-investigate from scratch.

import 'package:flutter/foundation.dart';

import '../main.dart';
import '../models/journey_bio.dart';
import '../models/onboarding_question.dart';
import '../state/app_state.dart';
import 'zyra_auth.dart';

class ZyraOnboardingAnswersService {
  ZyraOnboardingAnswersService._();

  /// `ch3_q26` has male and female client variants, but the persisted bank
  /// deliberately has one canonical qid. Strip only the explicit variant
  /// suffix at the persistence boundary; ordinary qids and Journey Bio keys
  /// pass through unchanged.
  static String persistedQuestionId(String responseKey) =>
      responseKey.split('::').first;

  /// Upserts the full current answer state for the signed-in user.
  /// Called at category-summary checkpoints (not per-question) to
  /// keep call volume reasonable across a ~174-question walk while
  /// still giving real crash/interruption resilience.
  static Future<void> syncAnswers({
    required Map<String, dynamic> ch3Answers,
    required Map<String, Map<String, TrafficLight>> ch4Preferences,
    required Map<String, Set<String>> ch4HardRequirements,
  }) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return;

    try {
      // Journey Bio metadata shares this own-row-only JSON store, but is not
      // a scored question. Always merge it back at a Values checkpoint so
      // the Chapter 3 write cannot erase the preceding Bio chapter.
      final completeCh3Answers = <String, dynamic>{
        ...AppState.instance.journeyBio.toOnboardingAnswers(),
        for (final entry in ch3Answers.entries)
          persistedQuestionId(entry.key): entry.value,
      };
      await supabase.from('onboarding_answers').upsert({
        'user_id': user.id,
        'ch3_answers': completeCh3Answers,
        'ch4_preferences': {
          for (final entry in ch4Preferences.entries)
            persistedQuestionId(entry.key): {
              for (final option in entry.value.entries)
                option.key: option.value.name,
            },
        },
        // PER-OPTION SINCE 2026-08-10 — {question_id: [option_label, ...]}.
        // WAS {question_id: bool}. The database CHECK constraint
        // onboarding_answers_ch4_hard_shape now REJECTS the old form, so a
        // stale build cannot quietly write an exclusion the engine would
        // then ignore. If this ever starts throwing
        // "violates check constraint", the shape is wrong — do not widen
        // the constraint to make it pass.
        //
        // Empty sets are dropped rather than written as `[]`: a question
        // with no exclusions should be absent from the payload, not present
        // and empty.
        'ch4_hard_requirements': {
          for (final entry in ch4HardRequirements.entries)
            if (entry.value.isNotEmpty)
              persistedQuestionId(entry.key): entry.value.toList(),
        },
      });
    } catch (e) {
      // LOGGED 2026-08-04. This was `catch (_) {}` — completely silent.
      //
      // Best-effort is the right behaviour: a network hiccup must not trap
      // someone 90 questions into a 174-question walk. Silent is not. These
      // answers are the only input the compatibility score will ever have,
      // so a persistent failure here means the entire premium feature
      // computes from nothing — and the app would look like it was working
      // the whole time.
      //
      // This is the exact shape of the `profile_complete` bug (audit
      // finding C3): a write that nobody watched, hidden by a fallback that
      // made the screen look fine.
      debugPrint(
        'ZYRA: onboarding answer sync failed — Chapter 3/4 answers '
        'not saved for this checkpoint. Compatibility cannot be computed '
        'without them. $e',
      );
    }
  }

  /// Saves the optional Journey Bio before Chapter 3 begins, using the
  /// existing own-row-only onboarding JSON. No schema change is needed and
  /// the public `profiles.bio` column is deliberately not used: its profile
  /// visibility is broader than the Founder-approved Journey-only reveal.
  static Future<bool> syncJourneyBio(JourneyBio bio) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return true; // Developer Access / offline preview.

    try {
      final existing = await supabase
          .from('onboarding_answers')
          .select('ch3_answers, ch4_preferences, ch4_hard_requirements')
          .eq('user_id', user.id)
          .maybeSingle();

      final existingCh3 = Map<String, dynamic>.from(
        (existing?['ch3_answers'] as Map?) ?? const {},
      );
      existingCh3.removeWhere((key, _) => key.startsWith('bio_'));
      existingCh3.addAll(bio.toOnboardingAnswers());

      await supabase.from('onboarding_answers').upsert({
        'user_id': user.id,
        'ch3_answers': existingCh3,
        'ch4_preferences': Map<String, dynamic>.from(
          (existing?['ch4_preferences'] as Map?) ?? const {},
        ),
        'ch4_hard_requirements': Map<String, dynamic>.from(
          (existing?['ch4_hard_requirements'] as Map?) ?? const {},
        ),
      });
      return true;
    } catch (e) {
      debugPrint(
        'ZYRA: Journey Bio sync failed — the draft remains available in '
        'this onboarding session. $e',
      );
      return false;
    }
  }
}
