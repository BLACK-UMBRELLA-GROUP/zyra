import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/zyra_membership_catalog.dart';
import '../data/zyra_reference_data.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_motion.dart';
import '../theme/zyra_preview_spacing.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_developer_title.dart';
import '../widgets/zyra_floating_surface.dart';
import '../widgets/zyra_glass_dialog.dart';
import '../widgets/zyra_profile_image.dart';
import '../widgets/zyra_profiles_components.dart';
import '../widgets/zyra_swipe_track.dart';
import '../widgets/zyra_tap_feedback.dart';
import 'zyra_one_journey_monogram_presentation.dart';
import 'zyra_signup_preview_controller.dart';

/// LOCK 34 presentation, backed exclusively by a detached preview controller.
/// The host supplies local sample pictures, guarded navigation and the existing
/// Partner preferences editor. No member signup, identity or store API is used.
class ZyraSignupPreview extends StatefulWidget {
  const ZyraSignupPreview({
    super.key,
    required this.controller,
    required this.canAct,
    required this.preferencesBuilder,
    required this.onPause,
    required this.onEnter,
    required this.samplePhotos,
    required this.ownCode,
    required this.onShareCode,
    this.onVerifyIdentity,
  });

  final ZyraSignupPreviewController controller;
  final bool Function() canAct;
  final WidgetBuilder preferencesBuilder;
  final VoidCallback onPause, onEnter, onShareCode;
  final VoidCallback? onVerifyIdentity;
  final List<String> samplePhotos;
  final String ownCode;

  @override
  State<ZyraSignupPreview> createState() => _ZyraSignupPreviewState();
}

class _ZyraSignupPreviewState extends State<ZyraSignupPreview> {
  final _textControllers = <String, TextEditingController>{};
  final _roleSwipe = ZyraSwipeController();
  final _membershipSwipe = ZyraSwipeController();
  Timer? _splashTimer;
  String _search = '';
  ZyraSignupStep? _lastStep;

