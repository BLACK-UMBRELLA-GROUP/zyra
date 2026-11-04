// Code-only gold presentation fixtures; immutable renderer inputs in production.
import 'package:flutter/material.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_auth.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/screens/welcome_screen.dart';
import 'package:zyra/dev/dev_onboarding_gold_design.dart';
export 'package:zyra/dev/dev_onboarding_gold_design.dart';

abstract final class ZyraDevOnboardingGoldMotion {
  static const defaultMotion = ZyraOnboardingGoldMotion.liveDrift;
  static final ValueNotifier<ZyraOnboardingGoldMotion> _selection =
      ValueNotifier(defaultMotion);
  static final ValueNotifier<int> _pageEntry = ValueNotifier(0);
  static int _accountGeneration = ZyraAccountState.generation;

  static Listenable get changes => _selection;
  static Listenable get pageEntries => _pageEntry;
  static ZyraOnboardingGoldMotion get current =>
      _accountGeneration == ZyraAccountState.generation
      ? _selection.value
      : defaultMotion;

  static bool select(ZyraOnboardingGoldMotion motion) {
    if (!ZyraDeveloperAccess.canUseDeveloperTools) return false;
    final generation = ZyraAccountState.generation;
    if (_accountGeneration != generation) {
      _accountGeneration = generation;
      _selection.value = defaultMotion;
    }
    _selection.value = motion;
    return true;
  }

  static void pageEntered() {
    if (!ZyraDeveloperAccess.canUseDeveloperTools) return;
    _pageEntry.value++;
  }

  @visibleForTesting
  static void resetForTesting() {
    assert(() {
      _accountGeneration = ZyraAccountState.generation;
      _selection.value = defaultMotion;
      _pageEntry.value = 0;
      return true;
    }());
  }
}

abstract final class ZyraDevOnboardingGoldDesign {
  static const defaultDesign = ZyraOnboardingGoldDesign.diagonalDust;
  static final ValueNotifier<ZyraOnboardingGoldDesign> _selection =
      ValueNotifier(defaultDesign);
  static int _accountGeneration = ZyraAccountState.generation;

  static Listenable get changes => _selection;
  static ZyraOnboardingGoldDesign get current =>
      _accountGeneration == ZyraAccountState.generation
      ? _selection.value
      : defaultDesign;

  static bool select(ZyraOnboardingGoldDesign design) {
    if (!ZyraDeveloperAccess.canUseDeveloperTools) return false;
    final generation = ZyraAccountState.generation;
    if (_accountGeneration != generation) {
      _accountGeneration = generation;
      _selection.value = defaultDesign;
    }
    _selection.value = design;
    return true;
  }

  @visibleForTesting
  static void resetForTesting() {
    assert(() {
      _accountGeneration = ZyraAccountState.generation;
      _selection.value = defaultDesign;
      return true;
    }());
  }
}

/// The small toggle preview uses the same geometry with stronger visibility.
class ZyraOnboardingGoldSwatch extends StatelessWidget {
  const ZyraOnboardingGoldSwatch(this.design, {super.key});
  final ZyraOnboardingGoldDesign design;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(7),
    child: DecoratedBox(
      decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
      child: SizedBox(
        width: 56,
        height: 36,
        child: CustomPaint(
          painter: ZyraOnboardingGoldPainter(design, preview: true),
        ),
      ),
    ),
  );
}

class OnboardingGoldBackdropFixture extends StatelessWidget {
  const OnboardingGoldBackdropFixture({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      ZyraDevOnboardingGoldDesign.changes,
      ZyraDevOnboardingGoldMotion.changes,
    ]),
    builder: (context, _) => ZyraOnboardingGoldBackdrop(
      design: ZyraDevOnboardingGoldDesign.current,
      motion: ZyraDevOnboardingGoldMotion.current,
      pageEntries: ZyraDevOnboardingGoldMotion.pageEntries,
    ),
  );
}

class Queue44WelcomeFixture extends StatelessWidget {
  const Queue44WelcomeFixture({
    super.key,
    this.googleSignIn,
    this.appleSignIn,
    this.devPreview = false,
    this.devIntroductionBuilder,
    this.devIntroductionRouteBuilder,
  });
  final Future<ZyraAuthResult> Function()? googleSignIn, appleSignIn;
  final bool devPreview;
  final WidgetBuilder? devIntroductionBuilder;
  final PageRoute<void> Function(WidgetBuilder)? devIntroductionRouteBuilder;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      ZyraDevOnboardingGoldDesign.changes,
      ZyraDevOnboardingGoldMotion.changes,
    ]),
    builder: (context, _) => WelcomeScreen(
      googleSignIn: googleSignIn,
      appleSignIn: appleSignIn,
      devPreview: devPreview,
      devIntroductionBuilder: devIntroductionBuilder,
      devIntroductionRouteBuilder: devIntroductionRouteBuilder,
      onboardingGoldDesign: ZyraDevOnboardingGoldDesign.current,
      onboardingGoldMotion: ZyraDevOnboardingGoldMotion.current,
      onboardingPageEntries: ZyraDevOnboardingGoldMotion.pageEntries,
    ),
  );
}
