import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_floating_surface.dart';
import '../widgets/zyra_tap_feedback.dart';

/// Locked presentation for the Founder sample. The shell owns all callbacks.
class ZyraSeekerPlacesPreview extends StatelessWidget {
  const ZyraSeekerPlacesPreview({
    super.key,
    required this.isOne,
    required this.journeys,
    this.familyPlaces,
  });

  final bool isOne;
  final List<ZyraProfileSmallPageRow> journeys;
  final List<ZyraProfileSmallPageRow>? familyPlaces;

  @override
  Widget build(BuildContext context) {
    final family = familyPlaces;
    return _Page(
      id: 'small_pages_seeker_places',
      title: 'Your places',
      children: [
        _ListSection(heading: 'JOURNEY PLACES', rows: journeys),
        _Caption(
          isOne
              ? 'Seeker One has 3 Journey places. A place frees up when a Journey ends.'
              : 'Seeker Basic has 1 Journey place. A place frees up when a Journey ends.',
        ),
        if (family != null) ...[
          _ListSection(heading: 'ZYRA FAMILY PLACES', rows: family),
          const _Caption(
            'Your ZYRA Family pays for these together in one monthly plan.',
          ),
        ],
      ],
    );
  }
}

class ZyraGuardianPlacesPreview extends StatelessWidget {
  const ZyraGuardianPlacesPreview({
    super.key,
    required this.seekers,
    this.familyPayer,
    this.isBasic = false,
  });

  final List<ZyraProfileSmallPageRow> seekers;
  final String? familyPayer;
  final bool isBasic;

  @override
  Widget build(BuildContext context) {
    final payer = familyPayer;
    final plan = payer != null
        ? 'Guardian One · Family place'
        : isBasic
        ? 'Guardian Basic · Free plan'
        : 'Guardian One · Your own plan';
    final detail = payer != null
        ? 'Paid by $payer’s ZYRA Family'
        : isBasic
        ? 'You pay nothing'
        : 'You pay £19.99 a month';

    return _Page(
      id: 'small_pages_guardian_places',
      title: 'Your places',
      children: [
        _ListSection(
          heading: 'YOUR PLAN',
          rows: [
            ZyraProfileSmallPageRow(
              icon: Icons.security,
              title: plan,
              subtitle: detail,
            ),
          ],
        ),
        _ListSection(
          heading: 'YOUR SEEKERS',
          rows: seekers.isEmpty
              ? const [
                  ZyraProfileSmallPageRow(
                    icon: Icons.person_outline,
                    title: 'No Seekers yet',
                    subtitle: 'Use + in the Seekers tab to add one',
                  ),
                ]
              : seekers,
        ),
        const _Caption(
          'A Seeker can cover your Guardian One with their ZYRA Family place.',
        ),
      ],
    );
  }
}

class ZyraSwitchProfilePreview extends StatelessWidget {
  const ZyraSwitchProfilePreview({
    super.key,
    required this.guardian,
    required this.seekerPlan,
    required this.guardianPlan,
    required this.onSwitch,
    this.otherRoleMissing = false,
  });

  final bool guardian, otherRoleMissing;
  final String seekerPlan, guardianPlan;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) => _Page(
    id: 'small_pages_switch_profile',
    title: 'Switch profile',
    children: [
      const _Intro(
        'One account, two roles. Switch any time; each keeps its own Journeys, Guardians and membership.',
        bottom: 14,
      ),
      _RoleCard(
        guardian: guardian,
        plan: guardian ? guardianPlan : seekerPlan,
        current: true,
      ),
      const SizedBox(height: 12),
      _RoleCard(
        guardian: !guardian,
        plan: otherRoleMissing ? null : (guardian ? seekerPlan : guardianPlan),
        onAction: onSwitch,
      ),
    ],
  );
}

class ZyraInvitePreview extends StatelessWidget {
  const ZyraInvitePreview({
    super.key,
    required this.guardian,
    required this.link,
    required this.onCopy,
    required this.onShare,
  });

  final bool guardian;
  final String link;
  final VoidCallback onCopy, onShare;

