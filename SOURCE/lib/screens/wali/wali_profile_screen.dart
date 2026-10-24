// Guardian Profile follows the same ownership rule as Seeker Profile:
// identity and role-specific information live here; account controls live
// in Settings. Guardian remains intentionally smaller because it has no
// Browse-visible profile, photos, compatibility balance or Journey History.

import 'package:flutter/material.dart';
import '../../dev/zyra_app_gold_preview.dart';
import '../../dev/zyra_dev_local_preview.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_account_state.dart';
import '../../services/zyra_app_invite.dart';
import '../../services/zyra_developer_access.dart';
import '../../services/zyra_entitlement_service.dart';
import '../../services/zyra_notification_prefs_service.dart';
import '../../services/zyra_wali_link_service.dart';
import '../../services/zyra_promotion_engine.dart';
import '../../services/zyra_product_telemetry.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_account_switch_sheet.dart';
import '../../widgets/zyra_one_profile_avatar.dart';
import '../../widgets/zyra_profile_membership_row.dart';
import '../onboarding/account_path_overview_screen.dart';
import '../settings/help_support_screen.dart';
import '../settings/personalisation_screen.dart';
import '../settings/settings_screen.dart';
import '../subscription/upgrade_screen.dart';
import '../welcome_screen.dart';

class WaliProfileScreen extends StatefulWidget {
  // Retained for shell compatibility. Membership opens the shared plan page.
  final VoidCallback? onNavigateToNetwork;
  final Future<Map<ZyraNotifyCategory, bool>?> Function()?
  loadNotificationPreferences;
  final Future<bool> Function(ZyraNotifyCategory, bool)?
  saveNotificationPreference;
  final Future<ZyraSourceResult<List<WaliLinkedPerson>>> Function()?
  loadLinkedSeekers;

  const WaliProfileScreen({
    super.key,
    this.onNavigateToNetwork,
    this.loadNotificationPreferences,
    this.saveNotificationPreference,
    this.loadLinkedSeekers,
  });

  @override
  State<WaliProfileScreen> createState() => _WaliProfileScreenState();
}

class _WaliProfileScreenState extends State<WaliProfileScreen> {
  // A failed read is not a confirmed membership loss. Keep the rendered
  // result bound to the same account lifetime, separately from paid access.
  ZyraSourceResult<bool>? _membershipAccess;
  String? _membershipOwner;
  int? _membershipGeneration;
  final _membershipDisplay = ValueNotifier<String>('Checking…');
  late final String? _linksOwner;
  late final int _linksGeneration;
  late final bool _linksPreview;
  bool _linksLoading = true;
  bool _linksUnavailable = false;

  bool get _linksCurrent {
    final owner = _linksOwner;
    return owner != null &&
        _ownerId() == owner &&
        ZyraAccountState.isCurrent(owner, _linksGeneration);
  }

  bool get _membershipCurrent {
    final owner = _membershipOwner;
    final generation = _membershipGeneration;
    return owner != null &&
        generation != null &&
        _ownerId() == owner &&
        ZyraAccountState.isCurrent(owner, generation);
  }

  bool get _hasWaliOne => ZyraDeveloperAccess.isMainAppFounderPreview
      ? AppState.instance.waliHasWaliOne
      : _membershipCurrent &&
            _membershipAccess?.isAvailable == true &&
            AppState.instance.waliHasWaliOne;

  String get _membershipLabel {
    if (!ZyraDeveloperAccess.isMainAppFounderPreview) {
      if (!_membershipCurrent || _membershipAccess?.isUnavailable == true) {
        return 'Unavailable';
      }
      if (_membershipAccess == null) return 'Checking…';
    }
    return _hasWaliOne
        ? 'Guardian One'
        : (ZyraDevLocalPreview.basicMembershipPreviewLabel(guardian: true) ??
              'No active membership');
  }

  @override
  void initState() {
    super.initState();
    _linksOwner = _ownerId();
    _linksGeneration = ZyraAccountState.generation;
    _linksPreview = ZyraDeveloperAccess.isMainAppFounderPreview;
    AppState.instance.addListener(_onChange);
    _loadLinkedSeekers();
    if (!ZyraDeveloperAccess.isMainAppFounderPreview) _loadMembership();
    _membershipDisplay.value = _membershipLabel;
  }

