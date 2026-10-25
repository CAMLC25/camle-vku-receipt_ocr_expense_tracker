import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vku_receipt_ocr_expense_tracker/data/models/transaction_model.dart';
import 'package:vku_receipt_ocr_expense_tracker/data/repositories/in_memory_transaction_repository.dart';
import 'package:vku_receipt_ocr_expense_tracker/features/dashboard/providers/dashboard_provider.dart';
import 'package:vku_receipt_ocr_expense_tracker/features/statistics/screens/statistics_screen.dart';
import 'package:vku_receipt_ocr_expense_tracker/features/statistics/widgets/donut_chart_painter.dart';
import 'package:vku_receipt_ocr_expense_tracker/features/statistics/widgets/weekly_bar_chart_painter.dart';

void main() {
  late InMemoryTransactionRepository repository;
  late DashboardProvider dashboardProvider;

  final now = DateTime.now();
  final todayStr =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  final testTransactions = [
    TransactionModel(
      id: 'stat-tx-1',
      merchant: 'Highlands Coffee',
      amount: 60000,
      currency: 'VND',
      transactionDate: todayStr,
      transactionType: 'expense',
      category: 'Food & Drinks',
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    ),
    TransactionModel(
      id: 'stat-tx-2',
      merchant: 'Nhà sách VKU',
      amount: 40000,
      currency: 'VND',
      transactionDate: todayStr,
      transactionType: 'expense',
      category: 'Study',
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    ),
  ];

  setUp(() {
    repository = InMemoryTransactionRepository(testTransactions);
    dashboardProvider = DashboardProvider(repository: repository);
  });

  Widget buildTestableWidget() {
    return MaterialApp(
      home: ChangeNotifierProvider<DashboardProvider>.value(
        value: dashboardProvider,
        child: const StatisticsScreen(),
      ),
    );
  }

  testWidgets(
    'StatisticsScreen renders month picker, segment tabs and DonutChartWidget',
    (tester) async {
      await dashboardProvider.loadDashboardData();
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Check App Title
      expect(find.text('Thống kê chi tiêu'), findsOneWidget);

      // Check Tabs
      expect(find.text('Theo danh mục'), findsOneWidget);
      expect(find.text('Xu hướng 7 ngày'), findsOneWidget);

      // Check Category Donut Chart
      expect(find.byType(DonutChartWidget), findsOneWidget);
      expect(find.text('Phân bổ chi tiêu theo danh mục'), findsOneWidget);

      // Check category details items
      expect(find.text('Ăn uống'), findsOneWidget);
      expect(find.text('Học tập'), findsOneWidget);
    },
  );

  testWidgets(
    'StatisticsScreen switches to Weekly 7-day Bar Chart on tab tap',
    (tester) async {
      await dashboardProvider.loadDashboardData();
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Tap on 'Xu hướng 7 ngày'
      final weeklyTab = find.text('Xu hướng 7 ngày');
      await tester.tap(weeklyTab);
      await tester.pumpAndSettle();

      // Verify Weekly Bar Chart widget rendered
      expect(find.byType(WeeklyBarChartWidget), findsOneWidget);
      expect(find.text('Chi tiêu 7 ngày gần nhất'), findsOneWidget);
      expect(find.text('Chi tiết chi tiêu từng ngày'), findsOneWidget);
    },
  );

  testWidgets('StatisticsScreen displays empty state when month has no data', (
    tester,
  ) async {
    final emptyRepo = InMemoryTransactionRepository();
    final emptyDashboard = DashboardProvider(repository: emptyRepo);
    await emptyDashboard.loadDashboardData();

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<DashboardProvider>.value(
          value: emptyDashboard,
          child: const StatisticsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chưa có chi tiêu trong tháng'), findsOneWidget);
  });
}
