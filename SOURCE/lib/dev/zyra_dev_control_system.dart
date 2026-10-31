// Shared developer control sections for Seeker and Guardian shells.
//
// The edge rail is deliberately navigation, not independent stores:
// Preview reads the current page, Actions changes the existing scenario,
// and Home owns session/account entry points. Founder lock, 2026-08-29:
// visual comparison controls moved out of Developer Tools. Member-safe
// background, type and haptic choices now live in Profile > Personalisation.
// Exact Trio became the one Compatibility Breakdown treatment on 2026-08-29,
// so neither it nor the retired Three-part Rail remains a developer toggle.
// Both roles keep their existing scenario readers and one reset.
// Founder 2026-09-27 exception: the Mobbin splash comparison belongs in
// shared Home.
// Founder 2026-09-29: onboarding styles stay a separate category. Each starts
// the complete local first-use flow at Welcome, without real Auth writes.
// Founder 2026-10-08 cleanup: Home no longer offers gender, app gold, mobile
// menu, opening slide motion or app-icon comparisons. Gold accents remain a
// saved member choice in Personalisation; canonical menu defaults stay intact.
// Founder 2026-10-11: the protected request-style shell supplies Home/Actions
// only. Retained member coordinators keep their existing three sections.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_interaction_style.dart';
import '../theme/zyra_text.dart';
import 'dev_splash_directions.dart';
import 'dev_onboarding_directions.dart';
import 'dev_settings_design.dart';
import 'dev_discovery_directions.dart';
import 'zyra_dev_tool_section.dart';

// The rail is ordered by enum declaration. Home deliberately comes first so
// the one global/reset door is always the first control the Founder reaches;
// page inspection and scenario staging follow underneath it.
enum ZyraDevControlSection { home, preview, actions }

extension ZyraDevControlSectionX on ZyraDevControlSection {
  String get label => switch (this) {
    ZyraDevControlSection.preview => 'Preview',
    ZyraDevControlSection.actions => 'Actions',
    ZyraDevControlSection.home => 'Home',
  };

  IconData get icon => switch (this) {
    ZyraDevControlSection.preview => Icons.visibility_outlined,
    ZyraDevControlSection.actions => Icons.tune,
    ZyraDevControlSection.home => Icons.home_outlined,
  };
}

/// Presentation-only route epoch for cancelling a pending three-second hold.
/// A covered route returning to the same page is still a different epoch.
/// This observer grants no developer access or navigation capability.
class ZyraDevControlsRouteObserver extends NavigatorObserver
    with ChangeNotifier {
  int _revision = 0;
  static int _navigationRevision = 0;
  static final _navigationChanges = ValueNotifier(0);
  static bool _notificationScheduled = false;
  bool _disposed = false;

  int get revision => _revision;
  static int get navigationRevision => _navigationRevision;
  static Listenable get navigationChanges => _navigationChanges;

  void _changed() {
    if (_disposed) return;
    _revision++;
    _navigationRevision++;
    // Epochs change synchronously for dispatch denial, but a nested Navigator
    // may attach during build. Never rebuild an ancestor during that layout.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
      if (!_notificationScheduled) {
        _notificationScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _notificationScheduled = false;
          _navigationChanges.value = _navigationRevision;
        });
      }
    } else {
      notifyListeners();
      _navigationChanges.value = _navigationRevision;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _changed();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _changed();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _changed();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _changed();
}

/// Full-screen, in-place controls header. Closing this presentation does not
/// navigate or replace the member route underneath it.
class ZyraDevControlsPageHeader extends StatelessWidget {
  const ZyraDevControlsPageHeader({
    super.key,
    required this.pageLabel,
    required this.selected,
    required this.onSelected,
    required this.onClose,
  });

