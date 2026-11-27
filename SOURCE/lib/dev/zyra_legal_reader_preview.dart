import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../services/zyra_account_state.dart';
import '../services/zyra_developer_access.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_floating_surface.dart';
import '../widgets/zyra_developer_title.dart';
import '../widgets/zyra_guardian_preview_lifetime.dart';
import '../widgets/zyra_tap_feedback.dart';
import 'zyra_help_safety_preview.dart';
import 'zyra_legal_preview_content.dart';
import 'zyra_dev_scenario.dart';
import 'zyra_preview_navigation_checkpoint.dart';

/// Opens a local LOCK 51 reader from an authorised preview surface.
Future<void> openZyraLegalReader(
  BuildContext context,
  ZyraLegalPreviewDocument document, {
  required bool Function() canOpen,
  required bool Function() canRetain,
  bool signup = false,
  VoidCallback? onReturn,
}) async {
  if (!context.mounted) return;
  final origin = ModalRoute.of(context);
  if (origin == null || !origin.isCurrent || !canOpen()) return;
  final accountGeneration = ZyraAccountState.generation;
  final navigator = Navigator.of(context);
  final authority = context
      .findAncestorWidgetOfExactType<ZyraGuardianPreviewRouteBoundary>()
      ?.authority;
  final ownedNavigator = context
      .getInheritedWidgetOfExactType<ZyraDeveloperOwnedNavigatorScope>();
  final bridge = ZyraDeveloperSeekerScope.bridgeOf(context);
  final changes = Listenable.merge([
    ?authority,
    ?ownedNavigator?.bridge,
    if (!identical(bridge, ownedNavigator?.bridge)) ?bridge,
    ZyraDevScenario.instance,
    ZyraDeveloperAccess.authorizationChanges,
    ZyraPreviewRouteObserver.navigationChanges,
  ]);
  bool retained() =>
      context.mounted &&
      origin.isActive &&
      !ZyraAccountState.isSigningOut &&
      accountGeneration == ZyraAccountState.generation &&
      canRetain();

  late final PageRoute<void> route;
  Widget buildReader(BuildContext readerContext) {
    return _LegalRouteBoundary(
      canRetain: retained,
      changes: changes,
      origin: origin,
      child: Scaffold(
        backgroundColor: ZyraColors.ivoryTop,
        body: retained()
            ? ZyraLegalReaderPreview(
                initialDocument: document,
                canAct: retained,
                onContact: () {
                  if (!retained() || !route.isCurrent) return;
                  if (signup) {
                    ScaffoldMessenger.maybeOf(readerContext)?.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Opens the support form — no sign-in needed.',
                        ),
                      ),
                    );
                  } else {
                    navigator.push(
                      _legalRoute(
                        readerContext,
                        (context) => _LegalRouteBoundary(
                          canRetain: retained,
                          changes: changes,
                          origin: route,
                          child: _LegalPreviewSupport(canRetain: retained),
                        ),
                      ),
                    );
                  }
                },
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  route = _legalRoute(context, buildReader);
  await navigator.push(route);
  if (retained() && origin.isCurrent) onReturn?.call();
}

PageRoute<void> _legalRoute(BuildContext context, WidgetBuilder builder) =>
    Theme.of(context).platform == TargetPlatform.iOS
    ? CupertinoPageRoute<void>(builder: builder)
    : MaterialPageRoute<void>(builder: builder);

/// The reader and its children withdraw with their exact retained owner.
/// Removal is deferred out of navigator notifications and never pops a sibling.
class _LegalRouteBoundary extends StatefulWidget {
  const _LegalRouteBoundary({
    required this.canRetain,
    required this.changes,
    required this.origin,
    required this.child,
  });

  final bool Function() canRetain;
  final Listenable changes;
  final Route<dynamic> origin;
  final Widget child;

  _LegalRouteBoundary wrap(Widget child, Route<dynamic> origin) =>
      _LegalRouteBoundary(
        canRetain: canRetain,
        changes: changes,
        origin: origin,
        child: child,
      );

  @override
  State<_LegalRouteBoundary> createState() => _LegalRouteBoundaryState();
}

class _LegalRouteBoundaryState extends State<_LegalRouteBoundary> {
  ModalRoute<dynamic>? _route;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    widget.changes.addListener(_changed);
    widget.origin.popped.then((_) {
      if (mounted) _withdraw();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
    _changed();
  }

  void _changed() {
    if (mounted && !widget.canRetain()) _withdraw();
  }

  void _withdraw() {
    if (_closing) return;
    _closing = true;
    final binding = WidgetsBinding.instance;
    if (binding.schedulerPhase != SchedulerPhase.persistentCallbacks) {
      setState(() {});
    }
    binding.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = _route;
      if (route != null && route.isActive && !route.isFirst) {
        route.navigator?.removeRoute(route);
      }
    });
    binding.ensureVisualUpdate();
  }

  @override
  void dispose() {
    widget.changes.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      !_closing && widget.canRetain() ? widget.child : const SizedBox.shrink();
}

// The reader opens the existing LOCK 37 sample contact presentation. This
// route has no inbox integration and shares the launcher's preview lifetime.
class _LegalPreviewSupport extends StatefulWidget {
  const _LegalPreviewSupport({required this.canRetain});

  final bool Function() canRetain;

  @override
  State<_LegalPreviewSupport> createState() => _LegalPreviewSupportState();
}

class _LegalPreviewSupportState extends State<_LegalPreviewSupport> {
  bool _sent = false;

  bool _canAct() =>
      mounted &&
      widget.canRetain() &&
      ModalRoute.of(context)?.isCurrent == true;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: !widget.canRetain()
        ? const SizedBox.shrink()
        : ZyraHelpSafetyPreview(
            key: ValueKey(_sent),
            screen: _sent
                ? ZyraHelpSafetyScreen.contactSent
                : ZyraHelpSafetyScreen.contact,
            guardian: false,
            firstName: '',
            onContactSent: () {
              if (_canAct()) setState(() => _sent = true);
            },
            onReportDone: _unused,
            onBlockReported: _unused,
            onOpenData: _unused,
            onOpenDelete: _unused,
            onRequestData: _unused,
            onDelete: _unused,
            onClose: _unused,
            onDone: () {
              if (_canAct()) Navigator.of(context).pop();
            },
            onLegal: (_) {},
            onSubscriptions: _unused,
          ),
  );

  static void _unused() {}
}

