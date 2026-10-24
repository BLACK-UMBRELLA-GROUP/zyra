import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Closes both Flutter's editable focus and the native software keyboard.
///
/// Clearing focus is normally sufficient, but iOS can keep the keyboard
/// painted for a frame while an IndexedStack changes its visible child. The
/// explicit platform hide makes tab changes deterministic without disposing
/// the form that lives in the now-hidden tab.
void dismissZyraKeyboard() {
  FocusManager.instance.primaryFocus?.unfocus();
  SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
}

/// Repeats dismissal after the next frame so route transitions cannot restore
/// focus after the first notification has already fired.
void dismissZyraKeyboardAfterNavigation() {
  dismissZyraKeyboard();
  WidgetsBinding.instance.addPostFrameCallback((_) => dismissZyraKeyboard());
}

/// App-wide mobile keyboard dismissal.
///
/// Flutter deliberately keeps a focused text field open after a touch outside
/// it on iOS and Android. ZYRA's forms should behave consistently instead:
/// touching anywhere outside the active field dismisses the keyboard while
/// allowing the underlying button, link or scroll gesture to continue.
class ZyraKeyboardDismissScope extends StatelessWidget {
  final Widget child;

  const ZyraKeyboardDismissScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Actions(
    actions: <Type, Action<Intent>>{
      EditableTextTapOutsideIntent:
          CallbackAction<EditableTextTapOutsideIntent>(
            onInvoke: (intent) {
              intent.focusNode.unfocus();
              dismissZyraKeyboard();
              return null;
            },
          ),
    },
    child: child,
  );
}

/// Clears any editable focus when navigation changes the visible page.
///
/// A field can remain focused while its route is popping, particularly on
/// iOS, which leaves the keyboard painted over the destination screen. This
/// observer closes that gap for push, pop, replace and remove transitions.
class ZyraKeyboardDismissNavigatorObserver extends NavigatorObserver {
  void _dismiss() => dismissZyraKeyboardAfterNavigation();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _dismiss();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _dismiss();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _dismiss();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _dismiss();
  }
}
