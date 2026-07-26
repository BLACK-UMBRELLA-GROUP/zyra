// Data-driven question model shared by Chapter 3 (Your Values) and
// Chapter 4 (Your Preferences, auto-derived from Ch3's CH4-flagged
// questions). Built this way because the real spec is ~174 questions
// across 9 categories (SEEKER ONBOARDING QUESTIONS/*.md) — far too many
// to hand-write one bespoke screen per question. One generic renderer
// (generic_select_question_screen.dart / traffic_light_question_screen.dart)
// + this data covers all of them faithfully.

enum QuestionSelectionType { single, multi }

/// Which Chapter 4 preference screen (if any) this Chapter 3 question
/// generates, per Chapter 3 Classification — Ch4 Mapping.md (V3 Approved).
enum Ch4Status { none, required, optional }

enum GenderVisibility { all, menOnly, womenOnly }

class OnboardingCategory {
  final String id;
  final String name;
  final List<OnboardingQuestion> questions;

  const OnboardingCategory({required this.id, required this.name, required this.questions});

  /// Questions in this category that generate a Chapter 4 preference screen.
  List<OnboardingQuestion> get ch4Questions =>
      questions.where((q) => q.ch4Status != Ch4Status.none).toList();
}

class OnboardingQuestion {
  final String id; // e.g. "ch3_q1"
  final String prompt;
  final List<String> options;
  final QuestionSelectionType selectionType;
  final Ch4Status ch4Status;
  final GenderVisibility genderVisibility;
  final bool hardRequirementSupported;

  const OnboardingQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    this.selectionType = QuestionSelectionType.single,
    this.ch4Status = Ch4Status.none,
    this.genderVisibility = GenderVisibility.all,
    this.hardRequirementSupported = true,
  });

  bool visibleFor(String? gender) {
    switch (genderVisibility) {
      case GenderVisibility.all:
        return true;
      case GenderVisibility.menOnly:
        return gender == 'male';
      case GenderVisibility.womenOnly:
        return gender == 'female';
    }
  }
}

/// Traffic light preference value for one option of a Chapter 4 question.
enum TrafficLight { green, yellow, red }

extension TrafficLightX on TrafficLight {
  String get emoji => switch (this) {
        TrafficLight.green => '🟢',
        TrafficLight.yellow => '🟡',
        TrafficLight.red => '🔴',
      };
}
