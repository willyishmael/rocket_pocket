import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_pocket/data/local/database.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/viewmodels/add_transaction_view_model.dart';
import 'package:rocket_pocket/viewmodels/pocket_view_model.dart';

void main() {
  test(
    'submit refreshes pocket state immediately for first income transaction',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );
      addTearDown(container.dispose);

      await container.read(pocketViewModelProvider.future);
      await container.read(addTransactionViewModelProvider.future);

      final notifier = container.read(addTransactionViewModelProvider.notifier);
      notifier.setType(TransactionType.income);
      notifier.setDescription('Salary');
      notifier.setAmount(500);

      await notifier.submit();

      final pockets = container.read(pocketViewModelProvider).requireValue;
      expect(pockets, hasLength(1));
      expect(pockets.first.balance, 500);
    },
  );
}
