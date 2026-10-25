import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vku_receipt_ocr_expense_tracker/data/models/transaction_model.dart';
import 'package:vku_receipt_ocr_expense_tracker/data/repositories/in_memory_transaction_repository.dart';
import 'package:vku_receipt_ocr_expense_tracker/features/dashboard/providers/dashboard_provider.dart';
import 'package:vku_receipt_ocr_expense_tracker/features/transactions/providers/transaction_provider.dart';
import 'package:vku_receipt_ocr_expense_tracker/features/transactions/screens/transaction_detail_screen.dart';

void main() {
  late InMemoryTransactionRepository repository;
  late TransactionProvider transactionProvider;
  late DashboardProvider dashboardProvider;

  final testTx = TransactionModel(
    id: 'tx-detail-1',
    merchant: 'The Coffee House',
    description: 'Trà sen vàng',
    amount: 69000,
    currency: 'VND',
    transactionDate: '2026-10-12',
    transactionTime: '11:20:00',
    transactionType: 'expense',
    category: 'Food & Drinks',
    paymentMethod: 'E-Wallet',
    referenceNumber: 'TCH9988',
    notes: 'Uống với nhóm bạn',
    createdAt: '2026-10-12T11:20:00.000',
    updatedAt: '2026-10-12T11:20:00.000',
  );

  setUp(() {
    repository = InMemoryTransactionRepository([testTx]);
    transactionProvider = TransactionProvider(repository: repository);
    dashboardProvider = DashboardProvider(repository: repository);
  });

  Widget buildTestableWidget({required TransactionModel transaction}) {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<TransactionProvider>.value(
            value: transactionProvider,
          ),
          ChangeNotifierProvider<DashboardProvider>.value(
            value: dashboardProvider,
          ),
        ],
        child: TransactionDetailScreen(transaction: transaction),
      ),
    );
  }

  testWidgets('TransactionDetailScreen displays transaction information', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget(transaction: testTx));
    await tester.pumpAndSettle();

    expect(find.text('Chi tiết giao dịch'), findsOneWidget);
    expect(find.text('The Coffee House'), findsOneWidget);
    expect(find.text('-69.000 ₫'), findsOneWidget);
    expect(find.text('Chi tiêu'), findsOneWidget);
    expect(find.text('12/10/2026'), findsOneWidget);
    expect(find.text('11:20:00'), findsOneWidget);
    expect(find.text('Ví điện tử'), findsOneWidget);
    expect(find.text('TCH9988'), findsOneWidget);
    expect(find.text('Uống với nhóm bạn'), findsOneWidget);
  });

  testWidgets('TransactionDetailScreen confirms and deletes transaction', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget(transaction: testTx));
    await tester.pumpAndSettle();

    // Tap delete action in AppBar
    final deleteIcon = find.byTooltip('Xóa giao dịch');
    expect(deleteIcon, findsOneWidget);
    await tester.tap(deleteIcon);
    await tester.pumpAndSettle();

    // Verify confirmation dialog
    expect(find.text('Xác nhận xóa'), findsOneWidget);
    expect(find.text('Xóa vĩnh viễn'), findsOneWidget);

    // Tap confirm delete
    await tester.tap(find.text('Xóa vĩnh viễn'));
    await tester.pumpAndSettle();

    // Verify transaction was deleted in repository
    final remaining = await repository.getAllTransactions();
    expect(remaining.isEmpty, isTrue);
  });
}
