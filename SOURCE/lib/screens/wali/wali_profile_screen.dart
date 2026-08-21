// Wali Profile tab — own identity + settings. Deliberately much
// smaller than the Seeker's ProfileScreen: per WALI ARCHITECTURE,
// "Guardian accounts carry identity only" — there's no Browse-visible
// profile, no connections list, no compatibility data to show here.
//
// 2026-07-26 (OA-ZYRA-124 per-account-type UX review, #27): four
// parity gaps with the Seeker ProfileScreen fixed. (1) The plan badge
// was static — Seeker's is tappable to the purchase screen, this
// wasn't. (2) There was no "Manage Subscription" settings row at all.
// (3+4) The "Notifications" and "Privacy" rows were `const
// _SettingsRow(label: ...)` with no `onTap` — silently dead taps, not
// wired to anything, which fails this project's own ERROR_AND_EMPTY_
// STATE_STANDARD ("never feel like a bug"). Fixed honestly rather
// than by copying the Seeker's screens verbatim: Seeker's
// PrivacySettingsScreen ("Visible in Browse") and UpgradeScreen (sells
// ZYRA Basic/One via AppState.plan) are both genuinely Seeker-only
// concepts that don't apply to a Guardian account — see this file's
// WaliNotificationSettingsScreen/_showPrivacyInfo/onNavigateToNetwork
// below for what actually does apply.

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_entitlement_service.dart';
import '../../services/zyra_wali_link_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_account_switch_sheet.dart';
import '../onboarding/account_path_overview_screen.dart';
import '../settings/help_support_screen.dart';
import '../welcome_screen.dart';
import 'link_wali_screen.dart';
import 'wali_notification_settings_screen.dart';
import '../../widgets/zyra_loading.dart';

class WaliProfileScreen extends StatefulWidget {
  // Jumps to the Network tab (the real Guardian+ purchase surface —
  // wali_network_screen.dart's "Get Guardian+" button), since that's
  // where entitlement is actually granted/purchased for a Guardian, unlike
  // the Seeker-only UpgradeScreen. Nullable/optional so this screen
  // still works if ever reached without a shell around it (matches
  // BrowseScreen.onNavigateToConnections' own nullable pattern).
  final VoidCallback? onNavigateToNetwork;
  const WaliProfileScreen({super.key, this.onNavigateToNetwork});

  @override
  State<WaliProfileScreen> createState() => _WaliProfileScreenState();
}