  ZyraSignupPreviewController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    c.addListener(_changed);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleSplash();
  }

  @override
  void didUpdateWidget(covariant ZyraSignupPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != c) {
      oldWidget.controller.removeListener(_changed);
      c.addListener(_changed);
      _lastStep = null;
      _scheduleSplash();
    }
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    c.removeListener(_changed);
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _changed() {
    if (!mounted) {
      return;
    }
    if (_lastStep != c.step) {
      _search = '';
      _textControllers['search']?.clear();
      _lastStep = c.step;
      _roleSwipe.cancel();
      _membershipSwipe.cancel();
      _scheduleSplash();
    }
    setState(() {});
  }

  void _scheduleSplash() {
    _splashTimer?.cancel();
    if (c.step != ZyraSignupStep.splash) {
      return;
    }
    final opening = c;
    _splashTimer = Timer(
      ZyraMotion.reduceMotion(context)
          ? Duration.zero
          : const Duration(seconds: 1),
      () {
        if (mounted &&
            identical(opening, c) &&
            widget.canAct() &&
            c.step == ZyraSignupStep.splash) {
          c.finishSplash();
        }
      },
    );
  }

  VoidCallback _action(VoidCallback callback) {
    final opening = c;
    final step = c.step;
    return ZyraTapFeedback.onTap(context, () {
      if (mounted &&
          identical(opening, c) &&
          c.step == step &&
          widget.canAct()) {
        callback();
      }
    })!;
  }

  ValueChanged<T> _change<T>(ValueChanged<T> callback) {
    final opening = c;
    final step = c.step;
    return (value) {
      if (mounted &&
          identical(opening, c) &&
          c.step == step &&
          widget.canAct()) {
        callback(value);
      }
    };
  }

  TextEditingController _text(String id, String value) {
    final controller = _textControllers.putIfAbsent(
      id,
      () => TextEditingController(text: value),
    );
    if (controller.text != value) {
      controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
    return controller;
  }

  void _pause() {
    c.pauseSetup();
    widget.onPause();
  }

  @override
  Widget build(BuildContext context) {
    if (c.step == ZyraSignupStep.preferences) {
      return KeyedSubtree(
        key: const ValueKey('signup_preferences'),
        child: widget.preferencesBuilder(context),
      );
    }
    final content = switch (c.step) {
      ZyraSignupStep.splash => _splash(),
      ZyraSignupStep.welcome => _welcome(),
      ZyraSignupStep.role => _role(),
      ZyraSignupStep.gender => _gender(),
      ZyraSignupStep.membership => _membership(),
      ZyraSignupStep.accountReady => _ready(),
      _ => _step(),
    };
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final compactEnlarged =
        MediaQuery.sizeOf(context).height < 700 &&
        (textScale > 1.2 || c.step == ZyraSignupStep.accountReady) &&
        c.step != ZyraSignupStep.splash &&
        c.step != ZyraSignupStep.welcome;
    return ColoredBox(
      color: ZyraColors.ivoryTop,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
        child: SafeArea(
          minimum: const EdgeInsets.only(top: 62, bottom: 34),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ZyraPreviewSpacing.pageMargin,
            ),
            child: compactEnlarged
                ? LayoutBuilder(
                    builder: (context, box) => SingleChildScrollView(
                      key: const ValueKey('signup_accessible_scroll'),
                      child: c.step == ZyraSignupStep.accountReady
                          ? ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: textScale > 1.2
                                    ? math.max(box.maxHeight, 600 * textScale)
                                    : box.maxHeight,
                              ),
                              child: content,
                            )
                          : SizedBox(
                              width: box.maxWidth,
                              height: math.max(box.maxHeight, 600 * textScale),
                              child: content,
                            ),
                    ),
                  )
                : content,
          ),
        ),
      ),
    );
  }

  Widget _brand({bool line = false}) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        'ZYRA',
        style: ZyraText.wordmark(size: 54).copyWith(letterSpacing: 14),
      ),
      const SizedBox(height: 8),
      Text(
        'Connecting Through Trust',
        style: ZyraText.subtext(size: ZyraText.taglineSize(context)),
      ),
      if (line) ...[
        const SizedBox(height: 22),
        SizedBox(
          width: 210,
          child: Divider(height: 1, color: ZyraColors.surfaceBorder),
        ),
      ],
    ],
  );

  Widget _splash() =>
      Center(key: const ValueKey('signup_splash'), child: _brand(line: true));

  Widget _welcome() {
    final appleFirst = Theme.of(context).platform != TargetPlatform.android;
    Widget signIn(bool apple) => _button(
      id: apple ? 'signup_apple' : 'signup_google',
      label: apple ? 'Continue with Apple' : 'Continue with Google',
      dark: true,
      leading: apple
          ? const Icon(Icons.apple, color: ZyraColors.ivoryTop, size: 20)
          : Text('G', style: ZyraText.button(color: ZyraColors.ivoryTop)),
      onPressed: () => c.chooseProvider(apple ? 'Apple' : 'Google'),
    );
    return Column(
      key: const ValueKey('signup_welcome'),
      children: [
        Expanded(child: Center(child: _brand())),
        signIn(appleFirst),
        const SizedBox(height: 12),
        signIn(!appleFirst),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _header() => SizedBox(
    height: 36,
    child: Row(
      children: [
        if (c.canGoBack)
          SizedBox(
            width: 34,
            child: IconButton(
              key: const ValueKey('signup_back'),
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              tooltip: 'Back',
              onPressed: _action(c.back),
              icon: Icon(
                Icons.chevron_left,
                color: ZyraColors.goldText,
                size: 27,
              ),
            ),
          )
        else
          const SizedBox(width: 34),
        Expanded(
          child: ZyraDeveloperTitle(
            longPress: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Semantics(
                label: 'Sign up progress',
                value: '${(c.progress * 100).round()}%',
                child: LinearProgressIndicator(
                  key: const ValueKey('signup_progress'),
                  value: c.progress,
                  minHeight: 2,
                  borderRadius: BorderRadius.circular(2),
                  color: ZyraColors.journeyGold,
                  backgroundColor: ZyraColors.divider,
                ),
              ),
            ),
          ),
        ),
        if (c.step != ZyraSignupStep.accountReady) ...[
          const SizedBox(width: 12),
          TextButton(
            key: const ValueKey('signup_skip'),
            onPressed: _action(() {
              if (c.step == ZyraSignupStep.allSet) {
                if (c.enterZyra()) {
                  widget.onEnter();
                }
              } else {
                c.skip();
              }
            }),
            style: TextButton.styleFrom(
              minimumSize: const Size(46, 32),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              foregroundColor: ZyraColors.secondaryText,
              side: BorderSide(color: ZyraColors.surfaceBorder),
              shape: const StadiumBorder(),
              textStyle: ZyraText.body(size: 11),
            ),
            child: const Text('Skip'),
          ),
        ],
      ],
    ),
  );

  Widget _title(String title, [String? detail]) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: ZyraText.pageTitle()),
      if (detail != null) ...[
        const SizedBox(height: 7),
        Text(detail, style: ZyraText.subtext(size: 14).copyWith(height: 1.45)),
      ],
    ],
  );

  Widget _card(Widget child, {bool center = true}) => ZyraFloatingSurface(
    child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ZyraColors.cardSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ZyraColors.surfaceBorder),
      ),
      child: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          physics: ZyraMotion.fixedCardScrollPhysics,
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0, box.maxHeight - 40),
            ),
            child: center ? Center(child: child) : child,
          ),
        ),
      ),
    ),
  );

  Widget _button({
    required String id,
    required String label,
    required VoidCallback? onPressed,
    bool dark = false,
    bool outlined = false,
    Widget? leading,
  }) {
    final button = SizedBox(
      width: double.infinity,
      height: math.max(
        52,
        52 * MediaQuery.textScalerOf(context).scale(14) / 14,
      ),
      child: outlined
          ? OutlinedButton(
              key: ValueKey(id),
              onPressed: onPressed == null ? null : _action(onPressed),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: ZyraColors.onAction,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                side: BorderSide(
                  color: ZyraColors.warmOverlay.withValues(alpha: .25),
                ),
                shape: const StadiumBorder(),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: ZyraText.button(size: 14),
              ),
            )
          : FilledButton(
              key: ValueKey(id),
              onPressed: onPressed == null ? null : _action(onPressed),
              style: FilledButton.styleFrom(
                backgroundColor: dark
                    ? ZyraColors.espresso
                    : ZyraColors.actionFill,
                foregroundColor: dark
                    ? ZyraColors.ivoryTop
                    : ZyraColors.onAction,
                disabledBackgroundColor: ZyraColors.actionFill.withValues(
                  alpha: .42,
                ),
                disabledForegroundColor: ZyraColors.secondaryStrong,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                side: BorderSide.none,
                shape: const StadiumBorder(),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leading != null) ...[leading, const SizedBox(width: 7)],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: ZyraText.button(
                        size: label.length > 40 ? 12.5 : 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
    // A transparent secondary action must not reveal a floating shadow as fill.
    return outlined
        ? button
        : ZyraFloatingSurface(radius: 999, gold: !dark, child: button);
  }

  Widget _later() => Padding(
    padding: const EdgeInsets.only(top: 7),
    child: TextButton(
      key: const ValueKey('signup_finish_later'),
      onPressed: _action(_pause),
      style: TextButton.styleFrom(
        foregroundColor: ZyraColors.goldText,
        textStyle: ZyraText.body(size: 13),
        minimumSize: const Size.fromHeight(32),
        padding: const EdgeInsets.symmetric(vertical: 6),
      ),
      child: const Text('Finish later and go to ZYRA'),
    ),
  );

  Widget _dots({required bool membership}) {
    final swipe = membership ? _membershipSwipe : _roleSwipe;
    return ZyraProfilesDots(
      count: 2,
      index: membership ? (c.membershipBasic ? 0 : 1) : (c.guardian ? 1 : 0),
      activeWidth: 28,
      size: 6,
      dotKey: (index) =>
          ValueKey('signup_${membership ? 'plan' : 'role'}_dot_$index'),
      itemLabel: (index) => membership
          ? (index == 0 ? 'Seeker Basic' : 'Seeker One')
          : (index == 0 ? 'Seeker' : 'Guardian'),
      canAct: widget.canAct,
      canSelect: () => !swipe.isMoving,
      onSelected: swipe.animateTo,
      exposeSemanticAction: true,
    );
  }

  Widget _role() => Column(
    key: const ValueKey('signup_role'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _header(),
      const SizedBox(height: 20),
      _title(
        'How will you use ZYRA?',
        'Swipe to the one that fits you. You can add the other role later.',
      ),
      const SizedBox(height: 18),
      _dots(membership: false),
      const SizedBox(height: 3),
      Expanded(
        child: ZyraSwipeTrack(
          controller: _roleSwipe,
          index: c.guardian ? 1 : 0,
          itemCount: 2,
          canAct: widget.canAct,
          onSettled: _change<int>((index) => c.setGuardian(index == 1)),
          itemBuilder: (context, index) => _choiceCard(
            monogram: index == 0 ? 'S' : 'G',
            title: index == 0 ? 'Seeker' : 'Guardian',
            eyebrow: index == 0
                ? 'LOOKING FOR A SPOUSE'
                : 'SUPPORTING A FAMILY MEMBER',
            lines: index == 0
                ? const [
                    'Build your profile and photos',
                    'Send and receive Journey requests',
                    'Bring your Guardians into each Journey',
                  ]
                : const [
                    'Link to your Seeker with their ZYRA Code',
                    'See their Journeys as they allow',
                    'Lead Family Review as Main Guardian',
                  ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      _button(id: 'signup_continue', label: 'Continue', onPressed: c.advance),
    ],
  );

  Widget _choiceCard({
    required String monogram,
    required String title,
    required String eyebrow,
    required List<String> lines,
    String? price,
  }) => LayoutBuilder(
    builder: (context, box) => _card(
      Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ZyraGoldRingMonogram(
                    name: monogram,
                    size: 76,
                    fontSize: monogram.length > 1 ? 14 : 32,
                    child: monogram.length > 1
                        ? Text(
                            monogram,
                            style: ZyraText.body(
                              size: 14,
                              color: ZyraColors.goldText,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: ZyraText.heading(size: 30)),
                        const SizedBox(height: 3),
                        Text(
                          eyebrow,
                          style: ZyraText.chapterLabel(
                            color: ZyraColors.goldText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (price != null) ...[
                const SizedBox(height: 20),
                Text(
                  price,
                  style: ZyraText.body(size: 15, color: ZyraColors.goldText),
                ),
              ],
            ],
          ),
          Column(
            children: [
              for (final line in lines)
                Container(
                  constraints: const BoxConstraints(minHeight: 52),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: ZyraColors.divider)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check, color: ZyraColors.goldText, size: 15),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(line, style: ZyraText.body(size: 14)),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                height: math.max(
                  40,
                  box.maxHeight * (price == null ? .255 : .225),
                ),
              ),
            ],
          ),
        ],
      ),
      center: false,
    ),
  );

  void _holdMembership() {
    showZyraGlassNotice(
      context: context,
      icon: Icons.info_outline,
      title: 'Not available in this build',
      body: ZyraMembershipCatalog.availability,
      buttonLabel: 'Back to cards',
    );
  }

  Widget _membership() => Column(
    key: const ValueKey('signup_membership'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _header(),
      const SizedBox(height: 20),
      _title(
        'Choose your membership',
        'Swipe to the one you want. Change any time in Membership.',
      ),
      const SizedBox(height: 18),
      _dots(membership: true),
      const SizedBox(height: 3),
      Expanded(
        child: ZyraSwipeTrack(
          controller: _membershipSwipe,
          index: c.membershipBasic ? 0 : 1,
          itemCount: 2,
          canAct: widget.canAct,
          onSettled: _change<int>((index) => c.setMembershipBasic(index == 0)),
          itemBuilder: (context, index) => _choiceCard(
            monogram: index == 0 ? 'BASIC' : 'ONE',
            title: index == 0 ? 'Seeker Basic' : 'Seeker One',
            eyebrow: index == 0 ? 'START SIMPLE' : 'EVERYTHING ZYRA OFFERS',
            price: index == 0
                ? '£4.99 once'
                : '14 days free, then £29.99 a month',
            lines: index == 0
                ? const [
                    '1 Journey place',
                    '25 profiles every 4 hours',
                    '10 Guardians, 1 on the free place',
                  ]
                : const [
                    '3 Journey places',
                    'Unlimited profiles and all filters',
                    '10 Guardians on any plan',
                  ],
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          'Checkout is not available in this preview.',
          textAlign: TextAlign.center,
          style: ZyraText.subtext(size: 11, color: ZyraColors.secondaryStrong),
        ),
      ),
      _button(
        id: 'signup_membership_checkout',
        label: c.membershipBasic
            ? 'Pay £4.99 for Seeker Basic'
            : 'Start 14 days free, then £29.99 a month',
        onPressed: c.verified ? _holdMembership : null,
      ),
    ],
  );

  Widget _gender() => Column(
    key: const ValueKey('signup_gender'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _header(),
      const SizedBox(height: 20),
      _title('Gender', 'This decides which profiles you see.'),
      const SizedBox(height: 20),
      for (final (index, label) in ['Male', 'Female'].indexed) ...[
        if (index > 0) const SizedBox(height: 14),
        Expanded(child: _genderCard(label)),
      ],
      const SizedBox(height: 12),
      _button(
        id: 'signup_continue',
        label: 'Continue',
        onPressed: c.canContinue ? c.advance : null,
      ),
    ],
  );

  Widget _genderCard(String label) {
    final selected = c.gender == label.toLowerCase();
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: label,
      child: ZyraFloatingSurface(
        child: Material(
          color: ZyraColors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
              color: selected
                  ? ZyraColors.journeyGold
                  : ZyraColors.surfaceBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            key: ValueKey('signup_gender_${label.toLowerCase()}'),
            borderRadius: BorderRadius.circular(22),
            onTap: _action(() => c.setGender(label.toLowerCase())),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ZyraGoldRingMonogram(name: label, size: 84, fontSize: 36),
                  const SizedBox(height: 16),
                  Text(label, style: ZyraText.heading(size: 24)),
                  if (selected) ...[
                    const SizedBox(height: 8),
                    Text(
                      '✓ CHOSEN',
                      style: ZyraText.chapterLabel(color: ZyraColors.goldText),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _step() {
    final allSet = c.step == ZyraSignupStep.allSet;
    final verify = c.step == ZyraSignupStep.verify;
    return Column(
      key: ValueKey('signup_${c.step.name}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(),
        const SizedBox(height: 20),
        Expanded(child: _card(_stepContent(), center: !verify)),
        const SizedBox(height: 12),
        _button(
          id: allSet
              ? 'signup_enter'
              : verify
              ? 'signup_verify_now'
              : 'signup_continue',
          label: allSet
              ? 'Enter ZYRA'
              : verify
              ? (c.verificationDeferred ? 'Continue' : 'Verify now')
              : 'Continue',
          onPressed: !c.canContinue
              ? null
              : allSet
              ? () {
                  if (c.enterZyra()) {
                    widget.onEnter();
                  }
                }
              : c.advance,
        ),
        if (c.isSetup && !allSet) _later(),
      ],
    );
  }

  Widget _stepContent() => switch (c.step) {
    ZyraSignupStep.name => _name(),
    ZyraSignupStep.dateOfBirth => _dateOfBirth(),
    ZyraSignupStep.location ||
    ZyraSignupStep.nationality ||
    ZyraSignupStep.ethnicity => _searchPage(),
    ZyraSignupStep.photos => _photos(),
    ZyraSignupStep.relationship => _relationship(),
    ZyraSignupStep.addSeeker => _addSeeker(),
    ZyraSignupStep.verify => _verify(),
    ZyraSignupStep.aboutYou => _about(),
    ZyraSignupStep.addGuardian => _addGuardian(),
    ZyraSignupStep.allSet => _allSet(),
    _ => const SizedBox.shrink(),
  };

  Widget _input({
    required String id,
    required String value,
    required String hint,
    required ValueChanged<String> onChanged,
    int? limit,
    String? error,
    TextInputType? keyboardType,
    int lines = 1,
    bool numeric = false,
  }) => TextField(
    key: ValueKey('signup_$id'),
    controller: _text(id, value),
    onChanged: _change(onChanged),
    enabled: widget.canAct(),
    keyboardType: keyboardType,
    maxLines: lines,
    textInputAction: lines == 1
        ? TextInputAction.next
        : TextInputAction.newline,
    textCapitalization: numeric
        ? TextCapitalization.none
        : TextCapitalization.sentences,
    inputFormatters: [
      if (numeric) FilteringTextInputFormatter.digitsOnly,
      if (limit != null) LengthLimitingTextInputFormatter(limit),
    ],
    style: ZyraText.body(size: 15),
    cursorColor: ZyraColors.journeyGold,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: ZyraText.subtext(size: 15),
      suffixIconConstraints: const BoxConstraints(minHeight: 24),
      suffixIcon:
          limit != null &&
              !numeric &&
              lines == 1 &&
              limit - value.characters.length <= 5
          ? Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Text(
                '${value.characters.length}/$limit',
                style: ZyraText.subtext(
                  size: 12,
                  color: value.characters.length == limit
                      ? ZyraColors.goldText
                      : ZyraColors.secondaryText,
                ),
              ),
            )
          : null,
      filled: error != null,
      fillColor: ZyraColors.dangerText.withValues(alpha: .045),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide(
          color: error != null
              ? ZyraColors.dangerText
              : ZyraColors.surfaceBorder,
          width: error != null ? 1.5 : 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide(
          color: error != null
              ? ZyraColors.dangerText
              : ZyraColors.surfaceBorder,
          width: error != null ? 1.5 : 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide(
          color: error != null ? ZyraColors.dangerText : ZyraColors.journeyGold,
          width: error != null ? 1.5 : 1,
        ),
      ),
    ),
  );

  Widget _name() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      _title(
        'Your name',
        "Filled in from your ${c.provider} account. Check it’s right; you can change it.",
      ),
      const SizedBox(height: 20),
      _input(
        id: 'first_name',
        value: c.firstName,
        hint: 'First name',
        limit: 30,
        keyboardType: TextInputType.name,
        onChanged: c.setFirstName,
      ),
      const SizedBox(height: 12),
      _input(
        id: 'surname',
        value: c.surname,
        hint: 'Surname',
        limit: 40,
        keyboardType: TextInputType.name,
        onChanged: c.setSurname,
      ),
    ],
  );

  Widget _dateOfBirth() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      _title(
        'Date of birth',
        'ZYRA is for adults aged 18 and over. Your identity check confirms it later.',
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            flex: 5,
            child: _input(
              id: 'day',
              value: c.day,
              hint: 'DD',
              limit: 2,
              numeric: true,
              keyboardType: TextInputType.number,
              onChanged: c.setDay,
              error: c.under18 || c.invalidCalendarDate || c.dayError != null
                  ? c.dateError
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: _input(
              id: 'month',
              value: c.month,
              hint: 'MM',
              limit: 2,
              numeric: true,
              keyboardType: TextInputType.number,
              onChanged: c.setMonth,
              error: c.under18 || c.invalidCalendarDate || c.monthError != null
                  ? c.dateError
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 7,
            child: _input(
              id: 'year',
              value: c.year,
              hint: 'YYYY',
              limit: 4,
              numeric: true,
              keyboardType: TextInputType.number,
              onChanged: c.setYear,
              error: c.under18 || c.invalidCalendarDate || c.yearError != null
                  ? c.dateError
                  : null,
            ),
          ),
        ],
      ),
      if (c.dateError != null) ...[
        const SizedBox(height: 10),
        Text(
          c.dateError!,
          style: ZyraText.subtext(size: 12, color: ZyraColors.dangerText),
        ),
      ] else if (c.age != null) ...[
        const SizedBox(height: 10),
        Text(
          '${c.age} years old',
          style: ZyraText.subtext(size: 13, color: ZyraColors.goldText),
        ),
      ],
    ],
  );

  Widget _searchPage() {
    final location = c.step == ZyraSignupStep.location;
    final ethnicity = c.step == ZyraSignupStep.ethnicity;
    final sampleChoices = location
        ? const [
            'London',
            'Birmingham',
            'Manchester',
            'Leeds',
            'Bradford',
            'Leicester',
          ]
        : ethnicity
        ? const [
            'Pakistani',
            'Bangladeshi',
            'Indian',
            'Arab',
            'Somali',
            'Nigerian',
            'British',
          ]
        : const [
            'British',
            'Pakistani',
            'Bangladeshi',
            'Indian',
            'Somali',
            'Nigerian',
          ];
    final choices = {
      ...sampleChoices,
      if (!location) ...(ethnicity ? zyraEthnicityNames : zyraNationalityNames),
    };
    final results = choices
        .where((item) => item.toLowerCase().contains(_search.toLowerCase()))
        .take(6)
        .toList();
    final selected = ethnicity
        ? c.ethnicities.toList()
        : [
            if (location ? c.location != null : c.nationality != null)
              (location ? c.location! : c.nationality!),
          ];
    void choose(String value) {
      if (ethnicity) {
        c.toggleEthnicity(value);
      } else if (location) {
        c.setLocation('$value, United Kingdom');
      } else {
        c.setNationality(value);
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(
          location
              ? 'Where do you live?'
              : ethnicity
              ? 'Ethnicity'
              : 'Nationality',
          location
              ? 'Your town or city shows on your profile.'
              : ethnicity
              ? 'Choose all that apply. Shown on your profile.'
              : 'Shown on your profile.',
        ),
        const SizedBox(height: 18),
        _input(
          id: 'search',
          value: _search,
          hint: ethnicity
              ? 'Type to search, choose all that apply'
              : 'Type to search',
          onChanged: (value) => setState(() => _search = value),
        ),
        if (selected.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 6,
            children: [
              for (final value in selected)
                ActionChip(
                  key: ValueKey('signup_remove_$value'),
                  label: Text(
                    '$value ×',
                    style: ZyraText.body(size: 12, color: ZyraColors.goldText),
                  ),
                  backgroundColor: ZyraColors.journeyGold.withValues(
                    alpha: .07,
                  ),
                  side: BorderSide(color: ZyraColors.journeyGold),
                  shape: const StadiumBorder(),
                  onPressed: _action(() {
                    if (ethnicity) {
                      c.toggleEthnicity(value);
                    } else if (location) {
                      c.setLocation(null);
                    } else {
                      c.setNationality(null);
                    }
                  }),
                ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        if (results.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text(
              'No match. Try another spelling.',
              style: ZyraText.body(size: 14),
            ),
          )
        else
          for (final value in results)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: ZyraColors.divider)),
              ),
              child: InkWell(
                key: ValueKey('signup_choice_$value'),
                onTap: _action(() => choose(value)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(value, style: ZyraText.body(size: 14)),
                      ),
                      if (selected.contains(value) ||
                          (location &&
                              c.location?.startsWith('$value,') == true))
                        Icon(Icons.check, size: 15, color: ZyraColors.goldText),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );
  }

  Widget _photos() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _title(
        'Add your photos',
        'Add at least one. Your first photo is your profile picture everywhere.',
      ),
      const SizedBox(height: 20),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 9,
          mainAxisSpacing: 10,
          childAspectRatio: .75,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          final filled = index < c.photos.length;
          return Semantics(
            button: true,
            label: filled
                ? 'Remove photo ${index + 1}'
                : 'Add photo ${index + 1}',
            child: InkWell(
              key: ValueKey('signup_photo_$index'),
              borderRadius: BorderRadius.circular(16),
              onTap: _action(() {
                if (filled) {
                  c.removePhoto(index);
                } else if (widget.samplePhotos.isNotEmpty) {
                  c.addPhoto(
                    widget.samplePhotos[c.photos.length %
                        widget.samplePhotos.length],
                  );
                }
              }),
              child: filled
                  ? Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: index == 0
                              ? ZyraColors.journeyGold
                              : ZyraColors.surfaceBorder,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ZyraProfileImage(c.photos[index]),
                    )
                  : CustomPaint(
                      painter: _DashedPhotoBorder(),
                      child: Center(
                        child: Icon(
                          Icons.add,
                          size: 22,
                          color: ZyraColors.journeyGold,
                        ),
                      ),
                    ),
            ),
          );
        },
      ),
    ],
  );

  Widget _relationship() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _title(
        'Who are you\nto your Seeker?',
        'This shows on your Guardian card.',
      ),
      const SizedBox(height: 20),
      Wrap(
        spacing: 8,
        runSpacing: 10,
        children: [
          for (final label in [
            'Father',
            'Mother',
            'Brother',
            'Sister',
            'Uncle',
            'Aunt',
            'Other',
          ])
            ZyraFloatingSurface(
              radius: 999,
              child: ChoiceChip(
                key: ValueKey('signup_relationship_$label'),
                label: Text(
                  label,
                  style: ZyraText.body(
                    size: 14,
                    color: c.relationship == label
                        ? ZyraColors.goldText
                        : ZyraColors.espresso,
                  ),
                ),
                selected: c.relationship == label,
                showCheckmark: false,
                backgroundColor: ZyraColors.cardSurface,
                selectedColor: ZyraColors.journeyGold.withValues(alpha: .06),
                side: BorderSide(
                  color: c.relationship == label
                      ? ZyraColors.journeyGold
                      : ZyraColors.surfaceBorder,
                ),
                shape: const StadiumBorder(),
                onSelected: _change<bool>((_) => c.setRelationship(label)),
              ),
            ),
        ],
      ),
    ],
  );

  Widget _addSeeker() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _title(
        'Add your Seeker',
        'Enter the ZYRA Code your Seeker shares with you. They still choose whether to link.',
      ),
      const SizedBox(height: 20),
      _input(
        id: 'seeker_code',
        value: c.seekerCode,
        hint: 'ZYRA–XXXX–XXXX–XXXX–XXXX–XXXX',
        onChanged: c.setSeekerCode,
        error: c.seekerCode.isNotEmpty && c.pendingSeekerName == null
            ? 'Invalid code. Please try again.'
            : null,
      ),
      if (c.seekerCode.isNotEmpty && c.pendingSeekerName == null) ...[
        const SizedBox(height: 8),
        Text(
          'Invalid code. Please try again.',
          style: ZyraText.subtext(size: 12, color: ZyraColors.dangerText),
        ),
      ],
      const SizedBox(height: 8),
      TextButton(
        key: const ValueKey('signup_seeker_later'),
        onPressed: _action(c.skip),
        child: Text(
          'Do this later',
          style: ZyraText.body(size: 14, color: ZyraColors.goldText),
        ),
      ),
    ],
  );

  Widget _verify() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      _title(
        'Verify your identity',
        'Every member is checked so families can trust who they meet. It takes about 2 minutes.',
      ),
      Column(
        children: [
          for (final (index, line) in [
            'A photo of your passport or driving licence',
            'A short selfie video, so we know it’s really you',
            'We confirm your name and that you’re 18 or over',
          ].indexed)
            Container(
              constraints: const BoxConstraints(minHeight: 74),
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: ZyraColors.divider)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ZyraColors.journeyGold.withValues(alpha: .6),
                      ),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: ZyraText.body(color: ZyraColors.goldText),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Text(line, style: ZyraText.body(size: 14))),
                ],
              ),
            ),
        ],
      ),
      Column(
        children: [
          if (!c.verificationDeferred)
            TextButton(
              key: const ValueKey('signup_verify_later'),
              onPressed: _action(c.verifyLater),
              child: Text(
                'Do this later',
                style: ZyraText.body(size: 14, color: ZyraColors.goldText),
              ),
            ),
          if (c.verificationDeferred)
            Text(
              key: const ValueKey('signup_verify_deferred_message'),
              'You can look around, but profiles stay hidden and membership can’t start until you’re verified. No one sees you either.',
              style: ZyraText.subtext(size: 11),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    ],
  );

  Widget _ready() => Column(
    key: const ValueKey('signup_account_ready'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          const SizedBox(height: 26),
          Center(
            child: ZyraGoldRingMonogram(
              name: c.firstName,
              size: 84,
              fontSize: 36,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Welcome, ${c.firstName}',
            textAlign: TextAlign.center,
            style: ZyraText.pageTitle(),
          ),
          const SizedBox(height: 8),
          Text(
            'Your account is ready. Here’s what’s left.',
            textAlign: TextAlign.center,
            style: ZyraText.subtext(size: 14),
          ),
          const SizedBox(height: 20),
          ZyraFloatingSurface(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: ZyraColors.cardSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ZyraColors.surfaceBorder),
              ),
              child: Column(
                children: [
                  _checklist(
                    'Identity check',
                    c.verified ? 'Done' : 'Needed to see profiles',
                    done: c.verified,
                  ),
                  if (c.guardian)
                    _checklist(
                      'Your Seeker linked',
                      c.linkedSeekerName == null ? 'Add their code' : 'Done',
                      done: c.linkedSeekerName != null,
                    )
                  else ...[
                    _checklist(
                      'Photos',
                      c.photos.isNotEmpty ? 'Done' : 'Add your photos',
                      done: c.photos.isNotEmpty,
                    ),
                    _checklist(
                      'Partner preferences',
                      'Set any time in Profile',
                    ),
                    _checklist(
                      'Guardians',
                      'Optional · add any time',
                      last: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _button(
            id: 'signup_finish_setup',
            label: 'Finish setting up',
            onPressed: c.resumeSetup,
          ),
          const SizedBox(height: 10),
          _button(
            id: 'signup_look_around',
            label: 'Look around first',
            outlined: true,
            onPressed: _pause,
          ),
          const SizedBox(height: 12),
          Text(
            'You need a finished profile to start a Journey.',
            textAlign: TextAlign.center,
            style: ZyraText.subtext(size: 11),
          ),
        ],
      ),
    ],
  );

  Widget _checklist(
    String title,
    String detail, {
    bool done = false,
    bool last = false,
  }) => Container(
    constraints: const BoxConstraints(minHeight: 52),
    decoration: BoxDecoration(
      border: last
          ? null
          : Border(bottom: BorderSide(color: ZyraColors.divider)),
    ),
    padding: const EdgeInsets.symmetric(vertical: 13),
    child: Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? ZyraColors.positiveGreen : null,
            border: done
                ? null
                : Border.all(
                    color: ZyraColors.warmOverlay.withValues(alpha: .3),
                  ),
          ),
          child: done
              ? const Icon(Icons.check, color: ZyraColors.ivoryTop, size: 13)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: ZyraText.body(size: 14))),
        const SizedBox(width: 8),
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              detail,
              textAlign: TextAlign.end,
              style: ZyraText.subtext(
                size: 12,
                color: done ? ZyraColors.secondaryText : ZyraColors.goldText,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _about() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _title(
        'A few words about you',
        'Families read this first. Keep it simple and true.',
      ),
      const SizedBox(height: 20),
      _input(
        id: 'about_you',
        value: c.aboutYou,
        hint: 'For example: what matters to you, your work, your family.',
        onChanged: c.setAboutYou,
        limit: 300,
        lines: 6,
        keyboardType: TextInputType.multiline,
      ),
      const SizedBox(height: 5),
      Text(
        '${c.aboutYou.characters.length}/300',
        textAlign: TextAlign.end,
        style: ZyraText.subtext(
          size: 12,
          color: c.aboutYou.characters.length == 300
              ? ZyraColors.goldText
              : null,
        ),
      ),
    ],
  );

  String get _displayCode {
    final groups = widget.ownCode.split('-');
    if (groups.length == 6 && groups.first == 'ZYRA') {
      return '${groups.take(4).join(' · ')}\n${groups.skip(4).join(' · ')}';
    }
    return widget.ownCode.replaceAll('-', ' · ');
  }

  Widget _addGuardian() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _title(
        'Add a Guardian',
        c.verified
            ? 'A parent or family member who walks the Journey with you. Share your ZYRA Code with them; you still choose who links.'
            : 'Guardians only link to verified members. Verify your identity first; it takes about 2 minutes.',
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ZyraColors.surfaceBorder),
        ),
        child: c.verified
            ? Column(
                children: [
                  Text(
                    'YOUR ZYRA CODE',
                    style: ZyraText.chapterLabel(color: ZyraColors.goldText),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _displayCode,
                    textAlign: TextAlign.center,
                    style: ZyraText.body(size: 16).copyWith(letterSpacing: 1.8),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    key: const ValueKey('signup_share_code'),
                    onPressed: _action(widget.onShareCode),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ZyraColors.goldText,
                      side: BorderSide(color: ZyraColors.journeyGold),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      'Share my code',
                      style: ZyraText.body(
                        size: 14,
                        color: ZyraColors.goldText,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: ZyraColors.journeyGold),
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: ZyraColors.journeyGold,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'VERIFIED MEMBERS ONLY',
                    style: ZyraText.chapterLabel(color: ZyraColors.goldText),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    key: const ValueKey('signup_guardian_verify_now'),
                    onPressed: _action(
                      widget.onVerifyIdentity ??
                          () => c.setStep(ZyraSignupStep.verify),
                    ),
                    child: Text(
                      'Verify now',
                      style: ZyraText.body(
                        size: 14,
                        color: ZyraColors.goldText,
                      ),
                    ),
                  ),
                ],
              ),
      ),
      const SizedBox(height: 18),
      Text(
        c.verified
            ? 'You can also do this later from the Guardian tab.'
            : 'Once you’re verified, add a Guardian from the Guardian tab.',
        textAlign: TextAlign.center,
        style: ZyraText.subtext(size: 12),
      ),
    ],
  );

  Widget _allSet() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ZyraColors.positiveGreen.withValues(alpha: .12),
        ),
        child: Icon(Icons.check, size: 43, color: ZyraColors.positiveGreen),
      ),
      const SizedBox(height: 30),
      Text('You’re all set', style: ZyraText.pageTitle()),
      const SizedBox(height: 12),
      Text(
        'Your profile is complete. You can now start Journeys.',
        textAlign: TextAlign.center,
        style: ZyraText.subtext(size: 14).copyWith(height: 1.45),
      ),
    ],
  );
}

class _DashedPhotoBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(.5),
          const Radius.circular(16),
        ),
      );
    final paint = Paint()
      ..color = ZyraColors.journeyGold.withValues(alpha: .5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      for (double distance = 0; distance < metric.length; distance += 5) {
        canvas.drawPath(
          metric.extractPath(distance, math.min(distance + 2, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedPhotoBorder oldDelegate) => false;
}
