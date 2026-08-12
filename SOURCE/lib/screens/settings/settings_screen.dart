// Settings — the account control centre.
//
// NEW 2026-08-06. Settings was previously a SECTION inside
// profile_screen.dart: a label and seven flat rows, below the profile card
// and a list of Connections counts.
//
// That one fact explained most of the Founder's review. A section cannot
// have a dashboard. Six groups nested inside a Profile page make it longer,
// not clearer. Delete Account was prominent because a flat list of seven has
// no hierarchy to demote anything into. And the page already duplicated
// Connections — Passed, Saved and Considered were rendered as rows, which is
// exactly what the "don't duplicate" principle forbids.
//
// THE DIVISION OF RESPONSIBILITY, Founder 2026-08-06,
// AMENDED 2026-08-07 — compatibility moved to Edit Profile:
//   Connections   manages relationships
//   Guardian page manages Guardians
//   Edit Profile  manages compatibility — what you look like to others
//   Settings      manages the account, privacy, notifications, support
//
// DELIBERATELY ABSENT:
//   Appearance      theme and language do not exist. An empty section
//                   labelled "future" is the dumping ground §8 warns about.
//   Data Export     Article 15, unbuilt, and three of its rules are open
//                   solicitor questions. Founder confirmed out of scope.
//   Change password ZYRA is OAuth-only — Google and Apple, no password for
//                   ANY user (zyra_auth.dart, Founder instruction
//                   2026-07-18). A row that errors for everyone is worse
//                   than no row.
//
// Privacy Policy appears under both Privacy and Support in the brief. It is
// here once, under Support, because two routes to one document is the same
// duplication in miniature.

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_wali_link_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../connections/connections_screen.dart' show ZyraCardMetrics;
import '../subscription/upgrade_screen.dart';
import '../../services/zyra_app_lock.dart';
import 'account_advanced_screen.dart';
import 'app_lock_screen.dart';
import 'blocked_users_screen.dart';
import 'feedback_screen.dart';
import 'help_support_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_and_data_screen.dart';
import 'privacy_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _guardians = 0;
  bool _hasMain = false;

  @override
  void initState() {
    super.initState();
    ZyraWaliLinkService.fetchLinkedPeople(asWali: false).then((people) {
      if (!mounted) return;
      setState(() {
        _guardians = people.length;
        _hasMain = people.any((p) => p.isMain);
      });
    });
  }

  /// The provider the user actually signed in with. Shown rather than
  /// inferred: ZYRA has no password, so "how do I get in" is a question
  /// only the provider can answer, and saying so is more useful than
  /// hiding it.
  String? get _providerRaw =>
      ZyraAuth.currentUser?.appMetadata['provider'] as String?;

  /// Short label — the summary card and the ACCOUNT row. Kept to one or
  /// two words so neither overflows.
  ///
  /// THE DEFAULT BRANCH USED TO RETURN 'Your provider'. Founder 2026-08-07:
  /// fix it so developers notice a misconfiguration immediately. That
  /// wording read as a deliberate design choice and so concealed a real
  /// fact — every one of the 149 accounts in the database today has
  /// `provider = 'email'` (seeded test accounts through the password
  /// provider, which is still enabled server-side). Not one Google or
  /// Apple identity has ever been created, so the panel has been reading
  /// "Signed in with Your provider" for its entire life and looking
  /// deliberate while doing it. A fallback that produces a plausible
  /// string is how a display bug survives to launch.
  String get _provider => switch (_providerRaw) {
        'google' => 'Google',
        'apple' => 'Apple',
        'email' => kReleaseMode ? 'Email' : 'Test account',
        null => kReleaseMode ? 'Unknown' : 'NOT SET',
        _ => _providerRaw ?? 'Unknown',
      };

  /// Non-null only when something is wrong. Shown in the dialog, loudly,
  /// and never in release — a real user cannot act on any of this.
  String? get _providerWarning {
    if (kReleaseMode) return null;
    return switch (_providerRaw) {
      'google' || 'apple' => null,
      'email' =>
        'DEV: signed in through the email/password provider, not OAuth. '
            'This is a seeded test account. Real builds must use Google or '
            'Apple — if you are seeing this on a device, OAuth is not '
            'configured.',
      null => 'DEV: no provider on the session at all. Check OAuth setup.',
      _ => 'DEV: unexpected provider "$_providerRaw".',
    };
  }

  String get _email => ZyraAuth.currentUser?.email ?? '—';

  /// Apple's Hide My Email mints a random forwarding address. It is the
  /// only address ZYRA ever receives, and shown without explanation it
  /// reads as an error — the user concludes we have the wrong address and
  /// goes looking for a way to correct it, which does not exist.
  bool get _isAppleRelay => _email.endsWith('@privaterelay.appleid.com');

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Settings', style: ZyraText.heading(size: 17)),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: ZyraColors.genderGradient(state.gender)),
        child: SafeArea(
          child: ListView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
            children: [
              // §1 — the page answers "what can I control?" before it offers
              // anything to control. Every value here is real; nothing is a
              // placeholder for a feature that does not exist.
              _SummaryCard(
                membership: state.plan == ZyraPlan.basic ? 'Free' : 'ZYRA One',
                guardians: _guardians == 0
                    ? 'None linked'
                    : _hasMain
                        ? '$_guardians linked · 1 Main'
                        : '$_guardians linked · no Main',
                signedInWith: _provider,
              ),

              const SizedBox(height: 28),
              _Section(
                title: 'ACCOUNT',
                children: [
                  _Row(
                    label: 'Personal information',
                    value: state.name,
                    onTap: () => _todo(context, 'Personal information'),
                  ),
                  _Row(
                    label: 'Sign-in & security',
                    value: _provider,
                    onTap: () => _showSignIn(context),
                  ),
                  // ADDED 2026-08-07. Sits in ACCOUNT rather than PRIVACY
                  // deliberately: it protects the account as a whole, not
                  // one aspect of what other people can see, and it is the
                  // row people will come looking for after being told the
                  // feature exists.
                  _Row(
                    label: 'App lock',
                    value: ZyraAppLock.instance.enabled ? 'On' : 'Off',
                    onTap: () async {
                      await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const AppLockScreen(),
                      ));
                      if (mounted) setState(() {}); // the row shows On/Off
                    },
                  ),
                  // §5 — Delete is two levels down, never in the main list.
                  _Row(
                    label: 'Advanced',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const AccountAdvancedScreen(),
                    )),
                  ),
                ],
              ),

              // ── COMPATIBILITY — MOVED OUT 2026-08-07 ─────────────────
              //
              // Founder: "in settings if the compatibility section is the
              // same as edit profile then you gotta maybe move that section
              // into edit profile part."
              //
              // It was the same. Profile had an Edit Profile button that
              // went nowhere while the five editors it implied lived here,
              // which made Settings the second route to an intention that
              // belonged on the first.
              //
              // Now in screens/profile/edit_profile_screen.dart, on the
              // Founder's own principle: "Settings should configure the
              // account, not become a duplicate navigation hub." Sect,
              // lifestyle and what someone wants in a marriage are not
              // account configuration — they are the profile.
              //
              // This supersedes the division of responsibility in this
              // file's header, which gave compatibility to Settings.

              _Section(
                title: 'PRIVACY',
                children: [
                  _Row(
                    label: 'Discovery & visibility',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const PrivacySettingsScreen(),
                    )),
                  ),
                  _Row(
                    label: 'Blocked users',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const BlockedUsersScreen(),
                    )),
                  ),
                ],
              ),

              _Section(
                title: 'NOTIFICATIONS',
                children: [
                  _Row(
                    label: 'Notifications & emails',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const NotificationSettingsScreen(),
                    )),
                  ),
                ],
              ),

              _Section(
                title: 'MEMBERSHIP',
                children: [
                  _Row(
                    label: 'Manage subscription',
                    value: state.plan == ZyraPlan.basic ? 'Free' : 'ZYRA One',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const UpgradeScreen(),
                    )),
                  ),
                ],
              ),

              _Section(
                title: 'SUPPORT',
                children: [
                  _Row(
                    label: 'Help & support',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const HelpSupportScreen(),
                    )),
                  ),
                  // ADDED 2026-08-07 (Founder: "a feedback section where we
                  // can improve the app from users requests").
                  //
                  // A SEPARATE ROW from Help & support, not a section inside
                  // it. Help is for someone stuck who wants an answer;
                  // feedback is for someone fine who has a thought. Folding
                  // the second into the first would put every idea behind a
                  // door marked "problem".
                  _Row(
                    label: 'Send feedback',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const FeedbackScreen(),
                    )),
                  ),
                ],
              ),

              // ADDED 2026-08-09 (Founder, from the Muzz teardown: "they
              // have a privacy and cookie setting"). A LEGAL section, not a
              // row inside PRIVACY — the existing PRIVACY section is about
              // choices the member makes (who sees them, who is blocked).
              // This is about what the company does, which is a different
              // question and belongs under its own heading.
              //
              // One row for now. The Privacy Policy and Terms get their own
              // rows the day the drafted text exists; until then a row that
              // opens nothing is worse than no row.
              _Section(
                title: 'LEGAL',
                children: [
                  _Row(
                    label: 'Privacy & data',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const PrivacyAndDataScreen(),
                    )),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              const Center(child: _VersionFooter()),
            ],
          ),
        ),
      ),
    );
  }

  /// Honest placeholder. These editors are the next increment and the rows
  /// are here because the structure is the deliverable — but a row that
  /// silently does nothing is worse than one that says so.
  void _todo(BuildContext context, String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what — editor coming next.')),
    );
  }

  /// ZYRA holds no password and does not own the email address. Rather than
  /// offer controls that cannot work, this says what is true.
  /// Sign-in & security.
  ///
  /// Founder-approved content, 2026-08-07: provider, email, an Apple relay
  /// explanation ONLY when the address is actually a relay, and an honest
  /// statement about recovery. Nothing here is invented — the section says
  /// what is true and stops.
  void _showSignIn(BuildContext context) {
    final warning = _providerWarning;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2A1F33),
        title: Text('Sign-in & security', style: ZyraText.heading(size: 17)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Signed in with $_provider',
                  style: ZyraText.body(size: 15, color: Colors.white)),
              const SizedBox(height: 4),
              Text(_email,
                  style: ZyraText.subtext(size: 13, color: Colors.white54)),

              // Only when it IS a relay. One row, two meanings — the copy
              // should not pretend otherwise.
              if (_isAppleRelay) ...[
                const SizedBox(height: 16),
                Text(
                  'Apple is hiding your real address. Email from ZYRA is '
                  'forwarded to you by Apple, and you can stop that at any '
                  'time in your Apple ID settings.',
                  style: ZyraText.subtext(size: 12.5, color: Colors.white54),
                ),
              ],

              const SizedBox(height: 16),
              Text(
                'ZYRA never stores a password, and cannot change your email '
                'address — $_provider manages both.',
                style: ZyraText.subtext(size: 12.5, color: Colors.white38),
              ),

              // The largest support burden OAuth-only apps carry. Said once,
              // calmly, here — rather than discovered by someone in distress.
              const SizedBox(height: 12),
              Text(
                'Because there is no ZYRA password, access to your account '
                'is access to your $_provider account. If you lose that, we '
                'have no way to let you back in.',
                style: ZyraText.subtext(size: 12.5, color: Colors.white38),
              ),

              if (warning != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8A65).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFFFF8A65).withValues(alpha: 0.4)),
                  ),
                  child: Text(warning,
                      style: ZyraText.subtext(
                          size: 12, color: const Color(0xFFFFAB91))),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close', style: ZyraText.body(size: 14, color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}

