// Profile tab — APP/Profiles/Script/Script_V1.md: no white content
// containers, info sits directly on the page background, white section
// headings, plan badge (ZYRA Basic / ZYRA One) replaces generic
// "Member" label. Includes the Passed/Saved/Considered review lists
// (DR-ZYRA-099 labels, 2026-07-25) per the same spec's Connection
// Profile Expansion section (kept as a simple list here rather than
// the full reused-Browse-viewer expansion, which is a larger follow-up).

import 'package:flutter/material.dart';
import '../../widgets/zyra_profile_image.dart';
import '../../services/zyra_auth.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
// Blocked users, Help, Notifications, Privacy and Upgrade are all reached
// through SettingsScreen now. Profile knows about Settings and nothing else.
import '../settings/settings_screen.dart';
import '../welcome_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_onChange);
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  void _todo(BuildContext context, String what) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('$what — coming next.')));

  /// PREVIEW — the Founder's stated highest priority for this page.
  ///
  /// NOT BUILT YET, and this is deliberately a stub rather than a
  /// half-preview, because a preview that is only approximately right is
  /// worse than none: the entire promise is "exactly what another Seeker
  /// sees", and a version that quietly showed your own unlocked data back
  /// to you would misrepresent what other people can actually see.
  ///
  /// Doing it properly means rendering the Browse card as a STRANGER sees
  /// it — honouring unlock tier, gender rules and blocks — and the viewer
  /// currently lives inside browse_screen.dart rather than as a reusable
  /// widget. Extracting it is the real work, and it is its own piece.
  void _preview(BuildContext context) =>
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile preview — building this next.')),
      );

  // ── "IMPROVE YOUR PROFILE" — REMOVED 2026-08-07 ─────────────────────
  //
  // Founder: "remove the improve your profile section."
  //
  // It listed two prompts: add more photos, and finish your compatibility
  // answers. Both are now reachable directly and obviously — Edit Photos
  // and Edit Profile sit side by side one line above where this card used
  // to be — so it was telling someone to press a button they were already
  // looking at.
  //
  // It was already a careful thing: not a percentage, nothing invented,
  // hidden entirely once there was nothing to say. It still earned its
  // place on the page by pointing at what the page already offered.
  //
  // If a nudge ever comes back it should measure MATCHING QUALITY rather
  // than cosmetic completion — the Founder's own condition, and not
  // something a checklist of two items was ever going to do.

  /// Membership, directly beneath Edit Photos / Edit Profile.
  ///
  /// MOVED 2026-08-07 (Founder: "move the membership status under edit
  /// photo / edit profile"). It was under a YOUR PROFILE heading below
  /// ABOUT ME, which put a fact about your account underneath facts about
  /// you, several sections away from the actions it relates to. Upgrading
  /// is what someone does after looking at what they can edit.
  ///
  /// The heading went with it. One row does not need a section, and
  /// "YOUR PROFILE" above a subscription tier was never quite true.
  ///
  /// "Member since" is still NOT here and is still not faked.
  /// `profiles.created_at` exists and IS selectable by the owner; AppState
  /// simply never loads it. One field plus one line in the session router,
  /// alongside `bio` and `surname_line`, and all three arrive together.
  Widget _membershipRow(AppState state) => Padding(
    padding: const EdgeInsets.only(top: 18),
    child: _InfoRow(
      label: 'Membership',
      value: state.plan == ZyraPlan.one ? 'ZYRA One' : 'ZYRA Basic',
    ),
  );
  Future<void> _signOut(BuildContext context) async {
    // Real sign-out (OA-102) — only meaningful once Supabase is
    // configured; no-ops harmlessly via ZyraAuth otherwise since
    // there's no session to end.
    await ZyraAuth.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  // Account deletion MOVED 2026-08-06 to
  // screens/settings/account_advanced_screen.dart. It is now two taps
  // below Settings rather than a row on this page — Founder: "Delete
  // should never be visible in the main list."

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    // 2026-08-01: prefer AppState.age, which ZyraSessionRouter hydrates
    // from ages_for() on every cold start. AppState.dob is only populated
    // during the onboarding session that captured it and is null on every
    // subsequent launch — `profiles.date_of_birth` is no longer selectable
    // by the client (audit C2). Computing from dob is kept as the
    // in-session path so the age appears immediately after Chapter 1,
    // before any rehydrate has happened.
    int? age = state.age;
    if (age == null && state.dob != null) {
      final now = DateTime.now();
      final dob = state.dob!;
      age = now.year - dob.year;
      final hadBirthdayThisYear =
          now.month > dob.month ||
          (now.month == dob.month && now.day >= dob.day);
      if (!hadBirthdayThisYear) age -= 1;
    }

    return Container(
      // 2026-07-25: gender-matched gradient (DR-ZYRA-094/OA-ZYRA-123)
      // instead of the neutral brand gradient — Blue for male, Pink for
      // female. Was previously hardcoded to the neutral gradient here;
      // see ZyraColors.genderGradient() doc comment.
      decoration: BoxDecoration(
        gradient: ZyraColors.genderGradient(state.gender),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
          children: [
            Row(
              children: [
                ClipOval(
                  child: state.photos.isNotEmpty
                      ? ZyraProfileImage(
                          state.photos.first,
                          width: 64,
                          height: 64,
                        )
                      : Container(
                          width: 64,
                          height: 64,
                          color: ZyraColors.iconButtonBg,
                          child: const Icon(
                            Icons.person,
                            color: Colors.white38,
                            size: 30,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // FULL NAME as of 2026-08-07 — "Maryam Fatima Ahmed",
                      // which the Founder asked for on 2026-08-06 and which
                      // was deliberately left as a first name at the time
                      // rather than faked: surname_line existed in the
                      // database but AppState never carried it.
                      //
                      // It does now (see AppState.fullName), hydrated in
                      // the same round trip the router already made. Falls
                      // back to the first name on its own when there is no
                      // surname, which is a real state — nothing in
                      // onboarding asks for one yet.
                      Text(
                        state.fullName ?? 'Your Profile',
                        style: ZyraText.heading(size: 20),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // PLAN BADGE REMOVED 2026-08-07 (Founder: "membership
                      // already appears elsewhere on the page, so this is
                      // duplicate information. The top of the Profile page
                      // should feel personal rather than repeating
                      // subscription information").
                      //
                      // Membership is on the YOUR PROFILE row below.
                      //
                      // The Founder asked for a full name here instead —
                      // "Maryam Fatima Ahmed". NOT done, and deliberately
                      // not faked: `profiles.surname_line` exists and is
                      // writable, but AppState carries only `name`. Showing
                      // a first name where a full name was asked for is
                      // honest; inventing one is not. One field plus one
                      // line in the session router, alongside `bio` and
                      // `created_at`, and all three arrive together.
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            // ── PREVIEW ───────────────────────────────────────────────
            //
            // Founder, 2026-08-06: "I actually think this is more important
            // than Profile Strength. If this page is about 'how others see
            // me', there should be a big obvious button."
            //
            // So it is the first thing under the header, and it is the only
            // full-width action on the page.
            _PrimaryAction(
              icon: Icons.visibility_outlined,
              label: 'Preview my profile',
              hint: 'See exactly what another Seeker sees',
              onTap: () => _preview(context),
            ),
            const SizedBox(height: 14),

            // §5 — equal weight. Edit Photos was the only obvious action, so
            // it read as the only one. These are the two things people
            // actually come here to do.
            Row(
              children: [
                Expanded(
                  child: _SecondaryAction(
                    icon: Icons.photo_library_outlined,
                    label: 'Edit Photos',
                    onTap: () => _todo(context, 'Edit Photos'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SecondaryAction(
                    icon: Icons.edit_outlined,
                    label: 'Edit Profile',
                    // A real screen as of 2026-08-07 — it now owns the
                    // compatibility answers that used to live in Settings.
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Membership sits with the two edit actions, not several
            // sections below them — see _membershipRow.
            _membershipRow(state),

            const SizedBox(height: 26),
            Text(
              'ABOUT ME',
              style: ZyraText.chapterLabel(color: Colors.white54),
            ),
            const SizedBox(height: 10),
            _InfoRow(label: 'Age', value: age?.toString() ?? '—'),
            _InfoRow(
              label: 'Gender',
              value: state.gender == null
                  ? '—'
                  : (state.gender == 'male' ? 'Brother' : 'Sister'),
            ),
            _InfoRow(label: 'Location', value: state.location ?? '—'),
            const SizedBox(height: 24),
            // ── PUBLIC INFORMATION — REMOVED 2026-08-06 ───────────────
            //
            // Founder: "Since Browse no longer displays things like Sect, I
            // don't think Public Information belongs on Profile anymore."
            //
            // It listed Sect and a photo count. Sect is no longer shown in
            // Browse, so the heading was claiming a publicness the field no
            // longer has; the photo count is answered better by the carousel
            // and the Edit Photos button. Editing lives in Edit Profile,
            // which owns those answers as of 2026-08-07 — it used to say
            // Settings → Compatibility, and that section has moved.
            //
            // YOUR CONNECTIONS is removed for the same reason it was removed
            // from the Settings section this morning: Connections owns it.
            //
            // YOUR PROFILE / Membership moved UP, to sit with Edit Photos
            // and Edit Profile — see _membershipRow.
            // ── REMOVED 2026-08-06 ────────────────────────────────────
            //
            // Passed / Saved / Considered were rendered here as rows. That
            // was the exact duplication the Founder's own principle
            // forbids: "Connections should stay in the Connections page…
            // Settings should configure the account, not become a
            // duplicate navigation hub."
            //
            // The whole SETTINGS section has also moved out, to
            // screens/settings/settings_screen.dart. It was seven flat rows
            // with Delete Account among them — a section cannot carry a
            // dashboard, cannot group six categories, and has no hierarchy
            // to demote a destructive action into. All three of those are
            // possible now that Settings is a screen.
            //
            // Profile is a profile again.
            const SizedBox(height: 8),
            _SettingsRow(
              label: 'Settings',
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
            _SettingsRow(label: 'Sign Out', onTap: () => _signOut(context)),
          ],
        ),
      ),
    );
  }
}

/// The one full-width action on the page. Preview earns it because it is
/// the only control that answers the page's own question — "how do other
/// people see me".
class _PrimaryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback onTap;
  const _PrimaryAction({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ZyraColors.accentBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ZyraColors.accentBorder, width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, size: 21, color: Colors.white),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: ZyraText.body(size: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hint,
                      style: ZyraText.subtext(size: 12, color: Colors.white60),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Equal-weight pair. Edit Photos used to be the only visible action, which
/// made it read as the only one available.
class _SecondaryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SecondaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.13),
              width: 0.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 19, color: Colors.white.withValues(alpha: 0.85)),
              const SizedBox(height: 6),
              Text(
                label,
                style: ZyraText.subtext(size: 12.5, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: ZyraText.subtext(size: 13))),
          Text(value, style: ZyraText.body(size: 13, color: Colors.white)),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _SettingsRow({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: ZyraText.body(size: 13.5, color: Colors.white),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}
