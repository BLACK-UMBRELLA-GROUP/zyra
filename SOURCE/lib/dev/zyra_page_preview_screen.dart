// Read-only page inventory opened from the Preview developer control.
// It documents the complete visual surface for the page currently selected;
// it never changes scenario, account, server rows or entitlement.

import 'package:flutter/material.dart';

import '../data/zyra_membership_catalog.dart';
import '../services/zyra_developer_access.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import 'zyra_developer_route_gate.dart';
import 'zyra_dev_scenario.dart';

class ZyraPagePreviewScreen extends StatelessWidget {
  final String roleLabel;
  final String pageLabel;
  final List<_PreviewGroup> _groups;

  const ZyraPagePreviewScreen._({
    required this.roleLabel,
    required this.pageLabel,
    required this._groups,
  });

  factory ZyraPagePreviewScreen.seeker(DevPage page) {
    return ZyraPagePreviewScreen._(
      roleLabel: 'Seeker',
      pageLabel: page.label,
      groups: _seekerGroups(page),
    );
  }

  factory ZyraPagePreviewScreen.guardian(WaliPage page) {
    return ZyraPagePreviewScreen._(
      roleLabel: 'Guardian',
      pageLabel: page.label,
      groups: _guardianGroups(page),
    );
  }

  factory ZyraPagePreviewScreen.entry(String label) {
    return ZyraPagePreviewScreen._(
      roleLabel: 'App entry',
      pageLabel: label,
      groups: _entryGroups,
    );
  }

  factory ZyraPagePreviewScreen.compatibility() => const ZyraPagePreviewScreen._(
    roleLabel: 'Seeker',
    pageLabel: 'Compatibility',
    groups: [
      _PreviewGroup('Overall', 'The headline compatibility result', [
        (
          Icons.lock_outline,
          'Available unlocks',
          'Local sample balances can be set to zero, one or five',
        ),
        (
          Icons.lock_open_outlined,
          'Locked and revealed',
          'A sample result stays revealed without repeat spending',
        ),
      ]),
      _PreviewGroup('The detail', 'Compatibility Unlock', [
        (
          Icons.info_outline,
          'Full Compatibility Unlock demo',
          'A local test credit reveals sample categories and a fictional Guardian; live results and spending stay unavailable',
        ),
      ]),
    ],
  );

  @override
  Widget build(BuildContext context) {
    if (!ZyraDeveloperAccess.canUseDeveloperTools) {
      return const SizedBox.shrink();
    }
    return ZyraDeveloperRouteGate(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text('$pageLabel preview', style: ZyraText.heading(size: 18)),
        ),
        body: Container(
          decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 68, 20, 32),
              children: [
                Text(
                  '$roleLabel · $pageLabel',
                  style: ZyraText.chapterLabel(color: ZyraColors.unlockText),
                ),
                const SizedBox(height: 7),
                Text(
                  'Everything this page can contain.',
                  style: ZyraText.heading(size: 26),
                ),
                const SizedBox(height: 6),
                Text(
                  'One read-only view of normal content, waiting states, '
                  'limits, interruptions and empty/error outcomes.',
                  style: ZyraText.subtext(size: 12.5),
                ),
                const SizedBox(height: 18),
                for (final group in _groups) ...[
                  _PreviewGroupCard(group: group),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 5),
                Text(
                  'PREVIEW ONLY · NOTHING WRITTEN',
                  textAlign: TextAlign.center,
                  style: ZyraText.chapterLabel(color: Colors.white30),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const List<_PreviewGroup> _entryGroups = [
  _PreviewGroup('Welcome & access', 'Every app-entry state', [
    (
      Icons.auto_awesome_outlined,
      'Splash and Welcome',
      'Cold-start identity, Apple and Google entry',
    ),
    (
      Icons.switch_account_outlined,
      'Developer Access',
      'Ready-made Seeker and Guardian identities',
    ),
    (
      Icons.security_outlined,
      'Recovery and verification',
      'Session, email and identity recovery paths',
    ),
    (
      Icons.error_outline,
      'Offline and service errors',
      'Truthful retry and return-to-Welcome outcomes',
    ),
  ]),
  _PreviewGroup('Seeker sign-up', 'The complete guided journey', [
    (Icons.badge_outlined, 'Essentials', 'Identity, age and location'),
    (
      Icons.photo_camera_outlined,
      'Profile',
      'Photos and visible profile information',
    ),
    (Icons.menu_book_outlined, 'Biography', 'About Me and life details'),
    (
      Icons.insights_outlined,
      'Compatibility',
      'Your answers and partner preferences',
    ),
    (
      Icons.traffic_outlined,
      'Answer importance',
      'Green, amber and red preference meaning',
    ),
    (Icons.verified_outlined, 'Review and readiness', 'Completion and gaps'),
  ]),
  _PreviewGroup('Guardian sign-up', 'The Guardian account path', [
    (Icons.badge_outlined, 'Identity', 'Name, gender and age eligibility'),
    (
      Icons.family_restroom_outlined,
      'Relationship',
      'Guardian context without overclaiming verification',
    ),
    (
      Icons.mark_email_unread_outlined,
      'Invite or link',
      'Connect to the Seeker you support',
    ),
    (Icons.verified_outlined, 'Review and readiness', 'Completion and gaps'),
  ]),
  _PreviewGroup('Flow outcomes', 'States that can replace a question', [
    (Icons.sync, 'Loading', 'Shared ZYRA loading language'),
    (Icons.warning_amber_outlined, 'Required answer', 'Inline validation'),
    (Icons.arrow_back, 'Back and resume', 'Safe return within the journey'),
    (Icons.check_circle_outline, 'Complete', 'Ready for the selected account'),
  ]),
];

class _PreviewGroup {
  final String title;
  final String subtitle;
  final List<(IconData, String, String)> items;

  const _PreviewGroup(this.title, this.subtitle, this.items);
}

class _PreviewGroupCard extends StatelessWidget {
  final _PreviewGroup group;

  const _PreviewGroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.065),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12, width: 0.6),
      ),
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(group.title, style: ZyraText.heading(size: 17)),
          const SizedBox(height: 3),
          Text(
            group.subtitle,
            style: ZyraText.subtext(size: 10.5, color: Colors.white38),
          ),
          const SizedBox(height: 9),
          for (final item in group.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item.$1, size: 17, color: ZyraColors.unlockText),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.$2, style: ZyraText.body(size: 12.5)),
                        const SizedBox(height: 2),
                        Text(
                          item.$3,
                          style: ZyraText.subtext(
                            size: 10,
                            color: Colors.white38,
                          ),
                        ),
                      ],
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

