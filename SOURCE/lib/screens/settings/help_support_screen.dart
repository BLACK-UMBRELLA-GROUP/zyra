// Help & Support — rebuilt 2026-08-01 (Founder: "the help and support
// page we gotta start building it... start building Q/A etc to let users
// navigate for any issues").
//
// WAS: four lines of text and an email address, with rows that rendered
// as "Email Report a technical issue to support@zyra.app" — a label
// sandwiched inside a sentence, which read as broken English.
//
// NOW: a real help centre. Searchable questions grouped by category,
// with the support email kept as the last resort at the BOTTOM rather
// than the first thing offered. Someone who can answer their own
// question in four seconds should never be asked to write an email and
// wait.
//
// Content lives in data/help_content.dart, deliberately separate — see
// that file's header for why, and for the note about moving it to
// Supabase so answers can be corrected without a release.
//
// GRADIENT: extendBodyBehindAppBar + manual top padding, matching
// notifications_screen.dart's fix from 2026-07-27 (Founder: "the purple
// at top doesn't suit so I'd rather the pink/purple takes whole
// screen"). Without it the transparent AppBar shows the Scaffold's flat
// background through, cutting the gender gradient off with a hard purple
// strip — exactly what the Founder screenshotted on this screen.

import 'package:flutter/material.dart';
import '../../data/help_content.dart';
import '../../services/zyra_auth.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  static const String supportEmail = 'support@zyra.app';

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    // ES-11 (proposed): every controller created here is disposed here.
    // Two existing leaks in this codebase came from skipping this.
    _search.dispose();
    super.dispose();
  }

  List<ZyraHelpCategory> get _filtered {
    if (_query.trim().isEmpty) return zyraHelpCategories;
    final out = <ZyraHelpCategory>[];
    for (final category in zyraHelpCategories) {
      final hits = category.entries.where((e) => e.matches(_query)).toList();
      if (hits.isNotEmpty) out.add(ZyraHelpCategory(category.title, hits));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;
    // SafeArea's top inset covers the status bar only, not the toolbar —
    // so with the body extended behind the AppBar, content needs both.
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Help & Support', style: ZyraText.heading(size: 17)),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: Container(
        // Only ever reached from inside a signed-in profile, so gender is
        // known — gender-matched gradient like every other profile-context
        // screen (DR-ZYRA-094 / OA-ZYRA-123).
        decoration: BoxDecoration(gradient: ZyraColors.genderGradient(AppState.instance.gender)),
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, topInset + 8, 20, 40),
          children: [
            _SearchField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 22),

            if (results.isEmpty)
              _NoResults(query: _query)
            else
              for (final category in results) ...[
                Text(category.title.toUpperCase(), style: ZyraText.chapterLabel(color: Colors.white54)),
                const SizedBox(height: 8),
                for (final entry in category.entries) _HelpTile(entry: entry),
                const SizedBox(height: 22),
              ],

            const SizedBox(height: 4),
            const _ContactCard(),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: ZyraText.body(size: 15, color: Colors.white),
      decoration: InputDecoration(
        hintText: 'What do you need help with?',
        hintStyle: ZyraText.subtext(size: 14),
        prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
        filled: true,
        fillColor: ZyraColors.iconButtonBg,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// One expandable question. Collapsed by default so the whole centre can
/// be scanned in a few seconds — the point is to find your question, not
/// to read everyone else's.
class _HelpTile extends StatefulWidget {
  final ZyraHelpEntry entry;
  const _HelpTile({required this.entry});

  @override
  State<_HelpTile> createState() => _HelpTileState();
}

class _HelpTileState extends State<_HelpTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      // ADDED 2026-08-01 (Fable's review): the collapse state was invisible
      // to VoiceOver — a screen-reader user got the question text with no
      // indication it could expand, or that it had. This screen is exactly
      // where a blind user is most likely to be when they are already stuck.
      child: Semantics(
        button: true,
        expanded: _open,
        label: widget.entry.question,
        child: GestureDetector(
        onTap: () => setState(() => _open = !_open),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: _open ? 0.09 : 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: _open ? 0.16 : 0.10), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(widget.entry.question, style: ZyraText.body(size: 14.5, color: Colors.white)),
                  ),
                  const SizedBox(width: 10),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.expand_more, size: 20, color: Colors.white38),
                  ),
                ],
              ),
              if (_open) ...[
                const SizedBox(height: 10),
                Text(widget.entry.answer, style: ZyraText.subtext(size: 13.5)),
              ],
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          const Icon(Icons.search_off, color: Colors.white38, size: 30),
          const SizedBox(height: 12),
          Text('Nothing matched "$query"', style: ZyraText.body(size: 15, color: Colors.white), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            'Try a different word, or email us below — a real person will read it.',
            style: ZyraText.subtext(size: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Last resort, at the bottom. There is genuinely no ticketing system yet
/// and the screen says so — an honest "email us" beats a Contact Us form
/// that goes nowhere.
class _ContactCard extends StatelessWidget {
  const _ContactCard();

  @override
  Widget build(BuildContext context) {
    final email = ZyraAuth.currentUser?.email;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white12, width: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Still need us?', style: ZyraText.body(size: 15, color: Colors.white)),
          const SizedBox(height: 6),
          Text(
            "There's no in-app messaging for support yet — email us and a real "
            'person will reply.',
            style: ZyraText.subtext(size: 13),
          ),
          const SizedBox(height: 14),
          SelectableText(
            HelpSupportScreen.supportEmail,
            style: ZyraText.body(size: 15.5, color: Colors.white).copyWith(fontWeight: FontWeight.w600),
          ),
          if (email != null) ...[
            const SizedBox(height: 14),
            Divider(color: Colors.white.withValues(alpha: 0.10), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text('Signed in as', style: ZyraText.subtext(size: 12.5))),
                Flexible(
                  child: Text(
                    email,
                    style: ZyraText.body(size: 12.5, color: Colors.white),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
