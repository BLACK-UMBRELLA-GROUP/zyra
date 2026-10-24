import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

class ZyraMessageReader {
  final String userId;
  final String firstName;
  final String? roleLabel;
  final DateTime? readAt;

  const ZyraMessageReader({
    required this.userId,
    required this.firstName,
    this.roleLabel,
    this.readAt,
  });

  String get identityLabel {
    final role = roleLabel?.trim();
    return role == null || role.isEmpty ? firstName : '$firstName · $role';
  }
}

/// A deliberately compact receipt shown only under the latest message sent by
/// the current member. Group chats name readers instead of using ambiguous
/// double ticks.
class ZyraMessageReceipt extends StatelessWidget {
  final List<ZyraMessageReader> readBy;
  final int recipientCount;
  // Optional caller-owned lifetime boundary. Defaults keep ordinary receipts
  // unchanged; a protected local preview must guard its already-open sheet.
  final bool Function()? canOpenReaders;
  final Widget Function(BuildContext context, Widget sheet)?
  readersSheetWrapper;

  const ZyraMessageReceipt({
    super.key,
    required this.readBy,
    required this.recipientCount,
    this.canOpenReaders,
    this.readersSheetWrapper,
  });

  String get summary {
    if (readBy.isEmpty) return 'Sent';
    if (recipientCount > 1 && readBy.length >= recipientCount) {
      return 'Seen by everyone';
    }
    if (readBy.length == 1) return 'Seen by ${readBy.first.firstName}';
    return 'Seen by ${readBy.first.firstName} + ${readBy.length - 1}';
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: Semantics(
      button: readBy.isNotEmpty,
      label: summary,
      child: InkWell(
        key: const ValueKey('message-read-receipt'),
        borderRadius: BorderRadius.circular(18),
        onTap: readBy.isEmpty ? null : () => _showReaders(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 3, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                readBy.isEmpty ? Icons.check_rounded : Icons.done_all_rounded,
                size: 14,
                color: readBy.isEmpty
                    ? ZyraColors.foregroundSecondary
                    : ZyraColors.surfaceSignal,
              ),
              const SizedBox(width: 4),
              Text(
                summary,
                style: ZyraText.subtext(
                  size: 10,
                  color: readBy.isEmpty
                      ? ZyraColors.foregroundSecondary
                      : ZyraColors.surfaceSignal,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _showReaders(BuildContext context) async {
    if (canOpenReaders?.call() == false) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final sheet = SafeArea(
          child: Container(
            key: const ValueKey('message-readers-sheet'),
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            decoration: BoxDecoration(
              color: ZyraColors.waliSheetBg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: ZyraColors.surfaceBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ZyraColors.ink(0.22),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Read by', style: ZyraText.heading(size: 21)),
                const SizedBox(height: 14),
                for (final reader in readBy)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 19,
                          backgroundColor: ZyraColors.actionFill.withValues(
                            alpha: 0.14,
                          ),
                          child: Text(
                            reader.firstName.substring(0, 1).toUpperCase(),
                            style: ZyraText.body(
                              size: 13,
                              color: ZyraColors.surfaceSignal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            reader.identityLabel,
                            style: ZyraText.body(size: 14),
                          ),
                        ),
                        if (reader.readAt case final readAt?)
                          Text(
                            _receiptTime(readAt),
                            style: ZyraText.subtext(size: 10.5),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
        return readersSheetWrapper?.call(context, sheet) ?? sheet;
      },
    );
  }
}

class ZyraUnreadMessagesDivider extends StatelessWidget {
  const ZyraUnreadMessagesDivider({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    key: const ValueKey('unread-messages-divider'),
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        Expanded(
          child: Divider(color: ZyraColors.actionFill.withValues(alpha: 0.42)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'UNREAD MESSAGES',
            style: ZyraText.chapterLabel(color: ZyraColors.surfaceSignal),
          ),
        ),
        Expanded(
          child: Divider(color: ZyraColors.actionFill.withValues(alpha: 0.42)),
        ),
      ],
    ),
  );
}

String _receiptTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${local.hour < 12 ? 'AM' : 'PM'}';
}
