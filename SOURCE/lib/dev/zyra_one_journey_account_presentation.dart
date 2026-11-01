import '../widgets/zyra_floating_surface.dart';
// Disposable account presentation, copied from the current account owners.
// The caller supplies every sample fact and every action. This file neither
// reads a member account nor changes preferences, security or paid access.
import '../widgets/zyra_tap_feedback.dart';
import 'package:flutter/material.dart';

import '../data/zyra_membership_catalog.dart';
import '../theme/zyra_card_metrics.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_membership_choices.dart';
import '../widgets/zyra_profile_image.dart';

enum ZyraConceptAccountAction {
  yourSeekers,
  previewProfile,
  editProfile,
  managePhotos,
  compatibilityStore,
  pastJourneys,
  guardianInfo,
  safetyAdvice,
  invite,
  personalisation,
  settings,
  signOut,
  signInSecurity,
  appLock,
  advanced,
  guardianPrivacy,
  visibility,
  hiddenProfiles,
  phoneAccess,
  notificationSettings,
  membership,
  helpSupport,
  feedback,
  privacyData,
  background,
  haptics,
  cancelMembership,
  subscriptions,
}

/// Explicit sample data only; no field here establishes account authority.
class ZyraConceptAccountData {
  const ZyraConceptAccountData({
    required this.guardian,
    required this.name,
    required this.age,
    required this.gender,
    required this.location,
    required this.membership,
    required this.isOne,
    required this.relationship,
    required this.linkedSeekers,
    required this.guardianCount,
    required this.signedInWith,
    required this.backgroundLabel,
    required this.hapticLabel,
    required this.gold,
    this.linkedSeekerSummary,
    this.guardianInfoSeen = false,
    this.photoAsset,
    this.standardUnlocks,
    this.plusUnlocks,
    this.appLock = false,
    this.phoneAccessSeen = false,
    this.smoothSettings = false,
    this.versionLine,
    this.membershipPaymentHistory = ZyraMembershipPaymentHistory.unknown,
  });

  final bool guardian;
  final bool guardianInfoSeen;
  final String name;
  final String age;
  final String gender;
  final String location;
  final String membership;
  final bool isOne;
  final String relationship;
  final String linkedSeekers;
  final String? linkedSeekerSummary;
  final String guardianCount;
  final String signedInWith;
  final String backgroundLabel;
  final String hapticLabel;
  final bool gold;
  final String? photoAsset;
  final int? standardUnlocks;
  final int? plusUnlocks;
  final bool appLock;
  final bool phoneAccessSeen;
  final bool smoothSettings;
  final String? versionLine;
  final ZyraMembershipPaymentHistory membershipPaymentHistory;

  ZyraMembershipProduct get currentProduct => switch ((guardian, isOne)) {
    (false, true) => ZyraMembershipProduct.seekerOne,
    (false, false) => ZyraMembershipProduct.seekerBasic,
    (true, true) => ZyraMembershipProduct.guardianOne,
    (true, false) => ZyraMembershipProduct.guardianBasic,
  };
}

typedef ZyraConceptAccountActionCallback =
    void Function(ZyraConceptAccountAction action);

/// LOCK21: caller-owned Profile actions in the locked Monogram layout.
class ZyraConceptProfilePresentation extends StatelessWidget {
  const ZyraConceptProfilePresentation({
    super.key,
    required this.data,
    required this.onAction,
    required this.onSwitchRole,
    this.simplifiedMethodology = false,
  });
  final ZyraConceptAccountData data;
  final ZyraConceptAccountActionCallback onAction;
  final VoidCallback onSwitchRole;
  final bool simplifiedMethodology;

  Widget _row(
    String id,
    String title,
    IconData icon,
    ZyraConceptAccountAction action, {
    String? detail,
    bool destructive = false,
  }) => _MonogramRow(
    key: ValueKey('concept_$id'),
    title: title,
    icon: icon,
    detail: detail,
    destructive: destructive,
    onTap: () => onAction(action),
  );

