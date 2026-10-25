import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vku_receipt_ocr_expense_tracker/data/models/parsed_receipt.dart';
import 'package:vku_receipt_ocr_expense_tracker/data/repositories/in_memory_transaction_repository.dart';
import 'package:vku_receipt_ocr_expense_tracker/features/transactions/providers/transaction_provider.dart';
import 'package:vku_receipt_ocr_expense_tracker/features/transactions/screens/review_screen.dart';

void main() {
  late InMemoryTransactionRepository repository;
  late TransactionProvider provider;

  setUp(() {
    repository = InMemoryTransactionRepository();
    provider = TransactionProvider(repository: repository);
  });

  Widget buildTestableWidget({required ParsedReceipt receipt}) {
    return MaterialApp(
      home: ChangeNotifierProvider<TransactionProvider>.value(
        value: provider,
        child: ReviewScreen(
          parsedReceipt: receipt,
          imagePath: '/fake/receipt.jpg',
        ),
      ),
    );
  }

  testWidgets('ReviewScreen renders parsed candidate values', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final receipt = ParsedReceipt(
      merchantCandidate: 'Phúc Long Coffee',
      amountCandidate: 65000,
      dateCandidate: '2026-10-12',
      timeCandidate: '14:30',
      categoryCandidate: 'Food & Drinks',
      transactionTypeCandidate: 'expense',
      paymentMethodCandidate: 'Cash',
      referenceCandidate: 'PL12345',
      rawText: 'Phuc Long Coffee\n65.000 d',
      confidenceScore: 0.85,
      warnings: const ['Vui lòng kiểm tra lại đơn vị'],
    );

    await tester.pumpWidget(buildTestableWidget(receipt: receipt));
    await tester.pumpAndSettle();

    expect(find.text('Xác minh & Lưu giao dịch'), findsOneWidget);
    expect(find.text('Phúc Long Coffee'), findsOneWidget);
    expect(find.text('65000'), findsOneWidget);
    expect(find.text('Độ tin cậy OCR: 85%'), findsOneWidget);
    expect(find.text('Lưu giao dịch'), findsOneWidget);
    expect(find.textContaining('Vui lòng kiểm tra lại đơn vị'), findsOneWidget);
  });

  testWidgets('ReviewScreen shows validation errors when fields are empty', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final receipt = ParsedReceipt.empty('/fake/receipt.jpg');

    await tester.pumpWidget(buildTestableWidget(receipt: receipt));
    await tester.pumpAndSettle();

    // Tap save button without filling required fields
    final saveButton = find.text('Lưu giao dịch');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Check that validators triggered
    expect(
      find.text('Vui lòng nhập tên đơn vị hoặc người nhận'),
      findsOneWidget,
    );
    expect(find.text('Vui lòng nhập số tiền'), findsOneWidget);
  });

  testWidgets('ReviewScreen allows editing and saves transaction', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final receipt = ParsedReceipt(
      merchantCandidate: 'Old Shop',
      amountCandidate: 25000,
      dateCandidate: '2026-10-12',
      categoryCandidate: 'Food & Drinks',
      rawText: 'Raw OCR',
      confidenceScore: 0.7,
      warnings: const [],
    );

    await tester.pumpWidget(buildTestableWidget(receipt: receipt));
    await tester.pumpAndSettle();

    // Change merchant text
    final merchantField = find.widgetWithText(TextFormField, 'Old Shop');
    await tester.enterText(merchantField, 'The Coffee House');

    // Change amount
    final amountField = find.widgetWithText(TextFormField, '25000');
    await tester.enterText(amountField, '45000');

    // Scroll to and tap Save
    final saveButton = find.text('Lưu giao dịch');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Verify transaction was added to the provider repository
    expect(provider.transactions.length, 1);
    final saved = provider.transactions.first;
    expect(saved.merchant, 'The Coffee House');
    expect(saved.amount, 45000);
    expect(saved.category, 'Food & Drinks');
  });
}
