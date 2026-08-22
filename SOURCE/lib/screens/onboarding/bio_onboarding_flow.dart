import 'package:flutter/material.dart';

import '../../models/journey_bio.dart';
import '../../services/zyra_onboarding_answers_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/onboarding_scaffold.dart';
import '../../widgets/privacy_indicator.dart';
import 'onboarding_stage_intro_screen.dart';
import 'values_preferences_flow.dart';

/// Optional, Journey-only Bio chapter.
///
/// The structured facts are intentionally entered here rather than copied
/// silently from private compatibility answers. Sharing something with a
/// future Journey is an explicit decision, not a side effect of matching.
class BioOnboardingFlow extends StatefulWidget {
  final String? gender;
  final bool devPreview;

  const BioOnboardingFlow({
    super.key,
    required this.gender,
    this.devPreview = false,
  });

  @override
  State<BioOnboardingFlow> createState() => _BioOnboardingFlowState();
}

class _BioOnboardingFlowState extends State<BioOnboardingFlow> {
  static const _sections = [
    'Work & education',
    'Family & marriage',
    'Practical life',
  ];
  static const int _totalSteps = 5;

  int _step = 0;
  bool _saving = false;
  final _aboutController = TextEditingController();
  final Map<String, TextEditingController> _freeTextControllers = {};
  final Map<String, String> _values = {};
  final Set<String> _visibleFieldIds = {};
  bool _showAboutMe = false;

  ZyraBackgroundVariant get _background => switch (widget.gender) {
    'male' => ZyraBackgroundVariant.male,
    'female' => ZyraBackgroundVariant.female,
    _ => ZyraBackgroundVariant.neutral,
  };

  List<JourneyBioFieldDefinition> _fieldsFor(String section) =>
      journeyBioFieldDefinitions
          .where((field) => field.section == section)
          .toList(growable: false);

  JourneyBio get _draft => JourneyBio(
    aboutMe: _aboutController.text,
    fieldValues: Map<String, String>.unmodifiable(_values),
    visibleFieldIds: Set<String>.unmodifiable(_visibleFieldIds),
    showAboutMe: _showAboutMe,
  );

  void _setValue(JourneyBioFieldDefinition field, String value) {
    setState(() {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        _values.remove(field.id);
        _visibleFieldIds.remove(field.id);
      } else {
        _values[field.id] = value;
        // Adding a Journey Bio detail opts that detail in. The review step
        // immediately below lets the Seeker turn any item back off.
        _visibleFieldIds.add(field.id);
      }
    });
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _next() async {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
      return;
    }

    setState(() => _saving = true);
    final draft = _draft;
    AppState.instance.saveJourneyBio(draft);
    final saved = widget.devPreview
        ? true
        : await ZyraOnboardingAnswersService.syncJourneyBio(draft);
    if (!mounted) return;
    setState(() => _saving = false);

    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your Bio is safe for this session. ZYRA will try saving it again with your Values.',
          ),
        ),
      );
    }

    final gender = widget.gender;
    if (gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complete Gender in Essentials before starting Compatibility.',
          ),
        ),
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (stageContext) => OnboardingStageIntroScreen(
          stage: SeekerOnboardingStage.compatibility,
          onContinue: () => Navigator.of(stageContext).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ValuesPreferencesFlow(
                gender: gender,
                devPreview: widget.devPreview,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _aboutController.dispose();
    for (final controller in _freeTextControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    late String question;
    late String subtext;
    late Widget content;

    if (_step == 0) {
      question = 'Tell them about you — in your own words.';
      subtext = 'Optional · Maximum ${JourneyBio.characterLimit} characters';
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _aboutController,
            minLines: 7,
            maxLines: 11,
            maxLength: JourneyBio.characterLimit,
            onChanged: (value) => setState(() {
              if (value.trim().isEmpty) {
                _showAboutMe = false;
              } else if (!_showAboutMe) {
                _showAboutMe = true;
              }
            }),
            style: ZyraText.body(size: 15.5),
            cursorColor: ZyraColors.unlockText,
            decoration: InputDecoration(
              hintText:
                  'Your character, the life you hope to build, and what matters to you…',
              hintStyle: ZyraText.subtext(color: Colors.white30),
              filled: true,
              fillColor: ZyraColors.iconButtonBg,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: ZyraColors.iconButtonBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: ZyraColors.unlockText),
              ),
              counterStyle: ZyraText.subtext(size: 11, color: Colors.white38),
            ),
          ),
          const SizedBox(height: 10),
          _JourneyShareSwitch(
            label: 'Include this biography in my Journey profile',
            value: _showAboutMe,
            enabled: _aboutController.text.trim().isNotEmpty,
            onChanged: (value) => setState(() => _showAboutMe = value),
          ),
        ],
      );
    } else if (_step <= _sections.length) {
      final section = _sections[_step - 1];
      final fields = _fieldsFor(section);
      question = section;
      subtext = 'Optional · Choose only what you would want a Journey to see';
      content = Column(
        children: [
          for (final field in fields) ...[
            _BioFieldEditor(
              definition: field,
              value: _values[field.id] ?? '',
              controller: field.usesFreeText
                  ? _freeTextControllers.putIfAbsent(
                      field.id,
                      () =>
                          TextEditingController(text: _values[field.id] ?? ''),
                    )
                  : null,
              shared: _visibleFieldIds.contains(field.id),
              onChanged: (value) => _setValue(field, value),
              onSharedChanged: (shared) => setState(() {
                if (shared) {
                  _visibleFieldIds.add(field.id);
                } else {
                  _visibleFieldIds.remove(field.id);
                }
              }),
            ),
            if (field != fields.last) const SizedBox(height: 12),
          ],
        ],
      );
    } else {
      question = 'Review what your Journey can reveal.';
      subtext = 'Optional · Nothing here affects your compatibility score';
      content = _BioVisibilityReview(
        bio: _draft,
        onShowAboutMeChanged: (value) => setState(() => _showAboutMe = value),
        onFieldChanged: (id, shared) => setState(() {
          if (shared) {
            _visibleFieldIds.add(id);
          } else {
            _visibleFieldIds.remove(id);
          }
        }),
      );
    }

    return OnboardingScaffold(
      background: _background,
      chapterName: 'Your Bio',
      chapterProgress: (_step + 1) / _totalSteps,
      chapterComplete: _step == _totalSteps - 1,
      question: question,
      subtext: subtext,
      privacy: PrivacyLevel.private,
      privacyOverrideText:
          'Journey only — shown after both Seekers choose to reveal.',
      fabActive: !_saving,
      onContinue: _next,
      devPreview: widget.devPreview,
      onDevSkip: _next,
      devSkipLabel: 'Skip page',
      onSwipeBack: _step > 0 ? _back : null,
      content: content,
    );
  }
}

