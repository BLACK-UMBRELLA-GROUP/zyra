import 'zyra_developer_title.dart';
import 'package:flutter/material.dart';

import '../theme/zyra_text.dart';

/// The heading at the top of a main tab. Each tab owns its surrounding layout.
class ZyraTabTitle extends StatelessWidget {
  const ZyraTabTitle(
    this.title, {
    super.key,
    this.textKey,
    this.textScaler,
    this.developerTitle = true,
  });

  final String title;
  final Key? textKey;
  final TextScaler? textScaler;
  final bool developerTitle;

  @override
  Widget build(BuildContext context) {
    final heading = ValueListenableBuilder(
      valueListenable: ZyraText.appFontSelection,
      builder: (context, _, child) => Text(
        title,
        key: textKey,
        style: ZyraText.pageTitle(),
        textAlign: TextAlign.left,
        textScaler: textScaler,
      ),
    );
    return developerTitle ? ZyraDeveloperTitle(child: heading) : heading;
  }
}
