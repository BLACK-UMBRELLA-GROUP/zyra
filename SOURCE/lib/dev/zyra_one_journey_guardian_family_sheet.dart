import 'package:flutter/material.dart';

import '../data/zyra_membership_catalog.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_floating_surface.dart';
import '../widgets/zyra_tap_feedback.dart';

enum ZyraGuardianFamilyState { noFamily, freePlace, full }

enum _FamilyStep { introduction, price, invited }

/// LOCK 19 §6. Caller-owned, local preview only: this sheet never purchases,
/// allocates a paid place, changes access, or contacts a service.
class ZyraGuardianFamilySheet extends StatefulWidget {
  const ZyraGuardianFamilySheet({
    super.key,
    required this.guardianName,
    required this.canAct,
    required this.invited,
    this.familyState = ZyraGuardianFamilyState.noFamily,
    this.seekers = 1,
    this.guardians = 1,
    required this.onInvite,
    required this.onCancelInvite,
    required this.onClose,
  });

  final String guardianName;
  final bool Function() canAct;
  final bool invited;
  final ZyraGuardianFamilyState familyState;
  final int seekers;
  final int guardians;
  final VoidCallback onInvite;
  final VoidCallback onCancelInvite;
  final VoidCallback onClose;

  @override
  State<ZyraGuardianFamilySheet> createState() =>
      _ZyraGuardianFamilySheetState();
}

class _ZyraGuardianFamilySheetState extends State<ZyraGuardianFamilySheet> {
  late _FamilyStep _step;
  int _renderRevision = 0;
  bool _closed = false;
  bool _revoked = false;

  @override
  void initState() {
    super.initState();
    _step = widget.invited ? _FamilyStep.invited : _FamilyStep.introduction;
  }

  @override
  void didUpdateWidget(covariant ZyraGuardianFamilySheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    _renderRevision++;
    if (oldWidget.guardianName != widget.guardianName ||
        oldWidget.familyState != widget.familyState ||
        oldWidget.seekers != widget.seekers ||
        oldWidget.guardians != widget.guardians ||
        oldWidget.invited != widget.invited) {
      _step = widget.invited ? _FamilyStep.invited : _FamilyStep.introduction;
    }
  }

  bool _current(int revision, bool Function() authority) {
    if (!mounted || _closed || _revoked || revision != _renderRevision) {
      return false;
    }
    if (!authority() || !widget.canAct()) {
      _revoked = true;
      return false;
    }
    return true;
  }

  VoidCallback _handler(
    BuildContext context,
    int revision,
    VoidCallback action,
  ) {
    final authority = widget.canAct;
    final feedback = ZyraTapFeedback.onTap(context, () {
      if (_current(revision, authority)) action();
    }, canAct: () => _current(revision, authority));
    return () {
      // A retained physical or semantic callback must deny before feedback.
      if (_current(revision, authority)) feedback?.call();
    };
  }

  void _changeStep(_FamilyStep next) {
    _renderRevision++;
    setState(() => _step = next);
  }

  void _sendInvite() {
    _changeStep(_FamilyStep.invited);
    widget.onInvite();
  }

  void _close({bool cancelInvite = false}) {
    _closed = true;
    _renderRevision++;
    if (cancelInvite) widget.onCancelInvite();
    widget.onClose();
  }