// ── Summary card ───────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final String membership;
  final String guardians;
  final String signedInWith;

  const _SummaryCard({
    required this.membership,
    required this.guardians,
    required this.signedInWith,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14), width: 0.5),
      ),
      child: Column(
        children: [
          _line('Membership', membership),
          _divider(),
          _line('Guardians', guardians),
          _divider(),
          _line('Signed in with', signedInWith),
        ],
      ),
    );
  }

  Widget _line(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Expanded(child: Text(k, style: ZyraText.subtext(size: 13, color: Colors.white54))),
            Text(v, style: ZyraText.body(size: 14, color: Colors.white)),
          ],
        ),
      );

  Widget _divider() => Container(
        height: 0.5,
        margin: const EdgeInsets.symmetric(vertical: 3),
        color: Colors.white.withValues(alpha: 0.08),
      );
}

// ── Section ────────────────────────────────────────────────────────────
/// The version line at the foot of Settings — "1.0.0 (1)".
///
/// ADDED 2026-08-09. Founder, from the Muzz teardown: "at bottom a version
/// number with 8.77.1 (563)". Same shape: marketing version, then build
/// number in brackets.
///
/// ── WHY package_info_plus AND NOT A CONSTANT. A hand-maintained
/// `const kVersion = '1.0.0'` is wrong the first time someone bumps
/// pubspec and forgets, and a version string that lies is worse than no
/// version string — its entire purpose is for a user to read it back to
/// support. This reads the real value out of the built app bundle, so it
/// cannot disagree with what was shipped.
///
/// ── WHY IT IS ALLOWED TO SHOW NOTHING. The lookup is async and can fail
/// on a platform that has not been configured. On failure this renders the
/// wordmark alone, exactly as the footer did before today — an empty space
/// where a version should be is a smaller problem than an error, and this
/// is the least important element on the screen.
class _VersionFooter extends StatefulWidget {
  const _VersionFooter();

