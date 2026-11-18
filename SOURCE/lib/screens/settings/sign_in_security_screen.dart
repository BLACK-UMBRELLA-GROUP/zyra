import 'package:flutter/material.dart';
import '../../dev/zyra_app_gold_preview.dart';

import '../../services/zyra_auth.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';

class SignInSecurityScreen extends StatefulWidget {
  const SignInSecurityScreen({super.key});

  @override
  State<SignInSecurityScreen> createState() => _SignInSecurityScreenState();
}

class _SignInSecurityScreenState extends State<SignInSecurityScreen> {
  @override
  Widget build(BuildContext context) {
    final providers = ZyraAuth.linkedProviders;
    final methods = <_CurrentSignInMethod>[
      if (providers.contains('apple'))
        _CurrentSignInMethod(
          key: 'apple',
          icon: Icons.apple,
          title: 'Apple',
          detail: ZyraAuth.providerEmail('apple') ?? 'Connected',
        ),
      if (providers.contains('google'))
        _CurrentSignInMethod(
          key: 'google',
          icon: Icons.g_mobiledata,
          title: 'Google',
          detail: ZyraAuth.providerEmail('google') ?? 'Connected',
        ),
    ];

    // Seeded developer personas currently use an email identity. Keep that
    // existing method visible without presenting email as a public sign-up
    // choice or offering an unsupported provider-linking action.
    if (methods.isEmpty) {
      methods.add(
        _CurrentSignInMethod(
          key: 'email',
          icon: Icons.alternate_email,
          title: 'Email sign-in',
          detail: ZyraAuth.currentUser?.email ?? 'Connected',
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Sign-in & security', style: ZyraText.heading(size: 17)),
        iconTheme: IconThemeData(color: ZyraColors.ink(0.70)),
      ),
      body: Container(
        decoration: ZyraAppGoldDecoration(gradient: ZyraColors.brandGradient),
        child: SafeArea(
          child: ListView(
            physics: const ScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 90),
            children: [
              Text('How you sign in', style: ZyraText.heading(size: 24)),
              SizedBox(height: 8),
              Text(
                'These are the sign-in methods currently connected to your ZYRA account.',
                style: ZyraText.body(size: 13.5),
              ),
              SizedBox(height: 22),
              Text(
                'CURRENT SIGN-IN METHODS',
                style: ZyraText.chapterLabel(color: ZyraColors.ink(0.54)),
              ),
              SizedBox(height: 9),
              for (var index = 0; index < methods.length; index++) ...[
                _MethodCard(
                  key: ValueKey('sign_in_method_${methods[index].key}'),
                  icon: methods[index].icon,
                  title: methods[index].title,
                  detail: methods[index].detail,
                ),
                if (index != methods.length - 1) SizedBox(height: 10),
              ],
              SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 16,
                    color: ZyraColors.ink(0.38),
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'ZYRA never creates or stores a password.',
                      style: ZyraText.subtext(size: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;

  const _MethodCard({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return _SecurityCard(
      child: Row(
        children: [
          Icon(icon, color: ZyraColors.foreground, size: 23),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ZyraText.body(size: 14.5)),
                SizedBox(height: 3),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ZyraText.subtext(size: 11.5),
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
          const _ConnectedBadge(),
        ],
      ),
    );
  }
}

class _CurrentSignInMethod {
  final String key;
  final IconData icon;
  final String title;
  final String detail;

  const _CurrentSignInMethod({
    required this.key,
    required this.icon,
    required this.title,
    required this.detail,
  });
}

class _SecurityCard extends StatelessWidget {
  final Widget child;

  const _SecurityCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: ZyraColors.iconButtonBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ZyraColors.iconButtonBorder),
      ),
      child: child,
    );
  }
}

class _ConnectedBadge extends StatelessWidget {
  const _ConnectedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: ZyraColors.positiveGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: ZyraColors.positiveGreen.withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        'Connected',
        style: ZyraText.subtext(size: 10.5, color: ZyraColors.espresso),
      ),
    );
  }
}
