import 'package:flutter/material.dart';

import '../../../data/models/spending_summary.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';

/// Provider responsible for computing monthly summaries, balances, and recent transactions.
class DashboardProvider extends ChangeNotifier {
  final TransactionRepository repository;

  SpendingSummary _monthlySummary = SpendingSummary.empty;
  Map<String, int> _weeklyExpenses = {};
  List<TransactionModel> _recentTransactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  DateTime _selectedMonth = DateTime.now();

  DashboardProvider({required this.repository});

  SpendingSummary get monthlySummary => _monthlySummary;
  Map<String, int> get weeklyExpenses => _weeklyExpenses;
  List<TransactionModel> get recentTransactions => _recentTransactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get selectedMonth => _selectedMonth;

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _monthlySummary = await repository.getMonthlySummary(
        year: _selectedMonth.year,
        month: _selectedMonth.month,
      );

      _weeklyExpenses = await repository.getWeeklyDailyExpenses(
        endDate: DateTime.now(),
      );

      final all = await repository.getAllTransactions();
      _recentTransactions = all.take(5).toList();
    } catch (e) {
      _errorMessage = 'Không thể tải dữ liệu trang chủ: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void changeMonth(DateTime newMonth) {
    _selectedMonth = newMonth;
    loadDashboardData();
  }
}
