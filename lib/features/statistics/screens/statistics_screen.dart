import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../widgets/donut_chart_painter.dart';
import '../widgets/weekly_bar_chart_painter.dart';

/// Statistics Screen with month selector, animated category donut chart, and 7-day bar chart.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _selectedTabIndex = 0; // 0: Category Donut, 1: Weekly 7-Day Bars

  void _previousMonth(DashboardProvider dashboard) {
    final cur = dashboard.selectedMonth;
    final prev = DateTime(cur.year, cur.month - 1, 1);
    dashboard.changeMonth(prev);
  }

  void _nextMonth(DashboardProvider dashboard) {
    final cur = dashboard.selectedMonth;
    final next = DateTime(cur.year, cur.month + 1, 1);
    dashboard.changeMonth(next);
  }

  Future<void> _pickMonth(
    BuildContext context,
    DashboardProvider dashboard,
  ) async {
    final initialDate = dashboard.selectedMonth;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'CHỌN THÁNG THỐNG KÊ',
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      dashboard.changeMonth(DateTime(picked.year, picked.month, 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thống kê chi tiêu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, dashboard, child) {
          final summary = dashboard.monthlySummary;
          final categories = summary.expenseByCategory;
          final weekly = dashboard.weeklyExpenses;
          final curMonth = dashboard.selectedMonth;

          final monthLabel = 'Tháng ${curMonth.month} / ${curMonth.year}';
          final isCurrentMonth =
              curMonth.year == DateTime.now().year &&
              curMonth.month == DateTime.now().month;

          return RefreshIndicator(
            onRefresh: () => dashboard.loadDashboardData(),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              children: [
                // Month Selector Header (Only shown when viewing Category breakdown)
                if (_selectedTabIndex == 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.outlineDark
                            : AppColors.outlineLight,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded),
                          tooltip: 'Tháng trước',
                          onPressed: () => _previousMonth(dashboard),
                        ),
                        InkWell(
                          onTap: () => _pickMonth(context, dashboard),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  size: 18,
                                  color: AppColors.primaryLight,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  monthLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (!isCurrentMonth) ...[
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () => dashboard.changeMonth(
                                      DateTime(
                                        DateTime.now().year,
                                        DateTime.now().month,
                                        1,
                                      ),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withAlpha(25),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Hôm nay',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded),
                          tooltip: 'Tháng sau',
                          onPressed: () => _nextMonth(dashboard),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.outlineDark
                            : AppColors.outlineLight,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.insights_rounded,
                          size: 18,
                          color: AppColors.primaryLight,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Xu hướng biến động chi tiêu 7 ngày gần nhất',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Segment Selector (Donut vs Weekly Bars)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedTabIndex = 0),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedTabIndex == 0
                                  ? (isDark
                                        ? AppColors.primaryLight
                                        : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _selectedTabIndex == 0
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(15),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Theo danh mục',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _selectedTabIndex == 0
                                    ? (isDark
                                          ? Colors.white
                                          : AppColors.primary)
                                    : (isDark
                                          ? Colors.white70
                                          : AppColors.textSecondaryLight),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedTabIndex = 1),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedTabIndex == 1
                                  ? (isDark
                                        ? AppColors.primaryLight
                                        : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _selectedTabIndex == 1
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(15),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Xu hướng 7 ngày',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _selectedTabIndex == 1
                                    ? (isDark
                                          ? Colors.white
                                          : AppColors.primary)
                                    : (isDark
                                          ? Colors.white70
                                          : AppColors.textSecondaryLight),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Content View according to selected tab
                if (_selectedTabIndex == 0)
                  _buildCategoryDonutTab(
                    context,
                    categories,
                    summary.totalExpense,
                    isDark,
                  )
                else
                  _buildWeeklyTrendTab(context, weekly, isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryDonutTab(
    BuildContext context,
    Map<String, int> categories,
    int totalExpense,
    bool isDark,
  ) {
    if (categories.isEmpty || totalExpense <= 0) {
      return const EmptyStateView(
        icon: Icons.pie_chart_outline_rounded,
        title: 'Chưa có chi tiêu trong tháng',
        description: 'Chưa có dữ liệu chi tiêu trong tháng này. Quét hóa đơn hoặc tạo giao dịch mới để xem phân bổ danh mục!',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Donut Chart Container Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 20 : 8),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Phân bổ chi tiêu theo danh mục',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              DonutChartWidget(
                categoryExpenses: categories,
                totalExpense: totalExpense,
                size: 210,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Category Breakdown Details List
        const Text(
          'Chi tiết từng danh mục',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...categories.entries.map((entry) {
          final cat = entry.key;
          final amount = entry.value;
          final percent = totalExpense > 0
              ? (amount / totalExpense * 100).toStringAsFixed(1)
              : '0';

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.getCategoryColor(cat).withAlpha(35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    AppConstants.getCategoryIcon(cat),
                    color: AppColors.getCategoryColor(cat),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.getCategoryLabelVi(cat),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '$percent% tổng chi',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  CurrencyFormatter.formatVND(amount),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildWeeklyTrendTab(
    BuildContext context,
    Map<String, int> weekly,
    bool isDark,
  ) {
    int totalWeekExpense = 0;
    for (final v in weekly.values) {
      totalWeekExpense += v;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Weekly Bar Chart Container Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 20 : 8),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chi tiêu 7 ngày gần nhất',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    CurrencyFormatter.formatVND(totalWeekExpense),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.expenseRed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              WeeklyBarChartWidget(weeklyExpenses: weekly, height: 210),
              const SizedBox(height: 8),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Daily Breakdown List
        const Text(
          'Chi tiết chi tiêu từng ngày',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...weekly.entries.toList().reversed.map((entry) {
          final dateStr = entry.key;
          final amount = entry.value;

          final displayDate = DateFormatter.formatForDisplay(dateStr);
          final nowStr = DateFormatter.toIsoDate(DateTime.now());
          final yestStr = DateFormatter.toIsoDate(
            DateTime.now().subtract(const Duration(days: 1)),
          );
          final label = dateStr == nowStr
              ? 'Hôm nay ($displayDate)'
              : (dateStr == yestStr ? 'Hôm qua ($displayDate)' : displayDate);

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      amount > 0
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 18,
                      color: amount > 0
                          ? AppColors.primaryLight
                          : (isDark ? Colors.white30 : Colors.grey.shade400),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight:
                            amount > 0 ? FontWeight.bold : FontWeight.normal,
                        color: amount > 0
                            ? (isDark ? Colors.white : Colors.black87)
                            : (isDark ? Colors.white54 : Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
                Text(
                  amount > 0 ? CurrencyFormatter.formatVND(amount) : '0 đ',
                  style: TextStyle(
                    fontWeight:
                        amount > 0 ? FontWeight.bold : FontWeight.normal,
                    color: amount > 0
                        ? AppColors.expenseRed
                        : (isDark ? Colors.white38 : Colors.grey.shade400),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }
}