  @override
  State<_VersionFooter> createState() => _VersionFooterState();
}

class _VersionFooterState extends State<_VersionFooter> {
  String? _line;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _line = '${info.version} (${info.buildNumber})');
    } catch (_) {
      // Deliberately silent — see the class comment.
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('ZYRA', style: ZyraText.subtext(size: 11, color: Colors.white24)),
          if (_line != null) ...[
            const SizedBox(height: 3),
            // SelectableText, not Text: the one thing anybody ever does
            // with a version number is send it to support.
            SelectableText(
              _line!,
              style: ZyraText.subtext(size: 11, color: Colors.white24),
            ),
          ],
        ],
      );
}

class _Section extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  const _Section({required this.title, required this.children, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: ZyraText.chapterLabel(color: Colors.white54)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: ZyraText.subtext(size: 11.5, color: Colors.white38)),
          ],
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 0.5),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

// ── Row ────────────────────────────────────────────────────────────────
//
// §6 — where a setting has a current value, show it. "Membership · ZYRA One"
// answers the question without costing a tap.
class _Row extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;
  final bool destructive;

  const _Row({
    required this.label,
    required this.onTap,
    this.value,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final tint = destructive ? Colors.redAccent.shade100 : Colors.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Expanded(child: Text(label, style: ZyraText.body(size: 15, color: tint))),
              if (value != null && value!.isNotEmpty) ...[
                Flexible(
                  child: Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ZyraText.subtext(size: 13, color: Colors.white38),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(Icons.chevron_right, size: 18, color: Colors.white.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}
