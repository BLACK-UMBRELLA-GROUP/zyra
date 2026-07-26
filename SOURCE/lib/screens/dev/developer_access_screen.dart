// Developer Access — founder testing tool.
//
// Upgraded 2026-07-19 (explicit Founder request, relayed via the
// 2026-07-18 handoff §5) from a plain jump-menu into a test-scenario
// switcher. Two sections:
//
//   1. TEST ACCOUNTS (real backend) — one tap signs into a seeded
//      Supabase test account (real auth session, real RLS, real
//      profiles/subscriptions rows — see supabase/seed_dev_accounts.sql),
//      applies the matching AppState preset, and lands directly on the
//      fully-onboarded Home/WaliHome for that scenario. Hybrid approach
//      per Founder decision 2026-07-19: real rows where realism matters
//      (auth, RLS, backend paths), local AppState for what has no
//      schema yet (plan gating UI, Extended Wali mock).
//      Presets: Seeker ZYRA Basic (male/female), Seeker ZYRA One
//      (male/female), Wali Basic (male/female), Wali One / Extended
//      Wali (male/female — same two accounts as Wali Basic, with a
//      local-only AppState.waliHasExtendedWali mock override; the
//      Extended Wali entitlement engine has no real gating logic
//      wired up yet, even though subscriptions.plan_type does have
//      a real 'wali_premium' value in the schema — added 2026-07-25,
//      Founder request, so male AND female Wali presets exist at
//      both tiers, matching the Seeker section's coverage).
//
//   2. JUMP TO SCREEN — the original jump-menu, unchanged: straight
//      into any onboarding chapter or Home without an account, on mock
//      state, exactly as before.
//
// Test-account sign-in uses ZyraAuth.signInWithTestAccount (password
// auth, dev-only — NOT a user-facing method; Google + Apple remain the
// only real auth per Founder instruction 2026-07-18).
//
// Script_V1.md's Admin Permission System (role == Admin gate) still
// applies once real admin roles exist — this screen remains reachable
// from Welcome only, pre-auth, as a founder tool in the preview build.

import 'package:flutter/material.dart';
import '../../config/supabase_config.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_wali_link_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../home/home_shell.dart';
import '../onboarding/chapter2_flow.dart';
import '../onboarding/onboarding_flow.dart';
import '../onboarding/profile_ready_screen.dart';
import '../onboarding/values_preferences_flow.dart';
import '../wali/wali_home_shell.dart';

class DeveloperAccessScreen extends StatefulWidget {
  const DeveloperAccessScreen({super.key});

  @override
  State<DeveloperAccessScreen> createState() => _DeveloperAccessScreenState();
}

class _DevPreset {
  final String label;
  final String sublabel;
  final String email;
  final bool isWali;
  final ZyraPlan plan;
  final bool extendedWali;
  final String name;
  final String gender;
  final DateTime dob;
  final String location;

  const _DevPreset({
    required this.label,
    required this.sublabel,
    required this.email,
    required this.isWali,
    required this.plan,
    this.extendedWali = false,
    required this.name,
    required this.gender,
    required this.dob,
    required this.location,
  });
}

class _DeveloperAccessScreenState extends State<DeveloperAccessScreen> {
  // Seeded by supabase/seed_dev_accounts.sql. Test-only credentials for
  // a dev/preview database containing no real users — not a secret in
  // any meaningful sense, but rotate them if this project ever holds
  // real data.
  static const String _testPassword = 'ZyraTest!2026';

