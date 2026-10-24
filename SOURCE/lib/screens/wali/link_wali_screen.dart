import 'package:flutter/material.dart';

import 'zyra_code_screen.dart';

/// Compatibility route used by older profile and Journey entry points.
/// Every route now lands on the same permanent-code/request surface.
class LinkWaliScreen extends StatelessWidget {
  final bool asWali;

  const LinkWaliScreen({super.key, required this.asWali});

  @override
  Widget build(BuildContext context) => ZyraCodeScreen(asGuardian: asWali);
}
