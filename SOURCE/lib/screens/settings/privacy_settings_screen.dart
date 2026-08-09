// Privacy settings — real scope defined 2026-07-26 (DR-ZYRA-101 audit,
// Settings/Search/Notifications build-out). APP/Settings/Summary.md
// was, until this pass, literally "Placeholder — Approved Application
// Structure" with no feature definition at all.
//
// Scope for this pass: a single, genuinely-wired control — "Visible
// in Browse," toggling `profiles.is_active` (ZyraProfileService.
// setVisibility). This is the same column Browse's own discovery
// query filters on (`zyra_discovery_service.dart`: `.eq('is_active',
// true)`) and that profiles_select's RLS policy checks to decide
// whether the row is visible to anyone but its owner — so this
// toggle has a real, immediate effect: turning it off genuinely
// removes the Seeker from Browse for every other signed-in user, not
// just a cosmetic switch. Deliberately kept to one control rather
// than inventing a larger privacy settings surface with no backing
// mechanism yet.

import 'package:flutter/material.dart';
import '../../services/zyra_profile_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_loading.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _loading = true;
  bool _visible = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final visible = await ZyraProfileService.fetchVisibility();
    if (!mounted) return;
    setState(() {
      _visible = visible ?? true;
      _loading = false;
    });
  }

  Future<void> _setVisible(bool value) async {
    setState(() {
      _visible = value;
      _saving = true;
    });
    final ok = await ZyraProfileService.setVisibility(value);
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      setState(() => _visible = !value); // revert on failure
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Couldn't update this — check your connection and try again."),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // FIXED 2026-08-01 (Founder: "there should be no purple at top, it
      // should blend the pink/purple colour... that should be across all
      // things"). Same fix notifications_screen.dart got on 2026-07-27:
      // without this the transparent AppBar shows the Scaffold's own flat
      // background through, cutting the gender gradient off with a hard
      // purple strip. Body content compensates with SafeArea, which still
      // clears the status bar.
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Privacy', style: ZyraText.heading(size: 17)),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: ZyraColors.genderGradient(AppState.instance.gender)),
        child: SafeArea(
          child: _loading
              ? const ZyraLoading()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ZyraColors.iconButtonBg,
                        border: Border.all(color: ZyraColors.iconButtonBorder, width: 0.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Visible in Browse', style: ZyraText.body(size: 14, color: Colors.white)),
                                const SizedBox(height: 4),
                                Text(
                                  'When off, other Seekers will not see your profile in Browse. '
                                  'Existing Matches and Journeys are not affected.',
                                  style: ZyraText.subtext(size: 11.5),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Switch(
                            value: _visible,
                            onChanged: _saving ? null : _setVisible,
                            activeThumbColor: ZyraColors.accentBorder,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'More privacy controls (blocking, who can see your photos, etc.) are not built yet.',
                      style: ZyraText.subtext(size: 11.5, color: Colors.white38),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
