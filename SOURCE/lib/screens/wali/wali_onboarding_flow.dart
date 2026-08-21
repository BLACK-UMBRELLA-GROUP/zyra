// Wali Onboarding — v1 draft. WALI_ARCHITECTURE_CURRENT_VERSION_V5.md is
// a fully approved, detailed architecture (account model, capability
// grants, three entry paths, screen flow diagram, navigation), but the
// actual onboarding QUESTION CONTENT is never specified anywhere in it —
// the flow diagram only references a black-box "[ Guardian Onboarding ]"
// node between account creation and the Dashboard. This file fills that
// gap with a reasonable v1, recorded as a proposed decision (DR-ZYRA-081)
// rather than silently treated as final, same discipline as the
// compatibility scoring (DR-ZYRA-079) and error-state standard
// (DR-ZYRA-080) drafts earlier in this build.
//
// Scoped to PATH 3 ("Guardian Starts First") only — per WALI SCREEN FLOW,
// that's the only entry path reachable from this app's current Role
// Selection screen (Paths 1/2 require a Seeker-sent invite link/landing
// page, which doesn't exist as a flow yet). Relationship options and the
// "support and guidance, not surveillance" framing are taken directly
// from the spec's WHO IS A WALI and DESIGN PRINCIPLE sections.
//
// Date of birth added 2026-07-18 alongside real Supabase wiring (OA-102
// follow-on): ZYRA_DATABASE_SCHEMA_CURRENT_VERSION_V1.md's `profiles`
// table has date_of_birth as NOT NULL for every role, Guardian included,
// but the original v1 draft (DR-ZYRA-081) only asked name + relationship
// since nothing else in the Guardian UI uses a DOB. Adding the question here
// rather than relaxing the approved schema — small, faithful fix now
// that a real constraint exists to satisfy.

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import '../../services/zyra_profile_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../onboarding/transition_screen.dart';
import 'wali_invite_seeker_screen.dart';

class WaliOnboardingFlow extends StatefulWidget {
  final bool devPreview;

  const WaliOnboardingFlow({super.key, this.devPreview = false});

  @override
  State<WaliOnboardingFlow> createState() => _WaliOnboardingFlowState();
}

class _WaliOnboardingFlowState extends State<WaliOnboardingFlow> {
  int _step = 0; // 0 = name, 1 = date of birth, 2 = relationship
  final TextEditingController _nameController = TextEditingController();
  DateTime? _dob;
  String? _dobError;
  String? _relationship;
  bool _savingProfile = false;
  String? _saveError;

  static const int _totalQuestions = 3;

  static const _relationships = [
    'Father',
    'Grandfather',
    'Brother',
    'Paternal Uncle',
    'Other',
  ];

  bool get _fabActive {
    switch (_step) {
      case 0:
        return _nameController.text.trim().isNotEmpty;
      case 1:
        return _dob != null && _dobError == null;
      case 2:
        return _relationship != null;
      default:
        return false;
    }
  }

