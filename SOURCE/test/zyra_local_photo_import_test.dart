// Synthetic memory-only imports. No device library, Auth or Storage access.
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_local_photo_import.dart';
import 'package:zyra/services/zyra_photo_service.dart';

const _gallery = ['data:image/jpeg;base64,c3ludGhldGlj'];

ZyraPhotoSelectionResult _selected([int count = 1]) =>
    ZyraPhotoSelectionResult.selected([
      for (var i = 0; i < count; i++) Uint8List.fromList([i + 1]),
    ]);

void main() {
  test('requires both owner retention and fresh admission to open picker', () {
    var retain = true;
    var admit = false;
    var picks = 0;
    final imports = ZyraLocalPhotoImport(
      canRetain: () => retain,
      canAdmit: () => admit,
      admissionEpoch: () => 0,
      pick: (_) async {
        picks++;
        return _selected();
      },
    );
    expect(imports.begin(photos: _gallery), isNull);
    admit = true;
    retain = false;
    expect(imports.begin(photos: _gallery), isNull);
    expect(picks, 0);
    imports.dispose();
  });

  test('rejects invalid quota and simultaneous second picker', () async {
    final gate = Completer<ZyraPhotoSelectionResult>();
    var picks = 0;
    final imports = ZyraLocalPhotoImport(
      canRetain: () => true,
      canAdmit: () => true,
      admissionEpoch: () => 0,
      pick: (_) {
        picks++;
        return gate.future;
      },
    );
    expect(imports.begin(photos: List.filled(5, _gallery.single)), isNull);
    expect(imports.begin(photos: List.filled(6, _gallery.single)), isNull);
    final request = imports.begin(photos: _gallery)!;
    expect(imports.begin(photos: _gallery), isNull);
    expect(picks, 1);
    gate.complete(_selected());
    expect((await request.selection).photos, hasLength(1));
    imports.dispose();
  });

  for (final selectionBeforeProof in [true, false]) {
    test(
      'only a fresh consumer resumes selection: $selectionBeforeProof',
      () async {
        var admit = true;
        var epoch = 0;
        final gate = Completer<ZyraPhotoSelectionResult>();
        final imports = ZyraLocalPhotoImport(
          canRetain: () => true,
          canAdmit: () => admit,
          admissionEpoch: () => epoch,
          pick: (_) => gate.future,
        );
        final request = imports.begin(photos: _gallery)!;
        final old = Object(), fresh = Object();
        expect(imports.claim(request, old), isTrue);
        expect(imports.claim(request, fresh), isFalse);
        admit = false;
        expect(imports.pending, same(request));
        expect(imports.isCurrent(request, old), isFalse);
        expect(imports.claim(request, fresh), isFalse);
        if (selectionBeforeProof) gate.complete(_selected());
        admit = true;
        epoch++;
        expect(imports.isCurrent(request, old), isFalse);
        expect(imports.claim(request, fresh), isTrue);
        if (!selectionBeforeProof) gate.complete(_selected());
        expect((await request.selection).photos, hasLength(1));
        imports.finish(request, old);
        expect(imports.pending, same(request));
        expect(imports.isCurrent(request, old), isFalse);
        expect(imports.isCurrent(request, fresh), isTrue);
        imports.finish(request, fresh);
        expect(imports.pending, isNull);
        expect(imports.claim(request, fresh), isFalse);
        imports.dispose();
      },
    );
  }

  test(
    'denial clears pending selection and late native result is inert',
    () async {
      var retain = true;
      final gate = Completer<ZyraPhotoSelectionResult>();
      final imports = ZyraLocalPhotoImport(
        canRetain: () => retain,
        canAdmit: () => true,
        admissionEpoch: () => 0,
        pick: (_) => gate.future,
      );
      final request = imports.begin(photos: _gallery)!;
      retain = false;
      imports.synchronize();
      expect(
        (await request.selection).outcome,
        ZyraPhotoSelectionOutcome.cancelled,
      );
      gate.complete(_selected());
      await Future<void>.delayed(Duration.zero);
      retain = true;
      expect(imports.pending, isNull);
      expect(imports.claim(request, Object()), isFalse);
      imports.dispose();
    },
  );

  test('a cancelled picker cannot populate a newer request', () async {
    final gates = [
      Completer<ZyraPhotoSelectionResult>(),
      Completer<ZyraPhotoSelectionResult>(),
    ];
    var picks = 0;
    final imports = ZyraLocalPhotoImport(
      canRetain: () => true,
      canAdmit: () => true,
      admissionEpoch: () => 0,
      pick: (_) => gates[picks++].future,
    );
    final first = imports.begin(photos: _gallery)!;
    imports.cancel();
    final second = imports.begin(photos: _gallery)!;
    gates.first.complete(_selected(2));
    await Future<void>.delayed(Duration.zero);
    expect(imports.pending, same(second));
    expect(
      (await first.selection).outcome,
      ZyraPhotoSelectionOutcome.cancelled,
    );
    gates.last.complete(_selected());
    expect((await second.selection).photos, hasLength(1));
    imports.dispose();
  });

  test(
    'throwing retention check denies and throwing picker gives safe error',
    () async {
      var deny = false;
      final imports = ZyraLocalPhotoImport(
        canRetain: () => deny ? throw StateError('synthetic') : true,
        canAdmit: () => true,
        admissionEpoch: () => 0,
        pick: (_) => throw StateError('synthetic picker'),
      );
      final request = imports.begin(photos: _gallery)!;
      expect(
        (await request.selection).outcome,
        ZyraPhotoSelectionOutcome.error,
      );
      deny = true;
      expect(imports.pending, isNull);
      imports.dispose();
    },
  );

  test('oversized platform selection is never forwarded for review', () async {
    final imports = ZyraLocalPhotoImport(
      canRetain: () => true,
      canAdmit: () => true,
      admissionEpoch: () => 0,
      pick: (_) async => _selected(5),
    );
    final request = imports.begin(photos: _gallery)!;
    expect((await request.selection).outcome, ZyraPhotoSelectionOutcome.error);
    expect((await request.selection).photos, isEmpty);
    imports.dispose();
  });

  test(
    'dispose permanently closes buffer and releases waiting editor',
    () async {
      final gate = Completer<ZyraPhotoSelectionResult>();
      final imports = ZyraLocalPhotoImport(
        canRetain: () => true,
        canAdmit: () => true,
        admissionEpoch: () => 0,
        pick: (_) => gate.future,
      );
      final request = imports.begin(photos: _gallery)!;
      imports.dispose();
      gate.complete(_selected());
      expect(
        (await request.selection).outcome,
        ZyraPhotoSelectionOutcome.cancelled,
      );
      expect(imports.begin(photos: _gallery), isNull);
      expect(imports.claim(request, Object()), isFalse);
      expect(imports.pending, isNull);
    },
  );

  test('starting gallery and avatar are detached and local-only', () async {
    final photos = List<String>.of(_gallery);
    final imports = ZyraLocalPhotoImport(
      canRetain: () => true,
      canAdmit: () => true,
      admissionEpoch: () => 0,
      pick: (_) async => _selected(),
    );
    expect(imports.begin(photos: ['https://photo.invalid/member.jpg']), isNull);
    expect(imports.begin(photos: photos, alignmentX: double.nan), isNull);
    expect(imports.begin(photos: photos, alignmentY: 2), isNull);
    final request = imports.begin(
      photos: photos,
      alignmentX: .3,
      alignmentY: -.2,
    )!;
    photos.clear();
    expect(request.startingPhotos, _gallery);
    expect(request.remaining, 4);
    expect(request.alignmentX, .3);
    expect(request.alignmentY, -.2);
    expect(() => request.startingPhotos.clear(), throwsUnsupportedError);
    await request.selection;
    imports.dispose();
  });
}