class ZyraLegalReaderPreview extends StatefulWidget {
  const ZyraLegalReaderPreview({
    super.key,
    required this.initialDocument,
    required this.canAct,
    required this.onContact,
  });

  final ZyraLegalPreviewDocument initialDocument;
  final bool Function() canAct;
  final VoidCallback onContact;

  @override
  State<ZyraLegalReaderPreview> createState() => _ZyraLegalReaderPreviewState();
}

class _ZyraLegalReaderPreviewState extends State<ZyraLegalReaderPreview> {
  final _reading = ScrollController();
  final _chips = ScrollController();
  late ZyraLegalPreviewDocument _document;
  late List<GlobalKey> _sections;
  late List<GlobalKey> _chipPositions;
  int _activeSection = 0;
  int _jumpRevision = 0;
  bool _jumping = false;
  bool _sheetOpen = false;

  ZyraLegalPreviewPage get _page => zyraLegalPreviewPages[_document]!;

  bool _canUseReader() =>
      mounted && widget.canAct() && (ModalRoute.of(context)?.isCurrent ?? true);

  @override
  void initState() {
    super.initState();
    _setDocument(widget.initialDocument);
    _reading.addListener(_readPosition);
  }

  void _setDocument(ZyraLegalPreviewDocument document) {
    _document = document;
    _sections = List.generate(_page.sections.length, (_) => GlobalKey());
    _chipPositions = List.generate(_page.sections.length, (_) => GlobalKey());
    _activeSection = 0;
  }

  void _readNext(ZyraLegalPreviewDocument document) {
    if (!_canUseReader()) return;
    _jumpRevision++;
    _jumping = true;
    if (_reading.hasClients) _reading.jumpTo(0);
    if (_chips.hasClients) _chips.jumpTo(0);
    setState(() => _setDocument(document));
    _jumping = false;
  }

  @override
  void dispose() {
    _reading.dispose();
    _chips.dispose();
    super.dispose();
  }

  double? _offset(GlobalKey key) {
    final render = key.currentContext?.findRenderObject();
    if (render == null || !render.attached) return null;
    return RenderAbstractViewport.maybeOf(
      render,
    )?.getOffsetToReveal(render, 0).offset;
  }

  void _readPosition() {
    if (_jumping || !_reading.hasClients) return;
    final position = _reading.position;
    if (!position.hasContentDimensions) return;
    if (position.maxScrollExtent > 0 && position.extentAfter <= 4) {
      _select(_sections.length - 1);
      return;
    }
    final threshold = position.pixels + 90;
    var active = 0;
    for (var i = 1; i < _sections.length; i++) {
      final start = _offset(_sections[i]);
      if (start == null || start > threshold) break;
      active = i;
    }
    _select(active);
  }

