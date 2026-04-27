import 'package:rocket_pocket/data/model/transaction.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/repositories/pocket_repository.dart';

/// Applies (or reverts) the pocket-balance impact of [tx].
///
/// When [revert] is `true`, the effect is reversed — use this before deleting
/// or replacing a transaction.
Future<void> applyPocketImpact(
  Transaction tx, {
  required bool revert,
  required PocketRepository pocketRepository,
}) async {
  final multiplier = revert ? -1.0 : 1.0;

  if (tx.type.isPositive) {
    await _updatePocketBalance(
      tx.senderPocketId,
      tx.amount * multiplier,
      pocketRepository,
    );
    return;
  }

  if (tx.type == TransactionType.transfer) {
    await _updatePocketBalance(
      tx.senderPocketId,
      -tx.amount * multiplier,
      pocketRepository,
    );
    await _updatePocketBalance(
      tx.receiverPocketId,
      tx.amount * multiplier,
      pocketRepository,
    );
    return;
  }

  // Expense or other negative type: sender debited.
  await _updatePocketBalance(
    tx.senderPocketId,
    -tx.amount * multiplier,
    pocketRepository,
  );
}

Future<void> _updatePocketBalance(
  int? pocketId,
  double delta,
  PocketRepository pocketRepository,
) async {
  if (pocketId == null || delta == 0) return;
  final pocket = await pocketRepository.getPocketById(pocketId);
  if (pocket == null) return;
  await pocketRepository.updatePocket(
    pocket.copyWith(balance: pocket.balance + delta),
  );
}
