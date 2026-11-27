import 'package:flutter/material.dart';

import '../data/zyra_seeker_basic_policy.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_confirm_sheet.dart';
import '../widgets/zyra_floating_surface.dart';
import '../widgets/zyra_tap_feedback.dart';

typedef ZyraPreviewBrowseSnapshot = ({
  DateTime? startedAt,
  int seededViews,
  Set<String> people,
});

/// One local preview window. First exposure starts it; repainting a card
/// cannot count the same person a second time.
class ZyraPreviewBrowseWindow {
  ZyraPreviewBrowseWindow({this.startedAt, this.seededViews = 0});

  factory ZyraPreviewBrowseWindow.fromSnapshot(
    ZyraPreviewBrowseSnapshot snapshot,
  ) => ZyraPreviewBrowseWindow(
    startedAt: snapshot.startedAt,
    seededViews: snapshot.seededViews,
  ).._people.addAll(snapshot.people);

  ZyraPreviewBrowseSnapshot snapshot() => (
    startedAt: startedAt,
    seededViews: seededViews,
    people: Set.unmodifiable(_people),
  );

  final DateTime? startedAt;
  final int seededViews;
  final Set<String> _people = {};

  int countAt(DateTime now) => activeAt(now) ? _people.length + seededViews : 0;

  DateTime? get refillAt => startedAt?.add(ZyraSeekerBasicPolicy.swipeWindow);

  bool activeAt(DateTime now) =>
      startedAt != null && !now.isBefore(startedAt!) && now.isBefore(refillAt!);

  bool record(String profileId, DateTime now) =>
      activeAt(now) &&
      !ZyraSeekerBasicPolicy.swipeLimitReached(countAt(now)) &&
      _people.add(profileId);
}

class ZyraProfilesLimitBar extends StatelessWidget {
  const ZyraProfilesLimitBar({
    super.key,
    required this.count,
    required this.refillTime,
  });

  final int count;
  final String refillTime;

  double heightFor(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(text: '0 of 25 profiles', style: ZyraText.body(size: 12)),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final result = painter.height + 10;
    painter.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    const cap = ZyraSeekerBasicPolicy.swipeLimit;
    final text = ZyraText.body(size: 12, color: ZyraColors.secondaryText);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('$count of $cap profiles', style: text)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${count == cap ? 'More' : 'more'} at $refillTime',
                textAlign: TextAlign.end,
                style: text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: (count / cap).clamp(0, 1).toDouble(),
            minHeight: 4,
            color: ZyraColors.journeyGold,
            backgroundColor: ZyraColors.ink(.10),
          ),
        ),
      ],
    );
  }
}

class ZyraProfilesLimitCard extends StatelessWidget {
  const ZyraProfilesLimitCard({
    super.key,
    required this.refillTime,
    required this.onUpgrade,
  });

  final String refillTime;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) => ZyraFloatingSurface(
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: ZyraColors.confirmSheetSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: ZyraColors.journeyGold.withValues(alpha: .35),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, bounds) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: bounds.maxHeight),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _LimitIcon(Icons.search, size: 64),
                  const SizedBox(height: 18),
                  Text(
                    'You’ve seen your 25 for now',
                    textAlign: TextAlign.center,
                    style: ZyraText.heading(
                      size: 22,
                    ).copyWith(fontWeight: FontWeight.w300),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 286),
                      child: Text(
                        'More profiles at $refillTime. Seeker One has no limit.',
                        textAlign: TextAlign.center,
                        style: ZyraText.body(
                          size: 13,
                          color: ZyraColors.secondaryText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _LimitButton(
                    label: 'Try Seeker One free for 14 days',
                    onPressed: onUpgrade,
                    primary: true,
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

class ZyraSentRequestCount extends StatelessWidget {
  const ZyraSentRequestCount({
    super.key,
    required this.waiting,
    required this.cap,
  });

  final int waiting;
  final int cap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
    child: Text(
      '$waiting of $cap requests waiting'
      '${waiting >= cap ? ' · cancel one to ask someone new' : ''}',
      style: ZyraText.body(size: 13, color: ZyraColors.secondaryText),
    ),
  );
}

enum ZyraRequestLimitChoice { sent, upgrade }

class ZyraRequestsFullSheet extends StatelessWidget {
  const ZyraRequestsFullSheet({
    super.key,
    required this.cap,
    required this.basic,
    required this.onSent,
    required this.onUpgrade,
    required this.onDismiss,
  });

  final int cap;
  final bool basic;
  final VoidCallback onSent;
  final VoidCallback onUpgrade;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: ZyraIvorySheet.decoration,
    child: ZyraIvorySheet(
      surfaceKey: const ValueKey('lock48_requests_full'),
      child: SafeArea(
        top: false,
        minimum: ZyraIvorySheet.bottomPadding,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ZyraIvorySheetHandle(bottomSpacing: 16),
              const _LimitIcon(Icons.send_rounded),
              const SizedBox(height: 12),
              Text(
                'Your requests are full',
                textAlign: TextAlign.center,
                style: ZyraText.heading(
                  size: 21,
                ).copyWith(fontWeight: FontWeight.w300),
              ),
              const SizedBox(height: 8),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    'You have $cap requests waiting. To ask someone new, '
                    'cancel one you’ve sent.'
                    '${basic ? ' Seeker One lets you have 20 waiting.' : ''}',
                    textAlign: TextAlign.center,
                    style: ZyraText.body(
                      size: 13,
                      color: ZyraColors.secondaryText,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _LimitButton(
                label: 'See sent requests',
                onPressed: onSent,
                primary: true,
              ),
              if (basic) ...[
                const SizedBox(height: 10),
                _LimitButton(label: 'See Seeker One', onPressed: onUpgrade),
              ],
              const SizedBox(height: 8),
              _LimitButton(label: 'Not now', onPressed: onDismiss, quiet: true),
            ],
          ),
        ),
      ),
    ),
  );
}

class _LimitIcon extends StatelessWidget {
  const _LimitIcon(this.icon, {this.size = 56});
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: ZyraColors.journeyGold.withValues(alpha: .60),
          ),
        ),
        child: Icon(icon, size: 24, color: ZyraColors.journeyGold),
      ),
    ),
  );
}

class _LimitButton extends StatelessWidget {
  const _LimitButton({
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.quiet = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;
  final bool quiet;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: const BorderRadius.all(Radius.circular(999)),
      boxShadow: primary
          ? ZyraFloatingSurface.goldShadows
          : ZyraFloatingSurface.standardShadows,
    ),
    child: FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        backgroundColor: primary
            ? ZyraColors.goldTextFill
            : quiet
            ? ZyraColors.ivoryTop
            : ZyraColors.confirmSheetSurface,
        foregroundColor: quiet ? ZyraColors.secondaryText : ZyraColors.espresso,
        side: primary
            ? BorderSide.none
            : BorderSide(color: ZyraColors.ink(.10)),
        textStyle: ZyraText.button(size: 14),
      ),
      onPressed: ZyraTapFeedback.onTap(context, onPressed),
      child: Text(label, textAlign: TextAlign.center),
    ),
  );
}
