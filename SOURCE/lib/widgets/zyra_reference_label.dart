import 'package:flutter/widgets.dart';

/// Keeps the printed identifier together while the prefix may wrap normally.
class ZyraReferenceLabel extends StatelessWidget {
  const ZyraReferenceLabel({
    super.key,
    required this.prefix,
    required this.code,
    required this.style,
    this.textAlign,
  });

  final String prefix;
  final String code;
  final TextStyle style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => Text(
    '$prefix ${code.replaceAll('-', '\u2060-\u2060')}',
    semanticsLabel: '$prefix $code',
    textAlign: textAlign,
    style: style,
  );
}
