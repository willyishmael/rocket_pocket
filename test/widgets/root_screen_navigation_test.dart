import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/router/navigation_helper.dart';
import 'package:rocket_pocket/viewmodels/pocket_view_model.dart';

import '../helpers/test_data_builders.dart';

void main() {
  testWidgets(
    'bottom navigation includes Statistics between Loan and Settings',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          pocketViewModelProvider.overrideWith(
            () => _FakePocketViewModel([
              buildPocketModel(
                id: 1,
                name: 'Main',
                currency: 'USD',
                balance: 100,
                icon: '\$',
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      NavigationHelper();
      addTearDown(() async {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: NavigationHelper.router),
        ),
      );
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      final labels =
          navBar.destinations
              .map((d) => (d as NavigationDestination).label)
              .toList();

      expect(labels, [
        'Dashboard',
        'Transaction',
        'Budget',
        'Loan',
        'Statistics',
        'Settings',
      ]);
    },
  );
}

class _FakePocketViewModel extends PocketViewModel {
  final List<Pocket> _pockets;

  _FakePocketViewModel(this._pockets);

  @override
  Future<List<Pocket>> build() async => _pockets;
}
