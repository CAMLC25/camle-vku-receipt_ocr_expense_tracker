import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../scanner/screens/image_input_screen.dart';
import '../../transactions/screens/transaction_detail_screen.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/recent_transaction_tile.dart';
import '../widgets/summary_card.dart';

/// Home Dashboard displaying monthly balances, quick actions, and recent transactions.
class DashboardScreen extends StatefulWidget {
  final VoidCallback onNavigateToHistory;

  const DashboardScreen({super.key, required this.onNavigateToHistory});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboardData();
    });
  }

  void _showMonthPicker(BuildContext context) async {
    final provider = context.read<DashboardProvider>();
    final current = provider.selectedMonth;

    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'CHỌN THÁNG XEM BÁO CÁO',
      cancelText: 'HỦY',
      confirmText: 'CHỌN',
    );

    if (picked != null) {
      provider.changeMonth(DateTime(picked.year, picked.month));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'VKU Expense Tracker',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, dashboard, child) {
          if (dashboard.isLoading && dashboard.recentTransactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => dashboard.loadDashboardData(),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              children: [
                // Monthly Summary Card
                SummaryCard(
                  summary: dashboard.monthlySummary,
                  selectedMonth: dashboard.selectedMonth,
                  onSelectMonth: () => _showMonthPicker(context),
                  onResetToCurrentMonth: () => dashboard.changeMonth(
                    DateTime(DateTime.now().year, DateTime.now().month, 1),
                  ),
                ),
                const SizedBox(height: 20),

                // Quick Action Bar
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ImageInputScreen(),
                            ),
                          ).then((_) => dashboard.loadDashboardData());
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(
                              isDark ? 50 : 20,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withAlpha(80),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_rounded,
                                color: AppColors.primaryLight,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Quét hóa đơn',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Recent Transactions Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Giao dịch gần đây',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onNavigateToHistory,
                      child: const Text('Xem tất cả'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Recent List / Empty State
                if (dashboard.recentTransactions.isEmpty)
                  EmptyStateView(
                    icon: Icons.receipt_long_outlined,
                    title: 'Chưa có giao dịch nào',
                    description:
                        'Nhấn Quét hóa đơn để bắt đầu số hóa chi tiêu của bạn!',
                    actionLabel: 'Quét hóa đơn ngay',
                    onAction: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ImageInputScreen(),
                        ),
                      ).then((_) => dashboard.loadDashboardData());
                    },
                  )
                else
                  ...dashboard.recentTransactions.map(
                    (tx) => RecentTransactionTile(
                      transaction: tx,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TransactionDetailScreen(transaction: tx),
                          ),
                        ).then((_) => dashboard.loadDashboardData());
                      },
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