  static final List<_DevPreset> _presets = [
    _DevPreset(
      label: 'Seeker — ZYRA Basic, male',
      sublabel: 'Adam, 29, London',
      email: 'dev.seeker.basic.m@zyra.test',
      isWali: false,
      plan: ZyraPlan.basic,
      name: 'Adam',
      gender: 'male',
      dob: DateTime(1997, 3, 14),
      location: 'London',
    ),
    _DevPreset(
      label: 'Seeker — ZYRA Basic, female',
      sublabel: 'Maryam, 27, Birmingham — has a linked Wali (Ibrahim)',
      email: 'dev.seeker.basic.f@zyra.test',
      isWali: false,
      plan: ZyraPlan.basic,
      name: 'Maryam',
      gender: 'female',
      dob: DateTime(1998, 7, 22),
      location: 'Birmingham',
    ),
    _DevPreset(
      label: 'Seeker — ZYRA One, male',
      sublabel: 'Yusuf, 31, Manchester',
      email: 'dev.seeker.one.m@zyra.test',
      isWali: false,
      plan: ZyraPlan.one,
      name: 'Yusuf',
      gender: 'male',
      dob: DateTime(1994, 11, 2),
      location: 'Manchester',
    ),
    _DevPreset(
      label: 'Seeker — ZYRA One, female',
      sublabel: 'Aisha, 30, Leeds',
      email: 'dev.seeker.one.f@zyra.test',
      isWali: false,
      plan: ZyraPlan.one,
      name: 'Aisha',
      gender: 'female',
      dob: DateTime(1996, 5, 9),
      location: 'Leeds',
    ),
    _DevPreset(
      label: 'Wali — Basic, male',
      sublabel: 'Ibrahim — linked to Maryam',
      email: 'dev.wali@zyra.test',
      isWali: true,
      plan: ZyraPlan.basic,
      name: 'Ibrahim',
      gender: 'male',
      dob: DateTime(1968, 1, 15),
      location: 'Birmingham',
    ),
    _DevPreset(
      label: 'Wali — Basic, female',
      sublabel: 'Khadija — linked to Yusuf',
      email: 'dev.wali.f@zyra.test',
      isWali: true,
      plan: ZyraPlan.basic,
      name: 'Khadija',
      gender: 'female',
      dob: DateTime(1970, 4, 2),
      location: 'Manchester',
    ),
    _DevPreset(
      label: 'Wali — One, male',
      sublabel: 'Ibrahim, same account — Extended Wali gate open (local mock)',
      email: 'dev.wali@zyra.test',
      isWali: true,
      plan: ZyraPlan.basic,
      extendedWali: true,
      name: 'Ibrahim',
      gender: 'male',
      dob: DateTime(1968, 1, 15),
      location: 'Birmingham',
    ),
    _DevPreset(
      label: 'Wali — One, female',
      sublabel: 'Khadija, same account — Extended Wali gate open (local mock)',
      email: 'dev.wali.f@zyra.test',
      isWali: true,
      plan: ZyraPlan.basic,
      extendedWali: true,
      name: 'Khadija',
      gender: 'female',
      dob: DateTime(1970, 4, 2),
      location: 'Manchester',
    ),
  ];

  String? _busyEmailLabel;
  String? _error;

  // Guards against overlapping switches — checked and set synchronously,
  // before any `await`, so a second tap landing while the first switch
  // is still in flight (e.g. two taps registered in the same frame,
  // before the tiles visually disable) can't start a second, overlapping
  // signOut()+signIn() call. Found 2026-07-19: tapping between test
  // profiles quickly caused several concurrent sign-out/sign-in calls to
  // race each other and crash the app at the native session-storage
  // level (no Dart exception, so it looked unexplained from the logs
  // alone) — `_busyEmailLabel != null` alone wasn't enough of a guard
  // because it's only enforced once the rebuild from setState() has
  // actually run, which isn't necessarily before the next tap lands.
  bool _switching = false;

  Future<void> _enterAs(_DevPreset preset) async {
    if (_switching) return;
    _switching = true;
    setState(() {
      _busyEmailLabel = preset.label;
      _error = null;
    });

    final result = await ZyraAuth.signInWithTestAccount(preset.email, _testPassword);
    _switching = false;
    if (!mounted) return;

    if (result.outcome != ZyraAuthOutcome.success) {
      setState(() {
        _busyEmailLabel = null;
        _error = result.errorMessage ?? 'Test sign-in failed.';
      });
      return;
    }

    final app = AppState.instance;
    if (preset.isWali) {
      app.applyDevPreset(
        // 2026-07-25 fix: gender was never passed here, so
        // AppState.gender stayed null for Wali dev presets and every
        // Wali screen fell back to the neutral brand gradient instead
        // of ZyraColors.brandGradientMale via genderGradient() — the
        // other half of the gap DR-ZYRA-101's audit caught (Seeker
        // dev presets were already correct).
        gender: preset.gender,
        waliName: preset.name,
        waliRelationship: 'Father',
        waliHasExtendedWali: preset.extendedWali,
      );
      // Real linked Seekers from the live wali_links table, so the
      // Dashboard/Seekers tabs show genuine backend data immediately.
      final linked = await ZyraWaliLinkService.fetchLinkedPeople(asWali: true);
      app.setWaliRealLinkedSeekers(linked);
    } else {
      app.applyDevPreset(
        name: preset.name,
        gender: preset.gender,
        dob: preset.dob,
        plan: preset.plan,
        location: preset.location,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => preset.isWali ? const WaliHomeShell() : const HomeShell()),
      (route) => false,
    );
  }

