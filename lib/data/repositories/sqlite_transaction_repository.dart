import '../../core/utils/file_storage_helper.dart';
import '../database/transaction_dao.dart';
import '../models/spending_summary.dart';
import '../models/transaction_model.dart';
import 'transaction_repository.dart';

/// SQLite-backed implementation of [TransactionRepository].
/// Handles persistent local storage, financial aggregations, and receipt image lifecycle.
class SqliteTransactionRepository implements TransactionRepository {
  final TransactionDao _dao;

  SqliteTransactionRepository(this._dao);

  @override
  Future<List<TransactionModel>> getAllTransactions() async {
    return await _dao.getAllTransactions();
  }

  @override
  Future<TransactionModel?> getTransactionById(String id) async {
    return await _dao.getTransactionById(id);
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    TransactionModel toSave = transaction;

    // If an image path was provided, copy it to app-private directory
    if (transaction.receiptImagePath != null &&
        transaction.receiptImagePath!.isNotEmpty) {
      final relativePath = await FileStorageHelper.saveReceiptImage(
        transaction.receiptImagePath!,
      );
      toSave = transaction.copyWith(receiptImagePath: relativePath);
    }

    await _dao.insertTransaction(toSave);
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    TransactionModel toSave = transaction;

    if (transaction.receiptImagePath != null &&
        transaction.receiptImagePath!.isNotEmpty) {
      final relativePath = await FileStorageHelper.saveReceiptImage(
        transaction.receiptImagePath!,
      );
      toSave = transaction.copyWith(receiptImagePath: relativePath);
    }

    await _dao.updateTransaction(toSave);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final existing = await _dao.getTransactionById(id);
    if (existing != null && existing.receiptImagePath != null) {
      await FileStorageHelper.deleteReceiptImage(existing.receiptImagePath);
    }
    await _dao.deleteTransaction(id);
  }

  @override
  Future<SpendingSummary> getMonthlySummary({
    required int year,
    required int month,
  }) async {
    return await _dao.getMonthlySummary(year: year, month: month);
  }

  @override
  Future<Map<String, int>> getCategoryExpenses({
    required int year,
    required int month,
  }) async {
    return await _dao.getCategoryExpenses(year: year, month: month);
  }

  @override
  Future<Map<String, int>> getWeeklyDailyExpenses({
    required DateTime endDate,
  }) async {
    return await _dao.getWeeklyDailyExpenses(endDate: endDate);
  }

  /// Exposes parameterized filtering from the DAO.
  Future<List<TransactionModel>> getFilteredTransactions({
    String? type,
    String? category,
    String? startDate,
    String? endDate,
    String? searchQuery,
  }) async {
    return await _dao.getFilteredTransactions(
      type: type,
      category: category,
      startDate: startDate,
      endDate: endDate,
      searchQuery: searchQuery,
    );
  }
}