  void _select(int section) {
    if (!mounted || section == _activeSection) return;
    setState(() => _activeSection = section);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_chips.hasClients || _activeSection != section) return;
      final chip = _offset(_chipPositions[section]);
      if (chip == null) return;
      final target = (chip - 60).clamp(0.0, _chips.position.maxScrollExtent);
      _chips.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _jumpToSection(int section) async {
    if (!_canUseReader() || !_reading.hasClients) return;
    final offset = _offset(_sections[section]);
    if (offset == null) return;
    final revision = ++_jumpRevision;
    _jumping = true;
    _select(section);
    await _reading.animateTo(
      (offset - 8).clamp(0.0, _reading.position.maxScrollExtent),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
    if (!mounted || revision != _jumpRevision) return;
    _jumping = false;
    _readPosition();
  }

  Future<void> _showSections() async {
    if (!_canUseReader() || _sheetOpen) return;
    _sheetOpen = true;
    final document = _document;
    final sections = _page.sections;
    final owner = context.findAncestorWidgetOfExactType<_LegalRouteBoundary>();
    final origin = ModalRoute.of(context)!;
    final section = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x611E1610),
      barrierLabel: 'Close',
      useSafeArea: false,
      isScrollControlled: true,
      builder: (context) {
        final sheet = LayoutBuilder(
          builder: (context, bounds) => ConstrainedBox(
            constraints: BoxConstraints(maxHeight: bounds.maxHeight * .76),
            child: Material(
              key: const ValueKey('legal_sections_sheet'),
              color: ZyraColors.confirmSheetSurface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
              clipBehavior: Clip.antiAlias,
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(17, 10, 17, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 3,
                        decoration: BoxDecoration(
                          color: ZyraColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 13, 8, 8),
                      child: _label(
                        'ON THIS PAGE · ${sections.length} SECTIONS',
                      ),
                    ),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: sections.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, color: ZyraColors.divider),
                        itemBuilder: (context, index) => InkWell(
                          key: ValueKey('legal_sheet_section_$index'),
                          onTap: ZyraTapFeedback.onTap(context, () {
                            if (widget.canAct() &&
                                ModalRoute.of(context)?.isCurrent == true) {
                              Navigator.of(context).pop(index);
                            }
                          }, canAct: widget.canAct),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 51),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(4, 12, 4, 12),
                              child: _numbered(
                                index,
                                sections[index].heading,
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        return owner?.wrap(sheet, origin) ?? sheet;
      },
    );
    _sheetOpen = false;
    if (section != null && _canUseReader() && document == _document) {
      await _jumpToSection(section);
    }
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: ValueKey('legal_reader_${_document.name}'),
    decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
    child: SafeArea(
      bottom: false,
      minimum: const EdgeInsets.only(top: 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _readerTitle(),
                const SizedBox(height: 3),
                Text(
                  'Last updated ${_page.date}',
                  style: ZyraText.body(
                    size: 12.5,
                    color: ZyraColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          _chipRow(),
          Expanded(
            child: SingleChildScrollView(
              key: const ValueKey('legal_reading_scroll'),
              controller: _reading,
              padding: EdgeInsets.fromLTRB(
                22,
                8,
                22,
                math.max(22, MediaQuery.viewPaddingOf(context).bottom),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_page.summary case final summary?)
                    _inShort(summary)
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
                      child: Text(
                        _page.lead!,
                        style: ZyraText.heading(
                          size: 17,
                        ).copyWith(height: 1.45),
                      ),
                    ),
                  for (var i = 0; i < _page.sections.length; i++) ...[
                    const SizedBox(height: 26),
                    _section(i, _page.sections[i]),
                  ],
                  const SizedBox(height: 32),
                  _readNextCard(),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 4,
                    children: [
                      Text(
                        'Also on the web at',
                        style: ZyraText.body(
                          size: 12,
                          color: ZyraColors.secondaryStrong,
                        ),
                      ),
                      Text(
                        _page.webAddress,
                        style: ZyraText.body(
                          size: 12,
                          color: ZyraColors.espresso,
                        ).copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _readerTitle() {
    final style = ZyraText.pageTitle().copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w300,
      letterSpacing: .2,
      height: 1.15,
    );
    return LayoutBuilder(
      builder: (context, bounds) {
        final measured = TextPainter(
          text: TextSpan(text: _page.title, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout(maxWidth: bounds.maxWidth);
        final wrapPhotos =
            _document == ZyraLegalPreviewDocument.photos &&
            measured.didExceedMaxLines;
        measured.dispose();
        final words = _page.title.split(' ');
        final split = (words.length + 1) ~/ 2;
        return Semantics(
          header: true,
          label: wrapPhotos ? _page.title : null,
          excludeSemantics: wrapPhotos,
          child: Text(
            wrapPhotos
                ? '${words.take(split).join(' ')}\n${words.skip(split).join(' ')}'
                : _page.title,
            style: style,
          ),
        );
      },
    );
  }

  Widget _chipRow() => SingleChildScrollView(
    controller: _chips,
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(21, 2, 21, 16),
    child: Row(
      children: [
        Tooltip(
          message: 'All sections',
          child: _chip(
            index: null,
            label: const Icon(
              Icons.format_list_bulleted,
              size: 17,
              color: Color(0xFF845F24),
            ),
            onTap: _showSections,
          ),
        ),
        for (var i = 0; i < _page.sections.length; i++) ...[
          const SizedBox(width: 8),
          KeyedSubtree(
            key: _chipPositions[i],
            child: _chip(
              index: i,
              label: Text(
                '${i + 1} · ${_page.sections[i].chip}',
                softWrap: false,
                style: ZyraText.body(
                  size: 12.5,
                  color: _activeSection == i
                      ? const Color(0xFF845F24)
                      : ZyraColors.espresso,
                ),
              ),
              onTap: () => _jumpToSection(i),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _chip({
    required int? index,
    required Widget label,
    required VoidCallback onTap,
  }) {
    final selected = index == _activeSection;
    return Semantics(
      selected: index != null ? selected : null,
      child: Material(
        color: selected
            ? ZyraColors.journeyGold.withValues(alpha: .08)
            : ZyraColors.cardSurface,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? ZyraColors.journeyGold : ZyraColors.divider,
          ),
        ),
        child: InkWell(
          key: ValueKey(
            index == null ? 'legal_all_sections' : 'legal_chip_$index',
          ),
          customBorder: const StadiumBorder(),
          onTap: ZyraTapFeedback.onTap(context, onTap, canAct: _canUseReader),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: index == null ? 10 : 13,
              vertical: 7,
            ),
            child: label,
          ),
        ),
      ),
    );
  }

  Widget _inShort(List<String> points) => _card(
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('IN SHORT'),
          const SizedBox(height: 7),
          for (final point in points)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check,
                      size: 16,
                      color: ZyraColors.journeyGold,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      point,
                      style: ZyraText.body(
                        size: 14,
                      ).copyWith(height: 1.5, letterSpacing: 0),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );

  Widget _section(int index, ZyraLegalPreviewSection section) => Column(
    key: _sections[index],
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(
        header: true,
        child: _numbered(index, section.heading, fontSize: 16.5),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 27, top: 7),
        child: Text(
          section.body,
          style: ZyraText.body(
            size: 14.5,
            color: const Color(0xFF3A302A),
          ).copyWith(height: 1.6, letterSpacing: 0),
        ),
      ),
    ],
  );

  Widget _numbered(int index, String title, {required double fontSize}) => Row(
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      SizedBox(
        width: 27,
        child: Text(
          '${index + 1}',
          style: ZyraText.body(size: 13, color: ZyraColors.journeyGold),
        ),
      ),
      Expanded(
        child: Text(
          title,
          style: ZyraText.body(size: fontSize, color: ZyraColors.espresso)
              .copyWith(
                height: 1.35,
                fontWeight: fontSize > 16 ? FontWeight.w500 : FontWeight.w400,
              ),
        ),
      ),
    ],
  );

  Widget _readNextCard() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label('READ NEXT', secondary: true),
      const SizedBox(height: 10),
      _card(
        Column(
          children: [
            for (final next in ZyraLegalPreviewDocument.values)
              if (next != _document)
                _nextRow(
                  'legal_next_${next.name}',
                  zyraLegalPreviewPages[next]!.title,
                  () => _readNext(next),
                ),
            _nextRow(
              'legal_contact',
              'Questions? Contact support',
              widget.onContact,
            ),
          ],
        ),
      ),
    ],
  );

  Widget _nextRow(String key, String label, VoidCallback onTap) => InkWell(
    key: ValueKey(key),
    onTap: ZyraTapFeedback.onTap(context, onTap, canAct: _canUseReader),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 51),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 11, 20, 11),
        child: Row(
          children: [
            Expanded(child: Text(label, style: ZyraText.body(size: 14.5))),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFFAB9E8E)),
          ],
        ),
      ),
    ),
  );

  Widget _card(Widget child) => ZyraFloatingSurface(
    radius: 16,
    child: Material(
      color: ZyraColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: ZyraColors.surfaceBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    ),
  );

  Widget _label(String text, {bool secondary = false}) => Text(
    text,
    style: ZyraText.body(
      size: 10.5,
      color: secondary ? ZyraColors.secondaryText : const Color(0xFF845F24),
    ).copyWith(letterSpacing: 1),
  );
}