List<_PreviewGroup> _seekerGroups(DevPage page) => switch (page) {
  DevPage.browse => const [
    _PreviewGroup('Profile', 'The fixed full-screen discovery card', [
      (
        Icons.photo_outlined,
        'Photo and identity',
        'Name, age, city, photo progress and profile detail',
      ),
      (
        Icons.shield_outlined,
        'Trust context',
        'Verification, Guardian presence and reporting entry',
      ),
      (
        Icons.insights_outlined,
        'Compatibility context',
        'Approved headline signals without private answers',
      ),
    ]),
    _PreviewGroup('Decisions', 'Every action and gesture state', [
      (
        Icons.close,
        'Pass',
        'Silent next-profile decision and red rim feedback',
      ),
      (
        Icons.bookmark_outline,
        'Save',
        'Private Connections shortlist and amber feedback',
      ),
      (
        Icons.person_add_alt_1_outlined,
        'Consider',
        'Positive decision and green feedback',
      ),
    ]),
    _PreviewGroup(
      'Interruptions',
      'Content that can replace or cover the card',
      [
        (Icons.schedule, 'Browsing limit', 'Legacy four-hour limit fixture'),
        (
          Icons.lock_outline,
          'Save and Consider limits',
          'Truthful locked-feature explanation',
        ),
        (
          Icons.hourglass_empty,
          'Loading, empty and error',
          'Fetch, no-result and recovery states',
        ),
      ],
    ),
  ],
  DevPage.connections => const [
    _PreviewGroup('Connection groups', 'Every lifecycle section', [
      (
        Icons.auto_awesome_outlined,
        'Guardian introductions',
        'Profiles introduced through Guardians',
      ),
      (
        Icons.hourglass_top,
        'Potential',
        'Mutual interest before a Journey begins',
      ),
      (
        Icons.route_outlined,
        'Active Journey',
        'The one real server-backed active path',
      ),
      (
        Icons.pause_circle_outline,
        'Pause decisions',
        'Requested, deciding, mutually paused and resuming',
      ),
      (Icons.history, 'Ended', 'Completed or closed Journey history'),
    ]),
    _PreviewGroup(
      'Decisions and access',
      'States layered onto connection cards',
      [
        (
          Icons.family_restroom_outlined,
          'Family Review',
          'Waiting, proceed and closure outcomes',
        ),
        (
          Icons.lock_open_outlined,
          'Compatibility unlock',
          'Full reveal and retained earlier overall access',
        ),
        (
          Icons.error_outline,
          'Loading, empty and error',
          'Section and whole-page recovery',
        ),
      ],
    ),
  ],
  DevPage.activeJourney => const [
    _PreviewGroup('Journey path', 'The live guided relationship route', [
      (
        Icons.route_outlined,
        'Current stage',
        'The stage both Seekers have reached together',
      ),
      (
        Icons.swap_vert_circle_outlined,
        'Stage movement',
        'Continuous back-and-forward Journey navigation',
      ),
      (
        Icons.family_restroom_outlined,
        'Guardian and family gates',
        'Shared decisions and review states',
      ),
    ]),
    _PreviewGroup('Journey decisions', 'States owned inside the Journey', [
      (
        Icons.pause_circle_outline,
        'Pause decision',
        'Request, response, mutual pause and resume outcomes',
      ),
      (
        Icons.stop_circle_outlined,
        'End Journey',
        'Confirmed closure without losing truthful history',
      ),
      (
        Icons.error_outline,
        'Loading and recovery',
        'Truthful unavailable, retry and stale-state handling',
      ),
    ]),
  ],
  DevPage.guardian => const [
    _PreviewGroup('Guardian relationships', 'All relationship surfaces', [
      (
        Icons.verified_user_outlined,
        'Main Guardian',
        'Primary authority and active link',
      ),
      (
        Icons.people_outline,
        'Additional Guardians',
        'Support roles and linked profiles',
      ),
      (
        Icons.mark_email_unread_outlined,
        'Invitations received',
        'Pending decisions from Guardians',
      ),
      (
        Icons.outgoing_mail,
        'Invitations sent',
        'Open codes and invitation status',
      ),
    ]),
    _PreviewGroup('Page outcomes', 'Non-card states', [
      (
        Icons.person_add_alt_1_outlined,
        'No Guardian linked',
        'Centred invitation action',
      ),
      (Icons.sync, 'Loading and refresh', 'Real relationship fetch'),
      (Icons.error_outline, 'Unavailable', 'Retryable service failure'),
    ]),
  ],
  DevPage.dashboard => const [
    _PreviewGroup('Dashboard', 'Seeker hub destinations', [
      (
        Icons.bookmark_border,
        'Connections',
        'Journeys, introductions and activity',
      ),
      (Icons.gpp_good_outlined, 'Guardian', 'Guardian links and invitations'),
      (
        Icons.circle_notifications_outlined,
        'Notifications',
        'New service activity with live badge state',
      ),
    ]),
    _PreviewGroup('Attention state', 'Notification summary', [
      (Icons.notifications_active_outlined, 'Unread', 'Count is waiting'),
      (Icons.notifications_none, 'All clear', 'Nothing needs attention'),
    ]),
  ],
  DevPage.profile => const [
    _PreviewGroup('Account', 'Identity and plan surfaces', [
      (Icons.person_outline, 'Profile summary', 'Photo, name and completion'),
      (
        Icons.verified_user_outlined,
        'Verification',
        'Identity, age and photo integrity states',
      ),
      (
        Icons.workspace_premium_outlined,
        'Membership',
        'Inactive or ${ZyraMembershipCatalog.seekerOneTitle} access state',
      ),
      (
        Icons.switch_account_outlined,
        'Switch account',
        'Seeker and Guardian contexts',
      ),
    ]),
    _PreviewGroup('Settings', 'All destinations reachable from Profile', [
      (
        Icons.lock_outline,
        'Privacy and safety',
        'Visibility, blocking and account security',
      ),
      (
        Icons.notifications_outlined,
        'Notifications',
        'Device, service and marketing preferences',
      ),
      (
        Icons.help_outline,
        'Help and feedback',
        'Support, reporting and recovery',
      ),
      (
        Icons.settings_outlined,
        'Account controls',
        'Edit, advanced actions and deletion',
      ),
    ]),
  ],
};