  @override
  Widget build(BuildContext context) => _Page(
    id: 'small_pages_invite',
    title: 'Invite someone to ZYRA',
    children: [
      const _Intro(
        'Know someone looking for marriage the right way? Send them your link. They join as themselves; nothing about you is shared.',
        bottom: 12,
      ),
      _Card(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const _SectionLabel('YOUR INVITE LINK'),
            const SizedBox(height: 8),
            Text(
              link,
              textAlign: TextAlign.center,
              style: ZyraText.body(size: 17).copyWith(letterSpacing: .3),
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                _Action(
                  key: const ValueKey('small_pages_copy_link'),
                  label: 'Copy link',
                  minimumHeight: 40,
                  outlined: true,
                  onPressed: onCopy,
                ),
                _Action(
                  key: const ValueKey('small_pages_share_link'),
                  label: 'Share',
                  minimumHeight: 40,
                  onPressed: onShare,
                ),
              ],
            ),
          ],
        ),
      ),
      const _ListSection(
        heading: 'GOOD TO KNOW',
        vertical: 2,
        rows: [
          ZyraProfileSmallPageRow(
            icon: Icons.person_outline,
            title: 'They choose their own role',
            subtitle: 'Seeker or Guardian, when they sign up.',
          ),
          ZyraProfileSmallPageRow(
            icon: Icons.visibility_off_outlined,
            title: 'You don’t see them unless you’d see anyone',
            subtitle: 'An invite doesn’t link you or start anything.',
          ),
        ],
      ),
      _Caption(
        guardian
            ? 'Adding a Seeker? Use + in the Seekers tab instead; it links you to them.'
            : 'Adding a Guardian? Use Add a Guardian in the Guardian tab instead; it links them to you.',
      ),
    ],
  );
}

class ZyraRequestRestartPreview extends StatelessWidget {
  const ZyraRequestRestartPreview({
    super.key,
    required this.name,
    required this.subjectId,
    required this.sent,
    required this.unavailableReason,
    required this.onRequest,
  });

  final String name, subjectId;
  final bool sent;
  final String? unavailableReason;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final reason = unavailableReason;
    return _Page(
      id: 'small_pages_restart',
      title: 'Request restart',
      footer: _Action(
        key: const ValueKey('small_pages_request_restart'),
        buttonKey: ValueKey('draft_restart_send_$subjectId'),
        label: sent ? 'Request sent' : 'Request restart',
        outlined: sent || reason != null,
        minimumHeight: 50,
        onPressed: sent || reason != null ? null : onRequest,
      ),
      children: [
        _Card(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'A new Journey, not a reopened one',
                style: ZyraText.heading(size: 21).copyWith(height: 1.3),
              ),
              const SizedBox(height: 8),
              Text(
                '$name would need to accept a new request. Your ended Journey and its Timeline stay as they are.',
                style: _secondary(14),
              ),
              if (reason != null) ...[
                const SizedBox(height: 8),
                Text(reason, style: _secondary(14)),
              ],
            ],
          ),
        ),
        _ListSection(
          heading: 'GOOD TO KNOW',
          vertical: 2,
          rows: [
            ZyraProfileSmallPageRow(
              icon: Icons.schedule,
              title: 'You can ask once',
              subtitle:
                  '$name can accept or decline. If declined, you can’t ask again.',
            ),
            const ZyraProfileSmallPageRow(
              icon: Icons.history,
              title: 'Seeker One: your last 5 ended Journeys',
              subtitle: 'Older ones can’t be restarted.',
            ),
          ],
        ),
      ],
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({
    required this.id,
    required this.title,
    required this.children,
    this.footer,
  });

  final String id, title;
  final List<Widget> children;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => Material(
    key: ValueKey(id),
    color: Colors.transparent,
    child: DecoratedBox(
      decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
      child: SafeArea(
        child: KeyedSubtree(
          key: ValueKey('${id}_scroll'),
          child: CustomScrollView(
            physics: const ScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(title, style: ZyraText.pageTitle()),
                      const SizedBox(height: 18),
                      ...children,
                    ],
                  ),
                ),
              ),
              if (footer case final action?)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [action],
                    ),
                  ),
                )
              else
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ListSection extends StatelessWidget {
  const _ListSection({
    required this.heading,
    required this.rows,
    this.vertical = 12,
  });

  final String heading;
  final List<ZyraProfileSmallPageRow> rows;
  final double vertical;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 30),
      Padding(
        padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
        child: _SectionLabel(heading),
      ),
      _Card(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: vertical),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < rows.length; index++) ...[
              if (index > 0) Divider(height: 1, color: ZyraColors.divider),
              rows[index],
            ],
          ],
        ),
      ),
    ],
  );
}

