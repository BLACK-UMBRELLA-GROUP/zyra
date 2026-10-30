// Disposable account presentation, copied from the current account owners.
// The caller supplies every sample fact and every action. This file neither
// reads a member account nor changes preferences, security or paid access.
import '../widgets/zyra_tap_feedback.dart';
import 'package:flutter/material.dart';

import '../data/zyra_membership_catalog.dart';
import '../theme/zyra_card_metrics.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_account_switch_sheet.dart';
import '../widgets/zyra_membership_choices.dart';
import '../widgets/zyra_one_profile_avatar.dart';
import '../widgets/zyra_profile_membership_row.dart';
import '../widgets/zyra_profile_image.dart';

enum ZyraConceptAccountAction {
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
    this.guardianInfoSeen = false,
    this.photoAsset,
    this.standardUnlocks,
    this.plusUnlocks,
    this.appLock = false,
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
  final String guardianCount;
  final String signedInWith;
  final String backgroundLabel;
  final String hapticLabel;
  final bool gold;
  final String? photoAsset;
  final int? standardUnlocks;
  final int? plusUnlocks;
  final bool appLock;
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

/// ProfileScreen/WaliProfileScreen's current hierarchy, labels and metrics.
/// Owns its list padding; mount as a bounded tab body, not inside another list.
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
                key: const ValueKey('concept_profile_title'),
                textAlign: TextAlign.left,
                style: ZyraText.pageTitle(),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              key: const ValueKey('concept-current-profile-scroll'),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final nameStyle = ZyraText.heading(size: 20);
                    TextStyle measuredStyle(TextStyle style) {
                      final inherited = DefaultTextStyle.of(
                        context,
                      ).style.merge(style);
                      return MediaQuery.boldTextOf(context)
                          ? inherited.copyWith(fontWeight: FontWeight.bold)
                          : inherited;
                    }

                    bool nameFitsTwoLines(double width) {
                      if (width <= 0) return false;
                      final painter = TextPainter(
                        text: TextSpan(
                          text: data.name,
                          style: measuredStyle(nameStyle),
                        ),
                        textDirection: Directionality.of(context),
                        textScaler: MediaQuery.textScalerOf(context),
                        locale: Localizations.maybeLocaleOf(context),
                        maxLines: 2,
                        ellipsis: '…',
                      )..layout(maxWidth: width);
                      final fits = !painter.didExceedMaxLines;
                      painter.dispose();
                      return fits;
                    }

