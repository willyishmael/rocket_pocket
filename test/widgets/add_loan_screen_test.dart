import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/local/database.dart';
import 'package:rocket_pocket/router/paths.dart';
import 'package:rocket_pocket/screens/loan/add_loan_screen.dart';
import 'package:rocket_pocket/screens/loan/loan_screen.dart';
import 'package:rocket_pocket/services/local_notifications_adapter.dart';

void main() {
  testWidgets('saving a loan returns to the refreshed loan list', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        localNotificationsAdapterProvider.overrideWith(
          (ref) => _FakeLocalNotificationsAdapter(),
        ),
      ],
    );
    final router = GoRouter(
      initialLocation: Paths.loan,
      routes: [
        GoRoute(
          path: Paths.loan,
          builder: (context, state) => const LoanScreen(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const AddLoanScreen(),
            ),
          ],
        ),
      ],
    );
    addTearDown(() async {
      router.dispose();
      container.dispose();
      await database.close();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    final title = tester.widget<FlexibleSpaceBar>(
      find.byType(FlexibleSpaceBar),
    );
    expect(title.titlePadding, const EdgeInsets.only(bottom: 16));
    expect(title.centerTitle, isTrue);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Counterparty Name'),
      'Taylor',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Principal Amount'),
      '500',
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1400));
    await tester.pumpAndSettle();

    final titleRect = tester.getRect(find.text('Add Loan'));
    final backButtonRect = tester.getRect(find.byType(IconButton).first);
    expect(titleRect.left, greaterThanOrEqualTo(backButtonRect.right));

    await tester.ensureVisible(find.text('Save Loan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Loan'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, Paths.loan);
    expect(find.text('Taylor'), findsOneWidget);
  });
}

class _FakeLocalNotificationsAdapter extends LocalNotificationsAdapter {
  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    String? payload,
  }) async {}

  @override
  Future<void> cancel(int id) async {}
}
