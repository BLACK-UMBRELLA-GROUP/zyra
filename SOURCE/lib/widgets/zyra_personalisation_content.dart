import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_interaction_style.dart';
import '../theme/zyra_text.dart';

Color get _personalisationAccent => ZyraColors.journeyGold;

/// Presentation values only. This snapshot neither reads nor saves an account.
@immutable
class ZyraPersonalisationSnapshot {
  const ZyraPersonalisationSnapshot({
    required this.palette,
    required this.hapticLevel,
    required this.goldEnabled,
  });

  final ZyraDevPalette palette;
  final ZyraHapticLevel hapticLevel;
  final bool goldEnabled;
}

/// Retained member content with explicit caller-owned values and actions.
/// No account lookup, preference setter or default action fallback exists here.
class ZyraPersonalisationContent extends StatelessWidget {
  const ZyraPersonalisationContent({
    super.key,
    required this.snapshot,
    required this.onChooseBackground,
    required this.onChooseHaptic,
    required this.onGoldChanged,
    this.previewGradient,
    this.previewOnly = false,
    this.scrollKey = const ValueKey('personalisation-scroll'),
  });

  final ZyraPersonalisationSnapshot snapshot;
  final VoidCallback? onChooseBackground;
  final VoidCallback? onChooseHaptic;
  final ValueChanged<bool>? onGoldChanged;
  final LinearGradient? previewGradient;
  final bool previewOnly;
  final Key scrollKey;

  @override
  Widget build(BuildContext context) => ListView(
    key: scrollKey,
    physics: const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    ),
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
    children: [
      Text(
        'MAKE IT YOURS',
        style: ZyraText.chapterLabel(color: ZyraColors.foregroundSecondary),
      ),
      const SizedBox(height: 8),
      Text(
        'Choose how ZYRA looks and responds.',
        style: ZyraText.heading(size: 23),
      ),
      const SizedBox(height: 7),
      Text(
        previewOnly
            ? 'Changes apply to this preview session only. Your account settings stay unchanged.'
            : 'Your choices apply across the app on this device. They never change your profile or account.',
        style: ZyraText.subtext(
          size: 12.5,
          color: ZyraColors.foregroundSecondary,
        ),
      ),
      const SizedBox(height: 22),
      _PersonalisationPreview(
        key: const ValueKey('personalisation_preview'),
        gradient: previewGradient,
      ),
      const SizedBox(height: 26),
      Text(
        'YOUR EXPERIENCE',
        style: ZyraText.chapterLabel(color: ZyraColors.foregroundSecondary),
      ),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(
          color: ZyraColors.surfaceFill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ZyraColors.surfaceBorder, width: 0.6),
        ),
        child: Column(
          children: [
            _PersonalisationRow(
              key: const ValueKey('personalisation_background'),
              icon: Icons.gradient_outlined,
              title: 'Background',
              value: snapshot.palette.label.replaceAll(' · Current', ''),
              hint: 'Choose the colour atmosphere used across ZYRA.',
              onTap: onChooseBackground,
            ),
            const _PersonalisationDivider(),
            _PersonalisationRow(
              key: const ValueKey('personalisation_gold'),
              icon: Icons.auto_awesome_outlined,
              title: 'Gold accents',
              value: snapshot.goldEnabled ? 'On' : 'Off',
              hint: 'Subtle gold details; motion follows your device settings.',
              trailing: Semantics(
                label: 'Gold accents',
                child: Switch.adaptive(
                  key: const ValueKey('personalisation_gold_toggle'),
                  value: snapshot.goldEnabled,
                  activeTrackColor: ZyraColors.journeyGold,
                  onChanged: onGoldChanged,
                ),
              ),
            ),
            const _PersonalisationDivider(),
            const _PersonalisationRow(
              key: ValueKey('personalisation_font'),
              icon: Icons.text_fields_outlined,
              title: 'App text',
              value: 'Poppins',
              hint: 'ZYRA uses a separate wordmark font.',
            ),
            const _PersonalisationDivider(),
            _PersonalisationRow(
              key: const ValueKey('personalisation_haptic'),
              icon: Icons.vibration_outlined,
              title: 'Haptic feel',
              value: snapshot.hapticLevel.label,
              hint: 'Choose how taps feel on this device.',
              onTap: onChooseHaptic,
            ),
          ],
        ),
      ),
    ],
  );
}