  @override
  void dispose() {
    _closed = true;
    _renderRevision++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final revision = ++_renderRevision;
    final name = widget.guardianName;
    final title = switch (_step) {
      _FamilyStep.introduction => '$name can view, but not chat',
      _FamilyStep.price => 'Cover $name with ZYRA Family',
      _FamilyStep.invited => 'Invite sent to $name',
    };
    final subtitle = switch (_step) {
      _FamilyStep.introduction => '$name is on Guardian Basic',
      _FamilyStep.price => 'Guardian One for $name, in your monthly plan',
      _FamilyStep.invited => 'Guardian One · ZYRA Family place',
    };
    return Material(
      key: const ValueKey('guardian-family-sheet'),
      color: const Color(0xFFF7F2EA),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 14),
        child: SingleChildScrollView(
          key: const ValueKey('guardian-family-sheet-scroll'),
          padding: const EdgeInsets.fromLTRB(23, 14, 23, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ZyraColors.ink(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 17),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF75816E), Color(0xFF433B2E)],
                      ),
                    ),
                    child: Text(
                      name.isEmpty ? '' : name.characters.first.toUpperCase(),
                      style: ZyraText.body(size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: ZyraText.heading(
                            size: 20,
                          ).copyWith(height: 1.25),
                        ),
                        const SizedBox(height: 3),
                        Text(subtitle, style: ZyraText.subtext(size: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              switch (_step) {
                _FamilyStep.introduction => _introduction(name),
                _FamilyStep.price => _price(name),
                _FamilyStep.invited => _invited(name),
              },
              const SizedBox(height: 16),
              _primary(context, revision),
              const SizedBox(height: 5),
              TextButton(
                key: ValueKey('guardian-family-${_step.name}-secondary'),
                onPressed: _handler(context, revision, () {
                  switch (_step) {
                    case _FamilyStep.introduction:
                      _close();
                      return;
                    case _FamilyStep.price:
                      _changeStep(_FamilyStep.introduction);
                      return;
                    case _FamilyStep.invited:
                      _close(cancelInvite: true);
                      return;
                  }
                }),
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  foregroundColor: ZyraColors.mutedText,
                ),
                child: Text(
                  switch (_step) {
                    _FamilyStep.introduction => 'Not now',
                    _FamilyStep.price => 'Back',
                    _FamilyStep.invited => 'Cancel invite',
                  },
                  style: ZyraText.body(size: 14, color: ZyraColors.mutedText),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _group(List<Widget> children) => ZyraFloatingSurface(
    radius: 22,
    child: Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5EC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ZyraColors.ink(0.04)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    ),
  );

  Widget _divider() => Divider(height: 1, color: ZyraColors.divider);

  Widget _row(IconData icon, String title, String body) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 15),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 17, color: ZyraColors.goldTextFill),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ZyraText.body(size: 14).copyWith(height: 1.3)),
              const SizedBox(height: 4),
              Text(
                body,
                style: ZyraText.subtext(size: 12.5).copyWith(height: 1.3),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _introduction(String name) => _group([
    _row(
      Icons.visibility_outlined,
      'What $name can do now',
      'See the Journeys you let them view, follow each stage, and read your '
          'Guardian Circle.',
    ),
    _divider(),
    _row(
      Icons.forum_outlined,
      'Chat comes with Guardian One',
      'With Guardian One, $name can also chat in your Journeys when you '
          'turn Chat on.',
    ),
    _divider(),
    _row(
      Icons.add,
      switch (widget.familyState) {
        ZyraGuardianFamilyState.noFamily => 'Pay for $name with ZYRA Family',
        ZyraGuardianFamilyState.freePlace =>
          'Give $name your free Guardian place',
        ZyraGuardianFamilyState.full => 'Add a Guardian place for $name',
      },
      switch (widget.familyState) {
        ZyraGuardianFamilyState.noFamily =>
          'Put your membership and $name\'s Guardian One in one monthly plan. '
              'You\'ll see the price first.',
        ZyraGuardianFamilyState.freePlace =>
          'Your ZYRA Family has a Guardian One place free. It costs you '
              'nothing more.',
        ZyraGuardianFamilyState.full =>
          'Your ZYRA Family has no free Guardian place. You\'ll see the new '
              'price first.',
      },
    ),
    _divider(),
    _row(
      Icons.person_outline,
      'Or $name upgrades',
      'Guardian One is also in Profile → Membership in $name\'s app.',
    ),
  ]);

  Widget _price(String name) {
    final noFamily = widget.familyState == ZyraGuardianFamilyState.noFamily;
    final current = noFamily
        ? null
        : ZyraMembershipCatalog.familyQuote(widget.seekers, widget.guardians);
    final next = noFamily
        ? ZyraMembershipCatalog.familyQuote(1, 1)
        : ZyraMembershipCatalog.familyQuote(
            widget.seekers,
            widget.guardians + 1,
          );
    return _group([
      _priceLine(
        noFamily
            ? 'Now · Your membership'
            : 'Now · ZYRA Family · ${current!.members} places',
        noFamily
            ? ZyraMembershipCatalog.seekerOneMonthlyPence
            : current!.formulaMonthlyPence,
      ),
      _divider(),
      _priceLine(
        'New · ZYRA Family · ${next.members} places',
        next.formulaMonthlyPence,
        next: true,
      ),
      _divider(),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          '${noFamily ? 'You keep Seeker One as your own Family place; your current membership is replaced. ' : ''}'
          'Starts today; Apple adjusts this month\'s charge. $name still has '
          'to accept.',
          style: ZyraText.subtext(size: 12),
        ),
      ),
    ]);
  }

  Widget _priceLine(String label, int pence, {bool next = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: LayoutBuilder(
      builder: (context, box) {
        final price = '${ZyraMembershipCatalog.pounds(pence)} a month';
        final labelText = Text(
          label,
          style: ZyraText.body(
            size: 14,
            color: next ? ZyraColors.foreground : ZyraColors.mutedText,
          ),
        );
        final priceText = Text(
          price,
          key: ValueKey(
            next
                ? 'guardian-family-new-price'
                : 'guardian-family-current-price',
          ),
          style: ZyraText.body(
            size: 14,
            color: next ? ZyraColors.goldText : ZyraColors.mutedText,
          ),
        );
        if (box.maxWidth < 320 ||
            MediaQuery.textScalerOf(context).scale(14) > 18) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [labelText, const SizedBox(height: 6), priceText],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: labelText),
            const SizedBox(width: 8),
            priceText,
          ],
        );
      },
    ),
  );

  Widget _invited(String name) => _group([
    _row(
      Icons.mail_outline,
      '$name accepts in their app',
      '$name has 7 days to accept. If they don\'t, the place stays free for you.',
    ),
    _divider(),
    _row(
      Icons.forum_outlined,
      'Then you choose Chat',
      'Once $name accepts, the Chat switch opens here. It stays off until '
          'you turn it on.',
    ),
  ]);

  Widget _primary(BuildContext context, int revision) => ZyraFloatingSurface(
    gold: true,
    radius: 25,
    child: FilledButton(
      key: ValueKey('guardian-family-${_step.name}-primary'),
      onPressed: _handler(context, revision, () {
        switch (_step) {
          case _FamilyStep.introduction:
            if (widget.familyState == ZyraGuardianFamilyState.freePlace) {
              _sendInvite();
            } else {
              _changeStep(_FamilyStep.price);
            }
            return;
          case _FamilyStep.price:
            _sendInvite();
            return;
          case _FamilyStep.invited:
            _close();
            return;
        }
      }),
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 46),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        backgroundColor: ZyraColors.goldTextFill,
        foregroundColor: ZyraColors.espresso,
        shape: const StadiumBorder(),
      ),
      child: Text(
        switch (_step) {
          _FamilyStep.introduction => switch (widget.familyState) {
            ZyraGuardianFamilyState.noFamily => 'See the price',
            ZyraGuardianFamilyState.freePlace =>
              'Give ${widget.guardianName} the place',
            ZyraGuardianFamilyState.full => 'Add a place',
          },
          _FamilyStep.price => 'Continue with Apple',
          _FamilyStep.invited => 'Done',
        },
        style: ZyraText.button(size: 15, color: ZyraColors.espresso),
        textAlign: TextAlign.center,
      ),
    ),
  );
}
