import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vku_receipt_ocr_expense_tracker/app.dart';
import 'package:vku_receipt_ocr_expense_tracker/data/models/transaction_model.dart';
import 'package:vku_receipt_ocr_expense_tracker/data/repositories/in_memory_transaction_repository.dart';
import 'package:vku_receipt_ocr_expense_tracker/features/dashboard/providers/dashboard_provider.dart';
import 'package:vku_receipt_ocr_expense_tracker/features/settings/providers/settings_provider.dart';
import 'package:vku_receipt_ocr_expense_tracker/features/transactions/providers/transaction_provider.dart';

void main() {
  testWidgets('App renders dashboard, navigation bar, and metrics', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryTransactionRepository([
      TransactionModel(
        id: 'test-1',
        merchant: 'Highlands Coffee',
        amount: 50000,
        transactionDate: '2026-10-12',
        transactionType: 'expense',
        category: 'Food & Drinks',
        createdAt: '2026-10-12T10:00:00Z',
        updatedAt: '2026-10-12T10:00:00Z',
      ),
    ]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(
            create: (_) => DashboardProvider(repository: repository),
          ),
          ChangeNotifierProvider(
            create: (_) => TransactionProvider(repository: repository),
          ),
        ],
        child: const ExpenseTrackerApp(),
      ),
    );

    // Initial frame
    await tester.pumpAndSettle();

    // Verify app title & navigation items
    expect(find.text('VKU Expense Tracker'), findsOneWidget);
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Lịch sử'), findsOneWidget);
    expect(find.text('Thống kê'), findsOneWidget);
    expect(find.text('Cài đặt'), findsOneWidget);

    // Verify FAB
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
