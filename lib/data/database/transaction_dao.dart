import 'package:sqflite/sqflite.dart';

import '../models/spending_summary.dart';
import '../models/transaction_model.dart';
import 'app_database.dart';

/// Data Access Object (DAO) for transactions table.
/// Encapsulates all SQLite CRUD operations, parameterized queries, and financial aggregations.
class TransactionDao {
  final Database _database;

  TransactionDao(this._database);

  /// Inserts a new transaction into SQLite using parameterized query.
  Future<void> insertTransaction(TransactionModel item) async {
    await _database.insert(
      AppDatabase.tableTransactions,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Updates an existing transaction by UUID.
  Future<int> updateTransaction(TransactionModel item) async {
    return await _database.update(
      AppDatabase.tableTransactions,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Deletes a transaction by UUID.
  Future<int> deleteTransaction(String id) async {
    return await _database.delete(
      AppDatabase.tableTransactions,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Retrieves a single transaction by UUID.
  Future<TransactionModel?> getTransactionById(String id) async {
    final rows = await _database.query(
      AppDatabase.tableTransactions,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TransactionModel.fromMap(rows.first);
  }

  /// Retrieves all transactions ordered chronologically (newest first).
  Future<List<TransactionModel>> getAllTransactions() async {
    final rows = await _database.query(
      AppDatabase.tableTransactions,
      orderBy: 'transaction_date DESC, created_at DESC',
    );
    return rows.map((r) => TransactionModel.fromMap(r)).toList();
  }

  /// Filters transactions using parameterized queries.
  Future<List<TransactionModel>> getFilteredTransactions({
    String? type,
    String? category,
    String? startDate,
    String? endDate,
    String? searchQuery,
  }) async {
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (type != null && type.isNotEmpty && type.toLowerCase() != 'all') {
      whereClauses.add('transaction_type = ?');
      whereArgs.add(type.toLowerCase());
    }

    if (category != null && category.isNotEmpty && category != 'All') {
      whereClauses.add('category = ?');
      whereArgs.add(category);
    }

    if (startDate != null && startDate.isNotEmpty) {
      whereClauses.add('transaction_date >= ?');
      whereArgs.add(startDate);
    }

    if (endDate != null && endDate.isNotEmpty) {
      whereClauses.add('transaction_date <= ?');
      whereArgs.add(endDate);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final queryParam = '%${searchQuery.trim()}%';
      whereClauses.add(
        '(merchant LIKE ? OR description LIKE ? OR notes LIKE ? OR reference_number LIKE ?)',
      );
      whereArgs.addAll([queryParam, queryParam, queryParam, queryParam]);
    }

    final whereString = whereClauses.isEmpty
        ? null
        : whereClauses.join(' AND ');

    final rows = await _database.query(
      AppDatabase.tableTransactions,
      where: whereString,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'transaction_date DESC, created_at DESC',
    );

    return rows.map((r) => TransactionModel.fromMap(r)).toList();
  }

  /// Aggregates income, expense, count, and category distributions for a specific month.
  Future<SpendingSummary> getMonthlySummary({
    required int year,
    required int month,
  }) async {
    final startStr = '$year-${month.toString().padLeft(2, '0')}-01';
    final lastDay = DateTime(year, month + 1, 0).day;
    final endStr =
        '$year-${month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

    // 1. Total Expense
    final expenseRows = await _database.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM ${AppDatabase.tableTransactions} WHERE transaction_type = ? AND transaction_date >= ? AND transaction_date <= ?',
      ['expense', startStr, endStr],
    );
    final totalExpense = (expenseRows.first['total'] as num?)?.toInt() ?? 0;

    // 2. Total Income
    final incomeRows = await _database.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM ${AppDatabase.tableTransactions} WHERE transaction_type = ? AND transaction_date >= ? AND transaction_date <= ?',
      ['income', startStr, endStr],
    );
    final totalIncome = (incomeRows.first['total'] as num?)?.toInt() ?? 0;

    // 3. Count
    final countRows = await _database.rawQuery(
      'SELECT COUNT(*) AS count FROM ${AppDatabase.tableTransactions} WHERE transaction_date >= ? AND transaction_date <= ?',
      [startStr, endStr],
    );
    final count = (countRows.first['count'] as num?)?.toInt() ?? 0;

    // 4. Expenses by Category
    final categoryRows = await _database.rawQuery(
      'SELECT category, COALESCE(SUM(amount), 0) AS cat_total FROM ${AppDatabase.tableTransactions} WHERE transaction_type = ? AND transaction_date >= ? AND transaction_date <= ? GROUP BY category ORDER BY cat_total DESC',
      ['expense', startStr, endStr],
    );
    final categoryBreakdown = <String, int>{};
    for (final row in categoryRows) {
      final cat = row['category'] as String;
      final amount = (row['cat_total'] as num).toInt();
      categoryBreakdown[cat] = amount;
    }

    // 5. Daily Expenses in month
    final dailyRows = await _database.rawQuery(
      'SELECT transaction_date, COALESCE(SUM(amount), 0) AS day_total FROM ${AppDatabase.tableTransactions} WHERE transaction_type = ? AND transaction_date >= ? AND transaction_date <= ? GROUP BY transaction_date',
      ['expense', startStr, endStr],
    );
    final dailyExpenses = <String, int>{};
    for (final row in dailyRows) {
      final date = row['transaction_date'] as String;
      final amount = (row['day_total'] as num).toInt();
      dailyExpenses[date] = amount;
    }

    return SpendingSummary(
      totalExpense: totalExpense,
      totalIncome: totalIncome,
      transactionCount: count,
      expenseByCategory: categoryBreakdown,
      dailyExpenses: dailyExpenses,
    );
  }

  /// Returns expense sums by category for a specific month.
  Future<Map<String, int>> getCategoryExpenses({
    required int year,
    required int month,
  }) async {
    final summary = await getMonthlySummary(year: year, month: month);
    return summary.expenseByCategory;
  }

  /// Returns 7 daily expense values leading up to [endDate] for weekly bar charts.
  Future<Map<String, int>> getWeeklyDailyExpenses({
    required DateTime endDate,
  }) async {
    // Generate all 7 day strings from (endDate - 6 days) to endDate
    final result = <String, int>{};
    for (int i = 6; i >= 0; i--) {
      final d = endDate.subtract(Duration(days: i));
      final dStr =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      result[dStr] = 0;
    }

    final startDate = endDate.subtract(const Duration(days: 6));
    final startStr =
        '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    final endStr =
        '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

    final rows = await _database.rawQuery(
      'SELECT transaction_date, COALESCE(SUM(amount), 0) AS day_total FROM ${AppDatabase.tableTransactions} WHERE transaction_type = ? AND transaction_date >= ? AND transaction_date <= ? GROUP BY transaction_date',
      ['expense', startStr, endStr],
    );

    for (final row in rows) {
      final date = row['transaction_date'] as String;
      final amount = (row['day_total'] as num).toInt();
      if (result.containsKey(date)) {
        result[date] = amount;
      }
    }

    return result;
  }
}
