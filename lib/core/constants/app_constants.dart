import 'package:flutter/material.dart';

/// Predefined categories, payment methods, and transaction types.
class AppConstants {
  AppConstants._();

  static const String appName = 'VKU Expense Tracker';
  static const String defaultCurrency = 'VND';

  // Transaction Types
  static const String typeExpense = 'expense';
  static const String typeIncome = 'income';

  // Categories
  static const List<String> categories = [
    'Food & Drinks',
    'Study',
    'Travel',
    'Shopping',
    'Entertainment',
    'Bills & Utilities',
    'Healthcare',
    'Transfer',
    'Other',
  ];

  // Vietnamese category labels
  static const Map<String, String> categoryLabelsVi = {
    'Food & Drinks': 'Ăn uống',
    'Study': 'Học tập',
    'Travel': 'Di chuyển',
    'Shopping': 'Mua sắm',
    'Entertainment': 'Giải trí',
    'Bills & Utilities': 'Hóa đơn & Tiện ích',
    'Healthcare': 'Sức khỏe',
    'Transfer': 'Chuyển khoản',
    'Other': 'Khác',
  };

  // Category Icons
  static const Map<String, IconData> categoryIcons = {
    'Food & Drinks': Icons.restaurant_rounded,
    'Study': Icons.school_rounded,
    'Travel': Icons.directions_car_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Entertainment': Icons.movie_filter_rounded,
    'Bills & Utilities': Icons.receipt_long_rounded,
    'Healthcare': Icons.local_hospital_rounded,
    'Transfer': Icons.swap_horiz_rounded,
    'Other': Icons.category_rounded,
  };

  static String getCategoryLabelVi(String category) {
    return categoryLabelsVi[category] ?? category;
  }

  static IconData getCategoryIcon(String category) {
    return categoryIcons[category] ?? Icons.category_rounded;
  }

  // Payment Methods
  static const List<String> paymentMethods = [
    'Cash',
    'Bank Transfer',
    'E-Wallet',
    'Card',
    'Other',
  ];

  static const Map<String, String> paymentMethodLabelsVi = {
    'Cash': 'Tiền mặt',
    'Bank Transfer': 'Chuyển khoản ngân hàng',
    'E-Wallet': 'Ví điện tử',
    'Card': 'Thẻ ngân hàng',
    'Other': 'Khác',
  };

  static String getPaymentMethodLabelVi(String? method) {
    if (method == null) return 'Chưa xác định';
    return paymentMethodLabelsVi[method] ?? method;
  }
}
