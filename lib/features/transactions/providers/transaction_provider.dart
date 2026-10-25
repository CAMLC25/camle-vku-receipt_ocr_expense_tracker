import 'package:flutter/material.dart';

import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';

/// Manages transaction list, searching, filtering, and CRUD dispatch.
class TransactionProvider extends ChangeNotifier {
  final TransactionRepository repository;

  List<TransactionModel> _allTransactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Active Filters
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedType; // 'expense', 'income', or null for all
  DateTimeRange? _dateRange;

  TransactionProvider({required this.repository});

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  String? get selectedType => _selectedType;
  DateTimeRange? get dateRange => _dateRange;

  List<TransactionModel> get transactions {
    return _allTransactions.where((t) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchMerchant = t.merchant.toLowerCase().contains(query);
        final matchDesc = t.description?.toLowerCase().contains(query) ?? false;
        final matchNotes = t.notes?.toLowerCase().contains(query) ?? false;
        if (!matchMerchant && !matchDesc && !matchNotes) return false;
      }

      // Category filter
      if (_selectedCategory != null && t.category != _selectedCategory) {
        return false;
      }

      // Type filter
      if (_selectedType != null && t.transactionType != _selectedType) {
        return false;
      }

      // Date range filter
      if (_dateRange != null) {
        final date = DateTime.tryParse(t.transactionDate);
        if (date != null) {
          if (date.isBefore(_dateRange!.start) ||
              date.isAfter(_dateRange!.end.add(const Duration(days: 1)))) {
            return false;
          }
        }
      }

      return true;
    }).toList();
  }

  Future<void> loadTransactions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allTransactions = await repository.getAllTransactions();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách giao dịch: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSelectedType(String? type) {
    _selectedType = type;
    notifyListeners();
  }

  void setDateRange(DateTimeRange? range) {
    _dateRange = range;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _selectedType = null;
    _dateRange = null;
    notifyListeners();
  }

  Future<bool> addTransaction(TransactionModel transaction) async {
    try {
      await repository.addTransaction(transaction);
      await loadTransactions();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể thêm giao dịch: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTransaction(TransactionModel transaction) async {
    try {
      await repository.updateTransaction(transaction);
      await loadTransactions();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể cập nhật giao dịch: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTransaction(String id) async {
    try {
      await repository.deleteTransaction(id);
      await loadTransactions();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể xóa giao dịch: $e';
      notifyListeners();
      return false;
    }
  }

  /// Deletes all transactions and clears associated storage.
  Future<bool> clearAllTransactions() async {
    try {
      final all = await repository.getAllTransactions();
      for (final t in all) {
        await repository.deleteTransaction(t.id);
      }
      await loadTransactions();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể xóa toàn bộ dữ liệu: $e';
      notifyListeners();
      return false;
    }
  }
}
