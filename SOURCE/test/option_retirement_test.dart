import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('active runtime has no retired app-comparison implementation', () {
    final retired = RegExp(
      r'\b(ZyraVisualComparison|isWafaPreview|onOption1|appearanceCanAct|'
      r'cachedFounderAppStyleName|setFounderAppStyleName|comparisonInk|'
      r'comparisonGoldInk|comparisonPadding|comparisonRadius)\b|'
      r'concept_design_option2|concept_design_current|'
      r'zyra\.founder_app_style|Back to new style',
    );
    final files = Directory('lib')
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in files) {
      expect(
        retired.hasMatch(file.readAsStringSync()),
        isFalse,
        reason: 'Retired comparison remains in ${file.path}',
      );
    }
    expect(File('lib/theme/zyra_visual_comparison.dart').existsSync(), isFalse);
  });

  test(
    'retirement preserves member destinations and locked Ivory return cue',
    () {
      final router = File(
        'lib/services/zyra_session_router.dart',
      ).readAsStringSync();
      expect(
        RegExp(
          r"if \(role == 'wali'\) return const WaliHomeShell\(\)",
        ).hasMatch(router),
        isTrue,
      );
      expect(
        RegExp(r'return HomeShell\(\s*initialTab: 2').hasMatch(router),
        isTrue,
      );
      final shell = File(
        'lib/dev/zyra_one_journey_concept_shell.dart',
      ).readAsStringSync();
      // LOCK 14 V5 gold accent; APP_COLOURS/MASTERS/c05_profile_tab.png.
      expect(
        RegExp(
          r'founderWhite\s*\? ZyraFounderLaunchPageStyle.darkGoldInk\s*:\s*null',
        ).hasMatch(shell),
        isTrue,
      );
      expect(shell, contains('_accountSession.palette.gradient'));
      expect(File('lib/screens/home/home_shell.dart').existsSync(), isTrue);
      expect(
        File('lib/screens/wali/wali_home_shell.dart').existsSync(),
        isTrue,
      );
    },
  );
}