class _WaliProfileScreenState extends State<WaliProfileScreen> {
  // 2026-07-26 (#19): real entitlement, not AppState.waliHasWaliOne.
  bool _hasWaliOne = false;

  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_onChange);
    ZyraWaliLinkService.fetchLinkedPeople(asWali: true).then((people) {
      if (mounted) AppState.instance.setWaliRealLinkedSeekers(people);
    });
    ZyraEntitlementService.hasWaliOne().then((has) {
      if (mounted) setState(() => _hasWaliOne = has);
    });
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  /// CHANGED 2026-08-06. This row read `AppState.waliRelationship` — the
  /// answer given at Guardian onboarding, held in memory and never written
  /// anywhere. It now reads the live links, which is both authoritative and
  /// more truthful:
  ///
  /// relationship is per LINK, not per Guardian. The same man is father to
  /// his daughter and paternal uncle to his niece, so a single stored value
  /// on his profile could only ever have been right about one of them. Where
  /// the links genuinely differ, all of them are named rather than one being
  /// picked to stand for the rest.
  String _relationshipSummary(AppState state) {
    final labels = <String>{
      for (final p in state.waliRealLinkedSeekers)
        if (p.relationshipLabel != null) p.relationshipLabel!,
    };
    if (labels.isEmpty) return '—';
    return labels.join(', ');
  }

  // 2026-07-26 (#27): the "Privacy" row was previously dead (no onTap
  // at all). Rather than repurpose the Seeker's PrivacySettingsScreen —
  // its only toggle is "Visible in Browse", which is a genuinely
  // Seeker-only concept, since per WALI ARCHITECTURE a Guardian account has
  // no Browse-visible profile at all, so there's nothing to toggle —
  // this gives an honest explanation instead of a fake setting.
  void _showPrivacyInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ZyraColors.luxuryDarkPurple,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Privacy', style: ZyraText.heading(size: 16)),
        content: Text(
          "Guardian accounts don't appear in Browse and have no discoverability "
          "setting to control. Your identity is only ever shared with a Seeker "
          "who has linked you as their Guardian, and with any other Guardian they've "
          "also linked as part of the same Journey.",
          style: ZyraText.subtext(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Got it', style: ZyraText.subtext(size: 13)),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await ZyraAuth.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  /// The Guardian-side half of the one-identity context switch.
  /// Authentication is untouched: selecting Seeker either replaces the
  /// whole shell (once the context exists) or opens its first-time setup.
  /// The latter remains preview-gated until the server migration lands.
  Future<void> _switchAccount(BuildContext context) async {
    final selection = await showZyraAccountSwitchSheet(
      context: context,
      options: const [
        ZyraAccountSwitchOption(
          context: ZyraAccountContext.guardian,
          title: 'Guardian',
          subtitle: 'The people you support',
          icon: Icons.shield_outlined,
          current: true,
        ),
        ZyraAccountSwitchOption(
          context: ZyraAccountContext.seeker,
          title: 'Seeker',
          subtitle: 'First-time Seeker setup',
          icon: Icons.favorite_border,
          actionLabel: 'SET UP ›',
        ),
      ],
    );
    if (selection != ZyraAccountContext.seeker || !context.mounted) return;

    // The client shell switch is ready, but the current database cannot yet
    // say this Guardian also has a Seeker presentation. Keep the user inside
    // an honest setup preview instead of navigating to a shell whose server
    // reads would refuse them. This branch is removed when the migration is
    // explicitly authorised and its availability read is wired.
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SeekerOnboardingOverviewScreen(
          gender: AppState.instance.gender,
          migrationGatedPreview: true,
        ),
      ),
    );
  }

  // #22 — same real deletion as the Seeker side (ZyraAuth.deleteAccount(),
  // delete_own_account()). For a Wali, this also removes their
  // wali_links rows, ending their access to any linked Seeker.
  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ZyraColors.luxuryDarkPurple,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete your account?', style: ZyraText.heading(size: 16)),
        content: Text(
          'This permanently deletes your profile and ends your link to any '
          'Seeker you supervise. If you\'re a Seeker\'s only linked Guardian, they '
          'will need to link a new one. This cannot be undone.',
          style: ZyraText.subtext(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: ZyraText.subtext(size: 13)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB33A3A),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete Account', style: ZyraText.button(size: 13)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ZyraLoading(),
    );
    final ok = await ZyraAuth.deleteAccount();
    if (!context.mounted) return;
    Navigator.of(context).pop();

    if (ok) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Couldn't delete your account — try again, or email support@zyra.app.",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return Container(
      // 2026-07-25: was hardcoded to brandGradientMale regardless of the
      // signed-in Wali's actual gender (DR-ZYRA-094/OA-ZYRA-123 gap) —
      // now reads the Guardian's own gender like every other profile-context
      // screen. Every current test Wali persona is male, so this is a
      // no-op today but is correct once a female Wali persona exists.
      decoration: BoxDecoration(
        gradient: ZyraColors.genderGradient(state.gender),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: ZyraColors.iconButtonBg,
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Colors.white38,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.waliName ?? 'Your Profile',
                        style: ZyraText.heading(size: 20),
                      ),
                      const SizedBox(height: 4),
                      // 2026-07-26 (#27): now tappable → Network tab, the
                      // real Wali One purchase surface. Was previously a
                      // static, non-tappable badge (parity gap vs. the
                      // Seeker ProfileScreen's own tappable plan badge).
                      GestureDetector(
                        onTap: widget.onNavigateToNetwork,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: ZyraColors.accentBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: ZyraColors.accentBorder,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            _hasWaliOne ? 'Guardian+' : 'Standard Guardian',
                            style: ZyraText.subtext(
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'ABOUT YOU',
              style: ZyraText.chapterLabel(color: Colors.white54),
            ),
            const SizedBox(height: 10),
            _InfoRow(label: 'Relationship', value: _relationshipSummary(state)),
            _InfoRow(
              label: 'Linked Seekers',
              value: '${state.waliRealLinkedSeekers.length}',
            ),
            const SizedBox(height: 24),
            Text(
              'SETTINGS',
              style: ZyraText.chapterLabel(color: Colors.white54),
            ),
            const SizedBox(height: 10),
            _SettingsRow(
              label: 'Notifications',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const WaliNotificationSettingsScreen(),
                ),
              ),
            ),
            _SettingsRow(
              label: 'Privacy',
              onTap: () => _showPrivacyInfo(context),
            ),
            _SettingsRow(
              label: 'Manage Subscription',
              onTap: widget.onNavigateToNetwork,
            ),
            _SettingsRow(
              label: 'Link a Seeker',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LinkWaliScreen(asWali: true),
                ),
              ),
            ),
            _SettingsRow(
              label: 'Help & Support',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
              ),
            ),
            if (!kReleaseMode)
              _SettingsRow(
                label: 'Switch Account',
                onTap: () => _switchAccount(context),
              ),
            _SettingsRow(label: 'Sign Out', onTap: () => _signOut(context)),
            _SettingsRow(
              label: 'Delete Account',
              destructive: true,
              onTap: () => _deleteAccount(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: ZyraText.subtext(size: 13))),
          Text(value, style: ZyraText.body(size: 13, color: Colors.white)),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool destructive;
  const _SettingsRow({
    required this.label,
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: ZyraText.body(
                  size: 13.5,
                  color: destructive ? ZyraColors.destructive : Colors.white,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: destructive ? ZyraColors.destructive : Colors.white24,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
