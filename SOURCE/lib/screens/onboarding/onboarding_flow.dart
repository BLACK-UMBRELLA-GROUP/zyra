// Onboarding — Chapter 1 "About You": Name, Gender, Date of Birth.
// Spec: APP/Onboarding/SEEKER ONBOARDING QUESTIONS/Onboarding Rules & UX.md.
//
// SCOPE NOTE UPDATE (2026-07-25, DR-ZYRA-101 audit): the note below is
// stale. All 5 chapters are now built — this file pushes into
// Chapter2Flow (chapter2_flow.dart), which chains into
// ValuesPreferencesFlow, CategorySummaryScreen, and ProfileReadyScreen.
// Original 2026-07-18 note, kept for history: "only Chapter 1 of 5 is
// built out with real questions... Continue going straight to Home for
// now... see Task #44 follow-up for building out the remaining
// chapters." That follow-up is complete.
//
// Privacy indicator assignment (from spec table, Chapter 1):
//   Name -> public, Gender -> public, Date of Birth -> private
// Background: neutral until gender is answered, then male/female per spec.

import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../services/zyra_profile_service.dart';
import '../../widgets/onboarding_scaffold.dart';
import '../../widgets/privacy_indicator.dart';
import '../../widgets/zyra_state_widgets.dart';
import 'chapter2_flow.dart';
import 'transition_screen.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _step = 0; // 0 = name, 1 = gender, 2 = dob
  final TextEditingController _nameController = TextEditingController();
  String? _gender; // 'male' | 'female'
  DateTime? _dob;
  String? _dobError;
  bool _savingProfile = false;
  String? _saveError;

  static const int _totalQuestions = 3;

  ZyraBackgroundVariant get _background {
    if (_gender == 'male') return ZyraBackgroundVariant.male;
    if (_gender == 'female') return ZyraBackgroundVariant.female;
    return ZyraBackgroundVariant.neutral;
  }

  bool get _fabActive {
    switch (_step) {
      case 0:
        return _nameController.text.trim().isNotEmpty;
      case 1:
        return _gender != null;
      case 2:
        return _dob != null && _dobError == null;
      default:
        return false;
    }
  }

  /// Swipe-right-to-go-back (Onboarding Rules & UX §SCREEN ANATOMY —
  /// "No back button... swipe right"). At step 0 there's nowhere earlier
  /// to go within this route (Role Selection was pushReplacement'd away),
  /// so it's a no-op there — same boundary limitation as every chapter
  /// transition in this build.
  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _next() async {
    if (_step < _totalQuestions - 1) {
      setState(() => _step++);
      return;
    }

    AppState.instance.saveChapter1(
      name: _nameController.text.trim(),
      gender: _gender!,
      dob: _dob!,
    );

    // OA-102 follow-on: write the real profiles row now that Chapter 1
    // has every NOT NULL field the schema requires. No-ops safely if
    // Supabase isn't configured or there's no session (see
    // zyra_profile_service.dart) — AppState's in-memory copy above
    // always happens either way, so the rest of this build keeps
    // working exactly as before regardless of backend state.
    setState(() {
      _savingProfile = true;
      _saveError = null;
    });
    final error = await ZyraProfileService.createSeekerProfile(
      firstName: _nameController.text.trim(),
      gender: _gender!,
      dob: _dob!,
    );
    if (!mounted) return;
    setState(() => _savingProfile = false);
    if (error != null) {
      setState(() => _saveError = error);
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TransitionScreen(
          background: _background,
          title: 'Chapter 1 Complete',
          body: "Great start. Next, let's build your profile — the photos and "
              'details other members will see as you begin matching.',
          buttonLabel: 'Begin Your Profile',
          onContinue: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => Chapter2Flow(gender: _gender)),
          ),
        ),
      ),
    );
  }

  void _checkDob(DateTime picked) {
    final now = DateTime.now();
    var age = now.year - picked.year;
    final hadBirthdayThisYear =
        now.month > picked.month || (now.month == picked.month && now.day >= picked.day);
    if (!hadBirthdayThisYear) age -= 1;
    setState(() {
      _dob = picked;
      _dobError = age < 18 ? "You'll need to be 18 or over to continue." : null;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_step) {
      case 0:
        return OnboardingScaffold(
          background: _background,
          chapterName: 'About You',
          chapterProgress: 1 / _totalQuestions,
          question: 'What\'s your first name?',
          subtext: 'This is how you\'ll appear to other members.',
          privacy: PrivacyLevel.public,
          fabActive: _fabActive,
          onContinue: _next,
          onSwipeBack: _step > 0 ? _back : null,
          content: TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            style: ZyraText.body(size: 18, color: Colors.white),
            cursorColor: ZyraColors.royalPurple,
            decoration: InputDecoration(
              hintText: 'First name',
              hintStyle: ZyraText.body(size: 18, color: Colors.white24),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: ZyraColors.royalPurple)),
            ),
          ),
        );
      case 1:
        return OnboardingScaffold(
          background: _background,
          chapterName: 'About You',
          chapterProgress: 2 / _totalQuestions,
          question: 'What\'s your gender?',
          privacy: PrivacyLevel.public,
          fabActive: _fabActive,
          onContinue: _next,
          onSwipeBack: _back,
          content: Column(
            children: [
              _GenderOption(label: 'Male', selected: _gender == 'male', onTap: () => setState(() => _gender = 'male')),
              const SizedBox(height: 12),
              _GenderOption(label: 'Female', selected: _gender == 'female', onTap: () => setState(() => _gender = 'female')),
            ],
          ),
        );
      case 2:
      default:
        return OnboardingScaffold(
          background: _background,
          chapterName: 'About You',
          chapterProgress: 1.0,
          chapterComplete: true,
          question: 'When were you born?',
          subtext: 'You must be 18 or older to use ZYRA.',
          privacy: PrivacyLevel.private,
          fabActive: _fabActive && !_savingProfile,
          onContinue: _next,
          onSwipeBack: _back,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DobPicker(value: _dob, onPicked: _checkDob),
              ZyraFieldError(_dobError),
              if (_saveError != null) ...[
                const SizedBox(height: 12),
                ZyraErrorBanner(
                  message: _saveError!,
                  onRetry: _next,
                  onDismiss: () => setState(() => _saveError = null),
                ),
              ],
            ],
          ),
        );
    }
  }
}

class _GenderOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenderOption({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? ZyraColors.accentBg : ZyraColors.iconButtonBg,
          border: Border.all(color: selected ? ZyraColors.accentBorder : ZyraColors.iconButtonBorder, width: 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Center(child: Text(label, style: ZyraText.option())),
          ),
        ),
      ),
    );
  }
}

class _DobPicker extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime> onPicked;

  const _DobPicker({required this.value, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    final label = value == null
        ? 'Select date of birth'
        : '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}';
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime(now.year - 25, now.month, now.day),
          firstDate: DateTime(now.year - 100),
          lastDate: now,
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        width: double.infinity,
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: ZyraColors.iconButtonBg,
          border: Border.all(color: ZyraColors.iconButtonBorder, width: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: Colors.white54, size: 18),
            const SizedBox(width: 12),
            Text(label, style: ZyraText.body(size: 15, color: value == null ? Colors.white38 : Colors.white)),
          ],
        ),
      ),
    );
  }
}
