// Fresh review candidates only. No writes to approved visual baselines.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/wali/wali_dashboard_screen.dart';
import 'package:zyra/services/zyra_dashboard_updates_service.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_guardian_dashboard_profile_card.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';

const _capture = bool.fromEnvironment('ZYRA_GUARDIAN_PROFILE_CARD_CAPTURE');
const _root = ValueKey('guardian-profile-card-candidate');

// Existing valid local-image test probe. It is deliberately not a real person's
// portrait and exercises decoding without network requests or borrowed assets.
const _localPhoto =
    'data:image/png;base64,'
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';

void main() {
  setUpAll(() async {
    final reading = FontLoader('PoppinsAudit');
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
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), icons.load()]);
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsAudit';
  });

  setUp(() {
    ZyraColors.restoreAppPalette(null);
    ZyraColors.restoreAppSurfaceStyle(null);
    ZyraText.restoreAppFont(null);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    AppState.instance.setWaliRealLinkedSeekers(const []);
  });

  tearDown(() {
    AppState.instance.setWaliRealLinkedSeekers(const []);
    AppState.instance.waliName = null;
  });

  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
  });

  for (final width in [320.0, 390.0, 430.0]) {
    for (final textScale in [1.0, 1.4]) {
      for (final state in [
        'photo',
        'long-identity',
        'null-profile',
        'loading',
      ]) {
        testWidgets('$state width $width text $textScale', (tester) async {
          tester.view.physicalSize = Size(width, 568);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final longIdentity = state == 'long-identity';
          final person = WaliLinkedPerson(
            id: 'profile-card-seeker',
            firstName: longIdentity ? 'Aaliyah Mariam Alexandra' : 'Aaliyah',
            relationship: longIdentity ? 'brother' : 'father',
            isMain: !longIdentity,
          );
          final profile = state == 'null-profile' || state == 'loading'
              ? null
              : SeekerProfile(
                  id: person.id,
                  firstName: person.firstName,
                  surnameLine: longIdentity
                      ? 'Abdul Rahman Al-Hussaini'
                      : 'Hussain',
                  age: 27,
                  city: longIdentity
                      ? 'Stratford-upon-Avon, Warwickshire, United Kingdom'
                      : 'Birmingham, UK',
                  photos: state == 'photo' ? const [_localPhoto] : const [],
                  gender: 'female',
                );
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData.dark(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!,
              ),
              home: Scaffold(
                body: RepaintBoundary(
                  key: _root,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: ZyraColors.brandGradient,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Guardian Dashboard',
                            style: ZyraText.heading(size: 24),
                          ),
                          const SizedBox(height: 24),
                          GuardianDashboardProfileCard(
                            person: person,
                            profile: profile,
                            detailsLoading: state == 'loading',
                            onViewProfile: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          // Bounded pumping also covers a loading indicator that deliberately
          // remains active; decoding has a separate asynchronous test turn.
          await tester.pump();
          await tester.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 20));
          });
          await tester.pump(const Duration(milliseconds: 400));
          expect(find.byType(GuardianDashboardProfileCard), findsOneWidget);
          final rect = tester.getRect(
            find.byType(GuardianDashboardProfileCard),
          );
          expect(rect.left, greaterThanOrEqualTo(20));
          expect(rect.right, lessThanOrEqualTo(width - 20));
          expect(rect.bottom, lessThanOrEqualTo(548));
          expect(tester.takeException(), isNull);
          if (_capture) {
            await expectLater(
              find.byKey(_root),
              matchesGoldenFile(
                'candidates/guardian_profile_card_2026_09_27/${state}_${width.toInt()}_text_${textScale.toString().replaceAll('.', '_')}.png',
              ),
            );
          }
        });
      }
    }
  }

  for (final textScale in [1.0, 1.4]) {
    testWidgets('profile card in actual Dashboard text $textScale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      AppState.instance.waliName = 'Ibrahim';
      AppState.instance.setWaliRealLinkedSeekers(const [
        WaliLinkedPerson(
          id: 'dashboard-seeker',
          firstName: 'Aaliyah',
          relationship: 'father',
          isMain: true,
        ),
      ]);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Scaffold(
            body: RepaintBoundary(
              key: _root,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  WaliDashboardScreen(
                    hasGuardianPlus: true,
                    onOpenSeekers: () {},
                    onOpenSeeker: (_) {},
                    loadJourneys: () async => [],
                    loadUpdates: () async => ZyraDashboardUpdatesPage(
                      rows: const [],
                      nextCursor: null,
                    ),
                    loadOpenReviews: (_) async =>
                        const ZyraSourceResult.available(<String>{}),
                    loadProfiles: (_) async => const [
                      SeekerProfile(
                        id: 'dashboard-seeker',
                        firstName: 'Aaliyah',
                        age: 27,
                        city: 'Birmingham, UK',
                        photos: [_localPhoto],
                        gender: 'female',
                      ),
                    ],
                  ),
                  FloatingNavBar(
                    currentIndex: 0,
                    onTap: (_) {},
                    items: const [
                      FloatingNavItem(
                        icon: Icons.dashboard_outlined,
                        label: 'Dashboard',
                      ),
                      FloatingNavItem(icon: Icons.groups, label: 'Network'),
                      FloatingNavItem(
                        icon: Icons.people_outline,
                        label: 'Seekers',
                      ),
                      FloatingNavItem(
                        icon: Icons.person_outline,
                        label: 'Profile',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pump();
      expect(find.byType(GuardianDashboardProfileCard), findsOneWidget);
      expect(find.text('Loading profile details…'), findsNothing);
      expect(tester.takeException(), isNull);
      if (_capture) {
        await expectLater(
          find.byKey(_root),
          matchesGoldenFile(
            'candidates/guardian_profile_card_2026_09_27/dashboard_390_text_${textScale.toString().replaceAll('.', '_')}.png',
          ),
        );
      }
    });
  }
}
