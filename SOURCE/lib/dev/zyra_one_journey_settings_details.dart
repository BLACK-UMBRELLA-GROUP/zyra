// Detached Settings click-through content for the protected comparison.
// Callers own navigation and admission. Nothing here reads an account, device,
// service or preference, or carries out a security, consent or account action.
import 'package:flutter/material.dart';

import '../theme/zyra_text.dart';
import 'zyra_one_journey_account_presentation.dart';
import 'zyra_founder_launch_review.dart';

enum ZyraConceptSettingsDetail {
  recovery,
  appLock,
  resetProfile,
  deleteAccount,
  discovery,
  hiddenProfiles,
  notifications,
  feedback,
  privacyPolicy,
  terms,
}

/// Canonical fictional rows supplied by the admitted shell, not member data.
class ZyraConceptHiddenProfile {
  const ZyraConceptHiddenProfile({
    required this.id,
    required this.name,
    required this.detail,
    this.thumbnail,
  });

  final String id, name, detail;

  /// Already-admitted offline presentation from the owning shell. This is not
  /// a stored photo reference or permission to retrieve a hidden identity.
  final Widget? thumbnail;
}

class ZyraConceptSettingsOverview extends StatelessWidget {
  const ZyraConceptSettingsOverview({
    super.key,
    required this.action,
    required this.data,
    required this.onOpenDetail,
    required this.onHelp,
    this.hiddenProfiles,
    this.onUnhide,
    this.confirmingHiddenProfileId,
    this.onViewHiddenProfile,
    this.onCancelUnhide,
    this.onConfirmUnhide,
  });

  final ZyraConceptAccountAction action;
  final ZyraConceptAccountData data;
  final ValueChanged<ZyraConceptSettingsDetail> onOpenDetail;
  final VoidCallback onHelp;
  final List<ZyraConceptHiddenProfile>? hiddenProfiles;
  final ValueChanged<String>? onUnhide;
  final String? confirmingHiddenProfileId;
  final VoidCallback? onViewHiddenProfile, onCancelUnhide, onConfirmUnhide;

  @override
  Widget build(BuildContext context) {
    final view = _overview(action, data);
    final localHidden = action == ZyraConceptAccountAction.hiddenProfiles
        ? hiddenProfiles
        : null;
    final fixedHelp = action == ZyraConceptAccountAction.hiddenProfiles;
    return _SettingsPage(
      id: 'overview_${action.name}',
      title: view.title,
      lead: view.lead,
      previewNote: view.previewNote,
      footer: fixedHelp
          ? _HelpAction(id: 'overview_${action.name}', onHelp: onHelp)
          : null,
      children: [
        if (localHidden != null) ...[
          for (final person in localHidden) ...[
            _HiddenProfileCard(
              key: ValueKey('concept_hidden_profile_card_${person.id}'),
              person: person,
              expanded: confirmingHiddenProfileId == person.id,
              onOpen: () => onUnhide?.call(person.id),
              onView: onViewHiddenProfile,
              onCancel: onCancelUnhide,
              onConfirm: onConfirmUnhide,
            ),
            const SizedBox(height: 14),
          ],
        ],
        for (final block in view.blocks) ...[
          _InformationBlock(block),
          const SizedBox(height: 14),
        ],
        for (final item in view.items) ...[
          _SettingsDestination(
            key: ValueKey(
              'concept_settings_open_${action.name}_${item.detail.name}',
            ),
            title: item.title,
            body: item.body,
            icon: item.icon,
            onTap: () => onOpenDetail(item.detail),
          ),
          const SizedBox(height: 12),
        ],
        if (!fixedHelp)
          _HelpAction(id: 'overview_${action.name}', onHelp: onHelp),
      ],
    );
  }
}

class _HiddenProfileCard extends StatelessWidget {
  const _HiddenProfileCard({
    super.key,
    required this.person,
    required this.expanded,
    required this.onOpen,
    required this.onView,
    required this.onCancel,
    required this.onConfirm,
  });

  final ZyraConceptHiddenProfile person;
  final bool expanded;
  final VoidCallback onOpen;
  final VoidCallback? onView, onCancel, onConfirm;