List<_PreviewGroup> _guardianGroups(WaliPage page) => switch (page) {
  WaliPage.dashboard => const [
    _PreviewGroup(
      'Seeker context',
      'Everything scoped to the selected Seeker',
      [
        (
          Icons.swap_horiz,
          'Seeker slider',
          'One to four names plus overflow selection',
        ),
        (
          Icons.people_outline,
          'Linked Seekers',
          'Cards, empty state and invitation action',
        ),
        (
          Icons.route_outlined,
          'Journeys',
          'Active, paused and ended Journey summaries',
        ),
      ],
    ),
    _PreviewGroup('Decisions waiting', 'Guardian actions requiring attention', [
      (
        Icons.fact_check_outlined,
        'Family Review',
        'Review, proceed and expiry states',
      ),
      (
        Icons.diversity_3_outlined,
        'Network connections',
        'Incoming, sent, connected and history',
      ),
      (
        Icons.error_outline,
        'Loading, empty and error',
        'Every dashboard-wide outcome',
      ),
    ]),
  ],
  WaliPage.network => const [
    _PreviewGroup('Discovery', 'The complete Seeker-scoped Network surface', [
      (
        Icons.swap_horiz,
        'Seeker slider',
        'Shared with Dashboard and capped before overflow',
      ),
      (
        Icons.person_search_outlined,
        'Recommended Seeker profile',
        'Person-led full card with Guardian context',
      ),
      (
        Icons.bookmark_outline,
        'Save and set aside',
        'Private reversible decisions',
      ),
      (
        Icons.send_outlined,
        'Request introduction',
        'Main-Guardian authority action',
      ),
    ]),
    _PreviewGroup('Connection stages', 'Every state after a request', [
      (
        Icons.mark_email_unread_outlined,
        'Incoming request',
        'Review and accept or decline privately',
      ),
      (Icons.outgoing_mail, 'Sent', 'Awaiting the other Main Guardian'),
      (
        Icons.handshake_outlined,
        'Connected',
        'Reciprocal profiles and structured exchange',
      ),
      (
        Icons.group_add_outlined,
        'Ready for Seekers',
        'Both Main Guardians have confirmed',
      ),
    ]),
    _PreviewGroup('Boundaries', 'Locked and non-content outcomes', [
      (
        Icons.lock_outline,
        'Guardian access states',
        'Linked/unlinked and entitled/unentitled',
      ),
      (Icons.filter_3, 'Three-process cap', 'Calm capacity state'),
      (
        Icons.hourglass_empty,
        'Loading, empty and error',
        'Honest availability and retry states',
      ),
    ]),
  ],
  WaliPage.seekers => const [
    _PreviewGroup('People you support', 'All Seeker relationship states', [
      (
        Icons.people_outline,
        'Linked Seekers',
        'Main and Additional relationship context',
      ),
      (Icons.outgoing_mail, 'Pending invitations', 'Unused invitation codes'),
      (
        Icons.person_add_alt_1_outlined,
        'Invite a Seeker',
        'Centred add action',
      ),
      (
        Icons.error_outline,
        'Loading, empty and error',
        'Fetch and recovery outcomes',
      ),
    ]),
  ],
  WaliPage.notifications => const [
    _PreviewGroup('Guardian activity', 'All notification categories', [
      (
        Icons.mark_email_unread_outlined,
        'Unread',
        'Quiet badge and unread rows',
      ),
      (Icons.diversity_3_outlined, 'Network', 'Digest-safe request updates'),
      (Icons.route_outlined, 'Journeys', 'Review and Journey service activity'),
      (
        Icons.people_outline,
        'Seeker links',
        'Invitation and relationship events',
      ),
    ]),
    _PreviewGroup('Page outcomes', 'Whole-feed states', [
      (Icons.notifications_off_outlined, 'Empty', 'No activity yet'),
      (Icons.sync, 'Loading', 'Feed refresh'),
      (Icons.error_outline, 'Error', 'Truthful retry state'),
    ]),
  ],
  WaliPage.profile => const [
    _PreviewGroup('Guardian account', 'Identity, role and entitlement', [
      (Icons.person_outline, 'Profile summary', 'Photo, name and relationship'),
      (
        Icons.verified_user_outlined,
        'Verification',
        'Guardian identity and relationship claims',
      ),
      (
        Icons.workspace_premium_outlined,
        'Membership',
        'Guardian access or membership inactive',
      ),
      (
        Icons.switch_account_outlined,
        'Switch account',
        'Guardian and Seeker contexts',
      ),
    ]),
    _PreviewGroup('Settings', 'Every profile destination', [
      (
        Icons.notifications_outlined,
        'Notifications',
        'Device, service and marketing preferences',
      ),
      (
        Icons.lock_outline,
        'Privacy and safety',
        'Blocking, security and data controls',
      ),
      (Icons.help_outline, 'Help and feedback', 'Support and recovery'),
      (
        Icons.settings_outlined,
        'Account controls',
        'Edit and advanced actions',
      ),
    ]),
  ],
};
