import 'package:flutter/material.dart';

import '../data/help_content.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import 'zyra_developer_title.dart';
import 'zyra_floating_surface.dart';
import 'zyra_tap_feedback.dart';

/// LOCK 43 presentation. The retained Help owner supplies its immutable FAQ
/// snapshot and account/route admission; this widget has no service access.
class ZyraHelpSupportPage extends StatefulWidget {
  const ZyraHelpSupportPage({
    super.key,
    required this.categories,
    required this.canAct,
    required this.onContact,
    required this.search,
    required this.query,
    required this.onQuery,
  });

  final List<ZyraHelpCategory> categories;
  final bool Function() canAct;
  final VoidCallback onContact;
  final TextEditingController search;
  final String query;
  final ValueChanged<String> onQuery;

  @override
  State<ZyraHelpSupportPage> createState() => _ZyraHelpSupportPageState();
}

class _ZyraHelpSupportPageState extends State<ZyraHelpSupportPage> {
  String _topic = 'All';
  String? _open;

  void _act(VoidCallback action) {
    if (widget.canAct()) action();
  }

  Widget _card(
    Widget child, {
    EdgeInsets padding = EdgeInsets.zero,
    Key? key,
  }) => ZyraFloatingSurface(
    key: key,
    radius: 16,
    child: Container(
      padding: padding,
      decoration: BoxDecoration(
        color: ZyraColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ZyraColors.surfaceBorder),
      ),
      child: child,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final bottomGap = MediaQuery.paddingOf(context).bottom > 0 ? 0.0 : 16.0;
    final results = [
      for (final category in widget.categories)
        if (_topic == 'All' || _topic == category.title)
          ZyraHelpCategory(category.title, [
            for (final entry in category.entries)
              if (entry.matches(widget.query)) entry,
          ]),
    ].where((category) => category.entries.isNotEmpty).toList();
    return Material(
      color: Colors.transparent,
      child: DefaultTextStyle.merge(
        style: const TextStyle(letterSpacing: 0, height: 1.45),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: ZyraDeveloperTitle(
                    child: Text(
                      'Help & support',
                      key: const ValueKey('help-support-preview-title'),
                      style: ZyraText.pageTitle(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: CustomScrollView(
                  key: const ValueKey('help-support-preview-scroll'),
                  physics: const ScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList.list(
                        children: [
                          _search(),
                          const SizedBox(height: 14),
                          _topics(),
                          if (results.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 28),
                              child: Text(
                                'No answers for “${widget.query}”. Try other words, or contact us below.',
                                textAlign: TextAlign.center,
                                style: ZyraText.body(
                                  size: 14,
                                  color: ZyraColors.secondaryText,
                                ),
                              ),
                            )
                          else
                            for (final category in results) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  2,
                                  30,
                                  2,
                                  10,
                                ),
                                child: Text(
                                  category.title.toUpperCase(),
                                  style: ZyraText.body(
                                    size: 10.5,
                                    color: ZyraColors.secondaryText,
                                  ).copyWith(letterSpacing: 1),
                                ),
                              ),
                              _card(
                                Column(
                                  children: [
                                    for (
                                      var i = 0;
                                      i < category.entries.length;
                                      i++
                                    ) ...[
                                      if (i > 0)
                                        const Divider(
                                          height: 1,
                                          color: ZyraColors.divider,
                                        ),
                                      _question(
                                        category.title,
                                        category.entries[i],
                                      ),
                                    ],
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                            ],
                        ],
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 28, 20, bottomGap),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [_contact()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _search() => Container(
    key: const ValueKey('help-support-preview-search'),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: ZyraColors.ivoryTop,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: ZyraColors.ink(0.14)),
    ),
    child: Row(
      children: [
        const Icon(Icons.search, size: 20, color: ZyraColors.secondaryText),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: widget.search,
            onChanged: widget.onQuery,
            minLines: 1,
            maxLines: null,
            style: ZyraText.body(size: 15, color: ZyraColors.espresso),
            decoration: InputDecoration(
              hintText: 'What do you need help with?',
              hintMaxLines: 3,
              hintStyle: ZyraText.body(
                size: 15,
                color: ZyraColors.secondaryText,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _topics() => SingleChildScrollView(
    key: const ValueKey('help-support-topics'),
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final topic in ['All', ...widget.categories.map((c) => c.title)])
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Semantics(
              selected: _topic == topic,
              child: OutlinedButton(
                key: ValueKey('help-topic:$topic'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  backgroundColor: ZyraColors.ivoryTop,
                  side: BorderSide(
                    color: _topic == topic
                        ? ZyraColors.journeyGold
                        : ZyraColors.ink(0.16),
                  ),
                  shape: const StadiumBorder(),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.standard,
                ),
                onPressed: ZyraTapFeedback.onTap(
                  context,
                  () => _act(() => setState(() => _topic = topic)),
                ),
                child: Text(
                  topic,
                  softWrap: false,
                  style: ZyraText.body(
                    size: 13,
                    color: _topic == topic
                        ? ZyraColors.goldTextStrong
                        : ZyraColors.espresso,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _question(String topic, ZyraHelpEntry entry) {
    final open = _open == entry.question;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          expanded: open,
          child: InkWell(
            key: ValueKey('help-support-faq:$topic:${entry.question}'),
            onTap: ZyraTapFeedback.onTap(
              context,
              () => _act(
                () => setState(() => _open = open ? null : entry.question),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.question,
                      style: ZyraText.body(
                        size: 14.5,
                        color: ZyraColors.espresso,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    open ? Icons.expand_more : Icons.chevron_right,
                    size: 18,
                    color: ZyraColors.journeyGold,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (open)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              entry.answer,
              style: ZyraText.body(
                size: 13.5,
                color: ZyraColors.strongSecondaryText,
              ).copyWith(height: 1.55),
            ),
          ),
      ],
    );
  }

  Widget _contact() => _card(
    Builder(
      builder: (context) {
        final label = Text(
          'Contact us',
          style: ZyraText.body(size: 13, color: ZyraColors.goldTextStrong),
        );
        final button = OutlinedButton(
          key: const ValueKey('help-contact-us'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            side: const BorderSide(color: ZyraColors.journeyGold),
            shape: const StadiumBorder(),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: ZyraTapFeedback.onTap(
            context,
            () => _act(widget.onContact),
          ),
          child: label,
        );
        final text = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Still need help?',
              style: ZyraText.body(size: 14.5, color: ZyraColors.espresso),
            ),
            const SizedBox(height: 2),
            Text(
              'We reply by email within 2 working days.',
              style: ZyraText.body(size: 12.5, color: ZyraColors.secondaryText),
            ),
          ],
        );
        double textWidth(String value, TextStyle style) {
          final painter = TextPainter(
            text: TextSpan(text: value, style: style),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout();
          final width = painter.width;
          painter.dispose();
          return width;
        }

        final requiredWidth =
            22 +
            12 +
            12 +
            30 +
            textWidth('Still need help?', ZyraText.body(size: 14.5)) +
            textWidth('Contact us', ZyraText.body(size: 13));
        final stacked = requiredWidth > MediaQuery.sizeOf(context).width - 72;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.help_outline,
                  color: ZyraColors.journeyGold,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(child: text),
                if (!stacked) ...[const SizedBox(width: 12), button],
              ],
            ),
            if (stacked) ...[
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: button),
            ],
          ],
        );
      },
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    key: const ValueKey('help-contact-card'),
  );
}
