import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:zyra/screens/profile/my_profile_preview_screen.dart';
import 'package:zyra/screens/profile/profile_screen.dart';
import 'package:zyra/screens/profile/seeker_profile_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_browse_designs.dart';
import 'package:zyra/widgets/zyra_pull_down_back_scope.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _scopeKey = ValueKey('concept_pull_down_back_scope');
const _backKey = ValueKey('zyra_visible_back_button');

ZyraBrowseDesigns _ownCard(WidgetTester tester) {
  final presenter = find.byType(ZyraBrowseDesigns);
  expect(presenter, findsOneWidget);
  final rendered = tester.widget<ZyraBrowseDesigns>(presenter);
  expect(rendered.readOnlyPreview, isTrue);
  expect(rendered.design, ZyraOneJourneyBrowseDesign.portraitCard);
  expect(rendered.profiles, hasLength(1));
  expect(rendered.selectedIndex, 0);
  expect(find.byType(SeekerProfileScreen), findsNothing);
  for (final key in [
    'concept_browse_footer',
    'concept_previous_profile',
    'concept_next_profile',
    'draft_profile_my-profile-preview',
  ]) {
    expect(find.byKey(ValueKey(key)), findsOneWidget);
  }
  for (final key in [
    'concept_browse_menu',
    'concept_filters',
    'concept_save_my-profile-preview',
  ]) {
    expect(find.byKey(ValueKey(key)), findsNothing);
  }
  for (final key in [
    'concept_previous_profile',
    'concept_next_profile',
    'draft_profile_my-profile-preview',
  ]) {
    expect(tester.widget<InkWell>(find.byKey(ValueKey(key))).onTap, isNull);
  }
  expect(find.text('Request a Journey'), findsOneWidget);
  for (final title in ['My profile', 'Browse', 'Profiles']) {
    expect(find.text(title), findsNothing);
  }
  final navigation = tester.widget<FloatingNavBar>(find.byType(FloatingNavBar));
  expect(navigation.items, hasLength(5));
  expect(navigation.items.first.label, 'Profiles');
  expect(navigation.currentIndex, 0);
  expect(
    tester
        .widget<IgnorePointer>(
          find.byKey(const ValueKey('own-profile-preview-inert-navigation')),
        )
        .ignoring,
    isTrue,
  );
  expect(rendered.onPrevious, isNull);
  expect(rendered.onNext, isNull);
  expect(rendered.onFilters, isNull);
  expect(rendered.onBrowseMenu, isNull);
  expect(rendered.onProfile, isNull);
  expect(rendered.onRequest, isNull);
  expect(rendered.onSave, isNull);
  return rendered;
}

