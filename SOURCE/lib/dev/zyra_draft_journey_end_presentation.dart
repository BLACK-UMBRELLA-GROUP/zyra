import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

/// Presentation only. The caller supplies already-guarded actions and omits
/// both identity and portrait when the Journey's person is unavailable.
class ZyraDraftJourneyEndPresentation extends StatelessWidget {
  const ZyraDraftJourneyEndPresentation({
    super.key,
    required this.subjectId,
    required this.title,
    required this.onConfirm,
    required this.onKeep,
    this.name,
    this.portrait,
  });

  final String subjectId;
  final String title;
  final String? name;
  final Widget? portrait;
  final VoidCallback? onConfirm;
  final VoidCallback onKeep;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        key: ValueKey('draft_end_reader_$subjectId'),
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - 36).clamp(0, double.infinity),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                key: ValueKey('draft_end_title_$subjectId'),
                style: ZyraText.pageTitle(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _identity(context),
                    const SizedBox(height: 24),
                    Container(
                      key: ValueKey('draft_end_consequences_$subjectId'),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: ZyraColors.surfaceFill,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: ZyraColors.surfaceBorder),
                      ),
                      child: Column(
                        children: [
                          _consequence(
                            Icons.chat_bubble_outline_rounded,
                            'Your conversation closes',
                            'This Journey ends for both of you and cannot be reopened.',
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Divider(
                              height: 1,
                              color: ZyraColors.surfaceBorder,
                            ),
                          ),
                          _consequence(
                            Icons.history_rounded,
                            'Your Timeline stays',
                            'Your shared history is kept.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KeyedSubtree(
                    key: ValueKey('draft_cancel_journey_action_$subjectId'),
                    child: _action(
                      id: 'draft_cancel_end_$subjectId',
                      label: 'Keep this Journey',
                      onPressed: onKeep,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _action(
                    id: 'draft_confirm_end_$subjectId',
                    label: 'End Journey',
                    onPressed: onConfirm,
                    destructive: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _identity(BuildContext context) {
    final photo = ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 104,
          height: 128,
          child:
              portrait ??
              ColoredBox(
                color: ZyraColors.surfaceFill,
                child: Icon(
                  Icons.people_outline,
                  size: 40,
                  color: ZyraColors.journeyGold,
                ),
              ),
        ),
      ),
    );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR JOURNEY',
          style: ZyraText.chapterLabel(color: ZyraColors.journeyGold),
        ),
        const SizedBox(height: 8),
        Text(
          name ?? 'A considered goodbye',
          key: ValueKey('draft_end_identity_$subjectId'),
          style: ZyraText.heading(size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          'Take a moment before you decide.',
          style: ZyraText.subtext(size: 13),
        ),
      ],
    );
    return MediaQuery.textScalerOf(context).scale(14) > 14 * 1.3
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [photo, const SizedBox(height: 18), text],
          )
        : Row(
            children: [
              photo,
              const SizedBox(width: 18),
              Expanded(child: text),
            ],
          );
  }

  Widget _consequence(IconData icon, String title, String detail) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ExcludeSemantics(
        child: Icon(icon, size: 21, color: ZyraColors.journeyGold),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: ZyraText.body(size: 15)),
            const SizedBox(height: 6),
            Text(
              detail,
              style: ZyraText.subtext(size: 13).copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _action({
    required String id,
    required String label,
    required VoidCallback? onPressed,
    bool destructive = false,
  }) {
    final color = destructive ? ZyraColors.destructive : ZyraColors.foreground;
    return OutlinedButton(
      key: ValueKey(id),
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        foregroundColor: color,
        disabledForegroundColor: ZyraColors.foregroundMuted.withValues(
          alpha: .5,
        ),
        backgroundColor: destructive
            ? ZyraColors.destructive.withValues(alpha: .08)
            : ZyraColors.surfaceEmphasisFill,
        side: BorderSide(
          color: destructive
              ? ZyraColors.destructiveBorder
              : ZyraColors.surfaceEmphasisBorder,
        ),
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: ZyraText.button(
          size: 14,
          color: onPressed == null
              ? ZyraColors.foregroundMuted.withValues(alpha: .5)
              : color,
        ),
      ),
    );
  }
}
