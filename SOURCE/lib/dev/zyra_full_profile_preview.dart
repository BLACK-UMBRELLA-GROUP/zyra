import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/seeker_profile.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_browse_designs.dart';
import '../widgets/zyra_floating_surface.dart';
import '../widgets/zyra_profile_details_page.dart';
import '../widgets/zyra_tab_title.dart';

/// LOCK 41 V2. The owner supplies only admitted public fields and owns every
/// action; this page neither looks up a person nor changes a Journey.
enum ZyraFullProfileSituation {
  journey,
  received,
  sent,
  introduction,
  general,
  unverified,
}

enum ZyraFullProfileOption { hide, report, block }

class ZyraFullProfilePreview extends StatefulWidget {
  const ZyraFullProfilePreview({
    super.key,
    required this.profile,
    required this.situation,
    required this.photoBuilder,
    required this.canAct,
    this.introductionByline,
    this.onAction,
    this.onSecondary,
    this.onCompatibility,
    this.onOption,
    this.initialPage = 0,
    this.onPageChanged,
  });

  final SeekerProfile profile;
  final ZyraFullProfileSituation situation;
  final ZyraBrowsePhotoBuilder photoBuilder;
  final bool Function() canAct;
  final String? introductionByline;
  final VoidCallback? onAction;
  final VoidCallback? onSecondary;
  final VoidCallback? onCompatibility;
  final ValueChanged<ZyraFullProfileOption>? onOption;
  final int initialPage;
  final ValueChanged<int>? onPageChanged;

  @override
  State<ZyraFullProfilePreview> createState() => _ZyraFullProfilePreviewState();
}

