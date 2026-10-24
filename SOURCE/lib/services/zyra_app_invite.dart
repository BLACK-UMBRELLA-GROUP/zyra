import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/zyra_interaction_style.dart';

/// Public app invitation. This deliberately does not include the member's
/// personal ZYRA Code: that code links Seeker and Guardian accounts and must
/// never be mistaken for a general referral code.
class ZyraAppInvite {
  ZyraAppInvite._();

  static const website = 'https://zyraconnect.app';

  static Future<void> share(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;

    await ZyraInteractionStyle.emitSelectionHaptic();
    await SharePlus.instance.share(
      ShareParams(
        subject: 'Discover ZYRA',
        text:
            'Discover ZYRA — a marriage Journey built for Seekers and '
            'Guardians.\n\n$website',
        sharePositionOrigin: origin,
      ),
    );
  }
}
