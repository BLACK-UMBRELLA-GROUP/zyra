import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../dev/zyra_one_journey_account_presentation.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import 'zyra_floating_surface.dart';
import 'zyra_developer_title.dart';
import 'zyra_photo_rules_card.dart';
import 'zyra_tap_feedback.dart';

/// LOCK 45 presentation; the admitted host owns every route and value.
class ZyraEditProfilePresentation extends StatefulWidget {
  const ZyraEditProfilePresentation({
    super.key,
    required this.name,
    required this.age,
    required this.gender,
    required this.photoCount,
    required this.about,
    required this.location,
    required this.nationality,
    required this.ethnicity,
    required this.bioProgress,
    required this.preferencesProgress,
    required this.onPreferences,
    required this.onSupport,
    this.onPhotos,
    this.onAbout,
    this.onLocation,
    this.onNationality,
    this.onEthnicity,
    this.onBio,
    this.leading,
    this.showTitle = true,
  });
  final String name, gender, about, location, nationality, ethnicity;
  final int? age;
  final int photoCount;
  final List<String> bioProgress;
  final String preferencesProgress;
  final VoidCallback? onPhotos, onAbout, onLocation, onNationality, onEthnicity;
  final VoidCallback? onPreferences, onSupport;
  final ValueChanged<int>? onBio;
  final Widget? leading;
  final bool showTitle;

  @override
  State<ZyraEditProfilePresentation> createState() =>
      _ZyraEditProfilePresentationState();
}

class _ZyraEditProfilePresentationState
    extends State<ZyraEditProfilePresentation> {
  final _support = TapGestureRecognizer();
  @override
  void dispose() {
    _support.dispose();
    super.dispose();
  }

  Widget _section(String title, List<Widget> rows, {Key? key}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 10),
        child: Text(
          title,
          style: ZyraText.body(
            size: 10.5,
            color: ZyraColors.secondaryText,
          ).copyWith(letterSpacing: 1),
        ),
      ),
      ZyraFloatingSurface(
        radius: 16,
        child: Container(
          key: key,
          decoration: BoxDecoration(
            color: ZyraColors.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ZyraColors.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rows,
          ),
        ),
      ),
    ],
  );

  Widget _row(
    String id,
    String label,
    String? value,
    VoidCallback? onTap, {
    String? subtitle,
    bool locked = false,
  }) => ZyraSettingsRow(
    key: ValueKey(id),
    label: label,
    value: value,
    subtitle: subtitle,
    onTap: locked ? null : onTap,
    smooth: false,
    locked: locked,
    wrapValue: true,
    valueSize: locked ? 14 : 13,
    horizontalPadding: 16,
    verticalPadding: 8,
    minHeight: 51,
  );

  // LOCK45 shows the first words, within V356's 230pt preview width.
  // Choose whole words instead of clipping reading text with an ellipsis (V9).
  String _aboutSnippet(BuildContext context) {
    final words = widget.about.trim().split(RegExp(r'\s+'));
    final painter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    );
    final style = DefaultTextStyle.of(
      context,
    ).style.merge(ZyraText.body(size: 12, color: ZyraColors.secondaryText));
    var snippet = words.first;
    for (var count = 1; count <= words.length; count++) {
      final candidate = words.take(count).join(' ');
      painter.text = TextSpan(text: candidate, style: style);
      painter.layout();
      if (painter.width > 230 && count > 1) break;
      snippet = candidate;
    }
    painter.dispose();
    return snippet;
  }

  @override
  Widget build(BuildContext context) {
    _support.onTap = ZyraTapFeedback.onTap(context, widget.onSupport);
    final content = ListView(
      key: const ValueKey('edit_profile_content_scroll'),
      padding: EdgeInsets.fromLTRB(20, widget.showTitle ? 30 : 42, 20, 32),
      children: [
        if (widget.leading != null) widget.leading!,
        _section('PHOTOS', [
          _row(
            'edit_profile_photos',
            'Photos and video',
            '${widget.photoCount} of 6',
            widget.onPhotos,
            subtitle: 'Your first photo is the one families see first',
          ),
        ]),
        const Padding(
          padding: EdgeInsets.fromLTRB(2, 10, 2, 20),
          child: ZyraPhotoRulesCard(),
        ),
        // The next 30pt section margin wins over the preceding 20pt margin
        // in the locked prototype's collapsed block flow.
        const SizedBox(height: 10),
        _section('ABOUT YOU', [
          _row(
            'edit_profile_about',
            'A few words about you',
            null,
            widget.onAbout,
            subtitle: widget.about.isEmpty ? null : _aboutSnippet(context),
          ),
          _row(
            'edit_profile_location',
            'Where you live',
            widget.location,
            widget.onLocation,
          ),
          _row(
            'edit_profile_nationality',
            'Nationality',
            widget.nationality,
            widget.onNationality,
          ),
          _row(
            'edit_profile_ethnicity',
            'Ethnicity',
            widget.ethnicity,
            widget.onEthnicity,
          ),
        ]),
        const SizedBox(height: 30),
        _section('JOURNEY BIO', [
          for (final entry in const [
            'Work and education',
            'Family and marriage',
            'Practical life',
          ].indexed)
            _row(
              'edit_profile_bio_${entry.$1}',
              entry.$2,
              widget.bioProgress[entry.$1],
              widget.onBio == null ? null : () => widget.onBio!(entry.$1),
            ),
        ]),
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
          child: Text(
            'Your Journey Bio is shown only to someone you are in a Journey with.',
            style: ZyraText.body(
              size: 12.5,
              color: ZyraColors.secondaryStrong,
            ).copyWith(height: 1.5),
          ),
        ),
        const SizedBox(height: 30),
        _section('PARTNER PREFERENCES', [
          _row(
            'compatibility-editor-trafficLights',
            'Partner preferences',
            widget.preferencesProgress,
            widget.onPreferences,
            subtitle: 'Prefer · Open to this · Not for me',
          ),
        ], key: const ValueKey('edit_profile_answers_card')),
        const SizedBox(height: 30),
        _section(
          'FROM YOUR IDENTITY CHECK',
          [
            _row(
              'edit_profile_identity_name',
              'Name',
              widget.name,
              null,
              locked: true,
            ),
            _row(
              'edit_profile_identity_birth',
              'Date of birth',
              widget.age == null ? '—' : 'Age ${widget.age}',
              null,
              locked: true,
            ),
            _row(
              'edit_profile_identity_gender',
              'Gender',
              widget.gender,
              null,
              locked: true,
            ),
          ],
          key: const ValueKey('edit_profile_fixed_card'),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text:
                      'These come from your identity check and can’t be changed here. If one is wrong, ',
                ),
                TextSpan(
                  text: 'contact support',
                  recognizer: _support,
                  style: const TextStyle(
                    color: ZyraColors.goldText,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
            key: const ValueKey('edit_profile_open_support'),
            style: ZyraText.body(
              size: 12.5,
              color: ZyraColors.secondaryStrong,
            ).copyWith(height: 1.5),
          ),
        ),
      ],
    );
    if (!widget.showTitle) return content;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          child: ZyraDeveloperTitle(
            child: Text(
              'Edit profile',
              key: const ValueKey('edit_profile_preview_title'),
              style: ZyraText.heading(size: 28),
            ),
          ),
        ),
        Expanded(child: content),
      ],
    );
  }
}
