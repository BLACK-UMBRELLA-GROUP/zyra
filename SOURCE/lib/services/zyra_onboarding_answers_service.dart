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

import '../main.dart';
import '../models/onboarding_question.dart';
import 'zyra_auth.dart';

class ZyraOnboardingAnswersService {
  ZyraOnboardingAnswersService._();

  /// Upserts the full current answer state for the signed-in user.
  /// Called at category-summary checkpoints (not per-question) to
  /// keep call volume reasonable across a ~174-question walk while
  /// still giving real crash/interruption resilience.
  static Future<void> syncAnswers({
    required Map<String, dynamic> ch3Answers,
    required Map<String, Map<String, TrafficLight>> ch4Preferences,
    required Map<String, bool> ch4HardRequirements,
  }) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('onboarding_answers').upsert({
        'user_id': user.id,
        'ch3_answers': ch3Answers,
        'ch4_preferences': {
          for (final entry in ch4Preferences.entries)
            entry.key: {
              for (final option in entry.value.entries) option.key: option.value.name,
            },
        },
        'ch4_hard_requirements': ch4HardRequirements,
      });
    } catch (_) {
      // Best-effort — see doc comment above.
    }
  }
}
