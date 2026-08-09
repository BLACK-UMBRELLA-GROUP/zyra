// Edit Profile — everything that changes what is ON your profile.
//
// NEW 2026-08-07. Founder: "in settings if the compatibility section is the
// same as edit profile then you gotta maybe move that section into edit
// profile part."
//
// It was. Settings had a COMPATIBILITY section — About you, Lifestyle,
// Marriage preferences, Green/Yellow/Red, Hard requirements — and Profile
// had an "Edit Profile" button pointing at nothing. Two routes to the same
// intention, one of which did not exist yet.
//
// This resolves it against the Founder's own principle, the one that moved
// Connections out of Settings in the first place: "Settings should
// configure the account, not become a duplicate navigation hub." Your sect,
// your lifestyle, what you are looking for in a marriage — none of those
// are account configuration. They are the profile.
//
// SO THE DIVISION IS NOW:
//   Profile → Edit Profile   what you look like to other people
//   Settings                 the account, privacy, notifications, support
//   Connections              relationships
//   Guardian page            Guardians
//
// which supersedes the line in settings_screen.dart's header giving
// compatibility to Settings.
//
// THE ROWS ARE STILL STUBS. They were stubs in Settings too — this move is
// structural, and none of the five editors has been built. Moving an
// unbuilt thing to the right place is worth doing precisely BECAUSE it is
// unbuilt: it is free now and expensive once five screens point at it.
//
// NOT INCLUDED YET, deliberately: name, About Me and location are all
// genuinely writable today (they hold column grants on profiles), so a
// Basics section belongs here and would work. It is not written because it
// was not asked for, and inventing a text editor inside a structural move
// is how a move becomes a rewrite. It is the obvious next piece.

import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  void _todo(BuildContext context, String what) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$what — coming next. (dev)')),
      );

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Edit Profile', style: ZyraText.heading(size: 17)),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: ZyraColors.genderGradient(state.gender)),
        child: SafeArea(
          child: ListView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
            children: [
              Text(
                'These are what ZYRA matches on. Changing them affects who '
                'ZYRA suggests to you from the next time it looks.',
                style: ZyraText.subtext(size: 12.5, color: Colors.white54),
              ),
              const SizedBox(height: 22),

              Text('COMPATIBILITY', style: ZyraText.chapterLabel(color: Colors.white54)),
              const SizedBox(height: 10),
              _Row(label: 'About you', onTap: () => _todo(context, 'About you')),
              _Row(label: 'Lifestyle', onTap: () => _todo(context, 'Lifestyle')),
              _Row(
                label: 'Marriage preferences',
                onTap: () => _todo(context, 'Marriage preferences'),
              ),
              _Row(
                label: 'Green / Yellow / Red',
                onTap: () => _todo(context, 'Green / Yellow / Red'),
              ),
              _Row(
                label: 'Hard requirements',
                onTap: () => _todo(context, 'Hard requirements'),
              ),

              const SizedBox(height: 30),
              // Said HERE because this is where someone looks for it. A
              // person who wants to correct their birth year opens Edit
              // Profile, not Settings, and finding nothing is worse than
              // finding a plain explanation.
              Text('FIXED', style: ZyraText.chapterLabel(color: Colors.white54)),
              const SizedBox(height: 10),
              _FixedRow(
                label: 'Date of birth',
                value: state.age == null ? '—' : 'Age ${state.age}',
              ),
              _FixedRow(
                label: 'Gender',
                value: state.gender == null
                    ? '—'
                    : (state.gender == 'male' ? 'Brother' : 'Sister'),
              ),
              const SizedBox(height: 10),
              Text(
                'Your date of birth and gender are set when you first publish '
                'your profile and cannot be changed afterwards — too much of '
                'how ZYRA works depends on them. If either is wrong, contact '
                'us and we will correct it.',
                style: ZyraText.subtext(size: 12, color: Colors.white38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _Row({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: ZyraText.body(size: 15, color: Colors.white)),
              ),
              const Icon(Icons.chevron_right, size: 19, color: Colors.white30),
            ],
          ),
        ),
      );
}

class _FixedRow extends StatelessWidget {
  final String label;
  final String value;
  const _FixedRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: ZyraText.body(size: 15, color: Colors.white54)),
            ),
            Text(value, style: ZyraText.subtext(size: 13.5, color: Colors.white38)),
            const SizedBox(width: 8),
            const Icon(Icons.lock_outline, size: 15, color: Colors.white24),
          ],
        ),
      );
}
