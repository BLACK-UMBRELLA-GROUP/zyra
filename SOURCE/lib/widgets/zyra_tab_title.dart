import 'package:flutter/material.dart';

import '../theme/zyra_text.dart';

/// The heading at the top of a main tab. Each tab owns its surrounding layout.
class ZyraTabTitle extends StatelessWidget {
  const ZyraTabTitle(this.title, {super.key, this.textKey, this.textScaler});

  final String title;
  final Key? textKey;
  final TextScaler? textScaler;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: ZyraText.appFontSelection,
    builder: (context, _, child) => Text(
      title,
      key: textKey,
      style: ZyraText.pageTitle(),
      textAlign: TextAlign.left,
      textScaler: textScaler,
    ),
  );
}
