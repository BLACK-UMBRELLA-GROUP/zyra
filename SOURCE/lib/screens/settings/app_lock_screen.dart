// App Lock settings.
//
// NEW 2026-08-07. One toggle, and deliberately one toggle — the feature is
// a single decision, and a screen of options would make a simple thing look
// like a security product it is not.
//
// See lib/services/zyra_app_lock.dart for the design and its two firm
// rules: there is no PIN of ours, and this is not a security boundary. The
// copy on this screen has to be honest about the second one without
// undermining the first — hence "even when your phone is unlocked", which
// is the true and useful claim, rather than anything implying the data
// itself is protected by this.

import 'package:flutter/material.dart';

import '../../services/zyra_app_lock.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../state/app_state.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final _lock = ZyraAppLock.instance;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Asked once, here, rather than assumed. A device with no biometrics
    // AND no passcode cannot use this, and the honest thing is to say so
    // instead of offering a toggle that silently fails.
    _lock.checkDeviceSupport().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _toggle(bool value) async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await _lock.setEnabled(value);
    if (!mounted) return;
    setState(() => _busy = false);

    // Silence would be ambiguous: a failed authentication and a cancelled
    // one look identical from here, and leaving the toggle to snap back
    // with no explanation is how a working feature gets reported as broken.
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? "App Lock wasn't turned on — that didn't verify."
                : "App Lock is still on — that didn't verify.",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final supported = _lock.deviceSupported;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('App lock', style: ZyraText.heading(size: 17)),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: ZyraColors.genderGradient(AppState.instance.gender),
        ),
        child: SafeArea(
          child: ListView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
                decoration: BoxDecoration(
                  color: ZyraColors.accentBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ZyraColors.accentBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Require Face ID, Touch ID or your passcode',
                        style:
                            ZyraText.body(size: 15, color: Colors.white),
                      ),
                    ),
                    if (_busy)
                      // COLOURED 2026-08-13 (DR-ZYRA-165). This was the
                      // only spinner in the app with no colour set, so it
                      // painted in Material's theme primary on a gender
                      // gradient while every other spinner is
                      // white54/white70.
                      //
                      // Colors.white70 rather than white.withValues(0.7):
                      // identical value (0xB3FFFFFF), but a const, so the
                      // enclosing const SizedBox survives. withValues() is
                      // a method call and cannot appear in a const
                      // expression.
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white70),
                      )
                    else
                      Switch(
                        value: _lock.enabled,
                        onChanged: supported == false ? null : _toggle,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              if (supported == false)
                _Note(
                  'This device has no Face ID, Touch ID, fingerprint or '
                  'passcode set up, so there is nothing for ZYRA to check. '
                  'Add a passcode in your device settings and this will '
                  'become available.',
                  warn: true,
                )
              else ...[
                _Note(
                  'ZYRA will ask to confirm it is you each time you open the '
                  'app — even when your phone is already unlocked. Useful if '
                  'your phone gets passed around.',
                ),
                const SizedBox(height: 14),
                _Note(
                  'ZYRA never sees your face or fingerprint, and there is no '
                  'ZYRA passcode to forget. Your phone does the checking and '
                  'only tells us yes or no.',
                ),
                const SizedBox(height: 14),
                _Note(
                  'This hides ZYRA from someone holding your phone. It is '
                  'not what keeps your account secure — that is your Apple '
                  'or Google sign-in. If Face ID ever stops working you can '
                  'sign out from the lock screen and sign back in.',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final String text;
  final bool warn;
  const _Note(this.text, {this.warn = false});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: ZyraText.subtext(
          size: 12.5,
          color: warn ? const Color(0xFFFFAB91) : Colors.white38,
        ),
      );
}
