import 'package:intl/intl.dart';

import '../models/transaction_model.dart';
import '../models/spending_summary.dart';
import 'transaction_repository.dart';

/// In-memory implementation of TransactionRepository for initial foundation & testing.
class InMemoryTransactionRepository implements TransactionRepository {
  final List<TransactionModel> _items = [];

  InMemoryTransactionRepository([List<TransactionModel>? initialItems]) {
    if (initialItems != null) {
      _items.addAll(initialItems);
    }
  }

  @override
  Future<List<TransactionModel>> getAllTransactions() async {
    final copy = List<TransactionModel>.from(_items);
    copy.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return copy;
  }

  @override
  Future<TransactionModel?> getTransactionById(String id) async {
    try {
      return _items.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    _items.removeWhere((t) => t.id == transaction.id);
    _items.add(transaction);
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    final index = _items.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _items[index] = transaction;
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _items.removeWhere((t) => t.id == id);
  }

  @override
  Future<SpendingSummary> getMonthlySummary({
    required int year,
    required int month,
  }) async {
    final monthPrefix = '$year-${month.toString().padLeft(2, '0')}';
    int totalExpense = 0;
    int totalIncome = 0;
    int count = 0;
    final Map<String, int> categoryExpenses = {};

    for (final t in _items) {
      if (t.transactionDate.startsWith(monthPrefix)) {
        count++;
        if (t.isExpense) {
          totalExpense += t.amount;
          categoryExpenses[t.category] =
              (categoryExpenses[t.category] ?? 0) + t.amount;
        } else if (t.isIncome) {
          totalIncome += t.amount;
        }
      }
    }

    return SpendingSummary(
      totalExpense: totalExpense,
      totalIncome: totalIncome,
      transactionCount: count,
      expenseByCategory: categoryExpenses,
    );
  }

  @override
  Future<Map<String, int>> getCategoryExpenses({
    required int year,
    required int month,
  }) async {
    final summary = await getMonthlySummary(year: year, month: month);
    return summary.expenseByCategory;
  }

  @override
  Future<Map<String, int>> getWeeklyDailyExpenses({
    required DateTime endDate,
  }) async {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final Map<String, int> daily = {};

    for (int i = 6; i >= 0; i--) {
      final day = endDate.subtract(Duration(days: i));
      final dateStr = formatter.format(day);
      daily[dateStr] = 0;
    }

    for (final t in _items) {
      if (t.isExpense && daily.containsKey(t.transactionDate)) {
        daily[t.transactionDate] = (daily[t.transactionDate] ?? 0) + t.amount;
      }
    }

    return daily;
  }
}
