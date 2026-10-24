// Local comparison candidates, never approved baseline replacements.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_menu_directions.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

const _capture = bool.fromEnvironment('ZYRA_MENU_CAPTURE');
const _boundary = ValueKey('menu-candidate');
const _directory = 'candidates/mobile_menu_2026_10_07';

Future<void> _candidate(WidgetTester tester, String name) async {
  if (!_capture) return;
  expect(autoUpdateGoldenFiles, isTrue);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await expectLater(
        bytes!.buffer.asUint8List(),
        matchesGoldenFile('$_directory/$name.png'),
      );
    } finally {
      image.dispose();
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final reading = FontLoader('PoppinsMenuPreview');
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      reading.addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Poppins-$weight.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    final wordmark = FontLoader('SyneMenuPreview')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Syne-SemiBold.ttf').readAsBytesSync(),
          ),
        ),
      );
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), wordmark.load(), icons.load()]);
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsMenuPreview';
    ZyraText.testWordmarkFontFamily = 'SyneMenuPreview';
  });
  setUp(() {
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevMenuDesign.instance.resetForTesting();
  });
  tearDown(() {
    ZyraDevMenuDesign.instance.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
  });
  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraText.testWordmarkFontFamily = null;
  });
  for (final guardian in [false, true]) {
    for (final design in ZyraMenuDesign.values.skip(1)) {
      testWidgets(
        '${guardian ? 'Guardian' : 'Seeker'} ${design.label} real-font comparison',
        (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final selection = ZyraDevMenuDesign.instance;
          selection.select(
            design,
            expectedGeneration: ZyraAccountState.generation,
            expectedRevision: selection.revision,
          );
          final items = guardian
              ? const [
                  FloatingNavItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    badge: 3,
                  ),
                  FloatingNavItem(
                    icon: Icons.diversity_3_outlined,
                    label: 'Network',
                    dimmed: true,
                  ),
                  FloatingNavItem(icon: Icons.people_outline, label: 'Seekers'),
                  FloatingNavItem(icon: Icons.person_outline, label: 'Profile'),
                ]
              : const [
                  FloatingNavItem(icon: Icons.search, label: 'Browse'),
                  FloatingNavItem(
                    icon: Icons.bookmark_border,
                    label: 'Connections',
                    dot: true,
                  ),
                  FloatingNavItem(
                    icon: Icons.dashboard_outlined,
                    label: 'My ZYRA',
                    badge: 3,
                  ),
                  FloatingNavItem(
                    icon: Icons.gpp_good_outlined,
                    label: 'Guardian',
                  ),
                  FloatingNavItem(icon: Icons.person_outline, label: 'Profile'),
                ];
          await tester.pumpWidget(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData.dark(),
              builder: (context, child) => RepaintBoundary(
                key: _boundary,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    padding: const EdgeInsets.only(top: 44, bottom: 34),
                    viewPadding: const EdgeInsets.only(top: 44, bottom: 34),
                    disableAnimations: true,
                  ),
                  child: child!,
                ),
              ),
              home: Scaffold(
                body: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: ZyraColors.brandGradient,
                        ),
                      ),
                    ),
                    ZyraMenuCanvas(
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'ZYRA',
                                style: ZyraText.wordmark(size: 22),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 44),
                              Text(
                                guardian ? 'Dashboard' : 'My ZYRA',
                                style: ZyraText.heading(size: 32),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Menu comparison',
                                style: ZyraText.subtext(size: 15),
                              ),
                              const SizedBox(height: 30),
                              for (final title in [
                                'Your Journey',
                                'Your profile',
                                'Guardian support',
                              ])
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: ZyraColors.surfaceFill,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: ZyraColors.surfaceBorder,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(22),
                                      child: Text(
                                        title,
                                        style: ZyraText.body(size: 17),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ZyraShellNavigation(
                      items: items,
                      currentIndex: guardian ? 0 : 2,
                      onTap: (_) {},
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final prefix = '${guardian ? 'guardian' : 'seeker'}_${design.name}';
          await _candidate(tester, '${prefix}_closed');
          if (design.opensMenu) {
            await tester.tap(find.byKey(const ValueKey('menu-open')));
            await tester.pumpAndSettle();
            await _candidate(tester, '${prefix}_open');
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
}
