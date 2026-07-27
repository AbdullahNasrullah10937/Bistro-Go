// test/widget/primary_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cibus/shared_widgets/primary_button.dart';

void main() {
  group('PrimaryButton Widget Tests', () {
    testWidgets('renders label and triggers onPressed callback when clicked', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Place Order',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Place Order'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, isTrue);
    });

    testWidgets('displays CircularProgressIndicator when isLoading is true and disables tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Place Order',
              isLoading: true,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Place Order'), findsNothing);

      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, isFalse);
    });

    testWidgets('renders optional icon when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Checkout',
              icon: Icons.shopping_bag_outlined,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
      expect(find.text('Checkout'), findsOneWidget);
    });
  });
}
