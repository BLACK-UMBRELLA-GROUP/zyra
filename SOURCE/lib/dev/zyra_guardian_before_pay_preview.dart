import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_purchase_fine_print.dart';

/// LOCK 38 b07/b08. A detached explanation, never a payment or entitlement.
class ZyraGuardianBeforePayPreview extends StatefulWidget {
  const ZyraGuardianBeforePayPreview({
    super.key,
    required this.seekerFirstName,
    required this.canAct,
    this.onNotice,
  });

  final String seekerFirstName;
  final bool Function() canAct;
  final ValueChanged<String>? onNotice;

  @override
  State<ZyraGuardianBeforePayPreview> createState() =>
      _ZyraGuardianBeforePayPreviewState();
}

class _ZyraGuardianBeforePayPreviewState
    extends State<ZyraGuardianBeforePayPreview> {
  bool _understood = false;

  bool _canAct() =>
      mounted && ModalRoute.of(context)?.isCurrent == true && widget.canAct();

  void _notice(String message) {
    if (widget.onNotice case final callback?) {
      callback(message);
    } else {
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Widget _card() {
    final name = widget.seekerFirstName;
    final style = ZyraText.body(size: 15, color: ZyraColors.espresso);
    return Container(
      key: const ValueKey('guardian-before-pay-card'),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: ZyraColors.ivoryTop,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECE5DA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Guardian One makes chat possible. It does not guarantee it.',
            style: style,
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE6DED3)),
          const SizedBox(height: 14),
          Text.rich(
            TextSpan(
              style: style,
              children: [
                TextSpan(
                  text: '$name decides. ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text:
                      '$name chooses a Main Guardian and switches chat '
                      'on or off for every other Guardian, Journey by Journey.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE6DED3)),
          const SizedBox(height: 14),
          Text.rich(
            TextSpan(
              style: style,
              children: const [
                TextSpan(
                  text: 'Chat follows the Journey. ',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text:
                      'It opens at the stages that allow it, and stops '
                      'if the Journey ends or either family blocks.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _understandRow() => InkWell(
    key: const ValueKey('guardian-before-pay-understand'),
    onTap: () {
      if (_canAct()) setState(() => _understood = !_understood);
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _understood ? ZyraColors.goldTextFill : Colors.transparent,
              border: Border.all(
                color: _understood
                    ? ZyraColors.goldText
                    : const Color(0xFFB9B0A4),
              ),
              borderRadius: BorderRadius.circular(7),
            ),
            child: _understood
                ? const Icon(Icons.check, size: 19, color: ZyraColors.espresso)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'I understand ${widget.seekerFirstName} decides.',
              style: ZyraText.body(size: 15, color: ZyraColors.espresso),
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ZyraColors.ivoryTop, ZyraColors.ivoryBottom],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, bounds) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: bounds.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Before you pay',
                        style: ZyraText.heading(
                          size: 28,
                          color: ZyraColors.espresso,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _card(),
                      const SizedBox(height: 6),
                      _understandRow(),
                      const Spacer(),
                      FilledButton(
                        key: const ValueKey('guardian-before-pay-continue'),
                        onPressed: _understood && _canAct()
                            ? () {
                                if (_canAct()) {
                                  _notice(ZyraPurchaseFinePrint.appleNotice);
                                }
                              }
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: ZyraColors.goldTextFill,
                          foregroundColor: ZyraColors.espresso,
                          disabledBackgroundColor: ZyraColors.goldTextFill
                              .withValues(alpha: .45),
                          disabledForegroundColor: ZyraColors.strongSecondaryText,
                          minimumSize: const Size.fromHeight(50),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('Continue to Apple'),
                      ),
                      const SizedBox(height: 8),
                      ZyraPurchaseFinePrint(
                        offer: ZyraPurchaseOffer.guardianOne,
                        onNotice: widget.onNotice,
                        canAct: _canAct,
                        canRetainLegal: widget.canAct,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
