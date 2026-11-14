import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../services/zyra_profile_video_service.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_confirm_sheet.dart';
import '../../widgets/zyra_guardian_add_card.dart'
    show ZyraGuardianDashedBorder;
import '../../widgets/zyra_profile_video_player.dart';
import '../../widgets/zyra_tap_feedback.dart';
import 'zyra_profile_video_trim_screen.dart';

/// The last tile in the LOCK 29 Photos grid. The caller owns route admission.
class ZyraManageProfileVideo extends StatefulWidget {
  const ZyraManageProfileVideo({
    super.key,
    required this.basic,
    required this.canAct,
    required this.onUpgrade,
    required this.store,
    required this.media,
  });

  final bool basic;
  final bool Function() canAct;
  final VoidCallback onUpgrade;
  final ZyraProfileVideoStore store;
  final ZyraProfileVideoMedia media;

  @override
  State<ZyraManageProfileVideo> createState() => _ZyraManageProfileVideoState();
}

class _ZyraManageProfileVideoState extends State<ZyraManageProfileVideo> {
  ZyraProfileVideoRecord? _record;
  String? _error;
  bool _busy = false;
  bool _confirming = false;
  bool _loading = true;
  File? _preview;
  Uint8List? _still;
  int _readRevision = 0;

  bool get _current => mounted && !widget.basic && widget.canAct();

  @override
  void initState() {
    super.initState();
    if (!widget.basic) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    if (!_current) return;
    try {
      final record = await widget.store.loadOwn();
      if (!_current) return;
      _showRecord(record);
    } catch (_) {
      if (_current) setState(() => _loading = false);
    }
  }

  void _showRecord(ZyraProfileVideoRecord? record) {
    final prior = _preview;
    _evictStill();
    final revision = ++_readRevision;
    setState(() {
      _record = record;
      _preview = null;
      _still = null;
      _loading = false;
      _error = null;
    });
    unawaited(_clear(prior));
    if (record != null && record.status != ZyraProfileVideoStatus.rejected) {
      unawaited(_loadPreview(record, revision));
    }
  }

  Future<void> _loadPreview(ZyraProfileVideoRecord record, int revision) async {
    File? clip;
    try {
      final bytes = await widget.store.readOwn(record);
      if (!_current || revision != _readRevision) return;
      final directory = await Directory.systemTemp.createTemp('zyra-profile-');
      clip = File('${directory.path}/preview.mp4');
      await clip.writeAsBytes(bytes, flush: true);
      final still = await widget.media.still(clip.path).catchError((_) => null);
      if (!_current || revision != _readRevision) return;
      setState(() {
        _preview = clip;
        _still = still;
      });
      clip = null;
    } catch (_) {
      // The checking state remains readable if the private still is unavailable.
    } finally {
      await _clear(clip);
    }
  }

  Future<void> _clear(File? clip) async {
    if (clip == null) return;
    try {
      await clip.parent.delete(recursive: true);
    } on FileSystemException {
      // Playback may already have cleared this temporary directory.
    }
  }

  void _evictStill() {
    final still = _still;
    if (still != null) unawaited(MemoryImage(still).evict());
  }

  Future<void> _submit(String path, Duration start, Duration duration) async {
    if (!_current) return;
    final clip = await widget.media.export(path, start);
    try {
      if (!_current) return;
      final record = await widget.store.submit(clip, duration);
      if (_current) _showRecord(record);
    } on ZyraProfileVideoRefusal catch (refusal) {
      if (_current) setState(() => _error = refusal.memberMessage);
    } catch (_) {
      if (_current) {
        setState(() {
          _error = const ZyraProfileVideoRefusal('not_a_video').memberMessage;
        });
      }
    } finally {
      try {
        await clip.delete();
      } on FileSystemException {
        // The native exporter owns only this temporary file.
      }
    }
  }

