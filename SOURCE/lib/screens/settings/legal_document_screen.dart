import '../../widgets/zyra_tap_feedback.dart';
import 'package:flutter/material.dart';

import '../../services/zyra_product_telemetry.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import 'help_support_screen.dart';

enum ZyraLegalDocument {
  privacyPolicy('Privacy Policy'),
  terms('Terms of Service');

  const ZyraLegalDocument(this.title);
  final String title;
}

/// Honest document availability, not invented legal text or acceptance.
/// The public website notice covers the website only, not the member app.
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.document,
    this.guardian = false,
  });

  final ZyraLegalDocument document;
  final bool guardian;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
    child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(document.title, style: ZyraText.heading(size: 17)),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          key: ValueKey('legal_document_${document.name}'),
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 36),
          children: [
            Icon(
              Icons.description_outlined,
              size: 34,
              color: ZyraColors.foregroundSecondary,
            ),
            const SizedBox(height: 22),
            Text('Not available yet', style: ZyraText.heading(size: 24)),
            const SizedBox(height: 14),
            Text(
              'The final ${document.title} for the ZYRA app has not been added here. '
              'The Privacy & data summary and the website privacy notice are not '
              'substitutes for this document.',
              style: ZyraText.body(size: 14),
            ),
            const SizedBox(height: 18),
            Text(
              'No document acceptance is recorded on this page. If you need '
              'clarification before continuing, use Help & support.',
              style: ZyraText.subtext(
                size: 13,
                color: ZyraColors.foregroundSecondary,
              ),
            ),
            const SizedBox(height: 30),
            OutlinedButton.icon(
              key: const ValueKey('legal_document_help'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(44, 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              ),
              onPressed: ZyraTapFeedback.onTap(context, () {
                if (!context.mounted ||
                    !(ModalRoute.of(context)?.isCurrent ?? false)) {
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => HelpSupportScreen(
                      telemetrySurface: guardian
                          ? ZyraTelemetrySurface.guardian
                          : ZyraTelemetrySurface.seeker,
                    ),
                  ),
                );
              }),
              icon: const Icon(Icons.help_outline_rounded),
              label: Text(
                'Open Help & support',
                style: ZyraText.button(size: 14),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