class ZyraProfileSmallPageRow extends StatelessWidget {
  const ZyraProfileSmallPageRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: ZyraColors.journeyGold),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ZyraText.body(size: 14)),
              if (subtitle case final text?) ...[
                const SizedBox(height: 3),
                Text(text, style: _secondary(12.5, height: 1.45)),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.guardian,
    required this.plan,
    this.current = false,
    this.onAction,
  });

  final bool guardian, current;
  final String? plan;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final role = guardian ? 'Guardian' : 'Seeker';
    final statusTextSize = MediaQuery.textScalerOf(context).scale(12);
    return _Card(
      selected: current,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                Icon(
                  guardian ? Icons.security : Icons.person_outline,
                  size: 24,
                  color: ZyraColors.journeyGold,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$role profile', style: ZyraText.body(size: 17)),
                      if (plan case final text?) ...[
                        const SizedBox(height: 2),
                        Text(text, style: _secondary(12.5)),
                      ],
                    ],
                  ),
                ),
                if (current)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth:
                          statusTextSize > 16 || constraints.maxWidth < 200
                          ? constraints.maxWidth / 2
                          : double.infinity,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        'Using now',
                        style: ZyraText.body(
                          size: 12,
                          color: ZyraColors.greenText,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!current) ...[
            const SizedBox(height: 14),
            _Action(
              key: ValueKey(
                plan == null
                    ? 'small_pages_add_role'
                    : 'small_pages_switch_role',
              ),
              label: plan == null ? 'Add a $role profile' : 'Switch to $role',
              minimumHeight: 44,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    required this.padding,
    this.selected = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool selected;

  @override
  Widget build(BuildContext context) => ZyraFloatingSurface(
    radius: 16,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: ZyraColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? ZyraColors.journeyGold.withValues(alpha: .6)
              : ZyraColors.surfaceBorder,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Padding(padding: padding, child: child),
    ),
  );
}

class _Action extends StatelessWidget {
  const _Action({
    super.key,
    required this.label,
    required this.minimumHeight,
    required this.onPressed,
    this.outlined = false,
    this.buttonKey,
  });

  final String label;
  final double minimumHeight;
  final VoidCallback? onPressed;
  final bool outlined;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    final action = OutlinedButton(
      key: buttonKey,
      onPressed: ZyraTapFeedback.onTap(context, onPressed),
      style: OutlinedButton.styleFrom(
        backgroundColor: outlined
            ? Colors.transparent
            : ZyraColors.goldTextFill,
        foregroundColor: outlined ? ZyraColors.goldText : ZyraColors.espresso,
        disabledForegroundColor: ZyraColors.strongSecondaryText,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        minimumSize: Size(0, minimumHeight),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const StadiumBorder(),
        side: BorderSide(
          color: outlined
              ? onPressed == null
                    ? ZyraColors.surfaceBorder
                    : ZyraColors.journeyGold
              : Colors.transparent,
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: ZyraText.button(size: 14),
      ),
    );
    if (outlined) return action;
    return ZyraFloatingSurface(radius: 999, gold: true, child: action);
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: ZyraText.chapterLabel(color: ZyraColors.secondaryText));
}

TextStyle _secondary(double size, {double height = 1.5}) => ZyraText.body(
  size: size,
  color: ZyraColors.secondaryText,
).copyWith(height: height);

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
    // These captions can sit under the floating card’s shadow.
    child: Text(
      text,
      style: _secondary(12.5).copyWith(color: ZyraColors.strongSecondaryText),
    ),
  );
}

class _Intro extends StatelessWidget {
  const _Intro(this.text, {required this.bottom});

  final String text;
  final double bottom;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(2, 4, 2, bottom),
    child: Text(text, style: _secondary(14)),
  );
}