  Future<void> _pick() async {
    if (!_current || _busy || _loading) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      var again = true;
      while (again && _current) {
        again = false;
        String? path;
        try {
          final picked = await widget.media.pick();
          path = picked?.path;
          if (path == null || !_current) return;
          final info = await widget.media.inspect(path);
          if (!_current) return;
          if (info.duration <= zyraProfileVideoLimit) {
            await _submit(path, Duration.zero, info.duration);
          } else {
            again = await _trim(path, info.duration, info.videoStartMs);
          }
        } catch (_) {
          if (_current) again = await _trim(null, Duration.zero, 0);
        } finally {
          if (path != null) {
            try {
              await File(path).delete();
            } on FileSystemException {
              // The iOS gallery picker copies the selected clip into its cache.
            }
          }
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _trim(String? path, Duration duration, int videoStartMs) async {
    final navigator = Navigator.of(context);
    late final MaterialPageRoute<bool> route;
    route = MaterialPageRoute<bool>(
      builder: (context) => ZyraProfileVideoTrimScreen(
        load: () async {
          if (path == null) throw StateError('Video unavailable');
          return ZyraProfileVideoTrimData(
            duration: duration,
            frames: await widget.media.thumbnails(path),
          );
        },
        previewBuilder: (context, start, end, reduceMotion) => path == null
            ? const SizedBox.expand()
            : ZyraProfileVideoPlayer(
                path: path,
                active: _current && ModalRoute.isCurrentOf(context) == true,
                startMs: videoStartMs + start.inMilliseconds,
                durationMs: (end - start).inMilliseconds,
                stillTimeMs: start.inMilliseconds,
                reduceMotion: reduceMotion,
                playOnTapWhenReduced: false,
                obeyLowPower: false,
              ),
        onUse: (start) async {
          if (path == null || !_current) return;
          await _submit(path, start, zyraProfileVideoLimit);
          if (_current && route.isCurrent) {
            navigator.pop(false);
          }
        },
        onChooseAnother: () {
          if (route.isCurrent) navigator.pop(true);
        },
      ),
    );
    return await navigator.push(route) ?? false;
  }

  Future<void> _remove() async {
    final record = _record;
    if (!_current || _busy || _confirming || record == null) return;
    _confirming = true;
    final confirm = await showZyraConfirm(
      context: context,
      icon: Icons.play_arrow_outlined,
      title: 'Remove your video?',
      body:
          'It disappears from your profile at once. You can add a new one at any time.',
      primaryLabel: 'Remove video',
      secondaryLabel: 'Keep video',
      canConfirm: () => mounted && _record == record && !_busy,
    ).whenComplete(() => _confirming = false);
    if (confirm != true || !_current || _record != record) return;
    setState(() => _busy = true);
    try {
      await widget.store.remove();
      if (_current) _showRecord(null);
    } catch (_) {
      await _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _evictStill();
    unawaited(_clear(_preview));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.basic) {
      return ZyraPhotoGridTile(
        label: 'See Seeker One',
        onTap: widget.onUpgrade,
        border: ZyraPhotoGridTileBorder.lockedVideo,
        child: _caption(
          const Icon(
            Icons.lock_outline,
            size: 22,
            color: ZyraColors.journeyGold,
          ),
          'Video',
          'Comes with Seeker One',
          link: 'See Seeker One ›',
        ),
      );
    }
    if (_loading || _busy && _record == null) {
      return const ZyraPhotoGridTile(
        child: Center(
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ZyraColors.journeyGold,
            ),
          ),
        ),
      );
    }
    final record = _record;
    if (record == null || record.status == ZyraProfileVideoStatus.rejected) {
      return ZyraPhotoGridTile(
        label: 'Add a video',
        onTap: _busy ? null : _pick,
        child: _caption(
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: ZyraColors.journeyGold.withValues(alpha: .6),
              ),
            ),
            child: const Icon(Icons.play_arrow, color: ZyraColors.journeyGold),
          ),
          'Add a video',
          'Up to 10 seconds · no sound',
          reason: _error ?? record?.reason,
        ),
      );
    }
    final checking = record.status == ZyraProfileVideoStatus.pending;
    final still = _still;
    final file = _preview;
    final stillView = still == null
        ? const ColoredBox(color: Color(0xFFD9CBB5))
        : Image.memory(still, fit: BoxFit.cover);
    return ZyraPhotoGridTile(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (checking || file == null)
            stillView
          else
            ZyraProfileVideoPlayer(
              path: file.path,
              active:
                  TickerMode.valuesOf(context).enabled &&
                  ModalRoute.isCurrentOf(context) != false,
              still: stillView,
            ),
          if (checking)
            ColoredBox(
              color: ZyraColors.ivoryTop.withValues(alpha: .62),
              child: _caption(
                _pill('Being checked'),
                null,
                'Only you can see it for now',
              ),
            )
          else ...[
            Positioned(
              left: 10,
              top: 10,
              child: _pill(
                '${(record.duration.inMilliseconds / 1000).ceil()} s',
                video: true,
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: IconButton(
                tooltip: 'Remove video',
                onPressed: _busy
                    ? null
                    : ZyraTapFeedback.onTap(context, _remove),
                icon: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ZyraColors.ivoryTop.withValues(alpha: .92),
                  ),
                  child: const Icon(Icons.close, size: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _caption(
    Widget leading,
    String? title,
    String detail, {
    String? link,
    String? reason,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        leading,
        if (title != null) ...[
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: ZyraText.body(size: 14),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: ZyraText.subtext(size: 11),
        ),
        if (link != null)
          Text(
            link,
            textAlign: TextAlign.center,
            style: ZyraText.body(size: 11, color: ZyraColors.goldText),
          ),
        if (reason != null)
          Text(
            reason,
            textAlign: TextAlign.center,
            style: ZyraText.body(size: 11, color: ZyraColors.dangerText),
          ),
      ],
    ),
  );

  Widget _pill(String text, {bool video = false}) => DecoratedBox(
    decoration: BoxDecoration(
      color: video ? const Color(0x99000000) : ZyraColors.ivoryTop,
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: ZyraColors.divider),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (video) ...[
            const Icon(
              Icons.volume_off_outlined,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: ZyraText.body(
                size: 12,
                color: video ? Colors.white : null,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

enum ZyraPhotoGridTileBorder { standard, mainPhoto, lockedVideo }

class ZyraPhotoGridTile extends StatelessWidget {
  const ZyraPhotoGridTile({
    super.key,
    required this.child,
    this.label,
    this.onTap,
    this.border = ZyraPhotoGridTileBorder.standard,
  });

  final Widget child;
  final String? label;
  final VoidCallback? onTap;
  final ZyraPhotoGridTileBorder border;

  @override
  Widget build(BuildContext context) {
    const cornerRadius = 18.0;
    const radius = BorderRadius.all(Radius.circular(cornerRadius));
    final side = switch (border) {
      ZyraPhotoGridTileBorder.standard => BorderSide(
        color: ZyraColors.surfaceBorder,
      ),
      ZyraPhotoGridTileBorder.mainPhoto => const BorderSide(
        color: ZyraColors.journeyGold,
        width: 1.5,
      ),
      ZyraPhotoGridTileBorder.lockedVideo => BorderSide.none,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: ZyraColors.cardShadows,
      ),
      child: CustomPaint(
        foregroundPainter: border == ZyraPhotoGridTileBorder.lockedVideo
            ? ZyraGuardianDashedBorder(
                cornerRadius,
                ZyraColors.journeyGold.withValues(alpha: .5),
              )
            : null,
        child: Material(
          color: ZyraColors.cardSurface,
          shape: RoundedRectangleBorder(borderRadius: radius, side: side),
          clipBehavior: Clip.antiAlias,
          child: onTap == null
              ? child
              : Semantics(
                  label: label,
                  button: true,
                  child: InkWell(
                    onTap: ZyraTapFeedback.onTap(context, onTap),
                    child: child,
                  ),
                ),
        ),
      ),
    );
  }
}