Future<void> _openOwnPreview(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: ProfileScreen())),
  );
  await tester.tap(find.text('Preview my profile'));
  await tester.pumpAndSettle();
  expect(find.byType(MyProfilePreviewScreen), findsOneWidget);
  expect(find.byKey(_backKey), findsNothing);
  expect(find.byKey(const ValueKey('zyra_back_header_space')), findsNothing);
  expect(find.byKey(const ValueKey('zyra_back_swipe_edge')), findsOneWidget);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraInternalPreviewClient.beginPreview();
    AppState.instance.applyDevPreset(
      name: 'Adam',
      gender: 'male',
      dob: DateTime(1997, 3, 14),
      location: 'London',
      plan: ZyraPlan.one,
    );
  });

  tearDown(() {
    ZyraInternalPreviewClient.finishSignOut();
    AppState.instance.resetForAccountChange();
    ZyraText.useTestFontStubs = false;
    ZyraAccountState.clearImagesForTesting = null;
    ZyraAccountState.resetForTesting();
  });

  testWidgets('own profile memory fixture decodes completely offline', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(
        base64Decode(_ownPhoto.split(',').last),
      );
      try {
        final frame = await codec.getNextFrame();
        try {
          expect(frame.image.width, 30);
          expect(frame.image.height, 40);
        } finally {
          frame.image.dispose();
        }
      } finally {
        codec.dispose();
      }
    });
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Preview my profile opens the bounded read-only card with edge return and no Back header',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ProfileScreen())),
      );

      expect(
        find.byKey(const ValueKey('preview-profile-action')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);

      await tester.tap(find.text('Preview my profile'));
      await tester.pumpAndSettle();

      expect(find.byType(MyProfilePreviewScreen), findsOneWidget);
      final previewContext = tester.element(
        find.byType(MyProfilePreviewScreen),
      );
      expect(ModalRoute.of(previewContext)!.opaque, isFalse);
      final rendered = _ownCard(tester);
      expect(rendered.profiles.single.firstName, 'Adam');
      expect(rendered.profiles.single.photos, isEmpty);
      // The ordinary account model currently supplies no public heritage
      // fields. Preview must not infer them from private answers or identity.
      expect(rendered.profiles.single.publicNationality, isNull);
      expect(rendered.profiles.single.publicEthnicity, isNull);
      expect(find.text('Nationality'), findsNothing);
      expect(find.text('Ethnicity'), findsNothing);
      final card = tester.getRect(
        find.byKey(const ValueKey('concept_browse_portrait_card')),
      );
      final viewport = tester.getRect(find.byType(MyProfilePreviewScreen));
      expect(card.width, greaterThan(0));
      expect(card.height, greaterThan(0));
      expect(card.left, greaterThan(viewport.left));
      expect(card.right, lessThan(viewport.right));
      expect(card.height, lessThan(viewport.height));
      expect(
        find.descendant(
          of: find.byType(MyProfilePreviewScreen),
          matching: find.text('Adam'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(MyProfilePreviewScreen),
          matching: find.textContaining('London'),
        ),
        findsOneWidget,
      );
      final details = find.byKey(
        const ValueKey('concept_browse_details_my-profile-preview'),
      );
      expect(details, findsOneWidget);
      expect(
        find.descendant(of: details, matching: find.text('Age')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: details, matching: find.text('Location')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: details, matching: find.byType(Image)),
        findsNothing,
      );
      expect(find.byType(SnackBar), findsNothing);
      expect(find.textContaining('building this next'), findsNothing);
      expect(find.byKey(const ValueKey('seeker-profile-close')), findsNothing);
      expect(
        find.byKey(const ValueKey('connections-profile-swipe-handle')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('seeker-profile-identity')),
        findsNothing,
      );
      expect(find.byKey(_scopeKey), findsOneWidget);
      expect(find.byKey(_backKey), findsNothing);
      expect(
        find.byKey(const ValueKey('zyra_back_swipe_edge')),
        findsOneWidget,
      );

      await swipeZyraBack(tester);
      expect(find.byType(MyProfilePreviewScreen), findsNothing);
      expect(find.text('Preview my profile'), findsOneWidget);
    },
  );

  testWidgets(
    'ordinary own card keeps center photo paging read-only and edge returns to Profile',
    (tester) async {
      _seedOwnPhotoProfile('Adam');
      AppState.instance.photos = [_ownPhoto, _ownPhoto];
      final photos = List<String>.of(AppState.instance.photos);
      final saved = List.of(AppState.instance.saved);
      final active = List.of(AppState.instance.activeJourneys);
      final potential = List.of(AppState.instance.potentialJourneys);
      final plan = AppState.instance.plan;
      await _openOwnPreview(tester);
      expect(_ownCard(tester).profiles.single.photos, photos);
      final pager = find.byKey(
        const ValueKey('concept_browse_photo_swipe_my-profile-preview'),
      );
      expect(pager, findsOneWidget);
      expect(tester.widget<PageView>(pager).controller!.page, 0);
      expect(
        find.byKey(const ValueKey('concept_browse_details_my-profile-preview')),
        findsOneWidget,
      );
      final rect = tester.getRect(pager);
      await tester.timedDragFrom(
        Offset(rect.left + rect.width * .8, rect.center.dy),
        Offset(-rect.width * .6, 0),
        const Duration(milliseconds: 450),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<PageView>(pager).controller!.page, closeTo(1, .01));
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.label == 'Photo 1 of 2',
        ),
        findsOneWidget,
      );
      expect(find.byType(MyProfilePreviewScreen), findsOneWidget);
      _ownCard(tester);
      final edge = tester.getRect(
        find.byKey(const ValueKey('zyra_back_swipe_edge')),
      );
      await tester.timedDragFrom(
        Offset(edge.left + 8, edge.top + edge.height * .35),
        const Offset(190, 0),
        const Duration(milliseconds: 450),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MyProfilePreviewScreen), findsNothing);
      expect(find.text('Preview my profile'), findsOneWidget);
      expect(AppState.instance.photos, photos);
      expect(AppState.instance.saved, saved);
      expect(AppState.instance.activeJourneys, active);
      expect(AppState.instance.potentialJourneys, potential);
      expect(AppState.instance.plan, plan);
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ordinary own preview withdraws loaded photos on owner change',
    (tester) async {
      await _bindProfileOwner(tester, 'profile-owner-a');
      _seedOwnPhotoProfile('Adam');
      await tester.pumpWidget(
        const MaterialApp(home: MyProfilePreviewScreen()),
      );
      await tester.pumpAndSettle();
      expect(_ownCard(tester).profiles.single.photos, [_ownPhoto]);

      await _bindProfileOwner(tester, 'profile-owner-b');
      _seedOwnPhotoProfile('Bilal');
      await tester.pump();
      expect(find.byType(ZyraBrowseDesigns), findsNothing);
      expect(find.byType(SeekerProfileScreen), findsNothing);
      expect(find.text('Adam'), findsNothing);
      expect(find.text('Bilal'), findsNothing);
      expect(
        find.byKey(const ValueKey('my-profile-preview-unavailable')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  testWidgets(
    'ordinary own preview cannot revive after owner A B A',
    (tester) async {
      await _bindProfileOwner(tester, 'profile-owner-a');
      _seedOwnPhotoProfile('Adam');
      await tester.pumpWidget(
        const MaterialApp(home: MyProfilePreviewScreen()),
      );
      await tester.pumpAndSettle();

      // No Flutter frame occurs between replacements. Generation, rather than
      // merely matching the final account ID, must revoke the old preview.
      await _bindProfileOwner(tester, 'profile-owner-b');
      await _bindProfileOwner(tester, 'profile-owner-a');
      _seedOwnPhotoProfile('Adam');
      await tester.pump();
      expect(find.byType(ZyraBrowseDesigns), findsNothing);
      expect(find.byType(SeekerProfileScreen), findsNothing);
      expect(
        find.byKey(const ValueKey('my-profile-preview-unavailable')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  testWidgets(
    'covered own preview removes only its revoked exact route',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await _bindProfileOwner(tester, 'profile-owner-a');
      _seedOwnPhotoProfile('Adam');
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: const Scaffold(body: Text('Profile parent')),
        ),
      );
      navigator.currentState!.push<void>(
        MaterialPageRoute(builder: (_) => const MyProfilePreviewScreen()),
      );
      await tester.pumpAndSettle();
      _ownCard(tester);
      final scope = tester.widget<ZyraPullDownBackScope>(find.byKey(_scopeKey));
      expect(scope.enabled, isTrue);
      final close = scope.onBack;
      navigator.currentState!.push<void>(
        MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Cover'))),
      );
      await tester.pumpAndSettle();

      await _bindProfileOwner(tester, 'profile-owner-b');
      close();
      await tester.pumpAndSettle();
      expect(find.text('Cover').hitTestable(), findsOneWidget);
      expect(
        find.byType(MyProfilePreviewScreen, skipOffstage: false),
        findsNothing,
      );
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('Profile parent').hitTestable(), findsOneWidget);
      expect(find.byType(ZyraBrowseDesigns), findsNothing);
      expect(find.byType(SeekerProfileScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  testWidgets(
    'no-client synthetic own preview survives a harmless theme update',
    (tester) async {
      _seedOwnPhotoProfile('Adam');
      await tester.pumpWidget(
        const MaterialApp(home: MyProfilePreviewScreen()),
      );
      await tester.pumpAndSettle();
      final original = tester.state(find.byType(MyProfilePreviewScreen));
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const MyProfilePreviewScreen(),
        ),
      );
      await tester.pumpAndSettle();
      final viewer = _ownCard(tester);
      expect(tester.state(find.byType(MyProfilePreviewScreen)), same(original));
      expect(viewer.profiles.single.firstName, 'Adam');
      expect(viewer.profiles.single.photos, [_ownPhoto]);
      expect(
        tester.widget<ZyraPullDownBackScope>(find.byKey(_scopeKey)).enabled,
        isTrue,
      );
      expect(find.byKey(_backKey), findsNothing);
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );
}

Future<void> _bindProfileOwner(WidgetTester tester, String owner) async {
  await tester.runAsync(() => ZyraAccountState.synchronize(owner));
}

final _ownPhoto = _localPhoto();

String _localPhoto() {
  final photo = img.Image(width: 30, height: 40);
  img.fill(photo, color: img.ColorRgb8(90, 70, 110));
  return 'data:image/png;base64,${base64Encode(img.encodePng(photo))}';
}

void _seedOwnPhotoProfile(String name) {
  ZyraInternalPreviewClient.beginPreview();
  AppState.instance.applyDevPreset(
    name: name,
    gender: 'male',
    dob: DateTime(1997, 3, 14),
    location: 'London',
    plan: ZyraPlan.one,
  );
  AppState.instance.photos = [_ownPhoto];
}
