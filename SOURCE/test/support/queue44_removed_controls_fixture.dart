// App-frame fixture for removal contracts; no replacement developer controls.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/main.dart';

class Queue44MemberFrame extends StatelessWidget {
  const Queue44MemberFrame({super.key, required this.child, this.scale = 1});
  final Widget child;
  final double scale;
  @override
  Widget build(BuildContext context) {
    final source = const ZyraApp().build(context) as ListenableBuilder;
    return ListenableBuilder(
      listenable: source.listenable,
      builder: (context, _) {
        final app = source.builder(context, null) as MaterialApp;
        return MaterialApp(
          navigatorKey: app.navigatorKey,
          navigatorObservers: app.navigatorObservers ?? const [],
          theme: app.theme,
          scrollBehavior: app.scrollBehavior,
          builder: (context, view) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: app.builder!(context, view),
          ),
          home: child,
        );
      },
    );
  }
}

void expectQueue44ControlsAbsent() {
  expect(
    find.byWidgetPredicate((w) {
      final key = w.key;
      return (key is ValueKey<String> &&
              (key.value.startsWith('dev_') ||
                  key.value.startsWith('identity-dev-'))) ||
          const {
            'ZyraDevControlRail',
            'ZyraDevHomeTools',
            'ZyraDevHoldToOpen',
            'ZyraDevPageOptions',
            'DevScenarioPanelV2',
            'WaliDevScenarioPanel',
            'DeveloperAccessScreen',
            'TesterAccessScreen',
            'ZyraEntryDevPanel',
          }.contains(w.runtimeType.toString());
    }),
    findsNothing,
  );
}

Future<void> holdQueue44MemberPage(WidgetTester tester) async {
  final gesture = await tester.startGesture(const Offset(80, 40));
  await tester.pump(const Duration(seconds: 4));
  await gesture.up();
  await tester.pumpAndSettle();
  expectQueue44ControlsAbsent();
  expect(tester.takeException(), isNull);
}
