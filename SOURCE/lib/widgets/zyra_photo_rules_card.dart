import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import 'zyra_floating_surface.dart';

/// Founder 24 Nov, option B. Shared by LOCK 45 and the LOCK 34 Photos step.
class ZyraPhotoRulesCard extends StatelessWidget {
  const ZyraPhotoRulesCard({super.key});

  @override
  Widget build(BuildContext context) => ZyraFloatingSurface(
    radius: 16,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: ZyraColors.surfaceFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final rule in const [
            (true, 'Just you, with your face clear'),
            (false, 'No group photos'),
            (false, 'No children or other people’s pictures'),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      rule.$1 ? Icons.check : Icons.close,
                      size: 16,
                      color: rule.$1
                          ? const Color(0xFF326B4C)
                          : const Color(0xFFAC453E),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(rule.$2, style: ZyraText.body(size: 12.5)),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
