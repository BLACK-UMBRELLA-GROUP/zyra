// Reusable Chapter Transition Screen — Onboarding Rules & UX §TRANSITION
// SCREENS. Scrollable, glass pill button below the fold, bouncing
// chevron hint. Used at all four chapter boundaries (Ch1->2, Ch2->3,
// Ch3->4, Ch4->5), each supplying its own copy per Flow Diagram.md.

import 'package:flutter/material.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';

class TransitionScreen extends StatelessWidget {
  final ZyraBackgroundVariant background;
  final String title;
  final String body;
  final String? citation;
  final String buttonLabel;
  final VoidCallback onContinue;

  const TransitionScreen({
    super.key,
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.onContinue,
    this.background = ZyraBackgroundVariant.neutral,
    this.citation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: ZyraColors.backgroundFor(background)),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - 80),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    Text(title, style: ZyraText.heading(size: 26)),
                    const SizedBox(height: 18),
                    Text(body, style: ZyraText.body(size: 15)),
                    if (citation != null) ...[
                      const SizedBox(height: 18),
                      Text(citation!, style: ZyraText.subtext()),
                    ],
                    const SizedBox(height: 260),
                    Center(
                      child: Column(
                        children: [
                          _GlassPillButton(label: buttonLabel, onTap: onContinue),
                          const SizedBox(height: 10),
                          const _BouncingChevron(),
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
}

class _GlassPillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GlassPillButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
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

class _BouncingChevronState extends State<_BouncingChevron> with SingleTickerProviderStateMixin {
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
      child: const Icon(Icons.keyboard_arrow_down, color: Colors.white38, size: 20),
    );
  }
}
