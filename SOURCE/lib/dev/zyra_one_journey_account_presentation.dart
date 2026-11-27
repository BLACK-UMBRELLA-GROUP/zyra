import '../widgets/zyra_developer_title.dart';
import 'dart:math' as math;

import '../widgets/zyra_floating_surface.dart';
// Disposable account presentation, copied from the current account owners.
// The caller supplies every sample fact and every action. This file neither
// reads a member account nor changes preferences, security or paid access.
import '../widgets/zyra_tab_title.dart';
import '../widgets/zyra_tap_feedback.dart';
import 'package:flutter/material.dart';

import '../data/zyra_membership_catalog.dart';
import '../theme/zyra_card_metrics.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_interaction_style.dart';
import '../theme/zyra_motion.dart';
import '../widgets/zyra_haptics_setting.dart';
import '../theme/zyra_preview_spacing.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_membership_choices.dart';
import '../widgets/zyra_seeker_avatar.dart';
import '../widgets/floating_nav_bar.dart';

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
  settings,
  signOut,
  signInSecurity,
  appLock,
  advanced,
  guardianPrivacy,
  visibility,
  privateMode,
  hiddenProfiles,
  phoneAccess,
  notificationSettings,
  membership,
  helpSupport,
  contactSupport,
  replayWalkthrough,
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
    this.familyPlacePayer,
    this.guardianInfoSeen = false,
    this.photoAsset,
    this.avatarAlignment = Offset.zero,
    this.standardUnlocks,
    this.plusUnlocks,
    this.appLock = false,
    this.profilePaused = false,
    this.privateMode = false,
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
  final String? familyPlacePayer;
  final String guardianCount;
  final String signedInWith;
  final String backgroundLabel;
  final String hapticLabel;
  final bool gold;
  final String? photoAsset;
  final Offset avatarAlignment;
  final int? standardUnlocks;
  final int? plusUnlocks;
  final bool appLock;
  final bool profilePaused, privateMode;
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