  void _checkDob(DateTime picked) {
    final now = DateTime.now();
    var age = now.year - picked.year;
    final hadBirthdayThisYear =
        now.month > picked.month ||
        (now.month == picked.month && now.day >= picked.day);
    if (!hadBirthdayThisYear) age -= 1;
    setState(() {
      _dob = picked;
      _dobError = age < 18 ? "You'll need to be 18 or over to continue." : null;
    });
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  void _devSkipCurrentQuestion() {
    if (!widget.devPreview) return;
    final now = DateTime.now();
    setState(() {
      if (_step == 0 && _nameController.text.trim().isEmpty) {
        _nameController.text = 'Dev Guardian';
      } else if (_step == 1) {
        _dob ??= DateTime(now.year - 45, 1, 1);
        _dobError = null;
      } else if (_step == 2) {
        _relationship ??= _relationships.first;
      }
    });
    _next();
  }

  Future<void> _next() async {
    if (_step < _totalQuestions - 1) {
      setState(() => _step++);
      return;
    }
    AppState.instance.saveWaliOnboarding(
      name: _nameController.text.trim(),
      relationship: _relationship!,
    );

    if (!widget.devPreview) {
      setState(() {
        _savingProfile = true;
        _saveError = null;
      });
      final error = await ZyraProfileService.createWaliProfile(
        firstName: _nameController.text.trim(),
        dob: _dob!,
      );
      if (!mounted) return;
      setState(() => _savingProfile = false);
      if (error != null) {
        setState(() => _saveError = error);
        return;
      }
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TransitionScreen(
          background: ZyraBackgroundVariant.male,
          title: 'Support and guidance',
          // CORRECTED 2026-08-01. This screen told every Guardian they would
          // see progress "without reading their private conversations".
          // That was false: messages_select's RLS grants an active linked
          // Guardian full read access to the conversation once a Journey
          // leaves 'potential'. The claim contradicted the database, the
          // WALI_ARCHITECTURE permissions table, and the FAQ — three
          // sources, three different answers.
          //
          // Founder decision (2026-08-01): the access is deliberate and
          // stays. So the wording changes, not the behaviour. "Guidance,
          // not surveillance" is kept because it is still the honest
          // framing of the ROLE — it just cannot be used to imply an
          // access limit that does not exist.
          body:
              'ZYRA treats you as a full part of this journey — not as an observer. '
              "You'll see your linked Seeker's progress, and you can read the "
              'conversation once a Journey becomes active. Both Seekers are told '
              'this before they begin.\n\n'
              'That openness is the point: ZYRA is built for a marriage process '
              'with family present. It is a trust placed in you — guidance, not '
              'surveillance.',
          buttonLabel: 'Continue',
          onContinue: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const WaliInviteSeekerScreen()),
          ),
        ),
      ),
    );
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
        return _WaliQuestionScaffold(
          progress: 1 / _totalQuestions,
          question: "What's your first name?",
          subtext: "This is how you'll appear to your linked Seeker.",
          fabActive: _fabActive,
          onContinue: _next,
          devPreview: widget.devPreview,
          onDevSkip: _devSkipCurrentQuestion,
          onSwipeBack: null,
          content: TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            style: ZyraText.body(size: 18, color: Colors.white),
            cursorColor: ZyraColors.unlockDot,
            decoration: InputDecoration(
              hintText: 'First name',
              hintStyle: ZyraText.body(size: 18, color: Colors.white24),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: ZyraColors.unlockDot),
              ),
            ),
          ),
        );
      case 1:
        return _WaliQuestionScaffold(
          progress: 2 / _totalQuestions,
          question: 'When were you born?',
          subtext: 'You must be 18 or older to use ZYRA.',
          fabActive: _fabActive,
          onContinue: _next,
          devPreview: widget.devPreview,
          onDevSkip: _devSkipCurrentQuestion,
          onSwipeBack: _back,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WaliDobPicker(value: _dob, onPicked: _checkDob),
              ZyraFieldError(_dobError),
            ],
          ),
        );
      case 2:
      default:
        return _WaliQuestionScaffold(
          progress: 1.0,
          question: 'What is your relationship to the Seeker you support?',
          subtext: 'Eligible Guardian relationships, per Islamic guidance.',
          fabActive: _fabActive && !_savingProfile,
          onContinue: _next,
          devPreview: widget.devPreview,
          onDevSkip: _devSkipCurrentQuestion,
          onSwipeBack: _back,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._relationships.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RelationshipOption(
                    label: r,
                    selected: _relationship == r,
                    onTap: () => setState(() => _relationship = r),
                  ),
                ),
              ),
              if (_saveError != null) ...[
                const SizedBox(height: 8),
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

class _WaliDobPicker extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime> onPicked;
  const _WaliDobPicker({required this.value, required this.onPicked});

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
          initialDate: DateTime(now.year - 45, now.month, now.day),
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
            const Icon(
              Icons.calendar_today_outlined,
              color: Colors.white54,
              size: 18,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: ZyraText.body(
                size: 15,
                color: value == null ? Colors.white38 : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Deliberately not reusing the Seeker's OnboardingScaffold — the Guardian
/// background is always the male-derived gradient (Guardian is, per spec, a
/// male guardian), and there's no privacy-indicator concept in Wali
/// onboarding (Wali identity fields aren't part of a Browse-visible
/// profile), so a lighter dedicated scaffold avoids dragging in Seeker-
/// only concepts that don't apply here.
class _WaliQuestionScaffold extends StatelessWidget {
  final double progress;
  final String question;
  final String? subtext;
  final Widget content;
  final bool fabActive;
  final VoidCallback onContinue;
  final VoidCallback? onSwipeBack;
  final bool devPreview;
  final VoidCallback? onDevSkip;

  const _WaliQuestionScaffold({
    required this.progress,
    required this.question,
    required this.content,
    required this.fabActive,
    required this.onContinue,
    this.subtext,
    this.onSwipeBack,
    this.devPreview = false,
    this.onDevSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: onSwipeBack == null
            ? null
            : (details) {
                if ((details.primaryVelocity ?? 0) > 250) onSwipeBack!();
              },
        child: Container(
          decoration: BoxDecoration(
            gradient: ZyraColors.backgroundFor(ZyraBackgroundVariant.male),
          ),
          child: Stack(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: SizedBox(
                          height: 1.5,
                          child: LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            backgroundColor: ZyraColors.progressTrack,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              ZyraColors.progressFill,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (!kReleaseMode && devPreview && onDevSkip != null) ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            key: const ValueKey('onboarding_dev_skip'),
                            onPressed: onDevSkip,
                            icon: const Icon(
                              Icons.skip_next_rounded,
                              size: 17,
                              color: ZyraColors.unlockText,
                            ),
                            label: Text(
                              'Skip question · DEV',
                              style: ZyraText.subtext(
                                size: 11.5,
                                color: ZyraColors.unlockText,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(question, style: ZyraText.heading()),
                      if (subtext != null) ...[
                        const SizedBox(height: 8),
                        Text(subtext!, style: ZyraText.subtext()),
                      ],
                      const SizedBox(height: 28),
                      Expanded(child: SingleChildScrollView(child: content)),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 14,
                right: 16,
                child: GestureDetector(
                  onTap: fabActive ? onContinue : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: fabActive
                          ? ZyraColors.fabActiveBg
                          : ZyraColors.fabDimmedBg,
                      border: Border.all(
                        color: fabActive
                            ? ZyraColors.fabActiveBorder
                            : ZyraColors.fabDimmedBorder,
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 20,
                      color: fabActive
                          ? ZyraColors.fabActiveArrow
                          : ZyraColors.fabDimmedArrow,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RelationshipOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RelationshipOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? ZyraColors.accentBg : ZyraColors.iconButtonBg,
          border: Border.all(
            color: selected
                ? ZyraColors.accentBorder
                : ZyraColors.iconButtonBorder,
            width: 1,
          ),
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
