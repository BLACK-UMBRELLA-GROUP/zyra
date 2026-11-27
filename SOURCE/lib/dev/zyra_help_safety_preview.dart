import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_tap_feedback.dart';

/// LOCK 37 presentation. The owning Founder shell supplies only sample state;
/// no support message, report, export request or deletion leaves this widget.
enum ZyraHelpSafetyScreen {
  contact,
  contactSent,
  reportSent,
  advanced,
  data,
  delete,
  closed,
  privacy,
}

class ZyraHelpSafetyPreview extends StatefulWidget {
  const ZyraHelpSafetyPreview({
    super.key,
    required this.screen,
    required this.guardian,
    required this.firstName,
    this.reportedName,
    this.dataRequestedAt,
    this.closedAt,
    required this.onContactSent,
    required this.onReportDone,
    required this.onBlockReported,
    required this.onOpenData,
    required this.onOpenDelete,
    required this.onRequestData,
    required this.onDelete,
    required this.onClose,
    required this.onDone,
    required this.onLegal,
    required this.onSubscriptions,
  });

  final ZyraHelpSafetyScreen screen;
  final bool guardian;
  final String firstName;
  final String? reportedName;
  final DateTime? dataRequestedAt, closedAt;
  final VoidCallback onContactSent, onReportDone, onBlockReported;
  final VoidCallback onOpenData, onOpenDelete, onRequestData, onDelete;
  final VoidCallback onClose, onDone, onSubscriptions;
  final ValueChanged<String> onLegal;

  @override
  State<ZyraHelpSafetyPreview> createState() => _ZyraHelpSafetyPreviewState();
}

class _ZyraHelpSafetyPreviewState extends State<ZyraHelpSafetyPreview> {
  static const _topics = [
    'Account and sign-in',
    'Membership and payments',
    'Journeys',
    'Guardians',
    'Safety',
    'Something else',
  ];
  final _message = TextEditingController();
  String? _topic;
  bool _screenshot = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  bool get _canSend => _topic != null && _message.text.trim().length >= 10;