/// LOCK 21 V5. The caller owns the Profile facts and action destinations.
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

  static const _avatarSize = 84.0;
  static const _cardRadius = 20.0;
  // Two points of interior padding and a one-point border at each end.
  static const _cardVerticalInset = 3.0;
  static const _dividerHeight = 1.0;

  Widget _row(
    String id,
    String title,
    IconData icon,
    ZyraConceptAccountAction action, {
    String? detail,
    bool destructive = false,
  }) => _ProfileRow(
    key: ValueKey('concept_$id'),
    title: title,
    icon: icon,
    detail: detail,
    destructive: destructive,
    onTap: () => onAction(action),
  );

  Widget _card(List<Widget> rows, double height, {double firstRowExtra = 0}) =>
      ZyraFloatingSurface(
        radius: _cardRadius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ZyraColors.cardSurface,
            borderRadius: BorderRadius.circular(_cardRadius),
            border: Border.all(color: ZyraColors.surfaceBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: _cardVerticalInset),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: _dividerHeight,
                      thickness: _dividerHeight,
                      indent: 55,
                      endIndent: 17,
                      color: ZyraColors.divider,
                    ),
                  SizedBox(
                    height: height + (i == 0 ? firstRowExtra : 0),
                    child: rows[i],
                  ),
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
    final textSize = switcher ? 13.0 : 12.5;
    final textHeight = MediaQuery.textScalerOf(context).scale(textSize) * 1.45;
    final pill = Material(
      key: ValueKey('${id}_surface'),
      color: switcher ? Colors.transparent : ZyraColors.surfaceFill,
      shape: StadiumBorder(side: BorderSide(color: ZyraColors.surfaceBorder)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 44,
          minHeight: math.max(34, textHeight + 8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (switcher) ...[
                Icon(
                  Icons.swap_horiz_rounded,
                  size: 18,
                  color: ZyraColors.foregroundSecondary,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ZyraText.body(
                    size: textSize,
                    color: switcher
                        ? ZyraColors.foregroundSecondary
                        : ZyraColors.foreground,
                  ).copyWith(height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      label: label,
      child: Stack(
        key: ValueKey(id),
        children: [
          ExcludeSemantics(
            child: Padding(
              // Extend the touch target five points on both sides of the pill.
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: switcher
                  ? pill
                  : ZyraFloatingSurface(radius: 999, child: pill),
            ),
          ),
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: ZyraTapFeedback.onTap(context, action),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar() => Semantics(
    label: '${data.membership} profile',
    image: true,
    excludeSemantics: true,
    child: Container(
      key: const ValueKey('concept_profile_avatar'),
      width: _avatarSize,
      height: _avatarSize,
      padding: EdgeInsets.all(data.guardian ? 1 : 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: ZyraColors.journeyGold,
          width: data.guardian ? 1 : 2,
        ),
      ),
      child: data.guardian
          ? ClipOval(
              child: Center(
                child: Text(
                  data.name.characters.firstOrNull ?? '',
                  textScaler: TextScaler.noScaling,
                  style: ZyraText.heading(
                    size: 40,
                    color: ZyraColors.journeyGold,
                  ),
                ),
              ),
            )
          : ZyraSeekerAvatar(
              photo: data.photoAsset,
              size: _avatarSize,
              alignmentX: data.avatarAlignment.dx,
              alignmentY: data.avatarAlignment.dy,
            ),
    ),
  );

  Widget _header(BuildContext context) => Row(
    children: [
      _avatar(),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.name,
              key: const ValueKey('concept_profile_name'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ZyraText.body(
                size: 24,
                color: ZyraColors.foreground,
              ).copyWith(height: 1.45),
            ),
            const SizedBox(height: 2),
            Text(
              data.membership.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ZyraText.body(
                size: 11,
                color: ZyraColors.goldText,
              ).copyWith(letterSpacing: 1.2, height: 1.45),
            ),
            const SizedBox(height: 5),
            Wrap(
              key: const ValueKey('concept_profile_pills'),
              spacing: 6,
              children: [
                if (!data.guardian) ...[
                  _pill(
                    context,
                    'concept_preview_profile',
                    'Preview',
                    () => onAction(ZyraConceptAccountAction.previewProfile),
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
                    data.guardian ? 'draft_role_seeker' : 'draft_role_guardian',
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
          ],
        ),
      ),
    ],
  );

  List<List<Widget>> _groups() => [
    [
      if (data.guardian)
        _row(
          'your_seekers',
          'Your Seekers',
          Icons.people,
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
    ],
    [
      _row(
        'membership',
        'Membership',
        Icons.workspace_premium_outlined,
        ZyraConceptAccountAction.membership,
        detail: switch ((data.isOne, data.familyPlacePayer)) {
          (true, final String payer) when data.guardian => 'Paid by $payer',
          _ => data.membership,
        },
      ),
      if (!data.guardian)
        _row(
          'compatibility_buy_more',
          'Compatibility Unlocks',
          Icons.insights_outlined,
          ZyraConceptAccountAction.compatibilityStore,
          detail: '${data.plusUnlocks?.toString() ?? '—'} left',
        ),
      _row(
        'subscriptions',
        'Your places',
        Icons.card_membership,
        ZyraConceptAccountAction.subscriptions,
      ),
    ],
    [
      if (!data.guardian)
        _row(
          'guardian_info',
          'What Guardians can do',
          Icons.security,
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
    ],
    [
      _row(
        'settings',
        'Settings',
        Icons.settings,
        ZyraConceptAccountAction.settings,
      ),
      _row(
        'sign_out',
        'Sign out',
        Icons.logout,
        ZyraConceptAccountAction.signOut,
        destructive: true,
      ),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final groups = _groups();
    final rowCount = groups.fold(0, (count, group) => count + group.length);
    const contentGap = ZyraNavBarMetrics.contentGap;
    final navInset =
        ZyraNavBarMetrics.contentBottomClearance(context) - contentGap;
    final minRowHeight = math.max(
      44.0,
      MediaQuery.textScalerOf(context).scale(_ProfileRow.titleSize) * 1.45 + 22,
    );
    final firstRowExtra = data.guardian ? 3.0 : 0.0;
    final groupGaps = (groups.length - 1) * ZyraPreviewSpacing.cardToCard;
    final groupInsets = groups.length * 2 * _cardVerticalInset;
    final dividers = (rowCount - groups.length) * _dividerHeight;
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ZyraPreviewSpacing.pageMargin,
                16,
                ZyraPreviewSpacing.pageMargin,
                8,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: const ZyraTabTitle(
                    'Profile',
                    textKey: ValueKey('concept_profile_title'),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: navInset),
                child: CustomScrollView(
                  key: const ValueKey('concept-current-profile-scroll'),
                  physics: ZyraMotion.scrollPhysics,
                  slivers: [
                    SliverPadding(
                      // The 44-point target extends five points below the pill.
                      padding: const EdgeInsets.fromLTRB(
                        ZyraPreviewSpacing.pageMargin,
                        2,
                        ZyraPreviewSpacing.pageMargin,
                        11,
                      ),
                      sliver: SliverToBoxAdapter(child: _header(context)),
                    ),
                    SliverLayoutBuilder(
                      builder: (context, constraints) {
                        // precedingScrollExtent includes the header at its actual
                        // wrapped height and stays constant while scrolling.
                        final rowSpace =
                            constraints.viewportMainAxisExtent -
                            constraints.precedingScrollExtent -
                            contentGap -
                            groupGaps -
                            groupInsets -
                            dividers -
                            firstRowExtra;
                        final rowHeight = math.max(
                          minRowHeight,
                          // Leave a rounding allowance so fitted content has no
                          // positive scroll extent from floating-point layout.
                          (rowSpace - 0.000001) / rowCount,
                        );
                        return SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            ZyraPreviewSpacing.pageMargin,
                            0,
                            ZyraPreviewSpacing.pageMargin,
                            contentGap,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              children: [
                                for (var i = 0; i < groups.length; i++) ...[
                                  if (i > 0)
                                    const SizedBox(
                                      height: ZyraPreviewSpacing.cardToCard,
                                    ),
                                  _card(
                                    groups[i],
                                    rowHeight,
                                    firstRowExtra: i == 0 ? firstRowExtra : 0,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.detail,
    this.destructive = false,
  });

  static const titleSize = 14.5;

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final String? detail;
  final bool destructive;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    key: title == 'Compatibility Unlocks'
        ? const ValueKey('concept_compatibility')
        : null,
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: ZyraTapFeedback.onTap(context, onTap),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 17),
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: destructive
                    ? const Color(0xFFB84A42)
                    : ZyraColors.journeyGold,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ZyraText.body(
                    size: titleSize,
                    color: destructive
                        ? const Color(0xFFAC453E)
                        : ZyraColors.foreground,
                  ).copyWith(height: 1.45),
                ),
              ),
              if (detail case final value?) ...[
                const SizedBox(width: 22),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * .4,
                  ),
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ZyraText.subtext(size: 13).copyWith(height: 1.45),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (!destructive) ...[
                const SizedBox(width: 14),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: ZyraColors.ink(.30),
                ),
              ],
            ],
          ),
        ),
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
    this.hapticLevel = ZyraInteractionStyle.currentDefaultHapticLevel,
    this.canChangeHaptics,
    this.onHapticChanged,
    this.hapticOwner,
    this.readHapticLevel,
  });

  final ZyraHapticLevel hapticLevel;
  final bool Function()? canChangeHaptics;
  final bool Function(ZyraHapticLevel)? onHapticChanged;
  final Object? hapticOwner;
  final ZyraHapticLevel Function()? readHapticLevel;
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
    }) => ZyraSettingsRow(
      key: ValueKey('concept_settings_${action.name}'),
      label: label,
      value: value,
      isNew: isNew,
      newTagKey: action == ZyraConceptAccountAction.replayWalkthrough
          ? const ValueKey('walkthrough_new')
          : const ValueKey('phone_access_new'),
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
              child: ZyraDeveloperTitle(
                child: Text(
                  'Settings',
                  key: const ValueKey('concept_settings_title'),
                  style: ZyraText.heading(size: 28),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                physics: const ScrollPhysics(),
                key: const ValueKey('concept-current-settings-scroll'),
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
                      if (!data.guardian) ...[
                        row(
                          'Pause My Profile',
                          ZyraConceptAccountAction.visibility,
                          value: data.profilePaused ? 'Paused' : null,
                        ),
                        row(
                          'Private mode',
                          ZyraConceptAccountAction.privateMode,
                          value: data.privateMode ? 'On' : 'Off',
                        ),
                      ],
                      row(
                        'Hidden and blocked',
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
                    title: 'NOTIFICATIONS & HAPTICS',
                    smooth: smooth,
                    children: [
                      row(
                        'Notifications & emails',
                        ZyraConceptAccountAction.notificationSettings,
                      ),
                      ZyraHapticsSetting(
                        level: hapticLevel,
                        ownerIdentity: hapticOwner,
                        readLevel: readHapticLevel,
                        canAct: canChangeHaptics ?? () => false,
                        onChanged: onHapticChanged ?? (_) => false,
                        row: (expanded, onTap) => ZyraSettingsRow(
                          key: const ValueKey('concept_settings_haptics'),
                          label: 'Haptics',
                          value: hapticLevel.label,
                          expanded: expanded,
                          smooth: smooth,
                          onTap: onTap,
                        ),
                      ),
                    ],
                  ),
                  _SettingsSection(
                    title: 'SUPPORT',
                    smooth: smooth,
                    children: [
                      row(
                        'Replay the walkthrough',
                        ZyraConceptAccountAction.replayWalkthrough,
                        isNew: true,
                      ),
                      row(
                        'Help & support',
                        ZyraConceptAccountAction.helpSupport,
                      ),
                      row(
                        'Contact support',
                        ZyraConceptAccountAction.contactSupport,
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
        currentContent: data.isOne
            ? Column(
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
              )
            : null,
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
    final radius = smooth ? 24.0 : ZyraCardMetrics.cardRadius;
    return ZyraFloatingSurface(
      radius: radius,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: smooth ? 20 : 18,
          vertical: smooth ? 22 : 18,
        ),
        decoration: BoxDecoration(
          color: ZyraColors.cardSurface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: ZyraColors.surfaceBorder),
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
          SizedBox(height: smooth ? 12 : ZyraPreviewSpacing.labelToCard),
          ZyraFloatingSurface(
            radius: smooth ? 23 : ZyraCardMetrics.cardRadius,
            child: Container(
              key: ValueKey('concept-settings-section-$title'),
              decoration: BoxDecoration(
                color: ZyraColors.surfaceFill,
                borderRadius: BorderRadius.circular(
                  smooth ? 23 : ZyraCardMetrics.cardRadius,
                ),
                border: Border.all(color: ZyraColors.surfaceBorder, width: 0.5),
              ),
              clipBehavior: smooth ? Clip.antiAlias : Clip.none,
              child: Column(children: children),
            ),
          ),
        ],
      ),
    ),
  );
}

class ZyraSettingsRow extends StatelessWidget {
  const ZyraSettingsRow({
    super.key,
    required this.label,
    required this.onTap,
    required this.smooth,
    this.value,
    this.isNew = false,
    this.newTagKey = const ValueKey('phone_access_new'),
    this.expanded = false,
    this.wrapValue = false,
    this.valueSize = 13,
    this.verticalPadding,
    this.horizontalPadding,
    this.subtitle,
    this.locked = false,
    this.minHeight,
  });
  final bool wrapValue;
  final double valueSize;
  final double? verticalPadding, horizontalPadding;
  final bool expanded;
  final bool isNew;
  final Key newTagKey;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final String? subtitle;
  final bool locked;
  final double? minHeight;
  final bool smooth;
  IconData get icon => switch (label) {
    'Sign-in & security' => Icons.verified_user_outlined,
    'App lock' => Icons.lock_outline_rounded,
    'Advanced' => Icons.tune_rounded,
    'Guardian privacy' || 'Pause My Profile' => Icons.visibility_outlined,
    'Hidden and blocked' => Icons.person_off_outlined,
    'Phone access' => Icons.phonelink_lock_outlined,
    'Notifications & emails' => Icons.notifications_outlined,
    'Haptics' => Icons.vibration,
    'Help & support' => Icons.help_outline_rounded,
    'Contact support' => Icons.support_agent_outlined,
    'Send feedback' => Icons.chat_bubble_outline_rounded,
    'Privacy & data' => Icons.shield_outlined,
    _ => Icons.chevron_right_rounded,
  };
  Widget _editRow(BuildContext context) => Material(
    color: Colors.transparent,
    child: locked
        ? _editRowBody(context)
        : InkWell(
            onTap: ZyraTapFeedback.onTap(context, onTap),
            child: _editRowBody(context),
          ),
  );

  Widget _editRowBody(BuildContext context) => Container(
    constraints: BoxConstraints(minHeight: minHeight!),
    padding: EdgeInsets.symmetric(
      horizontal: horizontalPadding ?? 16,
      vertical: verticalPadding ?? 8,
    ),
    child: LayoutBuilder(
      builder: (context, box) {
        final style = ZyraText.subtext(
          size: valueSize,
          color: ZyraColors.secondaryText,
        );
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: ZyraText.body(size: 15)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: ZyraText.body(
                        size: 12,
                        color: ZyraColors.secondaryText,
                      ).copyWith(height: 1.35),
                    ),
                  ],
                ],
              ),
            ),
            if (value != null && value!.isNotEmpty) ...[
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: (box.maxWidth - 26) / 2),
                child: IntrinsicWidth(
                  child: Text(value!, textAlign: TextAlign.right, style: style),
                ),
              ),
            ],
            const SizedBox(width: 4),
            ExcludeSemantics(
              child: Icon(
                locked ? Icons.lock_outline : Icons.chevron_right,
                size: locked ? 14 : 18,
                color: locked
                    ? ZyraColors.secondaryText
                    : ZyraColors.foreground.withValues(alpha: .3),
              ),
            ),
          ],
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) => minHeight != null
      ? _editRow(context)
      : Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: ZyraTapFeedback.onTap(context, onTap),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding ?? (smooth ? 18 : 16),
                vertical: verticalPadding ?? (smooth ? 17 : 15),
              ),
              child: Row(
                children: [
                  if (smooth) ...[
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: ZyraColors.ivoryTop,
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
                            key: newTagKey,
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
                    if (wrapValue)
                      Text(
                        value!,
                        textAlign: TextAlign.right,
                        style: ZyraText.subtext(
                          size: valueSize,
                          color: ZyraColors.secondaryText,
                        ),
                      )
                    else
                      Flexible(
                        child: Text(
                          value!,
                          maxLines: wrapValue ? null : 1,
                          overflow: wrapValue
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          textAlign: wrapValue ? TextAlign.right : null,
                          style: ZyraText.subtext(
                            size: valueSize,
                            color: ZyraColors.ink(0.38),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    expanded ? Icons.expand_more : Icons.chevron_right,
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
