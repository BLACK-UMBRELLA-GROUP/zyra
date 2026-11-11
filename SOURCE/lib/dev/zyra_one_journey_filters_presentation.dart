import '../widgets/zyra_floating_surface.dart';
// LOCK10 V7 presentation for the local sample preview. No repositories,
// transports, device permission, private answers or member counts.
import 'package:flutter/material.dart';
import '../data/zyra_reference_data.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_guardian_add_card.dart' show ZyraGuardianDashedBorder;
import '../widgets/zyra_profiles_components.dart';
import '../widgets/zyra_tap_feedback.dart';
import '../widgets/zyra_swipe_track.dart';
import 'zyra_browse_filter.dart';

// The master track uses the same padded width and 4 pt height throughout.
// Material's range track otherwise adds a thumb-radius inset at each end.
class _FiltersRangeTrack extends RoundedRectRangeSliderTrackShape {
  const _FiltersRangeTrack();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) => Rect.fromLTWH(
    offset.dx,
    offset.dy + (parentBox.size.height - sliderTheme.trackHeight!) / 2,
    parentBox.size.width,
    sliderTheme.trackHeight!,
  );

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset startThumbCenter,
    required Offset endThumbCenter,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
    double additionalActiveTrackHeight = 2,
  }) => super.paint(
    context,
    offset,
    parentBox: parentBox,
    sliderTheme: sliderTheme,
    enableAnimation: enableAnimation,
    startThumbCenter: startThumbCenter,
    endThumbCenter: endThumbCenter,
    isEnabled: isEnabled,
    isDiscrete: isDiscrete,
    textDirection: textDirection,
    additionalActiveTrackHeight: 0,
  );
}

class ZyraOneJourneyFiltersPresentation extends StatefulWidget {
  const ZyraOneJourneyFiltersPresentation({
    super.key,
    required this.filter,
    required this.canAct,
    required this.onChanged,
    required this.onApply,
    required this.onCountry,
    required this.onOrigin,
    required this.onPreferences,
    this.canPage,
    this.allFilters = true,
    this.initialIndex = 0,
    this.onIndexChanged,
    this.onUpgrade,
    this.currentArea = false,
    this.paintWhileCovered = false,
    this.homeTown = 'Manchester',
  });
  final ZyraBrowseFilter filter;
  final bool Function() canAct;
  final bool Function()? canPage;
  final bool allFilters;
  final int initialIndex;
  final ValueChanged<int>? onIndexChanged;
  final VoidCallback? onUpgrade;
  final ValueChanged<ZyraBrowseFilter> onChanged;
  final VoidCallback onApply, onCountry, onOrigin, onPreferences;

  /// Supplied only by the origin owner after an approximate area is available.
  final bool currentArea;
  final bool paintWhileCovered;
  final String homeTown;
  @override
  State<ZyraOneJourneyFiltersPresentation> createState() => _FiltersState();
}

class _FiltersState extends State<ZyraOneJourneyFiltersPresentation> {
  final _search = TextEditingController();
  final _focus = FocusNode();
  final _track = ZyraSwipeController();
  final _viewportKey = GlobalKey();
  final _ageSliderKey = GlobalKey();
  final _radiusSliderKey = GlobalKey();
  final _nationalitySearchKey = GlobalKey();
  final _ethnicitySearchKey = GlobalKey();
  late int _index = widget.initialIndex.clamp(0, _names.length - 1);
  int _pageEpoch = 0;
  static const _names = ['Age', 'Location', 'Nationality', 'Ethnicity'];
  static const _icons = [
    Icons.cake_outlined,
    Icons.public,
    Icons.outlined_flag,
    Icons.groups,
  ];
  static const _subtitles = [
    'Any age, or set a range.',
    'Near you, in a country, or anywhere.',
    'Search any nationality and add one or more.',
    'Search any ethnicity and add one or more.',
  ];
  static const _popularNationality = [
    'GB',
    'PK',
    'BD',
    'IN',
    'SO',
    'MA',
    'EG',
    'TR',
  ];
  static const _popularEthnicity = [
    'pakistani',
    'arab',
    'bangladeshi',
    'indian',
    'black_african',
    'somali',
    'turkish',
    'mixed',
  ];
  @override
  void initState() {
    super.initState();
    _focus.addListener(_focusChanged);
  }