  Future<void> _loadMembership() async {
    _membershipOwner = _ownerId();
    _membershipGeneration = ZyraAccountState.generation;
    final access = await ZyraEntitlementService.resolveGuardianPaidAccess();
    if (!mounted ||
        !_membershipCurrent ||
        ZyraDeveloperAccess.isMainAppFounderPreview) {
      return;
    }
    setState(() => _membershipAccess = access);
    _membershipDisplay.value = _membershipLabel;
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onChange);
    _membershipDisplay.dispose();
    super.dispose();
  }

  void _onChange() {
    _membershipDisplay.value = _membershipLabel;
    setState(() {});
  }

  String? _ownerId() {
    try {
      return ZyraAuth.currentUser?.id;
    } catch (_) {
      return null; // Local preview or widget test without a client.
    }
  }

  Future<void> _loadLinkedSeekers() async {
    final owner = _ownerId();
    final generation = ZyraAccountState.generation;
    ZyraSourceResult<List<WaliLinkedPerson>> result;
    try {
      result =
          await (widget.loadLinkedSeekers?.call() ??
              ZyraWaliLinkService.fetchLinkedPeopleResult(asWali: true));
    } catch (_) {
      result = const ZyraSourceResult.unavailable(
        ZyraSourceFailure.requestFailed,
      );
    }
    if (!mounted) return;
    final sameOwner =
        !ZyraAccountState.isSigningOut &&
        ZyraAccountState.generation == generation &&
        _ownerId() == owner;
    if (sameOwner && result.isAvailable) {
      AppState.instance.setWaliRealLinkedSeekers(result.valueOrNull!);
    }
    setState(() {
      _linksLoading = false;
      _linksUnavailable = !sameOwner || result.isUnavailable;
    });
  }

  void _openMembership(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          const UpgradeScreen(telemetrySurface: ZyraTelemetrySurface.guardian),
    ),
  );

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
    if (!_linksPreview && !_linksCurrent) return 'Unavailable';
    final labels = <String>{
      for (final p in state.waliRealLinkedSeekers)
        if (p.relationshipLabel != null) p.relationshipLabel!,
    };
    if (labels.isEmpty) {
      if (_linksLoading) return 'Checking…';
      return _linksUnavailable ? 'Unavailable' : '—';
    }
    return labels.join(', ');
  }

  String _linkedSeekerCount(AppState state) {
    if (!_linksPreview && !_linksCurrent) return 'Unavailable';
    if (state.waliRealLinkedSeekers.isNotEmpty) {
      return '${state.waliRealLinkedSeekers.length}';
    }
    if (_linksLoading) return 'Checking…';
    return _linksUnavailable ? 'Unavailable' : '0';
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
    // Revoked preview callbacks must not reopen the account picker.
    if (!context.mounted ||
        !ZyraDeveloperAccess.isMainAppFounderPreview ||
        ZyraAccountState.isSigningOut ||
        ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    final owner = _ownerId();
    final generation = ZyraAccountState.generation;
    bool canContinue() =>
        context.mounted &&
        ZyraDeveloperAccess.isMainAppFounderPreview &&
        !ZyraAccountState.isSigningOut &&
        ZyraAccountState.generation == generation &&
        _ownerId() == owner &&
        ModalRoute.of(context)?.isCurrent != false;

    final founderPreview = ZyraDeveloperAccess.isMainAppFounderPreview;
    final selection = await showZyraAccountSwitchPage(
      context: context,
      options: [
        ZyraAccountSwitchOption(
          context: ZyraAccountContext.guardian,
          title: 'Guardian Account',
          subtitle: founderPreview
              ? ZyraDevLocalPreview.guardianMembershipLabel
              : _membershipLabel,
          icon: Icons.shield_outlined,
          current: true,
        ),
        ZyraAccountSwitchOption(
          context: ZyraAccountContext.seeker,
          title: 'Seeker Account',
          subtitle: founderPreview
              ? ZyraDevLocalPreview.seekerMembershipLabel
              : 'Set up separately · identity check reused',
          icon: Icons.person_outline,
          actionLabel: founderPreview ? 'SWITCH ›' : 'SET UP ›',
        ),
      ],
    );
    if (!context.mounted ||
        !canContinue() ||
        selection != ZyraAccountContext.seeker) {
      return;
    }

    if (founderPreview) {
      await ZyraDevLocalPreview.switchAccountContext(
        context,
        toGuardian: false,
      );
      return;
    }

    await ZyraPromotionEngine.instance.clearForAccountSwitch();
    if (!context.mounted || !canContinue()) return;
    await ZyraPromotionEngine.instance.initialize();
    if (!context.mounted || !canContinue()) return;

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

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return Container(
      // 2026-07-25: was hardcoded to brandGradientMale regardless of the
      // signed-in Wali's actual gender (DR-ZYRA-094/OA-ZYRA-123 gap) —
      // now reads the Guardian's own gender like every other profile-context
      // screen. Every current test Wali persona is male, so this is a
      // no-op today but is correct once a female Wali persona exists.
      decoration: ZyraAppGoldDecoration(
        gradient: ZyraColors.genderGradient(state.gender),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
          children: [
            Row(
              children: [
                ZyraOneProfileAvatar(
                  isOne: _hasWaliOne,
                  guardian: true,
                  child: Container(
                    color: ZyraColors.iconButtonBg,
                    child: Icon(
                      Icons.shield_outlined,
                      color: ZyraColors.ink(0.38),
                      size: 30,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    state.waliName ?? 'Your Profile',
                    style: ZyraText.heading(size: 20),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (ZyraDeveloperAccess.isMainAppFounderPreview) ...[
                  SizedBox(width: 10),
                  ZyraAccountSwitchButton(
                    onPressed: () => _switchAccount(context),
                  ),
                ],
              ],
            ),
            // Follow the Seeker Profile hierarchy while keeping Guardian-only
            // content honest: Guardian has no Browse profile/photo gallery,
            // compatibility balance or Journey History section.
            const SizedBox(height: 28),
            Text(
              'MEMBERSHIP',
              style: ZyraText.chapterLabel(color: ZyraColors.ink(0.54)),
            ),
            ZyraProfileMembershipRow(
              key: const ValueKey('guardian-profile-membership'),
              value: _membershipLabel,
              isOne: _hasWaliOne,
              onTap: () => _openMembership(context),
            ),
            const SizedBox(height: 24),
            Text(
              'ABOUT ME',
              style: ZyraText.chapterLabel(color: ZyraColors.ink(0.54)),
            ),
            const SizedBox(height: 10),
            _InfoRow(label: 'Relationship', value: _relationshipSummary(state)),
            _InfoRow(label: 'Linked Seekers', value: _linkedSeekerCount(state)),
            const SizedBox(height: 24),
            Text(
              'SAFETY & SHARING',
              style: ZyraText.chapterLabel(color: ZyraColors.ink(0.54)),
            ),
            const SizedBox(height: 6),
            _SettingsRow(
              label: 'Safety & advice',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const HelpSupportScreen(
                    telemetrySurface: ZyraTelemetrySurface.guardian,
                    initialQuery: 'Safety and reporting',
                  ),
                ),
              ),
            ),
            Builder(
              builder: (inviteContext) => _SettingsRow(
                label: 'Invite someone to ZYRA',
                onTap: () => ZyraAppInvite.share(inviteContext),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'PERSONALISATION',
              style: ZyraText.chapterLabel(color: ZyraColors.ink(0.54)),
            ),
            const SizedBox(height: 6),
            _SettingsRow(
              label: 'Appearance & haptics',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PersonalisationScreen(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _SettingsRow(
              label: 'Settings',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    guardian: true,
                    guardianHasOne: _hasWaliOne,
                    guardianMembershipDisplay: _membershipDisplay,
                    loadNotificationPreferences:
                        widget.loadNotificationPreferences,
                    saveNotificationPreference:
                        widget.saveNotificationPreference,
                  ),
                ),
              ),
            ),
            _SettingsRow(label: 'Sign Out', onTap: () => _signOut(context)),
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
          Expanded(
            flex: 2,
            child: Text(label, style: ZyraText.subtext(size: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: ZyraText.body(size: 13, color: ZyraColors.foreground),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _SettingsRow({required this.label, this.onTap});

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
                style: ZyraText.body(size: 13.5, color: Colors.white),
              ),
            ),
            Icon(Icons.chevron_right, color: ZyraColors.ink(0.24), size: 16),
          ],
        ),
      ),
    );
  }
}
