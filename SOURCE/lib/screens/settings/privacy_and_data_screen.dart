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

import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../state/app_state.dart';

class PrivacyAndDataScreen extends StatelessWidget {
  const PrivacyAndDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
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
            children: const [
              _Lead(
                'ZYRA collects what it needs to introduce you properly, and '
                'nothing for advertising.',
              ),
              SizedBox(height: 26),

              _Block(
                heading: 'Cookies and tracking',
                body:
                    'The ZYRA app uses no cookies, no analytics and no '
                    'advertising or attribution services. Nothing you do in '
                    'the app is measured by a third party, so there is '
                    'nothing here to switch off.\n\n'
                    'If that ever changes, you will be asked first, and this '
                    'screen will say so.',
              ),

              _Block(
                heading: 'How you sign in',
                body:
                    'Through Apple or Google. ZYRA never sees or stores a '
                    'password, and does not ask for your phone number.',
              ),

              _Block(
                heading: 'What is stored about you',
                body:
                    'Your profile and photographs, your onboarding answers, '
                    'the people you save, consider or pass, your Journeys and '
                    'their messages, and your Guardian links.\n\n'
                    'Some answers describe your religious practice. Those are '
                    'held as special-category data and are handled separately '
                    'from the rest of your profile.',
              ),

              _Block(
                heading: 'Who can see it',
                body:
                    'Other Seekers see your profile only where the rules of '
                    'the app allow it. A linked Guardian sees a defined, '
                    'limited set — never your full browsing, never your '
                    'private decisions.\n\n'
                    'Your Guardian is shown what they need to support you, '
                    'and nothing beyond it.',
              ),

              _Block(
                heading: 'On your device only',
                body:
                    'App Lock and your last-used colour theme are kept on '
                    'your phone and are never uploaded.',
              ),

              _Block(
                heading: 'Deleting your account',
                body:
                    'Settings › Account › Advanced. Deletion removes your '
                    'profile, photographs, answers and Journeys.',
              ),

              SizedBox(height: 8),
              _Footnote(
                'This page is a plain-English summary of how the app behaves. '
                'The full Privacy Policy and Terms will be published before '
                'launch and linked here.',
              ),
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
      Text(text, style: ZyraText.body(size: 15, color: Colors.white));
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
            Text(heading, style: ZyraText.body(size: 14, color: Colors.white)),
            const SizedBox(height: 6),
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
        style: ZyraText.subtext(size: 12, color: Colors.white38),
      );
}
