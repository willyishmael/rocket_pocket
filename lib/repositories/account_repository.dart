import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/local/database.dart';
import 'package:rocket_pocket/utils/error_handler/app_error.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return AccountRepository(db);
});

class AccountRepository {
  final AppDatabase db;
  AccountRepository(this.db);

  Future<List<Account>> getAllAccounts() async {
    try {
      return await db.select(db.accounts).get();
    } catch (e, stack) {
      DatabaseError('Failed to fetch all accounts', stack).throwError();
    }
  }

  Future<int> insertAccount(AccountsCompanion account) async {
    try {
      return await db.into(db.accounts).insert(account);
    } catch (e, stack) {
      DatabaseError('Failed to insert account', stack).throwError();
    }
  }

  Future<Account?> getAccountById(int id) async {
    try {
      return await (db.select(db.accounts)
        ..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    } catch (e, stack) {
      DatabaseError('Failed to fetch account by ID', stack).throwError();
    }
  }

  Future updateAccount(AccountsCompanion account) async {
    try {
      return await db.update(db.accounts).replace(account);
    } catch (e, stack) {
      DatabaseError('Failed to update account', stack).throwError();
    }
  }

  Future deleteAccount(int id) async {
    try {
      return await (db.delete(db.accounts)
        ..where((tbl) => tbl.id.equals(id))).go();
    } catch (e, stack) {
      DatabaseError('Failed to delete account', stack).throwError();
    }
  }
}
