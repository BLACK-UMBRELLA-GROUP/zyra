import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_pull_down_back_scope.dart';

/// Detached, explicitly supplied dates for a past discussion example. This
/// is not a member profile, message/history permission or live Journey record.
@immutable
class ZyraCircleDiscussionArchive {
  const ZyraCircleDiscussionArchive({
    required this.topicId,
    required this.firstName,
    required this.startedOn,
    required this.endedOn,
    this.sharedSummaryLabel,
  });

  final String topicId;
  final String firstName;
  final DateTime startedOn;
  final DateTime endedOn;

  /// Caller-supplied first names and dates; adds no history capability.
  final String? sharedSummaryLabel;
}

/// Read-only child of the same Circle, with no lookup, composer or restart.
class ZyraCircleDiscussionArchiveView extends StatefulWidget {
  const ZyraCircleDiscussionArchiveView({
    super.key,
    required this.archive,
    required this.canAct,
    required this.onClose,
  });

  final ZyraCircleDiscussionArchive archive;
  final bool Function() canAct;
  final VoidCallback onClose;

  @override
  State<ZyraCircleDiscussionArchiveView> createState() =>
      _ZyraCircleDiscussionArchiveViewState();
}

class _ZyraCircleDiscussionArchiveViewState
    extends State<ZyraCircleDiscussionArchiveView> {
  late final ZyraCircleDiscussionArchive _archive = widget.archive;
  late final bool Function() _owner = widget.canAct;
  late final VoidCallback _close = widget.onClose;
  bool _revoked = false;

  @override
  void didUpdateWidget(covariant ZyraCircleDiscussionArchiveView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.archive, _archive) ||
        !identical(widget.canAct, _owner) ||
        !identical(widget.onClose, _close)) {
      _revoked = true;
    }
  }

  bool get _current {
    if (!mounted || _revoked) return false;
    try {
      if (_owner()) return true;
    } catch (_) {
      // A failed caller check is a terminal denial, not an empty live read.
    }
    _revoked = true;
    return false;
  }

  // Bind one exact return callback across appearance and inherited rebuilds.
  // ignore: prefer_function_declarations_over_variables
  late final VoidCallback _return = () {
    if (_current && (ModalRoute.of(context)?.isCurrent ?? false)) {
      _close();
    } else if (mounted) {
      setState(() {});
    }
  };

  @override
  Widget build(BuildContext context) => !_current
      ? const SizedBox.shrink()
      : Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
            child: SafeArea(
              child: ZyraPullDownBackScope(
                routeIdentity: _archive,
                onBack: _return,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _archive.sharedSummaryLabel == null
                                  ? 'Journey with ${_archive.firstName}'
                                  : 'Past Journey',
                              style: ZyraText.heading(size: 26),
                            ),
                          ),
                          IconButton(
                            key: const ValueKey(
                              'circle_discussion_archive_close',
                            ),
                            tooltip: 'Close Journey',
                            onPressed: _return,
                            icon: Icon(
                              Icons.close_rounded,
                              color: ZyraColors.foregroundMuted,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: ZyraColors.surfaceFill,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: ZyraColors.surfaceBorder,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_archive.sharedSummaryLabel != null)
                                  Text(
                                    _archive.sharedSummaryLabel!,
                                    style: ZyraText.body(
                                      size: 17,
                                      color: ZyraColors.journeyGold,
                                    ),
                                  )
                                else ...[
                                  Text(
                                    'Past Journey',
                                    style: ZyraText.body(
                                      size: 17,
                                      color: ZyraColors.journeyGold,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    'This Journey is archived.',
                                    style: ZyraText.subtext(size: 13),
                                  ),
                                  const SizedBox(height: 26),
                                  _milestone(
                                    context,
                                    'Journey started',
                                    _archive.startedOn,
                                    Icons.route_outlined,
                                  ),
                                  const SizedBox(height: 22),
                                  _milestone(
                                    context,
                                    'Journey ended',
                                    _archive.endedOn,
                                    Icons.history_rounded,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

  Widget _milestone(
    BuildContext context,
    String label,
    DateTime date,
    IconData icon,
  ) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: ZyraColors.journeyGold, size: 22),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: ZyraText.body(size: 14)),
            const SizedBox(height: 4),
            Text(
              MaterialLocalizations.of(context).formatShortDate(date),
              style: ZyraText.subtext(size: 12),
            ),
          ],
        ),
      ),
    ],
  );
}