  Future<void> _signOutTestAccount() async {
    if (_switching) return;
    _switching = true;
    setState(() => _error = null);
    await ZyraAuth.signOut();
    _switching = false;
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final backendAvailable = SupabaseConfig.isConfigured;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: ZyraColors.brandGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text('Developer Access', style: ZyraText.heading(size: 22)),
                const SizedBox(height: 6),
                Text(
                  'Enter the app as a preset test account (real backend), or jump straight to a screen (mock state).',
                  style: ZyraText.subtext(),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      if (_error != null) ...[
                        ZyraErrorBanner(message: _error!, onDismiss: () => setState(() => _error = null)),
                        const SizedBox(height: 14),
                      ],
                      Text('TEST ACCOUNTS — REAL BACKEND', style: ZyraText.chapterLabel(color: Colors.white54)),
                      const SizedBox(height: 10),
                      if (!backendAvailable)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Supabase isn\'t configured in this build — test accounts unavailable. The jump-menu below still works on mock state.',
                            style: ZyraText.subtext(size: 12, color: Colors.white38),
                          ),
                        )
                      else ...[
                        ..._presets.map(
                          (p) => _DevTile(
                            label: _busyEmailLabel == p.label ? 'Signing in…' : p.label,
                            sublabel: p.sublabel,
                            icon: p.isWali ? Icons.family_restroom_outlined : Icons.person_outline,
                            onTap: _busyEmailLabel != null ? null : () => _enterAs(p),
                          ),
                        ),
                        if (ZyraAuth.isSignedIn)
                          _DevTile(
                            label: 'Sign out current test account',
                            sublabel: ZyraAuth.currentUser?.email ?? '',
                            icon: Icons.logout,
                            onTap: _busyEmailLabel != null ? null : _signOutTestAccount,
                          ),
                        const SizedBox(height: 8),
                        Text(
                          'Test accounts are seeded rows in the dev database (no photos yet, so they don\'t appear in each other\'s Browse — Browse falls back to mock profiles). Sign-ins here are real Supabase sessions and exercise real RLS.',
                          style: ZyraText.subtext(size: 11, color: Colors.white38),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Text('JUMP TO SCREEN — MOCK STATE', style: ZyraText.chapterLabel(color: Colors.white54)),
                      const SizedBox(height: 10),
                      _DevTile(
                        label: 'Chapter 1 — About You',
                        onTap: () => _push(context, const OnboardingFlow()),
                      ),
                      _DevTile(
                        label: 'Chapter 2 — Your Profile (Male)',
                        onTap: () => _push(context, const Chapter2Flow(gender: 'male')),
                      ),
                      _DevTile(
                        label: 'Chapter 2 — Your Profile (Female)',
                        onTap: () => _push(context, const Chapter2Flow(gender: 'female')),
                      ),
                      _DevTile(
                        label: 'Chapter 3/4 — Values & Preferences (Male)',
                        onTap: () => _push(context, const ValuesPreferencesFlow(gender: 'male')),
                      ),
                      _DevTile(
                        label: 'Chapter 3/4 — Values & Preferences (Female)',
                        onTap: () => _push(context, const ValuesPreferencesFlow(gender: 'female')),
                      ),
                      _DevTile(
                        label: 'Chapter 5 — Profile Ready',
                        onTap: () => _push(context, const ProfileReadyScreen()),
                      ),
                      _DevTile(
                        label: 'Home — Browse / Matches / Profile',
                        onTap: () => _push(context, const HomeShell()),
                      ),
                      _DevTile(
                        label: 'Wali Home — Dashboard / Seekers / Network',
                        onTap: () => _push(context, const WaliHomeShell()),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _DevTile extends StatelessWidget {
  final String label;
  final String? sublabel;
  final IconData? icon;
  final VoidCallback? onTap;
  const _DevTile({required this.label, this.sublabel, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ZyraColors.iconButtonBg,
          border: Border.all(color: ZyraColors.iconButtonBorder, width: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white54, size: 18),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: ZyraText.body(size: 14)),
                        if (sublabel != null && sublabel!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(sublabel!, style: ZyraText.subtext(size: 11, color: Colors.white38)),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
