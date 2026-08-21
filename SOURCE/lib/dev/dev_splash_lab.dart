// The Splash lab — full-screen previews of the five candidate endings.
//
// BUILT 2026-08-12 (Founder: the splash's final movement "doesn't feel
// smooth… propose five alternative versions that all match the existing
// design language. I want five options to choose from").
//
// The choosing happens by WATCHING, not by reading descriptions: each
// button plays the real SplashScreen with that ending, at real timing, on
// the real gradient. Tap anywhere to leave; Replay runs it again. When the
// Founder picks, the winner becomes SplashScreen's `ending` default (one
// line in splash_screen.dart) and this lab stays for the next comparison.
//
// MOVED 2026-08-12, evening: reached from DEVELOPER ACCESS now (via
// DevSplashLabMenu below), not from the toggle panel. Founder review that
// evening: the panel is per-page scenario controls only, and the splash is
// not a page — global dev destinations live on the dev home. Dev-only by
// mount point either way: Developer Access is itself debug-build-gated.

import 'package:flutter/material.dart';

import '../screens/splash_screen.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_comet_rule.dart';

/// Founder-facing labels, in the order they were proposed.
const List<({ZyraSplashEnding ending, String label, String blurb})>
zyraSplashLabOptions = [
  (
    ending: ZyraSplashEnding.trailsMeet,
    label: 'Trails Meet — CURRENT',
    blurb: 'Two gold dots draw their own halves inward and connect.',
  ),
  (
    ending: ZyraSplashEnding.classic,
    label: 'Original',
    blurb: 'Arrive, then fade in place — replaced 2026-08-12 (it glitched).',
  ),
  (
    ending: ZyraSplashEnding.settle,
    label: '1 · Settle',
    blurb: 'Hold a beat, then dim like an ember into the rail.',
  ),
  (
    ending: ZyraSplashEnding.passThrough,
    label: '2 · Pass through',
    blurb:
        'The lights cross and carry on along each other\'s path. '
        'Founder-chosen 2026-08-12; superseded by Trails Meet.',
  ),
  (
    ending: ZyraSplashEnding.merge,
    label: '3 · Merge',
    blurb: 'Two lights become one glow that stays at the centre.',
  ),
  (
    ending: ZyraSplashEnding.ignite,
    label: '4 · Ignite',
    blurb: 'The meeting lights the whole rail, centre outward.',
  ),
  (
    ending: ZyraSplashEnding.ascend,
    label: '5 · Ascend',
    blurb: 'The merged light rises into the wordmark and dissolves.',
  ),
];

/// The lab's front door: the five endings as a list, each playing the real
/// splash. Pushed from Developer Access — one tile there, the detail here,
/// so the dev home stays a directory rather than growing five buttons.
class DevSplashLabMenu extends StatelessWidget {
  const DevSplashLabMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF241B2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Splash lab', style: ZyraText.heading(size: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            'Five candidate endings, same design language, real speed. '
            'Watch them full-screen; the chosen one is the app\'s opening.',
            style: ZyraText.subtext(size: 12, color: Colors.white54),
          ),
          const SizedBox(height: 14),
          for (final o in zyraSplashLabOptions) ...[
            InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      DevSplashLabScreen(ending: o.ending, label: o.label),
                ),
              ),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.label, style: ZyraText.button(size: 13.5)),
                    const SizedBox(height: 3),
                    Text(
                      o.blurb,
                      style: ZyraText.subtext(
                        size: 10.5,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DevSplashLabScreen extends StatefulWidget {
  final ZyraSplashEnding ending;
  final String label;
  const DevSplashLabScreen({
    super.key,
    required this.ending,
    required this.label,
  });

  @override
  State<DevSplashLabScreen> createState() => _DevSplashLabScreenState();
}

class _DevSplashLabScreenState extends State<DevSplashLabScreen> {
  /// Bumped to remount SplashScreen, which replays it from zero.
  int _run = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).maybePop(),
      child: Scaffold(
        body: Stack(
          children: [
            SplashScreen(key: ValueKey(_run), ending: widget.ending),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.label} — tap anywhere to leave',
                        style: ZyraText.subtext(
                          size: 11,
                          color: Colors.white38,
                        ),
                      ),
                      const SizedBox(height: 6),
                      OutlinedButton(
                        onPressed: () => setState(() => _run++),
                        child: Text('Replay', style: ZyraText.button(size: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
