// Current 2026-10-18: product summary only, not a formal app policy. The
// website notice covers the website, not the app. Fixed-label first-party
// telemetry and verified recovery email supersede the older dated inventory
// below; no placeholder consent control or legal acceptance is created here.
// Settings › Legal › Privacy & data.
//
// ADDED 2026-08-09. Founder: "on Muzz in settings they have a privacy and
// cookie setting."
//
// ── WHY THIS IS NOT A COOKIE SETTINGS SCREEN, which is what Muzz has.
//
// A cookie/consent screen exists to let you switch third-party tracking
// off. Muzz needs one because Muzz has trackers to switch off. Verified
// against pubspec.yaml on 2026-08-09, ZYRA's entire dependency list is:
//
//   google_fonts · supabase_flutter · image_picker · google_sign_in ·
//   sign_in_with_apple · crypto · shared_preferences · local_auth ·
//   package_info_plus · cupertino_icons
//
// There is no analytics SDK, no crash reporter, no attribution or ad
// library, and no WebView, so there is nothing a consent toggle could
// turn off. Shipping toggles that control nothing is worse than shipping
// none: it implies tracking exists and invites the user to believe they
// have switched it off.
//
// So this screen states the position instead. The project's own website
// document reached the same conclusion first — "a one-line 'no cookies'
// statement, which is itself a trust win".
//
// ── 🔴 THIS IS NOT THE PRIVACY POLICY, and must not be presented as one.
// It is a plain-English description of what the app does, written from
// the code. The formal Privacy Policy, Terms and Cookie Policy are
// drafted with the solicitor and are blocked on the open questions in
// ZYRA_LEGAL_RESEARCH — Article 9 consent route, retention periods and
// incorporation details. When those land, they get their own rows in the
// LEGAL section and this screen becomes the summary that sits above them.
//
// KEEP THIS FILE HONEST. Every claim below is checkable against the
// codebase today. If a tracking SDK is ever added, this screen is wrong
// the moment it lands, and it is the first thing that must change.

import 'package:flutter/material.dart';
import '../../dev/zyra_app_gold_preview.dart';

import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../state/app_state.dart';
import '../../services/zyra_product_telemetry.dart';
import 'legal_document_screen.dart';

class PrivacyAndDataScreen extends StatelessWidget {
  final bool guardian;

  const PrivacyAndDataScreen({super.key, this.guardian = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ZyraAppGoldDecoration(
        gradient: ZyraColors.genderGradient(AppState.instance.gender),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Privacy & data', style: ZyraText.heading(size: 17)),
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
            children: [
              const _Lead(
                'A summary of your account, sharing choices and device settings. '
                'This is not the full Privacy Policy.',
              ),
              const SizedBox(height: 26),

              _Block(
                heading: 'Feature usage',
                body: ZyraProductTelemetry.productionCollectionEnabled
                    ? 'This build can send limited feature-usage events to ZYRA. '
                          'Those events use fixed feature and action labels, not '
                          'your name, messages, answers or search terms. The app '
                          'does not configure an advertising or attribution SDK.'
                    : 'The app can keep a small, temporary record of fixed '
                          'feature actions in memory. Production usage-event '
                          'transmission is off in this build. These records do not '
                          'contain your name, messages, answers or search terms. '
                          'The app does not configure an advertising or attribution SDK.',
              ),

              const _Block(
                heading: 'How you sign in',
                body:
                    'Use Apple or Google to sign in. A separately verified '
                    'recovery email can help you recover your account with a '
                    'one-time code. ZYRA does not ask you to create an app password.',
              ),

              if (guardian)
                const _Block(
                  heading: 'What is stored about you',
                  body:
                      'Your account identity, the Seekers who link you, your '
                      'Journey access and the notification and privacy choices '
                      'you make. Messages you send as a Guardian are also kept '
                      'with the relevant conversation.',
                )
              else
                const _Block(
                  heading: 'What is stored about you',
                  body:
                      'Your profile and photographs, your onboarding answers, '
                      'the people you save, consider or pass, your Journeys and '
                      'their messages, and your Guardian links.\n\n'
                      'Some answers describe your religious practice. Those are '
                      'held as special-category data and are handled separately '
                      'from the rest of your profile.',
                ),

              if (guardian)
                const _Block(
                  heading: 'Who can see it',
                  body:
                      'Guardian accounts never appear in Profiles. A Seeker who '
                      'links you can see your Guardian identity. Other linked '
                      'Guardians see it only where you share responsibility in '
                      'the same Journey or Guardian Circle.',
                )
              else
                const _Block(
                  heading: 'Who can see it',
                  body:
                      'Other Seekers see your profile only where the rules of '
                      'the app allow it. A linked Guardian sees a defined, '
                      'limited set — never your full browsing, never your '
                      'private decisions.\n\n'
                      'Your Guardian is shown what they need to support you, '
                      'and nothing beyond it.',
                ),

              const _Block(
                heading: 'On your device only',
                body:
                    'App Lock and your last-used colour theme are kept on '
                    'your phone and are never uploaded.',
              ),

              _Block(
                heading: 'Deleting your account',
                body: guardian
                    ? 'Start in Settings › Account › Advanced. Review the '
                          'confirmation and the result before assuming your '
                          'Guardian account has been deleted. Records subject '
                          'to a safety or legal retention requirement are separate.'
                    : 'Start in Settings › Account › Advanced. Review the '
                          'confirmation and the result before assuming your '
                          'account has been deleted. Records subject to a '
                          'safety or legal retention requirement are separate.',
              ),

              const SizedBox(height: 8),
              const _Footnote(
                'This page is a plain-English summary of how the app behaves. '
                'The formal app documents below are not available yet; the '
                'website notice covers the public website only.',
              ),
              const SizedBox(height: 20),
              for (final document in ZyraLegalDocument.values) ...[
                _DocumentDestination(document: document, guardian: guardian),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Lead extends StatelessWidget {
  final String text;
  const _Lead(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: ZyraText.body(size: 15, color: ZyraColors.foreground));
}

class _Block extends StatelessWidget {
  final String heading;
  final String body;
  const _Block({required this.heading, required this.body});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: ZyraText.body(size: 14, color: ZyraColors.foreground),
        ),
        SizedBox(height: 6),
        Text(body, style: ZyraText.subtext(size: 13.5)),
      ],
    ),
  );
}

class _Footnote extends StatelessWidget {
  final String text;
  const _Footnote(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: ZyraText.subtext(size: 12, color: ZyraColors.foregroundSecondary),
  );
}

class _DocumentDestination extends StatelessWidget {
  const _DocumentDestination({required this.document, required this.guardian});
  final ZyraLegalDocument document;
  final bool guardian;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    key: ValueKey('privacy_document_${document.name}'),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(44, 48),
      padding: const EdgeInsets.all(16),
    ),
    onPressed: () {
      if (!context.mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) {
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              LegalDocumentScreen(document: document, guardian: guardian),
        ),
      );
    },
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(document.title, style: ZyraText.body(size: 14)),
              const SizedBox(height: 4),
              Text(
                'Not added yet',
                style: ZyraText.subtext(
                  size: 12,
                  color: ZyraColors.foregroundSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Icon(Icons.chevron_right, color: ZyraColors.foregroundSecondary),
      ],
    ),
  );
}
