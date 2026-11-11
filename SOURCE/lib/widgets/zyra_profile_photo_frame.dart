import 'package:flutter/widgets.dart';

import '../models/zyra_profile_photo_geometry.dart';

/// Gives the photo the same bounds as its crop without resizing its page.
class ZyraProfilePhotoFrame extends StatelessWidget {
  const ZyraProfilePhotoFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: AspectRatio(aspectRatio: zyraProfilePhotoAspectRatio, child: child),
  );
}