class _ZyraFullProfilePreviewState extends State<ZyraFullProfilePreview> {
  late int _page;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage.clamp(0, widget.profile.photos.length);
  }

  String get _title => switch (widget.situation) {
    ZyraFullProfileSituation.journey => 'Journey',
    ZyraFullProfileSituation.received ||
    ZyraFullProfileSituation.sent => 'Journey request',
    ZyraFullProfileSituation.introduction => 'Introduction',
    _ => 'Profile',
  };

  String get _mainLabel => switch (widget.situation) {
    ZyraFullProfileSituation.journey => 'Continue Journey',
    ZyraFullProfileSituation.received => 'Accept',
    ZyraFullProfileSituation.sent => 'Request sent',
    ZyraFullProfileSituation.introduction ||
    ZyraFullProfileSituation.general => 'Request a Journey',
    ZyraFullProfileSituation.unverified => 'Verify to request',
  };

  bool get _paired =>
      widget.situation == ZyraFullProfileSituation.received ||
      widget.situation == ZyraFullProfileSituation.introduction;

  void _nextPage() {
    if (!widget.canAct()) return;
    setState(() => _page = (_page + 1) % (widget.profile.photos.length + 1));
    widget.onPageChanged?.call(_page);
  }

  Future<void> _options() async {
    if (!widget.canAct() || widget.onOption == null) return;
    ModalRoute<ZyraFullProfileOption>? sheetRoute;
    final selected = await showModalBottomSheet<ZyraFullProfileOption>(
      context: context,
      backgroundColor: ZyraColors.ivoryTop,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        sheetRoute = ModalRoute.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ZyraColors.secondaryText.withValues(alpha: .3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 18),
                for (final (index, option, label, icon) in [
                  (
                    0,
                    ZyraFullProfileOption.hide,
                    'Hide ${widget.profile.firstName}',
                    Icons.visibility_off_outlined,
                  ),
                  (
                    1,
                    ZyraFullProfileOption.report,
                    'Report ${widget.profile.firstName}',
                    Icons.flag_outlined,
                  ),
                  (
                    2,
                    ZyraFullProfileOption.block,
                    'Block ${widget.profile.firstName}',
                    Icons.lock_outline,
                  ),
                ]) ...[
                  if (index > 0)
                    Divider(
                      height: 1,
                      color: ZyraColors.secondaryText.withValues(alpha: .15),
                    ),
                  ListTile(
                    key: ValueKey('full_profile_option_${option.name}'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                    leading: Icon(
                      icon,
                      color: option == ZyraFullProfileOption.block
                          ? ZyraColors.dangerText
                          : ZyraColors.journeyGold,
                    ),
                    title: Text(
                      label,
                      style: ZyraText.body(
                        size: 16,
                        color: option == ZyraFullProfileOption.block
                            ? ZyraColors.dangerText
                            : ZyraColors.espresso,
                      ),
                    ),
                    onTap: () => Navigator.of(sheetContext).pop(option),
                  ),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    key: const ValueKey('full_profile_option_cancel'),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: ZyraColors.ivoryTop,
                      side: BorderSide(
                        color: ZyraColors.secondaryText.withValues(alpha: .15),
                      ),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      'Cancel',
                      style: ZyraText.body(
                        size: 16,
                        color: ZyraColors.secondaryText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    await sheetRoute?.completed;
    if (mounted && widget.canAct() && selected != null) {
      widget.onOption?.call(selected);
    }
  }

  Widget _dots() => SizedBox(
    key: const ValueKey('full_profile_dots'),
    height: 16,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index <= widget.profile.photos.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: index == _page ? 30 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: index == _page
                  ? ZyraColors.journeyGold
                  : ZyraColors.secondaryText.withValues(alpha: .45),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _card() {
    final profile = widget.profile;
    final first = profile.photos.firstOrNull;
    final avatarSize = ZyraProfileDetailsPage.photoSizeFor(profile.seekerPlan);
    final child = _page == 0
        ? ZyraProfileDetailsPage(
            key: const ValueKey('full_profile_details'),
            profile: profile,
            fixedCard: true,
            introductionByline:
                widget.situation == ZyraFullProfileSituation.introduction
                ? widget.introductionByline
                : null,
            firstPhoto: first == null
                ? null
                : widget.photoBuilder(
                    context,
                    first,
                    width: avatarSize,
                    height: avatarSize,
                    alignment: ZyraProfileDetailsPage.photoAlignment,
                  ),
            onCompatibility: widget.onCompatibility == null
                ? null
                : () {
                    if (widget.canAct()) widget.onCompatibility!();
                  },
          )
        : widget.photoBuilder(
            context,
            profile.photos[_page - 1],
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
          );
    return ZyraFloatingSurface(
      radius: 26,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: GestureDetector(
          key: const ValueKey('full_profile_card'),
          behavior: HitTestBehavior.opaque,
          onTap: _nextPage,
          child: SizedBox.expand(child: child),
        ),
      ),
    );
  }

  Widget _button(
    String label,
    VoidCallback? action, {
    bool primary = false,
    required double height,
  }) => Expanded(
    child: SizedBox(
      height: height,
      child: OutlinedButton(
        key: ValueKey('full_profile_action_${label.replaceAll(' ', '_')}'),
        onPressed: action == null
            ? null
            : () {
                if (widget.canAct()) action();
              },
        style: OutlinedButton.styleFrom(
          backgroundColor: primary
              ? label == 'Request a Journey'
                    ? ZyraColors.goldTextFill
                    : ZyraColors.journeyGold
              : ZyraColors.ivoryTop,
          shadowColor: label == 'Request a Journey'
              ? ZyraColors.goldTextFill
              : null,
          foregroundColor: ZyraColors.espresso,
          side: BorderSide(
            color: primary
                ? ZyraColors.journeyGold
                : ZyraColors.journeyGold.withValues(alpha: .5),
          ),
          shape: const StadiumBorder(),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          softWrap: true,
          style: ZyraText.button(size: 15, color: ZyraColors.espresso),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (!widget.canAct()) {
      return const SizedBox.expand(key: ValueKey('full_profile_unavailable'));
    }
    if (_page > widget.profile.photos.length) _page = 0;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final buttonHeight = scale <= 1.2
        ? 50.0
        : math.max(50.0, 15 * scale * 2 * 1.25 + 12);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  Expanded(child: ZyraTabTitle(_title)),
                  IconButton(
                    key: const ValueKey('full_profile_options'),
                    onPressed: widget.onOption == null ? null : _options,
                    tooltip: 'Profile options',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 44,
                      height: 44,
                    ),
                    icon: const Icon(
                      Icons.more_horiz,
                      color: ZyraColors.journeyGold,
                    ),
                  ),
                ],
              ),
            ),
            _dots(),
            const SizedBox(height: 8),
            Expanded(child: _card()),
            const SizedBox(height: 12),
            SizedBox(
              height: buttonHeight + 8,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                  children: [
                    if (_paired) ...[
                      _button(
                        'Decline',
                        widget.onSecondary,
                        height: buttonHeight,
                      ),
                      const SizedBox(width: 10),
                    ],
                    _button(
                      _mainLabel,
                      widget.situation == ZyraFullProfileSituation.sent
                          ? null
                          : widget.onAction,
                      primary:
                          widget.situation != ZyraFullProfileSituation.sent &&
                          widget.situation != ZyraFullProfileSituation.received,
                      height: buttonHeight,
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
