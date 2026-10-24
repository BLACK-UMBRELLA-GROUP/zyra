import 'package:flutter/material.dart';

import '../screens/settings/settings_screen.dart';
import '../services/zyra_developer_access.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import 'dev_settings_design_state.dart';

/// Founder-only visual comparison. It opens the existing Settings routes, so
/// the candidate shows the real Seeker/Guardian content and never fabricates
/// a theme, language or account control that ZYRA does not support.
class DevSettingsDesignPicker extends StatelessWidget {
  const DevSettingsDesignPicker({
    super.key,
    required this.guardian,
    this.enabled = true,
    this.onBeforeOpen,
  });

  final bool guardian;
  final bool enabled;
  final VoidCallback? onBeforeOpen;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ZyraDeveloperAccess.authorizationChanges,
    builder: (context, _) {
      if (!ZyraDeveloperAccess.isMainAppFounderPreview) {
        return const SizedBox.shrink();
      }
      return ValueListenableBuilder<ZyraSettingsDesign>(
        valueListenable: ZyraDevSettingsDesign.selection,
        builder: (context, selected, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings design', style: ZyraText.body(size: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final design in ZyraSettingsDesign.values)
                  ChoiceChip(
                    key: ValueKey('dev_settings_design_${design.name}'),
                    selected: selected == design,
                    label: Text(
                      design == ZyraSettingsDesign.current
                          ? 'Current'
                          : 'Smooth cards',
                      style: ZyraText.body(size: 11),
                    ),
                    selectedColor: ZyraColors.unlockText.withValues(alpha: .24),
                    onSelected: enabled
                        ? (_) => ZyraDevSettingsDesign.select(design)
                        : null,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const ValueKey('dev_settings_open'),
              onPressed: enabled
                  ? () {
                      onBeforeOpen?.call();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SettingsScreen(guardian: guardian),
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Open Settings'),
            ),
          ],
        ),
      );
    },
  );
}
