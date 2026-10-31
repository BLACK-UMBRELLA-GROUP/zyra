import '../widgets/zyra_floating_surface.dart';
// LOCK10 V6 presentation for the local sample preview. No repositories,
// transports, device permission, private answers or member counts.
import 'package:flutter/material.dart';
import '../data/zyra_reference_data.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_profiles_components.dart';
import '../widgets/zyra_tap_feedback.dart';
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
    this.currentArea = false,
    this.paintWhileCovered = false,
    this.homeTown = 'Manchester',
  });
  final ZyraBrowseFilter filter;
  final bool Function() canAct;
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
  int _index = 0;
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
  }

  bool Function() _guard() {
    final epoch = _pageEpoch;
    final external = widget.canAct;
    return () => mounted && epoch == _pageEpoch && external();
  }

  Widget _control(Widget child) =>
      GestureDetector(onHorizontalDragStart: (_) {}, child: child);

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
  }) {
    final guard = _guard();
    return _control(
      TextButton(
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
      ),
    );
  }

  // Content height grows with Larger Text; controls wrap instead of ellipsising.
  Widget _segments(
    List<String> labels,
    int selected,
    ValueChanged<int> onChanged,
    String prefix,
  ) {
    final guard = _guard();
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
    return _control(
      ZyraFloatingSurface(
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
      ),
    );
  }

  Widget _slider(Widget child) => GestureDetector(
    // A horizontal slider drag belongs to the control, never to card paging.
    onHorizontalDragStart: (_) {},
    child: SliderTheme(
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
    ),
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
    final guard = _guard();
    final changed = widget.onChanged;
    return Column(
      children: [
        _segments(
          const ['Any age (18+)', 'Set range'],
          f.hasAgeRange ? 1 : 0,
          (i) => _change(f.withAge(i == 0 ? null : 18, i == 0 ? null : 70)),
          'concept_age',
        ),
        if (f.hasAgeRange) ...[
          const SizedBox(height: 26),
          _slider(
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
    final guard = _guard();
    final changed = widget.onChanged;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _segments(
          const ['Near me', 'Country', 'Worldwide'],
          f.where.index,
          (i) => _change(f.withWhere(ZyraBrowseWhere.values[i])),
          'concept_where',
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
              ),
            ),
          ),
          const SizedBox(height: 18),
          _slider(
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

  Widget _chip(String code, String label, bool selected) {
    final guard = _guard();
    final nationality = _index == 2;
    final filter = widget.filter;
    final changed = widget.onChanged;
    return _control(
      Semantics(
        button: true,
        label: '${selected ? 'Remove' : 'Add'} $label',
        excludeSemantics: true,
        child: InkWell(
          key: ValueKey(
            'filter_${selected ? 'remove' : 'add'}_${_index}_$code',
          ),
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
      ),
    );
  }

  Widget _heritage() {
    final guard = _guard();
    final nationality = _index == 2;
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
    final query = _search.text.trim();
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
        _control(
          TextField(
            key: ValueKey('filter_search_$kind'),
            controller: _search,
            focusNode: _focus,
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
              hintStyle: ZyraText.body(size: 13, color: ZyraColors.ink(.35)),
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
            children: [for (final c in values) _chip(c, labels[c]!, true)],
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
              for (final c in suggestions) _chip(c, labels[c]!, false),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboard =
        _focus.hasFocus || MediaQuery.viewInsetsOf(context).bottom > 0;
    final can = _paintEnabled;
    final guard = _guard();
    final index = _index;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(21, 16, 21, keyboard ? 10 : 31),
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
                  widget.filter.activeCount == 0
                      ? 'Clear'
                      : 'Clear (${widget.filter.activeCount})',
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
                ),
              ),
            ),
            Expanded(
              child: Semantics(
                label: '${_names[_index]}, filter ${_index + 1} of 4',
                container: true,
                explicitChildNodes: true,
                child: GestureDetector(
                  key: const ValueKey('filters_card'),
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragEnd: (d) {
                    if (guard() && (d.primaryVelocity ?? 0).abs() > 100) {
                      _page(index + (d.primaryVelocity! < 0 ? 1 : -1));
                    }
                  },
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
                          color: ZyraColors.journeyGold.withValues(alpha: .6),
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
                      child: ZyraShadowScrollView(
                        key: ValueKey('filter_scroll_$_index'),
                        padding: const EdgeInsets.fromLTRB(18, 36, 18, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Icon(
                              _icons[_index],
                              size: 34,
                              color: ZyraColors.journeyGold,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _names[_index],
                              textAlign: TextAlign.center,
                              style: ZyraText.heading(size: 26),
                            ),
                            const SizedBox(height: 6),
                            _text(_subtitles[_index], align: TextAlign.center),
                            const SizedBox(height: 20),
                            if (_index == 0)
                              _age()
                            else if (_index == 1)
                              _where()
                            else
                              _heritage(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (!keyboard) ...[
              SizedBox(
                height: 50,
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
                actionColor: ZyraColors.goldText,
                previousKey: const ValueKey('filter_previous'),
                nextKey: const ValueKey('filter_next'),
                previousLabel: 'Previous filter',
                nextLabel: 'Next filter',
                onPrevious: can && index > 0
                    ? () {
                        if (guard()) _page(index - 1);
                      }
                    : null,
                onNext: can && index < 3
                    ? () {
                        if (guard()) _page(index + 1);
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
