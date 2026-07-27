// test/widget/empty_state_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cibus/shared_widgets/empty_error_states.dart';

void main() {
  group('EmptyState & ErrorState Widget Tests', () {
    testWidgets('EmptyState renders title, subtitle, custom icon and action button', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'Your cart is empty',
              subtitle: 'Add items from the menu to start your order',
              icon: Icons.shopping_cart_outlined,
              actionLabel: 'Browse Menu',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.text('Add items from the menu to start your order'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
      expect(find.text('Browse Menu'), findsOneWidget);

      await tester.tap(find.text('Browse Menu'));
      expect(actionTriggered, isTrue);
    });

    testWidgets('ErrorState renders error message and retry button', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorState(
              message: 'Failed to connect to backend',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Failed to connect to backend'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      expect(retried, isTrue);
    });
  });
}