  final String pageLabel;
  final ZyraDevControlSection selected;
  final ValueChanged<ZyraDevControlSection> onSelected;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    const sections = [
      ZyraDevControlSection.actions,
      ZyraDevControlSection.preview,
      ZyraDevControlSection.home,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              key: const ValueKey('dev_controls_close'),
              tooltip: 'Close developer controls',
              onPressed: onClose,
              icon: Icon(Icons.close, color: Colors.white70),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Developer controls',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ZyraText.heading(size: 19),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
          child: Text(
            pageLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ZyraText.subtext(size: 13),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              for (final section in sections)
                Expanded(
                  child: Semantics(
                    selected: selected == section,
                    button: true,
                    child: TextButton(
                      key: ValueKey('dev_controls_tab_${section.name}'),
                      onPressed: () => onSelected(section),
                      child: Text(
                        section == ZyraDevControlSection.actions
                            ? 'Page options'
                            : section.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ZyraText.subtext(
                          size: 11,
                          color: selected == section
                              ? ZyraColors.goldText
                              : Colors.white60,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: Colors.white12),
      ],
    );
  }
}

/// Developer doors on the right edge, in the caller's requested order.
///
/// The retained member coordinators keep all three doors by default. A caller
/// can omit a door entirely; an omitted door has no widget or semantics target.
class ZyraDevControlRail extends StatelessWidget {
  final bool open;
  final ZyraDevControlSection selected;
  final ValueChanged<ZyraDevControlSection> onSelected;
  final Map<ZyraDevControlSection, Key> buttonKeys;
  final Map<ZyraDevControlSection, String> labels;
  final List<ZyraDevControlSection> visibleSections;

  const ZyraDevControlRail({
    super.key,
    required this.open,
    required this.selected,
    required this.onSelected,
    this.buttonKeys = const {},
    this.labels = const {},
    this.visibleSections = ZyraDevControlSection.values,
  });

  static const double width = 36;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      right: false,
      child: Align(
        alignment: Alignment.center,
        child: Material(
          color: ZyraColors.modalSheetSurface.withValues(alpha: 242 / 255),
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final section in visibleSections)
                  Tooltip(
                    message: labels[section] ?? section.label,
                    child: Semantics(
                      button: true,
                      selected: open && selected == section,
                      label:
                          '${labels[section] ?? section.label} developer control',
                      child: InkWell(
                        key:
                            buttonKeys[section] ??
                            ValueKey('dev_rail_${section.name}'),
                        onTap: () => onSelected(section),
                        child: SizedBox(
                          width: width,
                          height: 48,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                section.icon,
                                size: 17,
                                color: open && selected == section
                                    ? ZyraColors.accentOnCanvas
                                    : Colors.white54,
                              ),
                              if (open && selected == section)
                                Positioned(
                                  right: 0,
                                  child: SizedBox(
                                    width: 2,
                                    height: 22,
                                    child: ColoredBox(
                                      color: ZyraColors.accentOnCanvas,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ZyraDevPreviewLauncher extends StatelessWidget {
  final String pageLabel;
  final VoidCallback onOpen;

  const ZyraDevPreviewLauncher({
    super.key,
    required this.pageLabel,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('$pageLabel preview', style: ZyraText.heading(size: 20)),
        const SizedBox(height: 8),
        _DevSharedAction(
          key: const ValueKey('dev_open_page_preview'),
          icon: Icons.open_in_new,
          title: 'Open complete page preview',
          onTap: onOpen,
        ),
      ],
    );
  }
}

class ZyraDevHomeTools extends StatelessWidget {
  final bool busy;
  final bool guardian;
  final VoidCallback onHome;
  final VoidCallback onRestart;
  final VoidCallback? onReset;
  final VoidCallback onAccounts;
  final VoidCallback onSeekerSignUp;
  final VoidCallback onGuardianSignUp;
  final VoidCallback? onOpenSplashPreview;

  const ZyraDevHomeTools({
    super.key,
    required this.busy,
    this.guardian = false,
    required this.onHome,
    required this.onRestart,
    required this.onReset,
    required this.onAccounts,
    required this.onSeekerSignUp,
    required this.onGuardianSignUp,
    this.onOpenSplashPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ZyraDevToolSection(
          key: const ValueKey('dev_home_section_navigation'),
          child: _DevSharedAction(
            key: const ValueKey('dev_home_navigation'),
            icon: Icons.home_outlined,
            title: 'Home',
            onTap: busy ? null : onHome,
          ),
        ),
        const SizedBox(height: 16),
        ZyraDevToolSection(
          key: const ValueKey('dev_home_section_discovery_direction'),
          child: DevDiscoveryDirectionPicker(
            enabled: !busy,
            onBeforeOpen: onOpenSplashPreview,
          ),
        ),
        const SizedBox(height: 16),
        ZyraDevToolSection(
          key: const ValueKey('dev_home_section_splash'),
          child: DevSplashDirectionPicker(
            enabled: !busy,
            onBeforeOpen: onOpenSplashPreview,
          ),
        ),
        const SizedBox(height: 16),
        ZyraDevToolSection(
          key: const ValueKey('dev_home_section_onboarding'),
          child: DevOnboardingDirectionPicker(
            enabled: !busy,
            onBeforeOpen: onOpenSplashPreview,
          ),
        ),
        const SizedBox(height: 16),
        ZyraDevToolSection(
          key: const ValueKey('dev_home_section_settings'),
          child: DevSettingsDesignPicker(
            guardian: guardian,
            enabled: !busy,
            onBeforeOpen: onOpenSplashPreview,
          ),
        ),
        const SizedBox(height: 16),
        ZyraDevToolSection(
          key: const ValueKey('dev_home_section_account'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Account controls', style: ZyraText.body(size: 13)),
              const SizedBox(height: 6),
              _DevSharedAction(
                key: const ValueKey('dev_home_login'),
                icon: Icons.login_rounded,
                title: 'Restart at login',
                onTap: onRestart,
              ),
              const SizedBox(height: 8),
              _DevSharedAction(
                key: const ValueKey('dev_reset_state'),
                icon: Icons.restart_alt,
                title: busy ? 'Resetting…' : 'Reset account',
                onTap: busy ? null : onReset,
              ),
              const SizedBox(height: 8),
              _DevSharedAction(
                key: const ValueKey('dev_switch_accounts'),
                icon: Icons.switch_account_outlined,
                title: 'Switch test account',
                onTap: onAccounts,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One app-wide surface selector, deliberately placed in Home rather than a
/// page lab. Every option rebuilds the shared ZYRA tokens and both Dashboards.
class ZyraDevAppSurfacePicker extends StatelessWidget {
  const ZyraDevAppSurfacePicker({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ZyraColors.appSurfaceStyleSelection,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'APP SURFACE',
            style: ZyraText.chapterLabel(color: Colors.white38),
          ),
          const SizedBox(height: 7),
          for (final style in ZyraAppSurfaceStyle.values)
            _DevAppSurfaceOption(
              style: style,
              selected: ZyraColors.appSurfaceStyle == style,
              onTap: () => ZyraColors.selectAppSurfaceStyle(style),
            ),
        ],
      ),
    );
  }
}

class _DevAppSurfaceOption extends StatelessWidget {
  final ZyraAppSurfaceStyle style;
  final bool selected;
  final VoidCallback onTap;

  const _DevAppSurfaceOption({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = switch (style) {
      ZyraAppSurfaceStyle.glassSignals => Icons.linear_scale_rounded,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected
            ? ZyraColors.primaryAction.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: ValueKey('dev_app_surface_${style.name}'),
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.09),
                    border: Border.all(
                      color: selected
                          ? ZyraColors.primaryAction
                          : Colors.white24,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: selected ? ZyraColors.primaryAction : Colors.white60,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    style.label,
                    style: ZyraText.body(size: 12, color: Colors.white),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_rounded,
                    size: 17,
                    color: ZyraColors.primaryAction,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Session-only visual laboratory. The approved wordmark remains locked;
/// relaunching returns to the current Midnight Plum + Poppins defaults.
class ZyraDevStylePanel extends StatelessWidget {
  const ZyraDevStylePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ZyraColors.devPaletteSelection,
        ZyraText.appFontSelection,
        ZyraInteractionStyle.navStyleSelection,
        ZyraInteractionStyle.hapticLevelSelection,
      ]),
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Style lab', style: ZyraText.heading(size: 20)),
            const SizedBox(height: 15),
            Text(
              'DARK BACKGROUNDS',
              style: ZyraText.chapterLabel(color: Colors.white38),
            ),
            const SizedBox(height: 8),
            for (final palette in ZyraDevPalette.values)
              _PaletteOption(
                palette: palette,
                selected: ZyraColors.devPalette == palette,
              ),
            const SizedBox(height: 16),
            Text(
              'NAVIGATION',
              style: ZyraText.chapterLabel(color: Colors.white38),
            ),
            const SizedBox(height: 8),
            for (final style in ZyraNavStyle.values)
              _NavStyleChoice(
                style: style,
                selected: ZyraInteractionStyle.navStyle == style,
              ),
            const SizedBox(height: 16),
            Text(
              'HAPTIC FEEL',
              style: ZyraText.chapterLabel(color: Colors.white38),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.vibration_outlined,
                  size: 17,
                  color: Colors.white54,
                ),
                Expanded(
                  child: Slider(
                    key: const ValueKey('dev_haptic_level'),
                    min: 0,
                    max: (ZyraHapticLevel.values.length - 1).toDouble(),
                    divisions: ZyraHapticLevel.values.length - 1,
                    value: ZyraInteractionStyle.hapticLevel.index.toDouble(),
                    label: ZyraInteractionStyle.hapticLevel.label,
                    onChanged: (value) {
                      final level = ZyraHapticLevel.values[value.round()];
                      if (ZyraInteractionStyle.selectHapticLevel(level)) {
                        ZyraInteractionStyle.emitSelectionHaptic();
                      }
                    },
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    ZyraInteractionStyle.hapticLevel.label,
                    textAlign: TextAlign.end,
                    style: ZyraText.subtext(size: 10.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'APP TEXT',
              style: ZyraText.chapterLabel(color: Colors.white38),
            ),
            const SizedBox(height: 8),
            for (final font in ZyraAppFont.values)
              _FontChoice(font: font, selected: ZyraText.appFont == font),
            const SizedBox(height: 12),
            _DevSharedAction(
              key: const ValueKey('dev_style_reset'),
              icon: Icons.restore,
              title: 'Restore default style',
              onTap: () {
                ZyraColors.selectDevPalette(ZyraColors.currentDefaultPalette);
                ZyraColors.selectAppSurfaceStyle(
                  ZyraColors.currentDefaultSurfaceStyle,
                );
                ZyraText.selectAppFont(ZyraText.currentDefaultFont);
                ZyraInteractionStyle.restoreDefaults();
              },
            ),
          ],
        );
      },
    );
  }
}

class _NavStyleChoice extends StatelessWidget {
  final ZyraNavStyle style;
  final bool selected;

  const _NavStyleChoice({required this.style, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: selected
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          key: ValueKey('dev_nav_style_${style.name}'),
          borderRadius: BorderRadius.circular(11),
          onTap: () => ZyraInteractionStyle.selectNavStyle(style),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                _NavStyleGlyph(style: style),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(style.label, style: ZyraText.body(size: 12.5)),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: ZyraColors.unlockText,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavStyleGlyph extends StatelessWidget {
  final ZyraNavStyle style;
  const _NavStyleGlyph({required this.style});

  @override
  Widget build(BuildContext context) {
    final accent = switch (style) {
      ZyraNavStyle.goldUnderline => ZyraColors.journeyGold,
      ZyraNavStyle.labelledDock => Colors.white,
      _ => ZyraColors.primaryAction,
    };
    return Container(
      width: 52,
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: style == ZyraNavStyle.labelledDock
            ? const Color(0xFF242326)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(3, (index) {
          final active = index == 0;
          return Container(
            width: active && style == ZyraNavStyle.labelledDock ? 18 : 7,
            height: style == ZyraNavStyle.goldUnderline && active ? 2 : 7,
            decoration: BoxDecoration(
              color: active ? accent : Colors.white38,
              shape: style == ZyraNavStyle.accentRing
                  ? BoxShape.circle
                  : BoxShape.rectangle,
              borderRadius: style == ZyraNavStyle.accentRing
                  ? null
                  : BorderRadius.circular(8),
              border: style == ZyraNavStyle.accentRing && active
                  ? Border.all(color: accent, width: 1.5)
                  : null,
            ),
          );
        }),
      ),
    );
  }
}

class _PaletteOption extends StatelessWidget {
  final ZyraDevPalette palette;
  final bool selected;

  const _PaletteOption({required this.palette, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: selected
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          key: ValueKey('dev_palette_${palette.name}'),
          borderRadius: BorderRadius.circular(11),
          onTap: () => ZyraColors.selectDevPalette(palette),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: palette.gradient,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    palette.label,
                    style: ZyraText.body(size: 12.5, color: Colors.white),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: ZyraColors.unlockText,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FontChoice extends StatelessWidget {
  final ZyraAppFont font;
  final bool selected;

  const _FontChoice({required this.font, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('dev_font_${font.name}'),
        onTap: () => ZyraText.selectAppFont(font),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 21,
                child: selected
                    ? const Icon(
                        Icons.check,
                        size: 15,
                        color: ZyraColors.unlockText,
                      )
                    : null,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  font.label,
                  style: ZyraText.preview(
                    font,
                    size: 13.5,
                    color: selected ? Colors.white : Colors.white70,
                  ),
                ),
              ),
              Text(
                'Aa',
                style: ZyraText.preview(font, size: 16, color: Colors.white38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DevSharedAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _DevSharedAction({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(9);
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: onTap == null
                      ? Colors.white38
                      : ZyraColors.primaryAction,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: ZyraText.body(
                      size: 12.5,
                      color: onTap == null ? Colors.white38 : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  size: 17,
                  color: Colors.white24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