  Widget _card(List<Widget> rows) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: ZyraFloatingSurface(
      radius: 20,
      child: Container(
        decoration: BoxDecoration(
          color: ZyraColors.surfaceFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ZyraColors.surfaceBorder),
        ),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 54,
                  endIndent: 16,
                  color: ZyraColors.divider,
                ),
              rows[i],
            ],
          ],
        ),
      ),
    ),
  );

  Widget _pill(
    BuildContext context,
    String id,
    String label,
    VoidCallback action, {
    bool switcher = false,
  }) {
    final pill = Material(
      color: switcher ? Colors.transparent : ZyraColors.surfaceFill,
      shape: StadiumBorder(side: BorderSide(color: ZyraColors.surfaceBorder)),
      child: InkWell(
        key: ValueKey(id),
        customBorder: const StadiumBorder(),
        onTap: ZyraTapFeedback.onTap(context, action),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (switcher) ...[
                Icon(
                  Icons.swap_horiz_rounded,
                  size: 18,
                  color: ZyraColors.foregroundSecondary,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: ZyraText.body(
                  size: 13,
                  color: switcher
                      ? ZyraColors.foregroundSecondary
                      : ZyraColors.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Semantics(
        button: true,
        child: switcher ? pill : ZyraFloatingSurface(radius: 999, child: pill),
      ),
    );
  }

  Widget _avatar() => Semantics(
    label: '${data.membership} profile',
    image: true,
    excludeSemantics: true,
    child: Container(
      key: const ValueKey('concept_profile_avatar'),
      width: 104,
      height: 104,
      padding: EdgeInsets.all(data.guardian ? 1 : 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: ZyraColors.journeyGold,
          width: data.guardian ? 1 : 2,
        ),
      ),
      child: ClipOval(
        child: data.guardian || data.photoAsset == null
            ? Center(
                child: Text(
                  data.name.characters.firstOrNull ?? '',
                  style: ZyraText.heading(
                    size: 50,
                    color: ZyraColors.journeyGold,
                  ),
                ),
              )
            : data.photoAsset!.startsWith('assets/')
            ? Image.asset(data.photoAsset!, fit: BoxFit.cover)
            : ZyraAvatarImage(
                data.photoAsset!,
                width: 104,
                height: 104,
                alignmentX: 0,
                alignmentY: 0,
              ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Profile',
                textAlign: TextAlign.left,
                key: const ValueKey('concept_profile_title'),
                style: ZyraText.pageTitle(),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              key: const ValueKey('concept-current-profile-scroll'),
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: _avatar()),
                  const SizedBox(height: 12),
                  Text(
                    data.name,
                    key: const ValueKey('concept_profile_name'),
                    textAlign: TextAlign.center,
                    style: ZyraText.heading(size: 28),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${data.membership.toUpperCase()} · ${data.guardian ? 'GUARDIAN' : 'SEEKER'}',
                    textAlign: TextAlign.center,
                    style: ZyraText.body(
                      size: 11,
                      color: ZyraColors.goldText,
                    ).copyWith(letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    key: const ValueKey('concept_profile_pills'),
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (!data.guardian) ...[
                        _pill(
                          context,
                          'concept_preview_profile',
                          'Preview',
                          () =>
                              onAction(ZyraConceptAccountAction.previewProfile),
                        ),
                        _pill(
                          context,
                          'concept_edit_profile',
                          'Edit',
                          () => onAction(ZyraConceptAccountAction.editProfile),
                        ),
                      ],
                      KeyedSubtree(
                        key: ValueKey(
                          data.guardian
                              ? 'draft_role_seeker'
                              : 'draft_role_guardian',
                        ),
                        child: _pill(
                          context,
                          'switch-account-button',
                          'Switch',
                          onSwitchRole,
                          switcher: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _card([
                    if (data.guardian)
                      _row(
                        'your_seekers',
                        'Your Seekers',
                        Icons.people_outline,
                        ZyraConceptAccountAction.yourSeekers,
                        detail: data.linkedSeekerSummary,
                      )
                    else
                      _row(
                        'manage_photos',
                        'Manage photos',
                        Icons.photo_library_outlined,
                        ZyraConceptAccountAction.managePhotos,
                      ),
                  ]),
                  _card([
                    _row(
                      'membership',
                      data.membership,
                      Icons.workspace_premium_outlined,
                      ZyraConceptAccountAction.membership,
                      detail: data.isOne
                          ? 'Manage membership'
                          : 'See ${data.guardian ? 'Guardian' : 'Seeker'} One',
                    ),
                    if (!data.guardian)
                      _row(
                        'compatibility_buy_more',
                        'Compatibility Unlocks',
                        Icons.insights_outlined,
                        ZyraConceptAccountAction.compatibilityStore,
                        detail:
                            '${data.plusUnlocks?.toString() ?? '—'} left${data.isOne ? ' · 3 more each month' : ''}',
                      ),
                    _row(
                      'subscriptions',
                      'Profiles & Family places',
                      Icons.card_membership_outlined,
                      ZyraConceptAccountAction.subscriptions,
                      detail: 'Who your membership covers',
                    ),
                  ]),
                  _card([
                    if (!data.guardian)
                      _row(
                        'guardian_info',
                        'What Guardians can do',
                        Icons.verified_user_outlined,
                        ZyraConceptAccountAction.guardianInfo,
                      ),
                    _row(
                      'safety_advice',
                      'Safety & advice',
                      Icons.health_and_safety,
                      ZyraConceptAccountAction.safetyAdvice,
                    ),
                    _row(
                      'invite',
                      'Invite someone to ZYRA',
                      Icons.person_add,
                      ZyraConceptAccountAction.invite,
                    ),
                  ]),
                  _card([
                    _row(
                      'settings',
                      'Settings',
                      Icons.settings,
                      ZyraConceptAccountAction.settings,
                      detail: 'Account, privacy, notifications',
                    ),
                    _row(
                      'personalisation',
                      'Appearance & haptics',
                      Icons.tune,
                      ZyraConceptAccountAction.personalisation,
                    ),
                    _row(
                      'sign_out',
                      'Sign out',
                      Icons.logout,
                      ZyraConceptAccountAction.signOut,
                      destructive: true,
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _MonogramRow extends StatelessWidget {
  const _MonogramRow({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.detail,
    this.destructive = false,
  });
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final String? detail;
  final bool destructive;
  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFB84A42) : ZyraColors.foreground;
    return MergeSemantics(
      key: title == 'Compatibility Unlocks'
          ? const ValueKey('concept_compatibility')
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: ZyraTapFeedback.onTap(context, onTap),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: destructive ? color : ZyraColors.journeyGold,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: ZyraText.body(size: 14, color: color)),
                    if (detail != null) ...[
                      const SizedBox(height: 3),
                      Text(detail!, style: ZyraText.subtext(size: 12.5)),
                    ],
                  ],
                ),
              ),
              if (!destructive) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: ZyraColors.ink(.28),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// SettingsScreen's current sections and row copy. All actions stay caller-owned.
class ZyraConceptSettingsPresentation extends StatelessWidget {
  const ZyraConceptSettingsPresentation({
    super.key,
    required this.data,
    required this.onAction,
    required this.onBack,
    this.showBackButton = true,
  });

  final ZyraConceptAccountData data;
  final ZyraConceptAccountActionCallback onAction;
  final VoidCallback onBack;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final smooth = data.smoothSettings;
    Widget row(
      String label,
      ZyraConceptAccountAction action, {
      String? value,
      bool isNew = false,
    }) => _SettingsRow(
      key: ValueKey('concept_settings_${action.name}'),
      label: label,
      value: value,
      isNew: isNew,
      smooth: smooth,
      onTap: () => onAction(action),
    );
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: showBackButton
          ? AppBar(
              iconTheme: IconThemeData(color: ZyraColors.ink(0.70)),
              automaticallyImplyLeading: false,
              leading: BackButton(
                onPressed: ZyraTapFeedback.onTap(context, onBack),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                'Settings',
                key: const ValueKey('concept_settings_title'),
                style: ZyraText.heading(size: 28),
              ),
            ),
            Expanded(
              child: ListView(
                key: const ValueKey('concept-current-settings-scroll'),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
                children: [
                  if (smooth) ...[
                    _SettingsReveal(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your account, your choices.',
                            style: ZyraText.subtext(
                              size: 13,
                              color: ZyraColors.ink(.58),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                  _SettingsReveal(
                    enabled: smooth,
                    child: _SettingsSummary(data: data),
                  ),
                  const SizedBox(height: 28),
                  _SettingsSection(
                    title: 'ACCOUNT',
                    smooth: smooth,
                    children: [
                      row(
                        'Sign-in & security',
                        ZyraConceptAccountAction.signInSecurity,
                        value: data.signedInWith,
                      ),
                      row(
                        'App lock',
                        ZyraConceptAccountAction.appLock,
                        value: data.appLock ? 'On' : 'Off',
                      ),
                      row('Advanced', ZyraConceptAccountAction.advanced),
                    ],
                  ),
                  _SettingsSection(
                    title: 'PRIVACY',
                    smooth: smooth,
                    children: [
                      row(
                        'Pause My Profile',
                        ZyraConceptAccountAction.visibility,
                      ),
                      if (data.guardian)
                        row(
                          'Guardian privacy',
                          ZyraConceptAccountAction.guardianPrivacy,
                        ),
                      if (!data.guardian)
                        row(
                          'Hidden Profiles',
                          ZyraConceptAccountAction.hiddenProfiles,
                        ),
                      row(
                        'Phone access',
                        ZyraConceptAccountAction.phoneAccess,
                        isNew: !data.phoneAccessSeen,
                      ),
                    ],
                  ),
                  _SettingsSection(
                    title: 'NOTIFICATIONS',
                    smooth: smooth,
                    children: [
                      row(
                        'Notifications & emails',
                        ZyraConceptAccountAction.notificationSettings,
                      ),
                    ],
                  ),
                  _SettingsSection(
                    title: 'SUPPORT',
                    smooth: smooth,
                    children: [
                      row(
                        'Help & support',
                        ZyraConceptAccountAction.helpSupport,
                      ),
                      row('Send feedback', ZyraConceptAccountAction.feedback),
                    ],
                  ),
                  _SettingsSection(
                    title: 'LEGAL',
                    smooth: smooth,
                    children: [
                      row(
                        'Privacy & data',
                        ZyraConceptAccountAction.privacyData,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ZYRA',
                          style: ZyraText.wordmark(
                            size: 11,
                            color: ZyraColors.ink(0.24),
                          ),
                        ),
                        if (data.versionLine != null) ...[
                          const SizedBox(height: 3),
                          SelectableText(
                            data.versionLine!,
                            style: ZyraText.subtext(
                              size: 11,
                              color: ZyraColors.ink(0.24),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared management sections. Actions are local prototype callbacks only;
/// no receipt/payment flow is imported.
class ZyraConceptMembershipPresentation extends StatelessWidget {
  const ZyraConceptMembershipPresentation({
    super.key,
    required this.data,
    required this.onAction,
    required this.onDraftChanged,
    required this.onReview,
    required this.onBack,
    this.initialDraft,
    this.currentProducts,
    this.currentDetail,
    this.unlocksContent,
    this.canAct,
    this.showBackButton = true,
    this.storeName = 'App Store',
  });

  final ZyraConceptAccountData data;
  final ZyraConceptAccountActionCallback onAction;
  final ValueChanged<ZyraMembershipDraft> onDraftChanged;
  final ValueChanged<ZyraMembershipReviewRequest> onReview;
  final VoidCallback onBack;
  final ZyraMembershipDraft? initialDraft;
  final Set<ZyraMembershipProduct>? currentProducts;
  final String? currentDetail;
  final Widget? unlocksContent;
  final bool Function()? canAct;
  final bool showBackButton;
  final String storeName;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: SafeArea(
      child: ZyraMembershipChoices(
        initialDraft: initialDraft,
        currentProducts: currentProducts ?? {data.currentProduct},
        paymentHistory: data.membershipPaymentHistory,
        currentSummary: data.membership,
        currentDetail: currentDetail,
        canAct: canAct,
        onDraftChanged: onDraftChanged,
        onReview: onReview,
        onBack: onBack,
        showBackButton: showBackButton,
        onTerms: () {
          if (!(canAct?.call() ?? true)) return;
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const ZyraMembershipTermsSheet(),
          );
        },
        unlocksContent: unlocksContent,
        currentContent: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (data.isOne) ...[
              _MembershipAction(
                key: const ValueKey('concept_cancel_membership'),
                icon: Icons.cancel_outlined,
                title: 'Cancel membership',
                detail: data.guardian
                    ? 'If billed to you, manage or cancel securely in $storeName.'
                    : 'Turn off renewal securely in $storeName.',
                destructive: true,
                onTap: () {
                  if (canAct?.call() ?? true) {
                    onAction(ZyraConceptAccountAction.cancelMembership);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) =>
      Text(label, style: ZyraText.chapterLabel(color: ZyraColors.ink(0.54)));
}

class _SettingsSummary extends StatelessWidget {
  const _SettingsSummary({required this.data});
  final ZyraConceptAccountData data;
  Widget line(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: ZyraText.subtext(size: 13, color: ZyraColors.ink(0.54)),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ZyraText.body(size: 14, color: ZyraColors.foreground),
          ),
        ),
      ],
    ),
  );
  Widget divider() => Container(
    height: 0.5,
    margin: const EdgeInsets.symmetric(vertical: 3),
    color: ZyraColors.foreground.withValues(alpha: 0.08),
  );
  @override
  Widget build(BuildContext context) {
    final smooth = data.smoothSettings;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: smooth ? 20 : 18,
        vertical: smooth ? 22 : 18,
      ),
      decoration: BoxDecoration(
        color: ZyraColors.foreground.withValues(alpha: smooth ? .11 : .09),
        borderRadius: BorderRadius.circular(
          smooth ? 24 : ZyraCardMetrics.cardRadius,
        ),
        border: Border.all(
          color: smooth
              ? ZyraColors.unlockText.withValues(alpha: .28)
              : ZyraColors.foreground.withValues(alpha: .14),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          if (smooth) ...[
            Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: ZyraColors.unlockText,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your account',
                    maxLines: 2,
                    style: ZyraText.body(size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          line('Membership', data.membership),
          divider(),
          line(
            data.guardian ? 'Linked Seekers' : 'Guardians',
            data.guardian ? data.linkedSeekers : data.guardianCount,
          ),
          divider(),
          line('Signed in with', data.signedInWith),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
    required this.smooth,
  });
  final String title;
  final List<Widget> children;
  final bool smooth;
  @override
  Widget build(BuildContext context) => _SettingsReveal(
    enabled: smooth,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(title),
          SizedBox(height: smooth ? 12 : 10),
          Container(
            decoration: BoxDecoration(
              color: ZyraColors.foreground.withValues(
                alpha: smooth ? .085 : .05,
              ),
              borderRadius: BorderRadius.circular(
                smooth ? 23 : ZyraCardMetrics.cardRadius,
              ),
              border: Border.all(
                color: ZyraColors.foreground.withValues(
                  alpha: smooth ? .16 : .10,
                ),
                width: 0.5,
              ),
            ),
            clipBehavior: smooth ? Clip.antiAlias : Clip.none,
            child: Column(children: children),
          ),
        ],
      ),
    ),
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    super.key,
    required this.label,
    required this.onTap,
    required this.smooth,
    this.value,
    this.isNew = false,
  });
  final bool isNew;
  final String label;
  final String? value;
  final VoidCallback onTap;
  final bool smooth;
  IconData get icon => switch (label) {
    'Sign-in & security' => Icons.verified_user_outlined,
    'App lock' => Icons.lock_outline_rounded,
    'Advanced' => Icons.tune_rounded,
    'Guardian privacy' || 'Pause My Profile' => Icons.visibility_outlined,
    'Hidden Profiles' => Icons.person_off_outlined,
    'Phone access' => Icons.phonelink_lock_outlined,
    'Notifications & emails' => Icons.notifications_outlined,
    'Help & support' => Icons.help_outline_rounded,
    'Send feedback' => Icons.chat_bubble_outline_rounded,
    'Privacy & data' => Icons.shield_outlined,
    _ => Icons.chevron_right_rounded,
  };
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: ZyraTapFeedback.onTap(context, onTap),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: smooth ? 18 : 16,
          vertical: smooth ? 17 : 15,
        ),
        child: Row(
          children: [
            if (smooth) ...[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: ZyraColors.unlockText.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: ZyraColors.unlockText),
              ),
              const SizedBox(width: 13),
            ],
            Expanded(
              child: Wrap(
                spacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    label,
                    style: ZyraText.body(
                      size: 15,
                      color: ZyraColors.foreground,
                    ),
                  ),
                  if (isNew)
                    Container(
                      key: const ValueKey('phone_access_new'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: ZyraColors.goldTextFill,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'NEW',
                        style: ZyraText.body(
                          size: 10,
                          color: ZyraColors.espresso,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (value != null && value!.isNotEmpty) ...[
              Flexible(
                child: Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ZyraText.subtext(
                    size: 13,
                    color: ZyraColors.ink(0.38),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.chevron_right,
              size: 18,
              color: ZyraColors.foreground.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SettingsReveal extends StatelessWidget {
  const _SettingsReveal({this.enabled = true, required this.child});
  final bool enabled;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (!enabled || MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 440),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _MembershipAction extends StatelessWidget {
  const _MembershipAction({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
    this.destructive = false,
  });
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;
  final bool destructive;
  @override
  Widget build(BuildContext context) {
    final accent = destructive
        ? ZyraColors.negativeRed
        : ZyraColors.foregroundSecondary;
    return ZyraFloatingSurface(
      radius: ZyraCardMetrics.cardRadius,
      circle: false,
      gold: false,
      child: Material(
        color: ZyraColors.surfaceFill,
        borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
          onTap: ZyraTapFeedback.onTap(context, onTap),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
              border: Border.all(
                color: accent.withValues(alpha: destructive ? 0.34 : 0.18),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 21, color: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: ZyraText.body(size: 14, color: accent),
                      ),
                      const SizedBox(height: 3),
                      Text(detail, style: ZyraText.subtext(size: 11.5)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: ZyraColors.foregroundMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