                    final switchLabel = TextPainter(
                      text: TextSpan(
                        text: 'Switch',
                        style: measuredStyle(ZyraText.subtext(size: 11.5)),
                      ),
                      textDirection: Directionality.of(context),
                      textScaler: MediaQuery.textScalerOf(context),
                      locale: Localizations.maybeLocaleOf(context),
                      maxLines: 1,
                    )..layout();
                    // Keep Switch beside a full name that fits two lines in
                    // its reserved width. Only true two-line overflow uses a
                    // wider reading layout; the font never shrinks to fit.
                    final switchWidth = 16 + 8 + 22 + switchLabel.width;
                    final identityWidth = constraints.maxWidth - 68 - 16;
                    final stackSwitch = !nameFitsTwoLines(
                      identityWidth - 10 - switchWidth,
                    );
                    final fullWidthName =
                        stackSwitch && !nameFitsTwoLines(identityWidth);
                    final readingName =
                        fullWidthName &&
                        !nameFitsTwoLines(constraints.maxWidth);
                    switchLabel.dispose();
                    final avatar = ZyraOneProfileAvatar(
                      isOne: data.isOne,
                      guardian: data.guardian,
                      child: data.photoAsset != null && !data.guardian
                          ? data.photoAsset!.startsWith('data:image/')
                                ? ZyraAvatarImage(
                                    data.photoAsset!,
                                    width: 64,
                                    height: 64,
                                    alignmentX: 0,
                                    alignmentY: 0,
                                  )
                                : data.photoAsset!.startsWith('assets/')
                                ? Image.asset(
                                    data.photoAsset!,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                  )
                                : const SizedBox.square(dimension: 64)
                          : Container(
                              width: 64,
                              height: 64,
                              color: ZyraColors.iconButtonBg,
                              child: Icon(
                                data.guardian
                                    ? Icons.shield_outlined
                                    : Icons.person,
                                color: ZyraColors.ink(0.38),
                                size: 30,
                              ),
                            ),
                    );
                    final name = Text(
                      data.name,
                      key: const ValueKey('concept_profile_name'),
                      semanticsLabel: data.name,
                      style: nameStyle,
                      softWrap: true,
                      maxLines: readingName ? null : 2,
                      overflow: readingName
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    );
                    final switchButton = KeyedSubtree(
                      key: ValueKey(
                        data.guardian
                            ? 'draft_role_seeker'
                            : 'draft_role_guardian',
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        child: ZyraAccountSwitchButton(onPressed: onSwitchRole),
                      ),
                    );
                    if (fullWidthName) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 12,
                            children: [avatar, switchButton],
                          ),
                          const SizedBox(height: 12),
                          name,
                        ],
                      );
                    }
                    final identity = Row(
                      children: [
                        avatar,
                        const SizedBox(width: 16),
                        Expanded(child: name),
                        if (!stackSwitch) ...[
                          const SizedBox(width: 10),
                          switchButton,
                        ],
                      ],
                    );
                    if (!stackSwitch) return identity;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        identity,
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: switchButton,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),
                const _SectionLabel('MEMBERSHIP'),
                KeyedSubtree(
                  key: const ValueKey('concept_membership'),
                  child: ZyraProfileMembershipRow(
                    value: data.membership,
                    isOne: data.isOne,
                    onTap: () => onAction(ZyraConceptAccountAction.membership),
                  ),
                ),
                _ProfileAction(
                  key: const ValueKey('concept_subscriptions'),
                  icon: Icons.card_membership_outlined,
                  label: 'Your subscriptions',
                  onTap: () => onAction(ZyraConceptAccountAction.subscriptions),
                ),
                if (!data.guardian) ...[
                  const SizedBox(height: 24),
                  const _SectionLabel('COMPATIBILITY'),
                  const SizedBox(height: 4),
                  _UnlockBalance(
                    standard: data.standardUnlocks,
                    plus: data.plusUnlocks,
                    onBuyMore: () =>
                        onAction(ZyraConceptAccountAction.compatibilityStore),
                  ),
                  const SizedBox(height: 24),
                  const _SectionLabel('YOUR PROFILE'),
                  const SizedBox(height: 5),
                  _ProfileAction(
                    key: const ValueKey('concept_preview_profile'),
                    icon: Icons.person_outline,
                    label: 'Preview my profile',
                    onTap: () =>
                        onAction(ZyraConceptAccountAction.previewProfile),
                  ),
                  const _ProfileDivider(),
                  _ProfileAction(
                    key: const ValueKey('concept_edit_profile'),
                    icon: Icons.edit_outlined,
                    label: 'Edit profile',
                    onTap: () => onAction(ZyraConceptAccountAction.editProfile),
                  ),
                  const _ProfileDivider(),
                  _ProfileAction(
                    key: const ValueKey('concept_manage_photos'),
                    icon: Icons.photo_library_outlined,
                    label: 'Manage photos',
                    onTap: () =>
                        onAction(ZyraConceptAccountAction.managePhotos),
                  ),
                ],
                const SizedBox(height: 24),
                const _SectionLabel('ABOUT ME'),
                const SizedBox(height: 10),
                if (data.guardian) ...[
                  _InfoRow(
                    label: 'Relationship',
                    value: data.relationship,
                    guardian: true,
                  ),
                  _InfoRow(
                    label: 'Linked Seekers',
                    value: data.linkedSeekers,
                    guardian: true,
                  ),
                ] else ...[
                  _InfoRow(label: 'Age', value: data.age),
                  _InfoRow(label: 'Gender', value: data.gender),
                  _InfoRow(label: 'Location', value: data.location),
                  if (!simplifiedMethodology) ...[
                    const SizedBox(height: 24),
                    const _SectionLabel('JOURNEY HISTORY'),
                    const SizedBox(height: 6),
                    _ProfileSettingsRow(
                      key: const ValueKey('concept_past_journeys'),
                      label: 'Past Journeys',
                      onTap: () =>
                          onAction(ZyraConceptAccountAction.pastJourneys),
                    ),
                  ],
                ],
                const SizedBox(height: 24),
                const _SectionLabel('SAFETY & SHARING'),
                const SizedBox(height: 6),
                if (!data.guardian)
                  InkWell(
                    key: const ValueKey('concept_guardian_info'),
                    onTap: ZyraTapFeedback.onTap(
                      context,
                      () => onAction(ZyraConceptAccountAction.guardianInfo),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            size: 20,
                            color: ZyraColors.journeyGold,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'What Guardians can do',
                                  style: ZyraText.body(
                                    size: 13.5,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Who sees what, and what you control',
                                  style: ZyraText.body(
                                    size: 12.5,
                                    color: ZyraColors.journeyGold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!data.guardianInfoSeen) ...[
                            const SizedBox(width: 8),
                            Container(
                              key: const ValueKey('guardian_info_new'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: ZyraColors.journeyGold,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'NEW',
                                style: ZyraText.body(
                                  size: 10,
                                  color: ZyraColors.onPrimaryAction,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right,
                            color: ZyraColors.ink(.24),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                _ProfileSettingsRow(
                  key: const ValueKey('concept_safety_advice'),
                  label: 'Safety & advice',
                  onTap: () => onAction(ZyraConceptAccountAction.safetyAdvice),
                ),
                _ProfileSettingsRow(
                  key: const ValueKey('concept_invite'),
                  label: 'Invite someone to ZYRA',
                  onTap: () => onAction(ZyraConceptAccountAction.invite),
                ),
                const SizedBox(height: 24),
                if (!data.guardian) const SizedBox(height: 8),
                const _SectionLabel('PERSONALISATION'),
                const SizedBox(height: 6),
                _ProfileSettingsRow(
                  key: const ValueKey('concept_personalisation'),
                  label: 'Appearance & haptics',
                  onTap: () =>
                      onAction(ZyraConceptAccountAction.personalisation),
                ),
                const SizedBox(height: 14),
                _ProfileSettingsRow(
                  key: const ValueKey('concept_settings'),
                  label: 'Settings',
                  onTap: () => onAction(ZyraConceptAccountAction.settings),
                ),
                _ProfileSettingsRow(
                  key: const ValueKey('concept_sign_out'),
                  label: 'Sign Out',
                  onTap: () => onAction(ZyraConceptAccountAction.signOut),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
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
    }) => _SettingsRow(
      key: ValueKey('concept_settings_${action.name}'),
      label: label,
      value: value,
      smooth: smooth,
      onTap: () => onAction(action),
    );
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: smooth
            ? null
            : Text('Settings', style: ZyraText.heading(size: 17)),
        iconTheme: IconThemeData(color: ZyraColors.ink(0.70)),
        automaticallyImplyLeading: false,
        leading: showBackButton
            ? BackButton(onPressed: ZyraTapFeedback.onTap(context, onBack))
            : null,
      ),
      body: SafeArea(
        child: ListView(
          key: const ValueKey('concept-current-settings-scroll'),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
          children: [
            if (smooth) ...[
              const SizedBox(height: 38),
              _SettingsReveal(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Settings', style: ZyraText.heading(size: 30)),
                    const SizedBox(height: 5),
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
                row('Pause My Profile', ZyraConceptAccountAction.visibility),
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
              title: 'MEMBERSHIP',
              smooth: smooth,
              children: [
                row(
                  'Membership',
                  ZyraConceptAccountAction.membership,
                  value: data.membership,
                ),
              ],
            ),
            _SettingsSection(
              title: 'SUPPORT',
              smooth: smooth,
              children: [
                row('Help & support', ZyraConceptAccountAction.helpSupport),
                row('Send feedback', ZyraConceptAccountAction.feedback),
              ],
            ),
            _SettingsSection(
              title: 'LEGAL',
              smooth: smooth,
              children: [
                row('Privacy & data', ZyraConceptAccountAction.privacyData),
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

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: ZyraTapFeedback.onTap(context, onTap),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: ZyraColors.foregroundSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: ZyraText.body(size: 14, color: ZyraColors.foreground),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: ZyraColors.ink(0.28),
          ),
        ],
      ),
    ),
  );
}

class _ProfileDivider extends StatelessWidget {
  const _ProfileDivider();
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, indent: 34, color: ZyraColors.ink(0.10));
}

class _ProfileSettingsRow extends StatelessWidget {
  const _ProfileSettingsRow({
    super.key,
    required this.label,
    required this.onTap,
  });
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: ZyraTapFeedback.onTap(context, onTap),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.guardian = false,
  });
  final String label;
  final String value;
  final bool guardian;
  @override
  Widget build(BuildContext context) => Padding(
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
            style: ZyraText.body(
              size: 13,
              color: guardian ? ZyraColors.foreground : Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}

class _UnlockBalance extends StatelessWidget {
  const _UnlockBalance({
    required this.standard,
    required this.plus,
    required this.onBuyMore,
  });
  final int? standard;
  final int? plus;
  final VoidCallback onBuyMore;
  Widget count(String label, int? value) => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: value?.toString() ?? '—',
          style: ZyraText.body(size: 12.5, color: ZyraColors.journeyGold),
        ),
        TextSpan(text: '  $label', style: ZyraText.subtext(size: 11.5)),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(
      key: const ValueKey('concept_compatibility'),
      button: true,
      label: 'View compatibility unlocks',
      child: Tooltip(
        message: 'View compatibility unlocks',
        excludeFromSemantics: true,
        child: InkWell(
          key: const ValueKey('concept_compatibility_buy_more'),
          onTap: ZyraTapFeedback.onTap(context, onBuyMore),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              children: [
                Icon(
                  Icons.insights_outlined,
                  size: 20,
                  color: ZyraColors.journeyGold,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Compatibility unlocks',
                        style: ZyraText.body(
                          size: 14,
                          color: ZyraColors.foreground,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 18,
                        runSpacing: 5,
                        children: [
                          count('Unlocks', plus),
                          if (standard != null && standard! > 0)
                            count('Earlier overall credits', standard),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ExcludeSemantics(
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: ZyraColors.ink(0.28),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
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
            style: ZyraText.body(size: 14, color: Colors.white),
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
  });
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
    'Notifications & emails' => Icons.notifications_outlined,
    'Membership' => Icons.workspace_premium_outlined,
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
              child: Text(
                label,
                style: ZyraText.body(size: 15, color: Colors.white),
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
    return Material(
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
                    Text(title, style: ZyraText.body(size: 14, color: accent)),
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
    );
  }
}