class _BioFieldEditor extends StatelessWidget {
  final JourneyBioFieldDefinition definition;
  final String value;
  final TextEditingController? controller;
  final bool shared;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool> onSharedChanged;

  const _BioFieldEditor({
    required this.definition,
    required this.value,
    required this.controller,
    required this.shared,
    required this.onChanged,
    required this.onSharedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: ZyraColors.iconButtonBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ZyraColors.iconButtonBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(definition.prompt, style: ZyraText.body(size: 13.5)),
          const SizedBox(height: 10),
          if (definition.usesFreeText)
            TextField(
              controller: controller,
              onChanged: onChanged,
              style: ZyraText.body(size: 14.5),
              decoration: InputDecoration(
                hintText: 'Optional answer',
                hintStyle: ZyraText.subtext(color: Colors.white30),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: ZyraColors.unlockDot),
                ),
              ),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: hasValue ? value : null,
              isExpanded: true,
              dropdownColor: ZyraColors.luxuryDarkPurple,
              style: ZyraText.body(size: 14),
              decoration: InputDecoration(
                hintText: 'Choose an optional answer',
                hintStyle: ZyraText.subtext(color: Colors.white30),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: ZyraColors.unlockDot),
                ),
              ),
              items: [
                for (final option in definition.options)
                  DropdownMenuItem(value: option, child: Text(option)),
              ],
              onChanged: (next) => onChanged(next ?? ''),
            ),
          const SizedBox(height: 4),
          _JourneyShareSwitch(
            label: 'Show ${definition.label.toLowerCase()} in my Journey',
            value: shared && hasValue,
            enabled: hasValue,
            onChanged: onSharedChanged,
          ),
        ],
      ),
    );
  }
}

class _JourneyShareSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _JourneyShareSwitch({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        label,
        style: ZyraText.subtext(
          size: 11.5,
          color: enabled ? Colors.white70 : Colors.white30,
        ),
      ),
      value: enabled && value,
      activeTrackColor: ZyraColors.unlockDot.withValues(alpha: 0.5),
      activeThumbColor: ZyraColors.unlockText,
      onChanged: enabled ? onChanged : null,
    );
  }
}

class _BioVisibilityReview extends StatelessWidget {
  final JourneyBio bio;
  final ValueChanged<bool> onShowAboutMeChanged;
  final void Function(String id, bool shared) onFieldChanged;

  const _BioVisibilityReview({
    required this.bio,
    required this.onShowAboutMeChanged,
    required this.onFieldChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filledFields = journeyBioFieldDefinitions
        .where((field) => (bio.fieldValues[field.id] ?? '').trim().isNotEmpty)
        .toList(growable: false);
    if (bio.aboutMe.trim().isEmpty && filledFields.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
        decoration: BoxDecoration(
          color: ZyraColors.iconButtonBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ZyraColors.iconButtonBorder, width: 0.5),
        ),
        child: Column(
          children: [
            const Icon(Icons.notes_rounded, color: Colors.white54, size: 30),
            const SizedBox(height: 10),
            Text('No Bio added', style: ZyraText.heading(size: 18)),
            const SizedBox(height: 6),
            Text(
              'That is completely fine. Your Journey will simply explain that you chose not to add one.',
              textAlign: TextAlign.center,
              style: ZyraText.subtext(size: 12.5),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (bio.aboutMe.trim().isNotEmpty)
          _ReviewToggle(
            title: 'Biography',
            value:
                '${bio.aboutMe.trim().length} / ${JourneyBio.characterLimit} characters',
            shared: bio.showAboutMe,
            onChanged: onShowAboutMeChanged,
          ),
        for (final field in filledFields)
          _ReviewToggle(
            title: field.label,
            value: bio.fieldValues[field.id]!,
            shared: bio.visibleFieldIds.contains(field.id),
            onChanged: (shared) => onFieldChanged(field.id, shared),
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '${bio.sharedItemCount} item${bio.sharedItemCount == 1 ? '' : 's'} selected for Journey reveal',
            style: ZyraText.subtext(size: 11.5, color: ZyraColors.unlockText),
          ),
        ),
      ],
    );
  }
}

class _ReviewToggle extends StatelessWidget {
  final String title;
  final String value;
  final bool shared;
  final ValueChanged<bool> onChanged;

  const _ReviewToggle({
    required this.title,
    required this.value,
    required this.shared,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      decoration: BoxDecoration(
        color: ZyraColors.iconButtonBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ZyraColors.iconButtonBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ZyraText.body(size: 13.5)),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ZyraText.subtext(size: 11.5),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: shared,
            activeTrackColor: ZyraColors.unlockDot.withValues(alpha: 0.5),
            activeThumbColor: ZyraColors.unlockText,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
