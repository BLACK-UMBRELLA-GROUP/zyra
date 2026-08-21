import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/widgets/fab_continue_button.dart';

void main() {
  testWidgets('continue arrow is inset and clears the device safe area', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          size: Size(390, 844),
          padding: EdgeInsets.only(bottom: 34),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [FabContinueButton(active: false, onPressed: null)],
          ),
        ),
      ),
    );

    final positioned = tester.widget<Positioned>(find.byType(Positioned));
    expect(positioned.right, 28);
    expect(positioned.bottom, 56);
  });
}
