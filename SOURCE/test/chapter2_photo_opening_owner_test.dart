// OA303/304/305: the real Chapter2 caller forwards its opening lifetime through
// picker, crop and save. Generated in-memory pixels, SDK sessions and allowlisted
// .invalid HTTP only. No device picker, live member, storage or checkpoint write.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
// The existing supported platform interface replaces the native picker.
// ignore: depend_on_referenced_packages
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart' show supabase;
import 'package:zyra/screens/onboarding/chapter2_flow.dart';
import 'package:zyra/screens/profile/photo_crop_review_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/onboarding_scaffold.dart';
import 'package:zyra/widgets/zyra_profile_image.dart';

const _a = '00000000-0000-4000-8000-000000003431';
const _b = '00000000-0000-4000-8000-000000003432';
const _host = 'chapter2-photo-evidence.invalid';
const _flow = ValueKey('chapter2-opening-photo-owner');
const _cover = ValueKey('unrelated-chapter2-cover');
const _deadline = Duration(seconds: 5);

Uint8List _pixels([int red = 90]) {
  final photo = img.Image(width: 60, height: 80);
  img.fill(photo, color: img.ColorRgb8(red, 65, 110));
  return img.encodePng(photo);
}

Map<String, Object?> _sessionJson(String id, {String marker = 'opening'}) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return {
    'access_token':
        '${part({'alg': 'none'})}.${part({'sub': id, 'exp': 4102444800, 'jti': marker})}.synthetic',
    'token_type': 'bearer',
    'refresh_token': 'synthetic-in-memory-only',
    'user': {
      'id': id,
      'app_metadata': <String, Object?>{},
      'user_metadata': <String, Object?>{},
      'aud': 'authenticated',
      'created_at': '2026-10-18T00:00:00Z',
    },
  };
}

Future<void> _session(String id, {bool synchronize = true}) async {
  await supabase.auth.setInitialSession(jsonEncode(_sessionJson(id)));
  if (synchronize) await ZyraAccountState.synchronize(id);
}

class _MemoryPicker extends ImagePickerPlatform {
  _MemoryPicker(this.photos, {this.release});
  final List<Uint8List> photos;
  final Completer<void>? release;
  int calls = 0;
  void releasePending() {
    final waiting = release;
    if (waiting != null && !waiting.isCompleted) waiting.complete();
  }

  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async {
    calls++;
    await release?.future.timeout(_deadline);
    return [
      for (final pixels in photos)
        XFile.fromData(pixels, mimeType: 'image/png'),
    ];
  }
}

class _NoImageNetwork extends HttpOverrides {
  int attempts = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('All Chapter2 test pixels must remain in memory.');
  }
}

class _Backend {
  final reads = <http.Request>[];
  final uploads = <http.Request>[];
  final denied = <String>[];
  Completer<void>? uploadRelease;

  void releasePending() {
    final waiting = uploadRelease;
    if (waiting != null && !waiting.isCompleted) waiting.complete();
  }

  Future<http.Response> send(http.Request request) async {
    final path = request.url.path;
    final local =
        request.url.scheme == 'https' &&
        request.url.host == _host &&
        request.url.port == 443 &&
        request.url.userInfo.isEmpty &&
        request.url.fragment.isEmpty;
    if (local &&
        request.method == 'GET' &&
        const [
          '/rest/v1/seeker_details',
          '/rest/v1/profile_photos',
          '/rest/v1/consents',
        ].contains(path)) {
      reads.add(request);
      expectSync(request.url.queryParameters['user_id'], 'eq.$_a');
      return http.Response(
        '[]',
        200,
        request: request,
        headers: {'content-type': 'application/json'},
      );
    }
    if (local &&
        request.method == 'POST' &&
        request.url.query.isEmpty &&
        path.startsWith('/storage/v1/object/profile-photos/$_a/')) {
      uploads.add(request);
      await uploadRelease?.future.timeout(_deadline);
      return http.Response(
        jsonEncode({'Key': path.substring('/storage/v1/object/'.length)}),
        200,
        request: request,
        headers: {'content-type': 'application/json'},
      );
    }
    // Signing and every later-account/profile mutation are forbidden in this
    // fixture. Ordinary positive dispatch is held until its caller unmounts.
    denied.add('${request.method} ${request.url}');
    throw StateError('Unexpected Chapter2 synthetic transport.');
  }
}

