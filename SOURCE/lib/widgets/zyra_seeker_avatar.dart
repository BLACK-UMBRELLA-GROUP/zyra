import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import 'zyra_profile_image.dart';

/// The Seeker photo-one treatment. Callers supply an already-admitted photo
/// and retain their own ring, accessibility label and layout.
class ZyraSeekerAvatar extends StatelessWidget {
  const ZyraSeekerAvatar({
    super.key,
    this.photo,
    required this.size,
    this.alignmentX = 0,
    this.alignmentY = 0,
    this.applyAvatarCrop = true,
  });

  final String? photo;
  final double size;
  final double alignmentX;
  final double alignmentY;
  final bool applyAvatarCrop;

  @override
  Widget build(BuildContext context) {
    final source = photo;
    final placeholder = ColoredBox(
      color: ZyraColors.avatarPlaceholderFill,
      child: Center(
        child: Icon(
          Icons.person,
          color: ZyraColors.avatarSand,
          size: size * 0.98,
        ),
      ),
    );
    final alignment = Alignment(alignmentX, alignmentY);
    final Widget face;
    if (source == null || source.isEmpty) {
      face = placeholder;
    } else if (source.startsWith('assets/')) {
      face = Image.asset(
        source,
        fit: BoxFit.cover,
        alignment: alignment,
        frameBuilder: (_, child, frame, synchronous) =>
            frame != null || synchronous ? child : placeholder,
        errorBuilder: (_, _, _) => placeholder,
      );
    } else if (applyAvatarCrop) {
      face = ZyraProfileImageFallback(
        fallback: Transform.scale(
          scale: 1 / ZyraAvatarImage.cropScale,
          alignment: alignment,
          child: placeholder,
        ),
        child: ZyraAvatarImage(
          source,
          width: size,
          height: size,
          alignmentX: alignmentX,
          alignmentY: alignmentY,
        ),
      );
    } else {
      face = ZyraProfileImageFallback(
        fallback: placeholder,
        child: ZyraProfileImage(
          source,
          width: size,
          height: size,
          alignment: alignment,
        ),
      );
    }
    return SizedBox.square(
      dimension: size,
      child: ClipOval(child: face),
    );
  }
}
