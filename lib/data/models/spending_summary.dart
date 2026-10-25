/// Aggregated spending metrics used for dashboard cards and charts.
class SpendingSummary {
  final int totalExpense;
  final int totalIncome;
  final int transactionCount;
  final Map<String, int> expenseByCategory; // category -> total amount
  final Map<String, int> dailyExpenses; // YYYY-MM-DD -> total amount

  const SpendingSummary({
    required this.totalExpense,
    required this.totalIncome,
    required this.transactionCount,
    this.expenseByCategory = const {},
    this.dailyExpenses = const {},
  });

  int get netBalance => totalIncome - totalExpense;

  static const SpendingSummary empty = SpendingSummary(
    totalExpense: 0,
    totalIncome: 0,
    transactionCount: 0,
  );
}