Future<void> _flush(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<void> _until(WidgetTester tester, bool Function() done) async {
  for (var frame = 0; frame < 100 && !done(); frame++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  expect(
    done(),
    isTrue,
    reason: 'Synthetic Chapter2 photo operation did not progress.',
  );
}

Future<void> _operation(
  WidgetTester tester,
  Future<void> Function() action,
) async {
  var done = false;
  Object? failure;
  StackTrace? failureStack;
  action().then<void>(
    (_) => done = true,
    onError: (Object error, StackTrace stack) {
      failure = error;
      failureStack = stack;
      done = true;
    },
  );
  await _until(tester, () => done);
  if (failure != null) Error.throwWithStackTrace(failure!, failureStack!);
}

VoidCallback _add(WidgetTester tester) => tester
    .widget<GestureDetector>(
      find
          .ancestor(
            of: find.byIcon(Icons.add_photo_alternate_outlined),
            matching: find.byType(GestureDetector),
          )
          .first,
    )
    .onTap!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ImagePickerPlatform originalPicker;
  final previousHttp = HttpOverrides.current;
  final imageNetwork = _NoImageNetwork();
  final pickers = <_MemoryPicker>[];
  late _Backend backend;
  late GlobalKey<NavigatorState> navigation;

  Widget app({
    bool preview = false,
    String gender = 'male',
    Widget? home,
  }) => MaterialApp(
    navigatorKey: navigation,
    home: home ?? Chapter2Flow(key: _flow, gender: gender, devPreview: preview),
  );

  _MemoryPicker picker(List<Uint8List> photos, {bool held = false}) {
    final selected = _MemoryPicker(
      photos,
      release: held ? Completer<void>() : null,
    );
    pickers.add(selected);
    ImagePickerPlatform.instance = selected;
    return selected;
  }

  Future<void> mount(WidgetTester tester, {bool preview = false}) async {
    if (preview) {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
      ZyraInternalPreviewClient.beginPreview();
    }
    await tester.pumpWidget(app(preview: preview));
    await _until(
      tester,
      () =>
          find
              .byIcon(Icons.add_photo_alternate_outlined)
              .evaluate()
              .isNotEmpty ||
          (preview && find.byType(ZyraProfileImage).evaluate().length == 6),
    );
    await _flush(tester);
    expect(backend.reads.length, preview ? 0 : 3);
    expect(tester.takeException(), isNull);
  }

  Future<void> crop(
    WidgetTester tester, {
    bool preview = false,
    int count = 1,
  }) async {
    picker([for (var i = 0; i < count; i++) _pixels(90 + i)]);
    _add(tester)();
    await _until(tester, () => find.byType(Crop).evaluate().isNotEmpty);
    expect(
      tester
          .widget<PhotoCropReviewScreen>(find.byType(PhotoCropReviewScreen))
          .preview,
      preview,
    );
  }

  Future<void> change(WidgetTester tester, String kind) async {
    final sync = kind != 'SDK ABA';
    await _operation(tester, () => _session(_b, synchronize: sync));
    if (kind != 'replacement') {
      await _operation(tester, () => _session(_a, synchronize: sync));
    }
    await _flush(tester);
  }

  void photoTest(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      try {
        await _operation(tester, () => _session(_a));
        AppState.instance.applyDevPreset(
          name: 'Synthetic member',
          gender: 'male',
          location: 'Synthetic city',
        );
        await body(tester);
        expect(backend.denied, isEmpty);
        expect(imageNetwork.attempts, 0);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        for (final selected in pickers) {
          selected.releasePending();
        }
        backend.releasePending();
        await _flush(tester);
        await _operation(tester, () => ZyraAccountState.synchronize(null));
        var drained = false;
        Zone.root.run(() {
          ZyraLocalPrefs.bindAccount(_a);
          ZyraLocalPrefs.bindAccount(null).then<void>((_) => drained = true);
        });
        await _until(tester, () => drained);
        expect(backend.denied, isEmpty);
      }
    }, timeout: const Timeout(Duration(seconds: 25)));
  }

  setUpAll(() async {
    originalPicker = ImagePickerPlatform.instance;
    HttpOverrides.global = imageNetwork;
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    await Supabase.initialize(
      url: 'https://$_host',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
        localStorage: EmptyLocalStorage(),
      ),
      httpClient: MockClient((request) => backend.send(request)),
    );
  });
  setUp(() {
    backend = _Backend();
    navigation = GlobalKey<NavigatorState>();
    pickers.clear();
    imageNetwork.attempts = 0;
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(false);
    ZyraInternalPreviewClient.finishSignOut();
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
  });
  tearDown(() {
    ImagePickerPlatform.instance = originalPicker;
    ZyraAccountState.clearImagesForTesting = null;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraInternalPreviewClient.finishSignOut();
    ZyraText.useTestFontStubs = false;
  });
  tearDownAll(() async {
    await Supabase.instance.dispose();
    HttpOverrides.global = previousHttp;
  });

  for (final kind in ['replacement', 'account ABA', 'SDK ABA']) {
    photoTest('picker cannot open crop or upload after $kind', (tester) async {
      await mount(tester);
      final selected = picker([_pixels()], held: true);
      final add = _add(tester);
      add();
      await _until(tester, () => selected.calls == 1);
      final generation = ZyraAccountState.generation;
      await change(tester, kind);
      selected.releasePending();
      await _flush(tester);
      add();
      await _flush(tester);
      expect(find.byType(PhotoCropReviewScreen), findsNothing);
      expect(
        find.byKey(const ValueKey('chapter2_owner_unavailable')),
        findsOneWidget,
      );
      expect(backend.uploads, isEmpty);
      expect(selected.calls, 1);
      if (kind == 'SDK ABA') {
        expect(ZyraAccountState.generation, generation);
      }
    });

    photoTest('private crop and retained approval withdraw after $kind', (
      tester,
    ) async {
      await mount(tester);
      await crop(tester);
      final approve = tester.widget<Crop>(find.byType(Crop)).onCropped;
      await change(tester, kind);
      expect(
        find.byKey(const ValueKey('crop-owner-unavailable')),
        findsOneWidget,
      );
      approve(CropSuccess(_pixels()));
      await _flush(tester);
      expect(find.byType(Crop), findsNothing);
      expect(backend.uploads, isEmpty);
      expect(tester.takeException(), isNull);
    });

    photoTest(
      'already dispatched A upload cannot sign or continue as B after $kind',
      (tester) async {
        backend.uploadRelease = Completer<void>();
        await mount(tester);
        await crop(tester, count: 2);
        // Generated approved crop-result events exercise the existing real
        // processor/save path; they do not attest manual native cropping.
        tester
            .widget<Crop>(find.byType(Crop))
            .onCropped(CropSuccess(_pixels()));
        await _flush(tester);
        tester
            .widget<Crop>(find.byType(Crop))
            .onCropped(CropSuccess(_pixels(120)));
        await _until(tester, () => backend.uploads.length == 1);
        await change(tester, kind);
        backend.releasePending();
        await _flush(tester);
        expect(backend.uploads, hasLength(1));
        expect(backend.uploads.single.url.path, contains('/$_a/'));
        expect(
          find.byKey(const ValueKey('chapter2_owner_unavailable')),
          findsOneWidget,
        );
        expect(
          backend.denied,
          isEmpty,
          reason: 'No signing, B upload, later upload or checkpoint mutation.',
        );
      },
    );
  }

  photoTest(
    'picker completion under a cover never pushes crop and releases owned busy state',
    (tester) async {
      await mount(tester);
      final selected = picker([_pixels()], held: true);
      _add(tester)();
      await _until(tester, () => selected.calls == 1);
      unawaited(
        navigation.currentState!.push<void>(
          MaterialPageRoute(
            builder: (_) =>
                const Scaffold(key: _cover, body: Text('Unrelated')),
          ),
        ),
      );
      await _flush(tester);
      selected.releasePending();
      await _until(
        tester,
        () => find
            .byIcon(Icons.add_photo_alternate_outlined, skipOffstage: false)
            .evaluate()
            .isNotEmpty,
      );
      expect(find.byKey(_cover), findsOneWidget);
      expect(
        find.byType(PhotoCropReviewScreen, skipOffstage: false),
        findsNothing,
      );
      navigation.currentState!.pop();
      await _flush(tester);
      final cancelled = picker([]);
      _add(tester)();
      await _until(
        tester,
        () =>
            cancelled.calls == 1 &&
            find
                .byIcon(Icons.add_photo_alternate_outlined)
                .evaluate()
                .isNotEmpty,
      );
      expect(backend.uploads, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  photoTest('covered and disposed Add callbacks cannot invoke the picker', (
    tester,
  ) async {
    await mount(tester);
    final selected = picker([]);
    final add = _add(tester);
    unawaited(
      navigation.currentState!.push<void>(
        MaterialPageRoute(
          builder: (_) => const Scaffold(key: _cover, body: Text('Unrelated')),
        ),
      ),
    );
    await _flush(tester);
    add();
    await _flush(tester);
    expect(selected.calls, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    add();
    await _flush(tester);
    expect(selected.calls, 0);
    expect(tester.takeException(), isNull);
  });

  for (final binding in ['mode', 'gender']) {
    photoTest('same-key $binding ABA cannot release an older picker', (
      tester,
    ) async {
      await mount(tester);
      final selected = picker([_pixels()], held: true);
      _add(tester)();
      await _until(tester, () => selected.calls == 1);
      final state = tester.state(find.byType(Chapter2Flow));
      await tester.pumpWidget(
        app(
          preview: binding == 'mode',
          gender: binding == 'gender' ? 'female' : 'male',
        ),
      );
      await _flush(tester);
      await tester.pumpWidget(app());
      await _flush(tester);
      expect(tester.state(find.byType(Chapter2Flow)), same(state));
      selected.releasePending();
      await _flush(tester);
      expect(
        find.byKey(const ValueKey('chapter2_owner_unavailable')),
        findsOneWidget,
      );
      expect(find.byType(PhotoCropReviewScreen), findsNothing);
      expect(backend.uploads, isEmpty);
    });
  }

  for (final loss in ['authority', 'preview session']) {
    photoTest(
      'protected $loss ABA never converts pending photo selection to live mode',
      (tester) async {
        await mount(tester, preview: true);
        final selected = picker([_pixels()], held: true);
        _add(tester)();
        await _until(tester, () => selected.calls == 1);
        if (loss == 'authority') {
          ZyraDeveloperAccess.setAuthorizedForTesting(false);
          ZyraDeveloperAccess.setAuthorizedForTesting(true);
        } else {
          ZyraInternalPreviewClient.finishSignOut();
          ZyraInternalPreviewClient.beginPreview();
        }
        selected.releasePending();
        await _flush(tester);
        expect(
          find.byKey(const ValueKey('chapter2_preview_denied')),
          findsOneWidget,
        );
        expect(find.byType(PhotoCropReviewScreen), findsNothing);
        expect(backend.reads, isEmpty);
        expect(backend.uploads, isEmpty);
      },
    );
  }

  photoTest(
    'healthy token refresh still allows an owned ordinary upload dispatch',
    (tester) async {
      backend.uploadRelease = Completer<void>();
      await mount(tester);
      await crop(tester);
      // ignore: invalid_use_of_internal_member
      supabase.auth.notifyAllSubscribers(
        AuthChangeEvent.tokenRefreshed,
        session: Session.fromJson(_sessionJson(_a, marker: 'refreshed')),
        broadcast: false,
      );
      await _flush(tester);
      tester.widget<Crop>(find.byType(Crop)).onCropped(CropSuccess(_pixels()));
      await _until(tester, () => backend.uploads.length == 1);
      expect(backend.uploads.single.url.host, _host);
      expect(backend.uploads.single.url.path, contains('/$_a/'));
      // Retire the caller before ACK so no signed-network image/cache or real
      // checkpoint mutation belongs to this focused positive dispatch test.
      await tester.pumpWidget(const SizedBox.shrink());
      backend.releasePending();
      await _flush(tester);
      expect(backend.denied, isEmpty);
    },
  );

  photoTest(
    'current-owner crop cancellation returns to a usable unchanged photo page',
    (tester) async {
      await mount(tester);
      await crop(tester);
      await tester.tap(find.byTooltip('Cancel photo editing'));
      await _until(
        tester,
        () =>
            find.byType(PhotoCropReviewScreen).evaluate().isEmpty &&
            find
                .byIcon(Icons.add_photo_alternate_outlined)
                .evaluate()
                .isNotEmpty,
      );
      expect(find.byType(ZyraProfileImage), findsNothing);
      final cancelled = picker([]);
      _add(tester)();
      await _until(
        tester,
        () =>
            cancelled.calls == 1 &&
            find
                .byIcon(Icons.add_photo_alternate_outlined)
                .evaluate()
                .isNotEmpty,
      );
      expect(backend.uploads, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  photoTest(
    'owned local photo batch publishes three photos and keeps the existing minimum',
    (tester) async {
      await mount(tester, preview: true);
      await crop(tester, preview: true, count: 3);
      for (var index = 0; index < 3; index++) {
        tester
            .widget<Crop>(find.byType(Crop))
            .onCropped(CropSuccess(_pixels(90 + index)));
        await _flush(tester);
      }
      await _until(
        tester,
        () => find.byType(ZyraProfileImage).evaluate().length == 3,
      );
      expect(
        tester
            .widgetList<ZyraProfileImage>(find.byType(ZyraProfileImage))
            .every((image) => image.photo.startsWith('data:image/')),
        isTrue,
      );
      expect(
        tester
            .widget<OnboardingScaffold>(find.byType(OnboardingScaffold))
            .fabActive,
        isTrue,
      );
      expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
      expect(backend.reads, isEmpty);
      expect(backend.uploads, isEmpty);
    },
  );

  photoTest('existing six-photo Chapter2 ceiling is unchanged', (tester) async {
    AppState.instance.setProfilePhotos([
      for (var index = 0; index < 6; index++)
        'data:image/png;base64,${base64Encode(_pixels(90 + index))}',
    ]);
    await mount(tester, preview: true);
    expect(find.byType(ZyraProfileImage), findsNWidgets(6));
    expect(find.byIcon(Icons.add_photo_alternate_outlined), findsNothing);
    expect(backend.reads, isEmpty);
    expect(backend.uploads, isEmpty);
  });
}