  void _focusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_focusChanged);
    _focus.dispose();
    _search.dispose();
    super.dispose();
  }

  bool get _paintEnabled => widget.canAct() || widget.paintWhileCovered;

  void _change(ZyraBrowseFilter value) {
    if (mounted && widget.canAct()) widget.onChanged(value);
  }

  void _page(int value) {
    if (!mounted ||
        !widget.canAct() ||
        value < 0 ||
        value > 3 ||
        value == _index) {
      return;
    }
    _pageEpoch++;
    _focus.unfocus();
    _search.clear();
    setState(() => _index = value);
    widget.onIndexChanged?.call(value);
  }

  bool Function() _guard([int? page]) {
    final epoch = _pageEpoch;
    final external = widget.canAct;
    return () =>
        mounted &&
        epoch == _pageEpoch &&
        (page == null || page == _index) &&
        external();
  }

  bool _canStartSwipe(Offset position) {
    final editorKey = switch (_index) {
      0 => _ageSliderKey,
      1 => _radiusSliderKey,
      2 => _nationalitySearchKey,
      _ => _ethnicitySearchKey,
    };
    final editor = editorKey.currentContext?.findRenderObject();
    final viewport = _viewportKey.currentContext?.findRenderObject();
    if (editor is! RenderBox ||
        !editor.hasSize ||
        viewport is! RenderBox ||
        !viewport.hasSize) {
      return true;
    }
    // Keep slider adjustments and text selection with their controls.
    final local = editor.globalToLocal(viewport.localToGlobal(position));
    return !(Offset.zero & editor.size).contains(local);
  }

  Text _text(
    String value, {
    double size = 13,
    Color? color,
    TextAlign? align,
  }) => Text(
    value,
    textAlign: align,
    style: ZyraText.body(size: size, color: color ?? ZyraColors.ink(.65)),
  );
  Widget _button(
    String key,
    String label,
    VoidCallback? callback, {
    double size = 13,
    int? page,
  }) {
    final guard = _guard(page);
    return TextButton(
      key: ValueKey(key),
      onPressed: ZyraTapFeedback.onTap(
        context,
        callback == null
            ? null
            : () {
                if (guard()) callback();
              },
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: _text(
        label,
        size: size,
        color: size < 24 ? ZyraColors.goldText : ZyraColors.journeyGold,
      ),
    );
  }

  // Content height grows with Larger Text; controls wrap instead of ellipsising.
  Widget _segments(
    List<String> labels,
    int selected,
    ValueChanged<int> onChanged,
    String prefix,
    int page,
  ) {
    final guard = _guard(page);
    final large = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    Widget item(int i) => Semantics(
      selected: i == selected,
      button: true,
      child: InkWell(
        key: ValueKey('${prefix}_$i'),
        onTap: ZyraTapFeedback.onTap(context, () {
          if (guard()) onChanged(i);
        }),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          alignment: Alignment.center,
          decoration: i == selected
              ? BoxDecoration(
                  color: ZyraColors.frostSelectedFill,
                  boxShadow: ZyraFloatingSurface.standardShadows,
                  border: Border.all(
                    color: ZyraColors.journeyGold.withValues(alpha: .6),
                  ),
                  borderRadius: BorderRadius.circular(24),
                )
              : null,
          child: _text(
            labels[i],
            size: 12.5,
            color: ZyraColors.ink(i == selected ? .95 : .65),
            align: TextAlign.center,
          ),
        ),
      ),
    );
    return ZyraFloatingSurface(
      radius: 28,
      circle: false,
      gold: false,
      child: Container(
        key: ValueKey('${prefix}_segments'),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: ZyraColors.surfaceFill,
          border: Border.all(color: ZyraColors.surfaceBorder),
          borderRadius: BorderRadius.circular(28),
        ),
        child: large
            ? Column(
                children: [for (var i = 0; i < labels.length; i++) item(i)],
              )
            : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < labels.length; i++)
                      Expanded(child: item(i)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _slider(GlobalKey key, Widget child) => SliderTheme(
    key: key,
    data: SliderTheme.of(context).copyWith(
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(
        enabledThumbRadius: 11,
        elevation: 0,
        pressedElevation: 0,
      ),
      rangeThumbShape: const RoundRangeSliderThumbShape(
        enabledThumbRadius: 11,
        elevation: 0,
        pressedElevation: 0,
      ),
      rangeTrackShape: const _FiltersRangeTrack(),
      overlappingShapeStrokeColor: ZyraColors.journeyGold,
      activeTrackColor: ZyraColors.journeyGold,
      inactiveTrackColor: ZyraColors.surfaceBorder,
      thumbColor: ZyraColors.journeyGold,
      overlayColor: ZyraColors.journeyGold.withValues(alpha: .12),
      activeTickMarkColor: Colors.transparent,
      inactiveTickMarkColor: Colors.transparent,
      showValueIndicator: ShowValueIndicator.never,
    ),
    child: child,
  );
  Widget _scale(String low, String value, String high) {
    final label = _text(
      value,
      size: 12,
      color: ZyraColors.goldText,
      align: TextAlign.center,
    );
    if (MediaQuery.textScalerOf(context).scale(1) > 1.3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: _text(low, size: 12)),
              Flexible(child: _text(high, size: 12, align: TextAlign.right)),
            ],
          ),
          label,
        ],
      );
    }
    return Row(
      children: [
        _text(low, size: 12),
        Expanded(child: label),
        _text(high, size: 12),
      ],
    );
  }

  Widget _placeRow(
    IconData icon,
    String label,
    Widget action, {
    double size = 12,
  }) {
    final details = Row(
      children: [
        Icon(icon, size: 18, color: ZyraColors.journeyGold),
        const SizedBox(width: 8),
        Expanded(child: _text(label, size: size)),
      ],
    );
    return MediaQuery.textScalerOf(context).scale(1) > 1.3
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              details,
              Align(alignment: Alignment.centerRight, child: action),
            ],
          )
        : Row(
            children: [
              Expanded(child: details),
              action,
            ],
          );
  }

  Widget _age() {
    final f = widget.filter;
    final guard = _guard(0);
    final changed = widget.onChanged;
    return Column(
      children: [
        _segments(
          const ['Any age (18+)', 'Set range'],
          f.hasAgeRange ? 1 : 0,
          (i) => _change(f.withAge(i == 0 ? null : 18, i == 0 ? null : 70)),
          'concept_age',
          0,
        ),
        if (f.hasAgeRange) ...[
          const SizedBox(height: 26),
          _slider(
            _ageSliderKey,
            RangeSlider(
              key: const ValueKey('concept_age_range'),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              min: 18,
              max: 70,
              divisions: 52,
              values: RangeValues(
                (f.minAge ?? 18).toDouble(),
                (f.maxAge ?? 70).toDouble(),
              ),
              semanticFormatterCallback: (v) => '${v.round()} years',
              onChanged: _paintEnabled
                  ? (v) {
                      if (guard()) {
                        changed(f.withAge(v.start.round(), v.end.round()));
                      }
                    }
                  : null,
            ),
          ),
          _scale('18', '${f.minAge ?? 18} – ${f.maxAge ?? 70}', '70'),
        ],
      ],
    );
  }

  Widget _where() {
    final f = widget.filter;
    final guard = _guard(1);
    final changed = widget.onChanged;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _segments(
          const ['Near me', 'Country', 'Worldwide'],
          f.where.index,
          (i) => _change(f.withWhere(ZyraBrowseWhere.values[i])),
          'concept_where',
          1,
        ),
        const SizedBox(height: 22),
        if (f.where == ZyraBrowseWhere.country) ...[
          _placeRow(
            Icons.outlined_flag,
            zyraBrowseCountryLabel(f.countryCode) ?? '',
            _button(
              'concept_country',
              'Change ›',
              _paintEnabled ? widget.onCountry : null,
              page: 1,
            ),
            size: 14,
          ),
          _text('Your country of residence. Tap to choose another.', size: 12),
        ] else if (f.where == ZyraBrowseWhere.worldwide)
          _text('Members anywhere in the world.', align: TextAlign.center)
        else ...[
          KeyedSubtree(
            key: const ValueKey('concept_filter_origin_row'),
            child: _placeRow(
              widget.currentArea ? Icons.my_location : Icons.home_outlined,
              widget.currentArea
                  ? 'From your current area'
                  : 'From ${widget.homeTown} (home town)',
              _button(
                'concept_filter_origin',
                'Change',
                _paintEnabled ? widget.onOrigin : null,
                size: 12,
                page: 1,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _slider(
            _radiusSliderKey,
            Slider(
              key: const ValueKey('concept_radius'),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              min: 0,
              max: 10,
              divisions: 10,
              value: zyraBrowseRadiusSteps
                  .indexOf(f.radiusKm)
                  .clamp(0, 10)
                  .toDouble(),
              semanticFormatterCallback: (v) =>
                  'Within ${zyraBrowseRadiusSteps[v.round()].round()} kilometres',
              onChanged: _paintEnabled
                  ? (v) {
                      if (guard()) {
                        changed(f.withRadius(zyraBrowseRadiusSteps[v.round()]));
                      }
                    }
                  : null,
            ),
          ),
          _scale('5 km', 'Within ${f.radiusKm.round()} km', '500 km'),
        ],
      ],
    );
  }

  Widget _chip(int page, String code, String label, bool selected) {
    final guard = _guard(page);
    final nationality = page == 2;
    final filter = widget.filter;
    final changed = widget.onChanged;
    return Semantics(
      button: true,
      label: '${selected ? 'Remove' : 'Add'} $label',
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('filter_${selected ? 'remove' : 'add'}_${page}_$code'),
        onTap: ZyraTapFeedback.onTap(context, () {
          if (!guard()) return;
          final values = Set<String>.of(
            nationality ? filter.nationalityCodes : filter.ethnicityCodes,
          );
          selected ? values.remove(code) : values.add(code);
          changed(
            nationality
                ? filter.withNationalities(values)
                : filter.withEthnicities(values),
          );
          if (!selected) {
            _search.clear();
            setState(() {});
          }
        }),
        borderRadius: BorderRadius.circular(24),
        child: ZyraFloatingSurface(
          radius: 24,
          circle: false,
          gold: false,
          child: Container(
            constraints: const BoxConstraints(minHeight: 42),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: ZyraColors.surfaceFill,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: selected
                    ? ZyraColors.journeyGold.withValues(alpha: .7)
                    : ZyraColors.surfaceBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!selected) ...[
                  const Icon(
                    Icons.add,
                    size: 14,
                    color: ZyraColors.journeyGold,
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: _text(label, size: 13, color: ZyraColors.ink(.95)),
                ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.close,
                    size: 14,
                    color: ZyraColors.journeyGold,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heritage(int page) {
    final guard = _guard(page);
    final active = page == _index;
    final nationality = page == 2;
    final values = nationality
        ? widget.filter.nationalityCodes
        : widget.filter.ethnicityCodes;
    final labels = <String, String>{
      if (nationality)
        for (final c in zyraCountries)
          c.code: zyraBrowseFilterNationalityLabel(c.code)!
      else
        for (final e in zyraEthnicities)
          if (e.code != 'prefer_not_to_say') e.code: e.name,
    };
    final query = active ? _search.text.trim() : '';
    final suggestions =
        (query.isEmpty
                ? (nationality ? _popularNationality : _popularEthnicity)
                : labels.keys.where(
                    (c) =>
                        labels[c]!.toLowerCase().contains(query.toLowerCase()),
                  ))
            .where((c) => !values.contains(c))
            .take(8)
            .toList();
    final kind = nationality ? 'nationality' : 'ethnicity';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyedSubtree(
          key: nationality ? _nationalitySearchKey : _ethnicitySearchKey,
          child: TextField(
            key: ValueKey('filter_search_$kind'),
            controller: active ? _search : null,
            focusNode: active ? _focus : null,
            enabled: _paintEnabled,
            textInputAction: TextInputAction.done,
            style: ZyraText.body(size: 14),
            onChanged: (_) {
              if (guard()) setState(() {});
            },
            onSubmitted: (_) {
              if (guard()) _focus.unfocus();
            },
            onTapOutside: (_) {
              if (guard()) _focus.unfocus();
            },
            decoration: InputDecoration(
              hintText: 'Search any $kind',
              hintStyle: ZyraText.body(
                size: 13,
                color: ZyraColors.secondaryText,
              ),
              prefixIcon: Icon(
                Icons.search,
                size: 18,
                color: ZyraColors.ink(.4),
              ),
              filled: true,
              fillColor: ZyraColors.surfaceFill,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: ZyraColors.surfaceBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: ZyraColors.surfaceBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: ZyraColors.surfaceBorder),
              ),
            ),
          ),
        ),
        if (values.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in values) _chip(page, c, labels[c]!, true),
            ],
          ),
        ],
        const SizedBox(height: 14),
        _text(
          query.isEmpty ? 'POPULAR' : 'MATCHES',
          size: 10,
          color: ZyraColors.ink(.5),
        ),
        const SizedBox(height: 8),
        if (suggestions.isEmpty && query.isNotEmpty)
          _text('No $kind called “$query”.', size: 12)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in suggestions) _chip(page, c, labels[c]!, false),
            ],
          ),
      ],
    );
  }

  String _currentChoice(int page) {
    final f = widget.filter;
    return switch (page) {
      0 =>
        f.hasAgeRange
            ? '${f.minAge ?? 18} – ${f.maxAge ?? 70}'
            : 'ANY AGE (18+)',
      1 => switch (f.where) {
        ZyraBrowseWhere.nearMe => 'WITHIN ${f.radiusKm.round()} KM',
        ZyraBrowseWhere.country =>
          (zyraBrowseCountryLabel(f.countryCode) ?? '').toUpperCase(),
        ZyraBrowseWhere.worldwide => 'WORLDWIDE',
      },
      2 =>
        f.nationalityCodes.isEmpty
            ? 'ANY NATIONALITY'
            : '${f.nationalityCodes.length} CHOSEN',
      _ =>
        f.ethnicityCodes.isEmpty
            ? 'ANY ETHNICITY'
            : '${f.ethnicityCodes.length} CHOSEN',
    };
  }

  Widget _lockedHeritage(int page) {
    final guard = _guard(page);
    final canPage = widget.canPage;
    return CustomPaint(
      foregroundPainter: ZyraGuardianDashedBorder(
        18,
        ZyraColors.journeyGold.withValues(alpha: .5),
      ),
      child: Container(
        key: const ValueKey('filter-heritage-lock-panel'),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFBF7F0),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.lock_outline,
              color: ZyraColors.journeyGold,
              size: 26,
            ),
            const SizedBox(height: 10),
            Text(
              'Comes with Seeker One',
              textAlign: TextAlign.center,
              style: ZyraText.body(
                size: 17,
              ).copyWith(fontWeight: FontWeight.w300, height: 1.2),
            ),
            const SizedBox(height: 6),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 270),
                child: Text(
                  'Seeker Basic filters by age and location. Seeker One adds nationality and ethnicity.',
                  textAlign: TextAlign.center,
                  style: ZyraText.subtext(size: 12.5).copyWith(height: 1.3),
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: const ValueKey('filter-see-seeker-one'),
              onPressed: ZyraTapFeedback.onTap(
                context,
                widget.onUpgrade,
                canAct: () =>
                    guard() && !widget.allFilters && (canPage?.call() ?? true),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 46),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                shape: const StadiumBorder(),
                backgroundColor: ZyraColors.primaryAction,
                foregroundColor: ZyraColors.onPrimaryAction,
                textStyle: ZyraText.button(
                  size: 14,
                ).copyWith(fontWeight: FontWeight.w500),
              ),
              child: const Text('See Seeker One', textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardContent(int page) => LayoutBuilder(
    key: const ValueKey('filter_viewport'),
    builder: (context, bounds) {
      final locked = page >= 2 && !widget.allFilters;
      final centered = page < 2 || locked;
      final top = locked
          ? 0.0
          : centered
          ? 18.0
          : 36.0;
      final bottom = locked ? 0.0 : 18.0;
      final content = Column(
        key: const ValueKey('filter_content'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              key: const ValueKey('filter_monogram'),
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: ZyraColors.journeyGold.withValues(alpha: .7),
                ),
              ),
              child: Icon(
                _icons[page],
                size: 36,
                color: ZyraColors.journeyGold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _names[page],
            key: const ValueKey('filter_title'),
            textAlign: TextAlign.center,
            style: ZyraText.heading(size: 28).copyWith(
              fontWeight: FontWeight.w300,
              height: locked ? 1.2 : null,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            locked ? 'SEEKER ONE' : _currentChoice(page),
            key: const ValueKey('filter_current_choice'),
            textAlign: TextAlign.center,
            style: ZyraText.body(
              size: 11,
              color: ZyraColors.goldText,
            ).copyWith(letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          _text(_subtitles[page], align: TextAlign.center),
          const SizedBox(height: 20),
          if (page == 0)
            _age()
          else if (page == 1)
            _where()
          else if (locked)
            _lockedHeritage(page)
          else
            _heritage(page),
        ],
      );
      return ZyraShadowScrollView(
        key: ValueKey('filter_scroll_$page'),
        padding: EdgeInsets.fromLTRB(18, top, 18, bottom),
        child: centered
            ? ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (bounds.maxHeight - top - bottom).clamp(
                    0.0,
                    double.infinity,
                  ),
                ),
                child: Center(child: content),
              )
            : content,
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final keyboard =
        _focus.hasFocus || MediaQuery.viewInsetsOf(context).bottom > 0;
    final can = _paintEnabled;
    final activeCount =
        (widget.allFilters ? widget.filter : widget.filter.withoutHeritage())
            .activeCount;
    final guard = _guard();
    final pageOwner = widget.canPage;
    bool canPage() => guard() && (pageOwner?.call() ?? true);
    final index = _index;
    const sideInset = 21.0;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          sideInset,
          16,
          sideInset,
          keyboard ? 10 : 31,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Filters', style: ZyraText.heading(size: 28)),
                ),
                _button(
                  'concept_reset_filter_draft',
                  activeCount == 0 ? 'Clear' : 'Clear ($activeCount)',
                  can
                      ? () {
                          _search.clear();
                          _change(const ZyraBrowseFilter());
                        }
                      : null,
                ),
              ],
            ),
            SizedBox(
              height: 28,
              child: Center(
                child: ZyraProfilesDots(
                  count: 4,
                  index: _index,
                  dotKey: (i) => ValueKey('filter_dot_$i'),
                  activeWidth: 30,
                  size: 6,
                  lift: 0,
                  canAct: canPage,
                  onSelected: (value) {
                    if (canPage()) _track.animateTo(value);
                  },
                  targetKey: (i) => ValueKey('filter_dot_target_$i'),
                ),
              ),
            ),
            Expanded(
              child: KeyedSubtree(
                key: _viewportKey,
                child: ZyraSwipeTrack(
                  key: const ValueKey('filters_card'),
                  viewportInset: sideInset,
                  controller: _track,
                  index: index,
                  itemCount: _names.length,
                  canAct: canPage,
                  canStartAt: _canStartSwipe,
                  onSettled: _page,
                  itemBuilder: (context, page) => Semantics(
                    label: '${_names[page]}, filter ${page + 1} of 4',
                    container: true,
                    explicitChildNodes: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (guard()) _focus.unfocus();
                      },
                      child: ZyraFloatingSurface(
                        radius: 22,
                        circle: false,
                        gold: false,
                        child: Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: ZyraColors.journeyGold.withValues(
                                alpha: .6,
                              ),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color.alphaBlend(
                                  ZyraColors.surfaceFill,
                                  ZyraColors.ivoryTop,
                                ),
                                Color.alphaBlend(
                                  ZyraColors.surfaceFill,
                                  ZyraColors.ivoryBottom,
                                ),
                              ],
                            ),
                          ),
                          child: _cardContent(page),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (!keyboard) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 50),
                child: _button(
                  'filter_preferences',
                  'Your preferences also shape who you see ›',
                  can ? widget.onPreferences : null,
                  size: 12,
                ),
              ),
              ZyraProfilesRequestRow(
                actionKey: const ValueKey('concept_apply_filter'),
                label: 'Show profiles',
                labels: const ['Show profiles'],
                sent: false,
                previousKey: const ValueKey('filter_previous'),
                nextKey: const ValueKey('filter_next'),
                previousLabel: 'Previous filter',
                nextLabel: 'Next filter',
                onPrevious: can && index > 0
                    ? () {
                        if (canPage()) _track.animateTo(index - 1);
                      }
                    : null,
                onNext: can && index < 3
                    ? () {
                        if (canPage()) _track.animateTo(index + 1);
                      }
                    : null,
                onRequest: can ? widget.onApply : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