  @override
  Widget build(BuildContext context) {
    final screen = widget.screen;
    final title = switch (screen) {
      ZyraHelpSafetyScreen.contact ||
      ZyraHelpSafetyScreen.contactSent => 'Contact support',
      ZyraHelpSafetyScreen.reportSent => '',
      ZyraHelpSafetyScreen.advanced => 'Advanced',
      ZyraHelpSafetyScreen.data => 'Download my data',
      ZyraHelpSafetyScreen.delete => 'Delete my account',
      ZyraHelpSafetyScreen.closed => '',
      ZyraHelpSafetyScreen.privacy => 'Privacy & data',
    };
    return Material(
      key: ValueKey('help_safety_${screen.name}'),
      color: ZyraColors.ivoryTop,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title.isNotEmpty) ...[
                Text(
                  title,
                  style: ZyraText.pageTitle(),
                  key: ValueKey('help_safety_title_${screen.name}'),
                ),
                const SizedBox(height: 43),
              ],
              Expanded(
                child: ListView(
                  key: ValueKey('help_safety_scroll_${screen.name}'),
                  physics: const ScrollPhysics(),
                  children: switch (screen) {
                    ZyraHelpSafetyScreen.contact => _contact(),
                    ZyraHelpSafetyScreen.contactSent => _contactSent(),
                    ZyraHelpSafetyScreen.reportSent => _reportSent(),
                    ZyraHelpSafetyScreen.advanced => _advanced(),
                    ZyraHelpSafetyScreen.data => _data(),
                    ZyraHelpSafetyScreen.delete => _delete(),
                    ZyraHelpSafetyScreen.closed => _closed(),
                    ZyraHelpSafetyScreen.privacy => _privacy(),
                  },
                ),
              ),
              _footer(screen),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _contact() => [
    _section('WHAT IS IT ABOUT?'),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final topic in _topics)
          ChoiceChip(
            key: ValueKey('help_topic_$topic'),
            label: Text(topic),
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            selected: _topic == topic,
            onSelected: (_) => setState(() => _topic = topic),
            backgroundColor: ZyraColors.ivoryTop,
            selectedColor: ZyraColors.ivoryTop,
            labelStyle: ZyraText.body(
              size: 13,
              color: _topic == topic
                  ? ZyraColors.goldTextStrong
                  : ZyraColors.espresso,
            ),
            shape: StadiumBorder(
              side: BorderSide(
                color: _topic == topic
                    ? ZyraColors.goldTextStrong
                    : ZyraColors.surfaceBorder,
              ),
            ),
          ),
      ],
    ),
    const SizedBox(height: 34),
    _section('YOUR MESSAGE'),
    TextField(
      key: const ValueKey('help_contact_message'),
      controller: _message,
      maxLength: 1000,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      minLines: 5,
      maxLines: 5,
      style: ZyraText.body(size: 15, color: ZyraColors.espresso),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Tell us what happened and what you expected.',
        hintStyle: ZyraText.body(size: 15, color: ZyraColors.secondaryText),
        filled: true,
        fillColor: ZyraColors.ivoryTop,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: ZyraColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: ZyraColors.divider),
        ),
      ),
    ),
    const SizedBox(height: 8),
    _card([
      _row(
        _screenshot ? 'Screenshot added' : 'Add a screenshot',
        onTap: () => setState(() => _screenshot = !_screenshot),
        value: _screenshot ? '1 of 1' : 'Optional',
      ),
    ]),
    const SizedBox(height: 14),
    _copy(
      'We reply by email within 2 working days. Your name, membership and app version are added so you don’t have to type them.',
    ),
  ];

  List<Widget> _contactSent() => [
    const SizedBox(height: 220),
    _symbol(Icons.check, ZyraColors.positiveGreen),
    const SizedBox(height: 22),
    _center('Message sent', 25),
    const SizedBox(height: 14),
    _center('We’ll reply by email within 2 working days.', 15, secondary: true),
    const SizedBox(height: 20),
    Center(child: _chip('Reference ZS-48213')),
  ];

  List<Widget> _reportSent() {
    final name = widget.reportedName ?? 'this member';
    return [
      const SizedBox(height: 40),
      _symbol(Icons.security, ZyraColors.journeyGold),
      const SizedBox(height: 24),
      _center('Thank you for telling us', 25),
      const SizedBox(height: 2),
      _center('Your report about $name has been sent.', 14, secondary: true),
      const SizedBox(height: 14),
      _section('WHAT HAPPENS NEXT'),
      _card([
        _fact(
          Icons.schedule_outlined,
          'We look at every report within 24 hours',
          'A person on the ZYRA team reads it, not a computer alone.',
        ),
        _fact(
          Icons.visibility_off_outlined,
          '$name is not told who reported',
          'Your name is never shared.',
        ),
        _fact(
          Icons.gavel_outlined,
          'If our rules were broken, we act',
          'From a warning to removing the account.',
        ),
        _fact(
          Icons.notifications_outlined,
          'We tell you when it’s done',
          'You’ll see the outcome in My ZYRA.',
        ),
      ]),
    ];
  }

  List<Widget> _advanced() => [
    _section('YOUR DATA'),
    _card([
      _row(
        'Download my data',
        onTap: widget.onOpenData,
        value: widget.dataRequestedAt == null ? null : 'Requested',
      ),
    ]),
    const SizedBox(height: 36),
    _section('ACCOUNT'),
    _card([
      _row('Delete my account', onTap: widget.onOpenDelete, danger: true),
    ]),
    if (!widget.guardian) ...[
      const SizedBox(height: 8),
      _copyRoute(
        'Want a break instead? Pause My Profile in Settings ',
        ' Privacy. Your Journeys and Guardians stay as they are.',
      ),
    ],
    const SizedBox(height: 36),
    _section("IF YOU'RE AWAY"),
    _card([
      if (!widget.guardian)
        _fact(
          Icons.visibility_off_outlined,
          'After 6 months without opening ZYRA',
          'Your profile is hidden from Profiles. Nothing is deleted; open ZYRA to show it again.',
        ),
      _fact(
        Icons.history,
        'After 2 years',
        'Your account is closed. We email you before, and you then have 30 days to change your mind. Never while a paid plan is running.',
      ),
    ]),
  ];

  List<Widget> _data() => [
    Text(
      'A copy of everything ZYRA keeps about you, in one file.',
      maxLines: 1,
      style: ZyraText.body(size: 13, color: ZyraColors.secondaryText),
    ),
    const SizedBox(height: 21),
    _section('WHAT’S IN IT'),
    _card([
      if (widget.guardian) ...[
        _fact(Icons.person_outline, 'Your profile'),
        _fact(Icons.groups_outlined, 'Your Seeker links'),
      ] else ...[
        _fact(Icons.person_outline, 'Your profile and photos'),
        _fact(Icons.tune, 'Your Partner preferences answers'),
        _fact(
          Icons.people_outline,
          'Your Journeys, Timelines and Journey Bios',
        ),
        _fact(Icons.groups_outlined, 'Your Guardian links'),
      ],
      _fact(Icons.chat_bubble_outline, 'Messages you sent'),
    ]),
    const SizedBox(height: 8),
    _copy('Other members’ photos and private answers are not included.'),
  ];

  List<Widget> _delete() => [
    _section('WHAT HAPPENS'),
    _card([
      _fact(
        Icons.visibility_off_outlined,
        'Your profile disappears straight away',
        'No one can find you or send you requests.',
      ),
      if (widget.guardian)
        _fact(
          Icons.groups_outlined,
          'Your Seekers are unlinked',
          'Your Seekers see that you left ZYRA.',
        )
      else ...[
        _fact(
          Icons.people_outline,
          'Your Journeys end',
          'The other person sees “Journey ended”, with no reason.',
        ),
        _fact(
          Icons.groups_outlined,
          'Your Guardians are unlinked',
          'They see that you left ZYRA.',
        ),
      ],
      _fact(
        Icons.history,
        'You have 30 days to change your mind',
        'Sign in again within 30 days and everything comes back. After that it is deleted for good.',
      ),
    ]),
    const SizedBox(height: 28),
    _section('BEFORE YOU GO'),
    _card([
      _row('Download my data', onTap: widget.onOpenData),
      _row('Cancel subscription in App Store', onTap: widget.onSubscriptions),
    ]),
    const SizedBox(height: 8),
    _copy(
      'Deleting your account does not cancel an App Store subscription. Cancel it first so you aren’t charged again.',
    ),
  ];

  List<Widget> _closed() {
    final date = widget.closedAt?.add(const Duration(days: 30));
    final until = date == null
        ? '30 days'
        : '${date.day} ${_months[date.month - 1]}';
    return [
      const SizedBox(height: 220),
      _symbol(Icons.check, ZyraColors.goldTextStrong),
      const SizedBox(height: 22),
      _center('Your account is closed', 25),
      const SizedBox(height: 12),
      _center(
        'Thank you for being part of ZYRA, ${widget.firstName}. If you change your mind, sign in again before $until and everything comes back.',
        15,
        secondary: true,
      ),
    ];
  }

  List<Widget> _privacy() => [
    _section('READ'),
    _card([
      _row('Privacy policy', onTap: () => widget.onLegal('privacy')),
      _row('Terms of use', onTap: () => widget.onLegal('terms')),
      _row('How photos are kept safe', onTap: () => widget.onLegal('photos')),
    ]),
    const SizedBox(height: 28),
    _section('YOUR DATA'),
    _card([
      _row(
        'Download my data',
        onTap: widget.onOpenData,
        value: widget.dataRequestedAt == null ? null : 'Requested',
      ),
    ]),
    const SizedBox(height: 8),
    _copyRoute('To delete your account, go to Settings ', ' Advanced.'),
  ];

  Widget _footer(ZyraHelpSafetyScreen screen) => switch (screen) {
    ZyraHelpSafetyScreen.contact => _mainButton(
      'Send message',
      _canSend ? widget.onContactSent : null,
    ),
    ZyraHelpSafetyScreen.contactSent => _mainButton('Done', widget.onDone),
    ZyraHelpSafetyScreen.reportSent => Column(
      children: [
        _mainButton('Done', widget.onReportDone, goldFill: true),
        const SizedBox(height: 5),
        TextButton(
          key: const ValueKey('help_report_block_too'),
          onPressed: ZyraTapFeedback.onTap(context, widget.onBlockReported),
          child: Text(
            'Block ${widget.reportedName ?? 'this member'} too',
            style: ZyraText.body(size: 14, color: ZyraColors.dangerTextStrong),
          ),
        ),
      ],
    ),
    ZyraHelpSafetyScreen.data =>
      widget.dataRequestedAt == null
          ? _mainButton('Request my data', widget.onRequestData)
          : Container(
              key: const ValueKey('help_data_requested'),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: ZyraColors.positiveGreen.withValues(alpha: .4),
                ),
                borderRadius: BorderRadius.circular(16),
                color: ZyraColors.positiveGreen.withValues(alpha: .07),
              ),
              child: Text(
                'Requested on ${widget.dataRequestedAt!.day} ${_months[widget.dataRequestedAt!.month - 1]}. We’ll email you a download link, usually within 2 days. The link works for 7 days.',
                style: ZyraText.body(size: 14),
              ),
            ),
    ZyraHelpSafetyScreen.delete => OutlinedButton(
      key: const ValueKey('help_delete_open_confirm'),
      onPressed: ZyraTapFeedback.onTap(context, _confirmDelete),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: ZyraColors.dangerTextStrong,
        side: const BorderSide(color: ZyraColors.dangerTextStrong),
        shape: const StadiumBorder(),
      ),
      child: const Text('Delete my account'),
    ),
    ZyraHelpSafetyScreen.closed => _mainButton('Close', widget.onClose),
    _ => const SizedBox.shrink(),
  };

  Future<void> _confirmDelete() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ZyraColors.ivoryTop,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              _symbol(
                widget.firstName.isNotEmpty ? null : Icons.person_outline,
                ZyraColors.goldTextStrong,
                initial: widget.firstName.isEmpty
                    ? null
                    : widget.firstName[0].toUpperCase(),
              ),
              const SizedBox(height: 16),
              _center('Delete your account?', 24),
              const SizedBox(height: 12),
              _center(
                'Your profile disappears now. Sign in within 30 days to change your mind.',
                14,
                secondary: true,
              ),
              const SizedBox(height: 22),
              TextButton(
                key: const ValueKey('help_delete_confirm'),
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  widget.onDelete();
                },
                child: Text(
                  'Delete my account',
                  style: ZyraText.body(
                    size: 16,
                    color: ZyraColors.dangerTextStrong,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _mainButton(
                'Keep my account',
                () => Navigator.of(sheetContext).pop(),
                key: const ValueKey('help_delete_keep'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      label,
      style: ZyraText.chapterLabel(color: ZyraColors.secondaryText),
    ),
  );

  Widget _copy(String text) => Text(
    text,
    style: ZyraText.body(size: 14, color: ZyraColors.secondaryText),
  );

  Widget _copyRoute(String before, String after) => Text.rich(
    TextSpan(
      children: [
        TextSpan(text: before),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Icon(
            Icons.arrow_forward,
            size: 14,
            color: ZyraColors.secondaryText,
          ),
        ),
        TextSpan(text: after),
      ],
    ),
    style: ZyraText.body(size: 14, color: ZyraColors.secondaryText),
  );

  Widget _center(String text, double size, {bool secondary = false}) => Text(
    text,
    textAlign: TextAlign.center,
    style: secondary
        ? ZyraText.body(size: size, color: ZyraColors.secondaryText)
        : ZyraText.heading(size: size, color: ZyraColors.espresso),
  );

  Widget _chip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
    decoration: BoxDecoration(
      border: Border.all(color: ZyraColors.surfaceBorder),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(text, style: ZyraText.body(size: 14)),
  );

  Widget _symbol(IconData? icon, Color color, {String? initial}) => Center(
    child: Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color),
      ),
      child: Center(
        child: initial == null
            ? Icon(icon, size: 32, color: color)
            : Text(initial, style: ZyraText.heading(size: 29, color: color)),
      ),
    ),
  );

  Widget _card(List<Widget> children) => DecoratedBox(
    decoration: BoxDecoration(
      color: ZyraColors.cardSurface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: ZyraColors.surfaceBorder),
      boxShadow: const [
        BoxShadow(
          color: Color(0x10000000),
          blurRadius: 16,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) Divider(height: 1, color: ZyraColors.divider),
          children[i],
        ],
      ],
    ),
  );

  Widget _row(
    String title, {
    required VoidCallback onTap,
    String? value,
    bool danger = false,
  }) => InkWell(
    key: ValueKey('help_row_$title'),
    onTap: ZyraTapFeedback.onTap(context, onTap),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: ZyraText.body(
                size: 15,
                color: danger
                    ? ZyraColors.dangerTextStrong
                    : ZyraColors.espresso,
              ),
            ),
          ),
          if (value != null)
            Text(
              value,
              style: ZyraText.body(size: 13, color: ZyraColors.secondaryText),
            ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right,
            color: danger
                ? ZyraColors.dangerTextStrong
                : ZyraColors.secondaryText,
          ),
        ],
      ),
    ),
  );

  Widget _fact(IconData icon, String title, [String? detail]) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: ZyraColors.goldTextStrong),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: ZyraText.body(size: 14, color: ZyraColors.espresso),
              ),
              if (detail != null) ...[
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: ZyraText.body(
                    size: 12,
                    color: ZyraColors.secondaryText,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );

  Widget _mainButton(
    String text,
    VoidCallback? onTap, {
    Key? key,
    bool goldFill = false,
  }) => FilledButton(
    key: key ?? ValueKey('help_action_$text'),
    onPressed: onTap == null ? null : ZyraTapFeedback.onTap(context, onTap),
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      backgroundColor: goldFill
          ? ZyraColors.goldTextFill
          : ZyraColors.journeyGold,
      shadowColor: goldFill ? ZyraColors.goldTextFill : null,
      foregroundColor: ZyraColors.espresso,
      disabledBackgroundColor: ZyraColors.journeyGold.withValues(alpha: .46),
      disabledForegroundColor: ZyraColors.secondaryText,
      shape: const StadiumBorder(),
    ),
    child: Text(
      text,
      style: ZyraText.button(
        size: 15,
        color: onTap == null ? ZyraColors.secondaryText : ZyraColors.espresso,
      ),
    ),
  );

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}
