import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_browse_designs.dart';

const _person = SeekerProfile(
  id: 'confirmation-fixture',
  firstName: 'Sara',
  surnameLine: 'Ahmad',
  age: 27,
  city: 'Birmingham',
  photos: ['paint-only-photo'],
  gender: 'female',
);

void main() {
  for (final width in [320.0, 393.0, 430.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Hide confirmation fits ${width}px at ${scale}x text', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 852);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var cancels = 0;
        var hides = 0;
        var reservedHeight = 0.0;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                padding: const EdgeInsets.only(top: 59, bottom: 34),
                viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: Builder(
              builder: (context) {
                final height = FloatingNavConfirmationBar.layoutHeight(
                  context,
                  viewportWidth: width,
                  showOuterSurface: false,
                  contentEdgeInset: 20,
                );
                reservedHeight = height;
                // The fallback Ahem font may wrap even at normal scale. The
                // footer retains its ordinary height only when its labels fit.
                expect(height, greaterThanOrEqualTo(ZyraNavBarMetrics.height));
                return Scaffold(
                  body: Stack(
                    children: [
                      ZyraBrowseDesigns(
                        profiles: const [_person],
                        selectedIndex: 0,
                        design: ZyraOneJourneyBrowseDesign.portraitCard,
                        hapticLevel: ZyraHapticLevel.off,
                        bottomPadding: (height + 34 + 12)
                            .clamp(100, double.infinity)
                            .toDouble(),
                        photoBuilder:
                            (
                              _,
                              _, {
                              required width,
                              required height,
                              required alignment,
                            }) => const ColoredBox(color: Colors.grey),
                        onNext: () {},
                        onRequest: (_) {},
                        onBrowseMenu: (_) {},
                      ),
                      FloatingNavConfirmationBar(
                        showOuterSurface: false,
                        contentEdgeInset: 20,
                        hapticLevel: ZyraHapticLevel.off,
                        onCancel: () => cancels++,
                        onConfirm: () => hides++,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('browse-hide-outer-surface')),
          findsNothing,
        );
        final cancel = find.byKey(const ValueKey('browse-hide-cancel'));
        final confirm = find.byKey(const ValueKey('browse-hide-confirm'));
        for (final (finder, label) in [
          (cancel, 'Cancel'),
          (confirm, 'Hide profile'),
        ]) {
          final bounds = tester.getRect(finder);
          final text = tester.getRect(find.text(label));
          expect(bounds.height, greaterThanOrEqualTo(44));
          expect(bounds.width, greaterThanOrEqualTo(44));
          expect(
            bounds.height,
            closeTo(reservedHeight - 10, 0.001),
            reason: 'the painter and visible footer use the same font metrics',
          );
          expect(text.left, greaterThanOrEqualTo(bounds.left));
          expect(text.right, lessThanOrEqualTo(bounds.right));
          expect(text.top, greaterThanOrEqualTo(bounds.top));
          expect(text.bottom, lessThanOrEqualTo(bounds.bottom));
        }
        final browseScroll = find.byKey(
          const ValueKey('concept_browse_design_scroll'),
        );
        final outerScrollView = tester.widget<SingleChildScrollView>(
          browseScroll,
        );
        final scrollable = find.descendant(
          of: browseScroll,
          matching: find.byElementPredicate(
            (element) =>
                element.widget is Scrollable &&
                (element.widget as Scrollable).axisDirection ==
                    AxisDirection.down &&
                identical(
                  element
                      .findAncestorWidgetOfExactType<SingleChildScrollView>(),
                  outerScrollView,
                ),
          ),
        );
        expect(scrollable, findsOneWidget);
        final position = tester.state<ScrollableState>(scrollable).position;
        // An overlaid confirmation button can intercept a center drag. This
        // geometry check measures the footer after its actual final offset.
        position.jumpTo(position.maxScrollExtent);
        await tester.pumpAndSettle();
        expect(position.pixels, closeTo(position.maxScrollExtent, 0.001));
        expect(
          tester
              .getRect(find.byKey(const ValueKey('concept_browse_footer')))
              .bottom,
          lessThanOrEqualTo(tester.getRect(cancel).top - 11.99),
          reason: 'the conditional footer reserve prevents content overlap',
        );
        await tester.tapAt(tester.getCenter(cancel));
        await tester.pump();
        await tester.tapAt(tester.getCenter(confirm));
        await tester.pump();
        expect(cancels, 1);
        expect(hides, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