class _PersonalisationPreview extends StatelessWidget {
  const _PersonalisationPreview({super.key, this.gradient});

  final LinearGradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 17),
      decoration: BoxDecoration(
        color: gradient == null ? ZyraColors.surfaceFill : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ZyraColors.surfaceBorder, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: ZyraColors.journeyGold,
                ),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  'LIVE PREVIEW',
                  style: ZyraText.chapterLabel(color: _personalisationAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text('ZYRA', style: ZyraText.wordmark(size: 25)),
          const SizedBox(height: 5),
          Text(
            'Connecting Through Trust',
            style: ZyraText.preview(
              ZyraAppFont.poppins,
              size: 15,
              color: ZyraColors.foreground,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Your background changes appear immediately.',
            style: ZyraText.preview(
              ZyraAppFont.poppins,
              size: 11,
              color: ZyraColors.foregroundSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: 74,
            height: 1.2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: LinearGradient(
                colors: [
                  ZyraColors.journeyGold.withValues(alpha: 0),
                  ZyraColors.journeyGold,
                  ZyraColors.journeyGold.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalisationDivider extends StatelessWidget {
  const _PersonalisationDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 66,
      endIndent: 14,
      color: ZyraColors.ink(0.12),
    );
  }
}

class _PersonalisationRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String hint;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _PersonalisationRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.hint,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 15, 13, 15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ZyraColors.accentBg,
                  border: Border.all(
                    color: ZyraColors.accentBorder,
                    width: 0.6,
                  ),
                ),
                child: Icon(icon, size: 19, color: ZyraColors.foreground),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: ZyraText.body(
                        size: 14,
                        color: ZyraColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: ZyraText.subtext(
                        size: 12,
                        color: _personalisationAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hint,
                      style: ZyraText.subtext(
                        size: 10.5,
                        color: ZyraColors.foregroundSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ] else if (onTap != null) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 11),
                  child: Icon(
                    Icons.chevron_right,
                    size: 17,
                    color: ZyraColors.ink(0.34),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ZyraPersonalisationChoiceSheet<T> extends StatelessWidget {
  final String title;
  final List<T> options;
  final T selected;
  final String Function(T option) labelFor;
  final String? Function(T option)? detailFor;
  final Widget Function(T option)? leadingFor;
  final Widget Function(T option)? trailingFor;
  final TextStyle Function(T option, bool selected)? titleStyleFor;
  final ValueChanged<T> onSelected;

  const ZyraPersonalisationChoiceSheet({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.labelFor,
    required this.onSelected,
    this.detailFor,
    this.leadingFor,
    this.trailingFor,
    this.titleStyleFor,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.76;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Text(title, style: ZyraText.heading(size: 18)),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = option == selected;
                  final detail = detailFor?.call(option);
                  return Material(
                    color: isSelected
                        ? ZyraColors.accentBg
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(13),
                    child: Semantics(
                      button: true,
                      selected: isSelected,
                      child: InkWell(
                        key: ValueKey(
                          'personalisation_choice_${option.toString()}',
                        ),
                        borderRadius: BorderRadius.circular(13),
                        onTap: () => onSelected(option),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 44),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                if (leadingFor != null) ...[
                                  leadingFor!(option),
                                  const SizedBox(width: 11),
                                ],
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        labelFor(option),
                                        style:
                                            titleStyleFor?.call(
                                              option,
                                              isSelected,
                                            ) ??
                                            ZyraText.body(
                                              size: 14,
                                              color: ZyraColors.foreground,
                                            ),
                                      ),
                                      if (detail != null &&
                                          detail.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          detail,
                                          style: ZyraText.subtext(
                                            size: 10.5,
                                            color:
                                                ZyraColors.foregroundSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                if (trailingFor != null) ...[
                                  trailingFor!(option),
                                  const SizedBox(width: 10),
                                ],
                                ExcludeSemantics(
                                  child: Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    size: 18,
                                    color: isSelected
                                        ? _personalisationAccent
                                        : ZyraColors.ink(0.24),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
