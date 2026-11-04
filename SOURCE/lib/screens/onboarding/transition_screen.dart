// Shared Guardian support/consent handoff. The selected onboarding style keeps
// the reading area scrollable and its continuation consistently reachable.

import 'package:flutter/material.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_onboarding_direction_style.dart';
import '../../widgets/zyra_onboarding_continue_action.dart';

class TransitionScreen extends StatelessWidget {
  final ZyraBackgroundVariant background;
  final String title;
  final String body;
  final String? citation;
  final String buttonLabel;
  final VoidCallback onContinue;
  final bool devPreview;

  const TransitionScreen({
    super.key,
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.onContinue,
    this.devPreview = false,
    this.background = ZyraBackgroundVariant.neutral,
    this.citation,
  });

  @override
  Widget build(BuildContext context) {
    final previewStyle = OnboardingPreviewStyle.effectiveStyleOf(context);
    if (previewStyle != null) {
      return _styledTransition(context, previewStyle);
    }
    return Scaffold(
      // `constraints` added 2026-08-03 alongside the same fix on the
      // report screen. SingleChildScrollView sizes to its content, so this
      // Container could shrink and expose the Scaffold background — which
      // is now the gender gradient's first stop (Rose Pink for a female
      // Seeker) rather than the Royal Purple it used to be.
      //
      // The ConstrainedBox below already guards this with `screenHeight -
      // 80`, an estimate of the safe-area insets. On a device where those
      // insets total more than 80 it is one or two points short, which is
      // exactly the size of band the Founder spotted on the report screen.
      // The estimate is left in place — it also centres short content
      // nicely — but the gradient no longer depends on it being right.
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(
          gradient:
              previewStyle?.backgroundGradient ??
              ZyraColors.backgroundFor(background),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 80,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 20),
                    if (previewStyle != null) ...[
                      OnboardingPreviewAccent(
                        style: previewStyle,
                        size: 64,
                        progress: 1,
                      ),
                      const SizedBox(height: 22),
                    ],
                    Text(
                      title,
                      style: ZyraText.heading(
                        size: previewStyle?.titleSize ?? 26,
                      ),
                    ),
                    SizedBox(height: 18),
                    Text(body, style: ZyraText.body(size: 15)),
                    if (citation != null) ...[
                      SizedBox(height: 18),
                      Text(citation!, style: ZyraText.subtext()),
                    ],
                    SizedBox(height: previewStyle == null ? 260 : 140),
                    Center(
                      child: Column(
                        children: [
                          if (ZyraOnboardingArrowScope.enabledOf(context))
                            ZyraOnboardingArrowAction(
                              key: const ValueKey('transition_continue'),
                              active: true,
                              onPressed: onContinue,
                              semanticLabel: buttonLabel,
                            )
                          else ...[
                            _GlassPillButton(
                              label: buttonLabel,
                              onTap: onContinue,
                            ),
                            const SizedBox(height: 10),
                            const _BouncingChevron(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _styledTransition(
    BuildContext context,
    OnboardingPreviewStyle style,
  ) => Scaffold(
    body: Container(
      constraints: const BoxConstraints.expand(),
      decoration: BoxDecoration(gradient: style.backgroundGradient),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Text(
                'ZYRA',
                style: ZyraText.wordmark(
                  size: 17,
                  color: ZyraColors.splashWordmark,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: Column(
                  crossAxisAlignment: style.centered
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    OnboardingPreviewAccent(
                      style: style,
                      size: 64,
                      progress: 1,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        title,
                        textAlign: style.centered
                            ? TextAlign.center
                            : TextAlign.left,
                        style: ZyraText.heading(size: style.titleSize),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: style.cardDecoration(),
                      child: Text(
                        body,
                        style: ZyraText.body(size: 15).copyWith(height: 1.5),
                      ),
                    ),
                    if (citation != null) ...[
                      const SizedBox(height: 18),
                      Text(citation!, style: ZyraText.subtext()),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 14),
              child: ZyraOnboardingArrowScope.enabledOf(context)
                  ? ZyraOnboardingArrowAction(
                      key: const ValueKey('transition_continue'),
                      active: true,
                      onPressed: onContinue,
                      semanticLabel: buttonLabel,
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        key: const ValueKey('transition_continue'),
                        style: style.primaryButtonStyle,
                        onPressed: onContinue,
                        child: Text(buttonLabel, style: ZyraText.button()),
                      ),
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _GlassPillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GlassPillButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final previewStyle = OnboardingPreviewStyle.effectiveStyleOf(context);
    if (previewStyle != null) {
      return SizedBox(
        height: 51,
        child: FilledButton(
          onPressed: onTap,
          style: previewStyle.primaryButtonStyle,
          child: Text(label, style: ZyraText.button()),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ZyraColors.iconButtonBg,
        border: Border.all(color: ZyraColors.iconButtonBorder, width: 0.5),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            child: Text(label, style: ZyraText.button()),
          ),
        ),
      ),
    );
  }
}

class _BouncingChevron extends StatefulWidget {
  const _BouncingChevron();

  @override
  State<_BouncingChevron> createState() => _BouncingChevronState();
}

class _BouncingChevronState extends State<_BouncingChevron>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, 4 * _controller.value),
        child: child,
      ),
      child: Icon(
        Icons.keyboard_arrow_down,
        color: ZyraColors.ink(0.38),
        size: 20,
      ),
    );
  }
}
