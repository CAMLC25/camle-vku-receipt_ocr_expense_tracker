import '../models/transaction_model.dart';
import '../models/spending_summary.dart';

/// Abstract contract for Transaction data persistence and aggregation.
abstract class TransactionRepository {
  Future<List<TransactionModel>> getAllTransactions();
  Future<TransactionModel?> getTransactionById(String id);
  Future<void> addTransaction(TransactionModel transaction);
  Future<void> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);

  Future<SpendingSummary> getMonthlySummary({
    required int year,
    required int month,
  });
  Future<Map<String, int>> getCategoryExpenses({
    required int year,
    required int month,
  });
  Future<Map<String, int>> getWeeklyDailyExpenses({required DateTime endDate});
}
