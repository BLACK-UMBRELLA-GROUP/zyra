import 'package:flutter/material.dart';

import '../widgets/zyra_wordmark.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_floating_surface.dart';
import 'zyra_email_templates.dart';

/// LOCK 39 sample rendering. No button here sends mail or opens a live route.
class ZyraEmailTemplatePreview extends StatelessWidget {
  const ZyraEmailTemplatePreview({super.key, required this.template});

  final ZyraEmailTemplate template;

  @override
  Widget build(BuildContext context) => Material(
    color: ZyraColors.ivoryTop,
    child: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        children: [
          Text(template.subject, style: ZyraText.heading(size: 22)),
          const SizedBox(height: 16),
          Text('ZYRA', style: ZyraText.body(size: 13)),
          Text(
            'to ${template.recipientFirstName} · ${template.sampleDate}',
            style: ZyraText.body(size: 12, color: ZyraColors.secondaryText),
          ),
          const SizedBox(height: 18),
          ZyraFloatingSurface(
            radius: 20,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(19, 22, 19, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ZyraWordmark(
                    text: 'Z Y R A',
                    semanticsLabel: 'ZYRA',
                    textAlign: TextAlign.center,
                    style: ZyraText.heading(
                      size: 18,
                      color: ZyraColors.goldText,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _chipColor.withValues(alpha: .11),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 7,
                        ),
                        child: Text(
                          template.chipLabel,
                          style: ZyraText.body(size: 12, color: _chipColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 23),
                  Text(
                    'Assalaamu alaikum ${template.recipientFirstName},',
                    style: ZyraText.body(size: 15),
                  ),
                  const SizedBox(height: 14),
                  for (final paragraph in template.paragraphs) ...[
                    Text(paragraph, style: ZyraText.body(size: 14.5)),
                    const SizedBox(height: 14),
                  ],
                  if (template.buttonLabel != null) ...[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: ZyraColors.journeyGold),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        child: Text(
                          template.buttonLabel!,
                          textAlign: TextAlign.center,
                          style: ZyraText.body(size: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 17),
                  ],
                  for (final footer in template.footers) ...[
                    Text(
                      footer,
                      style: ZyraText.body(
                        size: 12.5,
                        color: ZyraColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 13),
                  ],
                  Text(template.signOff, style: ZyraText.body(size: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'ZYRA · ${ZyraEmailTemplate.settingsFooter}',
            style: ZyraText.body(size: 11, color: ZyraColors.secondaryText),
          ),
        ],
      ),
    ),
  );

  Color get _chipColor => switch (template.chipTone) {
    ZyraEmailChipTone.muted => ZyraColors.secondaryText,
    ZyraEmailChipTone.gold => ZyraColors.goldText,
    ZyraEmailChipTone.green => ZyraColors.greenText,
    ZyraEmailChipTone.red => ZyraColors.dangerText,
  };
}