  @override
  Widget build(BuildContext context) {
    final ink = ZyraFounderLaunchPageStyle.inkOf(context);
    final secondary = ZyraFounderLaunchPageStyle.secondaryOf(context);
    final gold = ZyraFounderLaunchPageStyle.goldOf(context);
    final border = ZyraFounderLaunchPageStyle.borderOf(context);
    final viewInk = onView == null ? secondary.withValues(alpha: .5) : ink;
    final photo = person.thumbnail;
    final radius = BorderRadius.circular(24);
    return Material(
      color: ZyraFounderLaunchPageStyle.surfaceOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: expanded ? gold.withValues(alpha: .65) : border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            expanded: expanded,
            child: InkWell(
              key: ValueKey('concept_hidden_profile_unhide_${person.id}'),
              onTap: expanded ? onCancel : onOpen,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        key: ValueKey(
                          'concept_hidden_profile_avatar_${person.id}',
                        ),
                        width: 56,
                        height: 56,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: gold.withValues(alpha: .8)),
                        ),
                        child: photo != null
                            ? ClipOval(
                                key: ValueKey(
                                  'concept_hidden_profile_photo_${person.id}',
                                ),
                                child: photo,
                              )
                            : Icon(
                                Icons.person_outline_rounded,
                                key: ValueKey(
                                  'concept_hidden_profile_placeholder_${person.id}',
                                ),
                                size: 26,
                                color: gold,
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            person.name,
                            style: ZyraText.body(size: 16, color: ink),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            person.detail,
                            style: ZyraText.subtext(size: 12, color: secondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ExcludeSemantics(
                      child: Icon(
                        expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 20,
                        color: gold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Divider(height: 1, thickness: 1, color: border),
                  const SizedBox(height: 5),
                  OutlinedButton(
                    key: const ValueKey('concept_hidden_profile_view'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(44, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 12,
                      ),
                      foregroundColor: ink,
                      side: BorderSide.none,
                    ),
                    onPressed: onView,
                    child: Row(
                      children: [
                        ExcludeSemantics(
                          child: Icon(
                            Icons.person_outline_rounded,
                            size: 20,
                            color: viewInk,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'View profile',
                            style: ZyraText.button(size: 14, color: viewInk),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ExcludeSemantics(
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: viewInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const ValueKey(
                      'concept_hidden_profile_restore_confirm',
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(44, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      foregroundColor: gold,
                      side: BorderSide(color: gold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed: onConfirm,
                    icon: const ExcludeSemantics(
                      child: Icon(Icons.visibility_outlined, size: 18),
                    ),
                    label: Text(
                      'Unhide profile',
                      textAlign: TextAlign.center,
                      style: ZyraText.button(size: 14, color: gold),
                    ),
                  ),
                  TextButton(
                    key: const ValueKey(
                      'concept_hidden_profile_restore_cancel',
                    ),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(44, 48),
                      foregroundColor: secondary,
                    ),
                    onPressed: onCancel,
                    child: Text(
                      'Cancel',
                      style: ZyraText.button(size: 14, color: secondary),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class ZyraConceptSettingsDetailPresentation extends StatelessWidget {
  const ZyraConceptSettingsDetailPresentation({
    super.key,
    required this.detail,
    required this.guardian,
    required this.onHelp,
    this.overviewAction,
  });

  final ZyraConceptSettingsDetail detail;
  final bool guardian;
  final VoidCallback onHelp;
  final ZyraConceptAccountAction? overviewAction;

  @override
  Widget build(BuildContext context) {
    final view = _detail(detail, guardian, overviewAction);
    return _SettingsPage(
      id: 'detail_${detail.name}',
      title: view.title,
      lead: view.lead,
      previewNote: view.previewNote,
      children: [
        for (final block in view.blocks) ...[
          _InformationBlock(block),
          const SizedBox(height: 14),
        ],
        _HelpAction(id: 'detail_${detail.name}', onHelp: onHelp),
      ],
    );
  }
}

class _PageContent {
  const _PageContent({
    required this.title,
    this.lead,
    this.previewNote,
    this.blocks = const [],
    this.items = const [],
  });

  final String title;
  final String? lead, previewNote;
  final List<_Information> blocks;
  final List<_Destination> items;
}

class _Information {
  const _Information(this.title, this.body);
  final String title, body;
}

class _Destination {
  const _Destination(this.detail, this.title, this.body, this.icon);
  final ZyraConceptSettingsDetail detail;
  final String title, body;
  final IconData icon;
}

_PageContent _overview(
  ZyraConceptAccountAction action,
  ZyraConceptAccountData data,
) => switch (action) {
  ZyraConceptAccountAction.signInSecurity => _PageContent(
    title: 'Sign-in & security',
    lead: 'Keep a way back to your account.',
    previewNote:
        'Connected sign-in methods and recovery addresses are not inspected or changed here.',
    blocks: [
      _Information('Sign-in method shown', data.signedInWith),
      const _Information(
        'Your provider stays in control',
        'Apple or Google handles provider sign-in. ZYRA does not create a separate app password.',
      ),
    ],
    items: const [
      _Destination(
        ZyraConceptSettingsDetail.recovery,
        'Recovery email',
        'Learn how a verified address helps with account recovery.',
        Icons.alternate_email_rounded,
      ),
    ],
  ),
  ZyraConceptAccountAction.appLock => _PageContent(
    title: 'App lock',
    lead: 'An extra check on this device.',
    previewNote:
        'No device authentication is requested, and App Lock is not changed here.',
    blocks: [
      _Information('Status shown', data.appLock ? 'On' : 'Off'),
      const _Information(
        'Your phone does the checking',
        'App Lock uses supported device authentication, such as Face ID, Touch ID or the device passcode. It is separate from signing in to ZYRA.',
      ),
    ],
    items: const [
      _Destination(
        ZyraConceptSettingsDetail.appLock,
        'How App Lock works',
        'Device requirements and what this extra check means.',
        Icons.lock_outline_rounded,
      ),
    ],
  ),
  ZyraConceptAccountAction.advanced => _PageContent(
    title: 'Advanced',
    lead: 'Understand your account choices before deciding.',
    previewNote:
        'Reset Profile and Delete Account are explanation-only while their written specifications await approval. Neither action can run here.',
    items: [
      const _Destination(
        ZyraConceptSettingsDetail.resetProfile,
        'Reset Profile',
        'Review the proposal and the decisions still required.',
        Icons.restart_alt_rounded,
      ),
      _Destination(
        ZyraConceptSettingsDetail.deleteAccount,
        'Delete Account',
        data.guardian
            ? 'Understand the effect on your linked Seekers.'
            : 'Understand permanent account closure before deciding.',
        Icons.delete_outline_rounded,
      ),
    ],
  ),
  ZyraConceptAccountAction.visibility => const _PageContent(
    title: 'Pause My Profile',
    lead: 'Take a break without starting over.',
    previewNote:
        'Your confirmed account pause state is unavailable here. No server setting is read or changed.',
    blocks: [
      _Information(
        'One reversible pause',
        'Pause My Profile is designed to hide your profile across ZYRA and pause activity involving your account. Your account, profile, Guardian links, Journeys, history and paid entitlements stay intact, and you stay signed in.',
      ),
      _Information(
        'Confirmed state, not a local switch',
        'The account-wide server protection must be available and confirmed before Pause or Unpause can be offered. The old discovery-only visibility setting is not this protection.',
      ),
    ],
    items: [
      _Destination(
        ZyraConceptSettingsDetail.discovery,
        'Pause and Unpause explained',
        'What others see and which protections stay in place.',
        Icons.pause_circle_outline_rounded,
      ),
    ],
  ),
  ZyraConceptAccountAction.hiddenProfiles => const _PageContent(
    title: 'Hidden profiles',
  ),
  ZyraConceptAccountAction.guardianPrivacy => const _PageContent(
    title: 'Guardian privacy',
    lead: 'Your role is shared only where it applies.',
    previewNote:
        'This page explains Guardian boundaries; it does not grant access to any Seeker or Journey.',
    blocks: [
      _Information(
        'Not shown in Profiles',
        'Guardian accounts do not appear in Profiles. A linked Seeker can see your Guardian identity.',
      ),
      _Information(
        'Shared responsibility',
        'Other Guardians see your identity only where the app authorises shared Journey or Guardian Circle responsibility.',
      ),
    ],
    items: [
      _Destination(
        ZyraConceptSettingsDetail.discovery,
        'About Guardian privacy',
        'Relationship, Journey and Circle access remain separate.',
        Icons.shield_outlined,
      ),
    ],
  ),
  ZyraConceptAccountAction.notificationSettings => _PageContent(
    title: 'Notifications & emails',
    lead: 'Separate useful updates from optional marketing.',
    previewNote:
        'No notification permission, preference or marketing consent is read or changed here.',
    blocks: [
      _Information(
        'Service notifications',
        data.guardian
            ? 'Seeker links, Journey activity and introductions can need your attention.'
            : 'Matches, Journeys and Guardian activity can need your attention.',
      ),
      const _Information(
        'Marketing is a separate choice',
        'Optional marketing choices are separate from service preferences. Changing a service preference is not marketing consent.',
      ),
    ],
    items: const [
      _Destination(
        ZyraConceptSettingsDetail.notifications,
        'About notifications',
        'Device permission, in-app updates and essential account messages.',
        Icons.notifications_outlined,
      ),
    ],
  ),
  ZyraConceptAccountAction.feedback => const _PageContent(
    title: 'Send feedback',
    lead: 'Help improve how ZYRA feels and works.',
    previewNote:
        'No feedback form or send action is available here. Nothing is submitted or saved.',
    blocks: [
      _Information(
        'A thought, an idea or something that feels wrong',
        'Useful feedback says which page you were on, what you expected and what happened instead. Do not include passwords, verification codes or private conversations.',
      ),
    ],
    items: [
      _Destination(
        ZyraConceptSettingsDetail.feedback,
        'Feedback and support',
        'Choose the right route for a suggestion or a safety concern.',
        Icons.chat_bubble_outline_rounded,
      ),
    ],
  ),
  ZyraConceptAccountAction.privacyData => _PageContent(
    title: 'Privacy & data',
    lead: 'Understand the boundaries around your information.',
    previewNote:
        'This is a product explanation, not the formal Privacy Policy or Terms. No account data or consent is changed here.',
    blocks: [
      _Information(
        'Your role and information',
        data.guardian
            ? 'Guardian identity, Seeker links and authorised Journey responsibilities have separate access boundaries. A link is not permission to see a Seeker’s private browsing or answers.'
            : 'Public profile information, private answers and shared Journey information have different access boundaries. A match does not automatically reveal private content.',
      ),
      const _Information(
        'Formal documents',
        'The Privacy Policy and Terms are separate from this explanation. The pages below show their current availability.',
      ),
    ],
    items: const [
      _Destination(
        ZyraConceptSettingsDetail.privacyPolicy,
        'Privacy Policy',
        'How the formal policy will be made available.',
        Icons.policy_outlined,
      ),
      _Destination(
        ZyraConceptSettingsDetail.terms,
        'Terms',
        'The formal terms are separate from this product explanation.',
        Icons.description_outlined,
      ),
    ],
  ),
  _ => const _PageContent(
    title: 'Settings',
    lead: 'This destination is not available here.',
    previewNote: 'No account action has been performed.',
  ),
};

_PageContent _detail(
  ZyraConceptSettingsDetail detail,
  bool guardian,
  ZyraConceptAccountAction? overviewAction,
) => switch (detail) {
  ZyraConceptSettingsDetail.recovery => const _PageContent(
    title: 'Recovery email',
    lead: 'A verified route back to your account.',
    previewNote:
        'No address is requested, no code is sent and no recovery setup is completed here.',
    blocks: [
      _Information(
        'Verify before relying on it',
        'The account recovery flow checks a recovery address using one-time codes. An unverified address is not a confirmed recovery method.',
      ),
      _Information(
        'Keep codes private',
        'Only enter a code in the recovery flow you started. Do not share sign-in codes, your provider password or your device passcode in feedback or support messages.',
      ),
    ],
  ),
  ZyraConceptSettingsDetail.appLock => const _PageContent(
    title: 'How App Lock works',
    lead: 'A local device check, not another ZYRA password.',
    previewNote:
        'This explanation does not enable App Lock or prove that this device supports it.',
    blocks: [
      _Information(
        'Supported device authentication',
        'A supported biometric or device passcode must be set up on the phone. The operating system performs the check; ZYRA does not receive your face, fingerprint or device passcode.',
      ),
      _Information(
        'Separate from account access',
        'App Lock does not replace Apple or Google sign-in, account recovery or server permissions. It is not a new account recovery method.',
      ),
    ],
  ),
  ZyraConceptSettingsDetail.resetProfile => _PageContent(
    title: 'Reset Profile',
    lead: guardian
        ? 'The Guardian reset contract still needs approval.'
        : 'A fresh start needs a clear, approved plan.',
    previewNote:
        'Unavailable pending approval of the written specification. There is no reset confirmation, data change or sign-out on this page.',
    blocks: const [
      _Information(
        'A proposal, not a promise',
        'The specification must settle exactly what is removed, anonymised or retained, including profile details, photos, answers, saved choices and paid entitlements. Existing reset behaviour is not the approved policy.',
      ),
      _Information(
        'Shared relationships need explicit rules',
        'Guardian links, Guardian Circle membership, active Journeys, chat history and what other people see must be agreed before execution is enabled. A Guardian cannot reset a Seeker’s profile.',
      ),
      _Information(
        'Recovery is not yet defined',
        'No recovery period or retention deadline has been approved. For a reversible break, review Pause My Profile instead; it is a separate control.',
      ),
    ],
  ),
  ZyraConceptSettingsDetail.deleteAccount => _PageContent(
    title: 'Delete Account',
    lead: guardian
        ? 'Consider the Seekers who rely on your role.'
        : 'Understand permanent account closure.',
    previewNote:
        'Unavailable pending approval of the written specification. No deletion request, confirmation, photo removal or sign-out can run here.',
    blocks: [
      _Information(
        'Shared consequences must be agreed',
        guardian
            ? 'The specification must define Seeker links, replacement-Guardian needs, Circle membership and shared Journey and chat history. These outcomes are not approved by opening this explanation.'
            : 'The specification must define profile and photo deletion, Guardian links, Circle membership, active Journeys, shared chat history and the neutral state shown to other people.',
      ),
      const _Information(
        'Retention and recovery remain undecided',
        'Exact deleted, anonymised and retained fields, safety and payment records, legal holds, backups, recovery availability and any recovery period require written approval. No deadline or neutral-history promise is made here.',
      ),
      const _Information(
        'Need a reversible break?',
        'Pause My Profile is separate from deletion and keeps the account and paid entitlements. Pausing does not cancel Apple or Google store billing.',
      ),
    ],
  ),
  ZyraConceptSettingsDetail.discovery
      when guardian &&
          overviewAction == ZyraConceptAccountAction.guardianPrivacy =>
    const _PageContent(
      title: 'Guardian privacy',
      lead: 'Your role does not make every profile visible.',
      previewNote:
          'This is an explanation only. No relationship, Journey or Circle access is read or changed here.',
      blocks: [
        _Information(
          'Access follows your responsibilities',
          'Guardian identity and shared information belong only in authorised Seeker links, Journeys and Circle membership. Being a Guardian is not permission to browse private profiles.',
        ),
        _Information(
          'Restrictions still apply',
          'Block, account pause and safety restrictions must take priority over links and shared history. When access is unavailable, the app must not reveal the reason.',
        ),
        _Information(
          'Taking a break is separate',
          'Pause My Profile is a separate account-wide control. It must use confirmed server state; this explanation does not pause or unpause your account.',
        ),
      ],
    ),
  ZyraConceptSettingsDetail.discovery => _PageContent(
    title: 'Pause My Profile',
    lead: 'Return when you are ready, without undoing protections.',
    previewNote:
        'This page explains the required account-wide behaviour. Your confirmed Pause state is unavailable here; no Pause or Unpause request is sent.',
    blocks: const [
      _Information(
        'What others see',
        'When access is restricted, other people see a neutral unavailable state. It must not reveal whether the reason is pause, block or another restriction.',
      ),
      _Information(
        'Unpause My Profile',
        'The live control must offer a clear Unpause My Profile action after reading confirmed server state. Unpausing changes only your account pause; it does not unblock anyone, restore a removed Guardian, lift a safety restriction or resume a separately paused Journey.',
      ),
      _Information(
        'Your account and billing stay separate',
        'You stay signed in for permitted features. Profile data, links, Journeys, history and paid entitlements are retained. Pausing does not cancel store billing.',
      ),
    ],
  ),
  ZyraConceptSettingsDetail.hiddenProfiles => const _PageContent(
    title: 'Hidden profiles',
  ),
  ZyraConceptSettingsDetail.notifications => _PageContent(
    title: 'About notifications',
    lead: 'Different updates need different controls.',
    previewNote:
        'No device prompt, subscription, marketing consent or notification preference is changed here.',
    blocks: [
      _Information(
        'Service updates',
        guardian
            ? 'Relevant Seeker links and Journey responsibilities can appear in your in-app updates.'
            : 'Relevant request, Journey and Guardian activity can appear in My ZYRA.',
      ),
      const _Information(
        'Device permission is separate',
        'A preference inside ZYRA does not prove that phone notifications are enabled. Delivery also depends on device permission and the notification service being ready.',
      ),
      const _Information(
        'Marketing and account safety',
        'Marketing is optional and separate from service preferences. Essential account and safety communications are treated separately; no subscription to either is made here.',
      ),
    ],
  ),
  ZyraConceptSettingsDetail.feedback => const _PageContent(
    title: 'Feedback and support',
    lead: 'Send a suggestion through the right route.',
    previewNote:
        'No message is submitted here. Open Help & support below to view the available guidance.',
    blocks: [
      _Information(
        'Product feedback',
        'For an idea or a bug, describe the page, the action you took and the outcome. Leave out other people’s personal details and private messages.',
      ),
      _Information(
        'A safety concern is not general feedback',
        'Use the relevant profile or message reporting action for a safety concern. Product feedback does not replace reporting and is not an emergency channel.',
      ),
    ],
  ),
  ZyraConceptSettingsDetail.privacyPolicy => const _PageContent(
    title: 'Privacy Policy',
    lead: 'The formal policy is not available here yet.',
    previewNote:
        'This is an unavailable-document notice, not a Privacy Policy or a statement that one has been published.',
    blocks: [
      _Information(
        'A separate formal document',
        'A product summary cannot replace the formal Privacy Policy.',
      ),
      _Information(
        'Need clarification?',
        'Open Help & support for the available guidance. Do not share sensitive account information while asking about a policy.',
      ),
    ],
  ),
  ZyraConceptSettingsDetail.terms => const _PageContent(
    title: 'Terms',
    lead: 'The formal terms are not available here yet.',
    previewNote:
        'This notice does not create terms, record acceptance or claim that formal terms have been published.',
    blocks: [
      _Information(
        'A separate formal document',
        'Membership prices and feature descriptions cannot replace the formal Terms.',
      ),
      _Information(
        'Ask before relying on an assumption',
        'Open Help & support for the available guidance. The formal Terms must set out any applicable cancellation, refund, legal and dispute rules.',
      ),
    ],
  ),
};

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({
    required this.id,
    required this.title,
    this.lead,
    this.previewNote,
    this.footer,
    required this.children,
  });

  final String id, title;
  final String? lead, previewNote;
  final Widget? footer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
    key: ValueKey('concept_settings_$id'),
    color: ZyraFounderLaunchPageStyle.activeOf(context)
        ? Colors.white
        : Colors.transparent,
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              title,
              key: ValueKey('concept_settings_title_$id'),
              style: ZyraText.pageTitle().copyWith(
                color: ZyraFounderLaunchPageStyle.inkOf(context),
              ),
            ),
          ),
          Expanded(
            child: KeyedSubtree(
              key: ValueKey('concept_settings_scroll_$id'),
              child: ListView(
                key: id.startsWith('overview_')
                    ? const ValueKey('concept_account_action_scroll')
                    : null,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                children: [
                  if (ZyraFounderLaunchPageStyle.activeOf(context)) ...[
                    _FounderLaunchNote(id: id),
                    const SizedBox(height: 24),
                  ],
                  if (lead case final text?) ...[
                    Text(
                      text,
                      style: ZyraText.heading(
                        size: 22,
                        color: ZyraFounderLaunchPageStyle.inkOf(context),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (previewNote case final note?) ...[
                    Container(
                      key: ValueKey('concept_settings_preview_scope_$id'),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ZyraFounderLaunchPageStyle.surfaceOf(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: ZyraFounderLaunchPageStyle.borderOf(context),
                        ),
                      ),
                      child: Text(
                        note,
                        style: ZyraText.subtext(
                          size: 12.5,
                          color: ZyraFounderLaunchPageStyle.secondaryOf(
                            context,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  ...children,
                ],
              ),
            ),
          ),
          if (footer case final action?)
            Padding(
              key: ValueKey('concept_settings_footer_$id'),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: action,
            ),
        ],
      ),
    ),
  );
}

class _FounderLaunchNote extends StatelessWidget {
  const _FounderLaunchNote({required this.id});
  final String id;

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey('founder_launch_note_$id'),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: ZyraFounderLaunchPageStyle.surfaceOf(context),
      border: Border.all(color: ZyraFounderLaunchPageStyle.borderOf(context)),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Founder input needed before launch',
            style: ZyraText.button(
              size: 14,
              color: ZyraFounderLaunchPageStyle.darkGoldInk,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          ZyraFounderLaunchPageStyle.noteFor(
            ZyraFounderLaunchPageStyle.pendingOf(context),
          ),
          style: ZyraText.body(
            size: 13,
            color: ZyraFounderLaunchPageStyle.darkInk,
          ),
        ),
      ],
    ),
  );
}

class _InformationBlock extends StatelessWidget {
  const _InformationBlock(this.information);
  final _Information information;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          information.title,
          style: ZyraText.heading(
            size: 17,
            color: ZyraFounderLaunchPageStyle.inkOf(context),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          information.body,
          style: ZyraText.body(
            size: 13,
            color: ZyraFounderLaunchPageStyle.bodyOf(context),
          ),
        ),
      ],
    ),
  );
}

class _SettingsDestination extends StatelessWidget {
  const _SettingsDestination({
    super.key,
    required this.title,
    required this.body,
    required this.icon,
    required this.onTap,
  });

  final String title, body;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: ZyraFounderLaunchPageStyle.surfaceOf(context),
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ExcludeSemantics(
                child: Icon(
                  icon,
                  size: 23,
                  color: ZyraFounderLaunchPageStyle.goldOf(context),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: ZyraText.body(
                        size: 14,
                        color: ZyraFounderLaunchPageStyle.bodyOf(context),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      body,
                      style: ZyraText.subtext(
                        size: 12,
                        color: ZyraFounderLaunchPageStyle.secondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ExcludeSemantics(
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: ZyraFounderLaunchPageStyle.secondaryOf(context),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _HelpAction extends StatelessWidget {
  const _HelpAction({required this.id, required this.onHelp});
  final String id;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: OutlinedButton.icon(
      key: ValueKey('concept_settings_help_$id'),
      onPressed: onHelp,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(44, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        foregroundColor: ZyraFounderLaunchPageStyle.inkOf(context),
        side: BorderSide(color: ZyraFounderLaunchPageStyle.borderOf(context)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      icon: const ExcludeSemantics(child: Icon(Icons.help_outline_rounded)),
      label: Text(
        'Open Help & support',
        style: ZyraText.button(
          size: 14,
          color: ZyraFounderLaunchPageStyle.inkOf(context),
        ),
      ),
    ),
  );
}
