import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../providers/transaction_provider.dart';
import '../../dashboard/widgets/recent_transaction_tile.dart';
import 'transaction_detail_screen.dart';

/// Transaction history screen with search, type filter, category filter, and date range filter.
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _pickDateRange(BuildContext context) async {
    final provider = context.read<TransactionProvider>();
    final initial =
        provider.dateRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 30)),
          end: DateTime.now(),
        );

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'CHỌN KHOẢNG THỜI GIAN',
      cancelText: 'HỦY',
      confirmText: 'ÁP DỤNG',
    );

    if (picked != null) {
      provider.setDateRange(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lịch sử giao dịch',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Lọc theo ngày',
            icon: const Icon(Icons.date_range_rounded),
            onPressed: () => _pickDateRange(context),
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Search Input
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm đơn vị, nội dung...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) => provider.setSearchQuery(val),
                ),
              ),

              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    // Type: All
                    ChoiceChip(
                      label: const Text('Tất cả'),
                      selected: provider.selectedType == null,
                      onSelected: (_) => provider.setSelectedType(null),
                    ),
                    const SizedBox(width: 8),

                    // Type: Expense
                    ChoiceChip(
                      label: const Text('Chi tiêu'),
                      selected:
                          provider.selectedType == AppConstants.typeExpense,
                      selectedColor: AppColors.expenseRedLight,
                      onSelected: (selected) {
                        provider.setSelectedType(
                          selected ? AppConstants.typeExpense : null,
                        );
                      },
                    ),
                    const SizedBox(width: 8),

                    // Type: Income
                    ChoiceChip(
                      label: const Text('Thu nhập'),
                      selected:
                          provider.selectedType == AppConstants.typeIncome,
                      selectedColor: AppColors.incomeGreenLight,
                      onSelected: (selected) {
                        provider.setSelectedType(
                          selected ? AppConstants.typeIncome : null,
                        );
                      },
                    ),
                    const SizedBox(width: 8),

                    // Category Filter Dropdown / Active Category Chip
                    if (provider.selectedCategory != null)
                      InputChip(
                        avatar: Icon(
                          AppConstants.getCategoryIcon(
                            provider.selectedCategory!,
                          ),
                          size: 16,
                          color: AppColors.getCategoryColor(
                            provider.selectedCategory!,
                          ),
                        ),
                        label: Text(
                          AppConstants.getCategoryLabelVi(
                            provider.selectedCategory!,
                          ),
                        ),
                        selected: true,
                        selectedColor:
                            AppColors.primary.withAlpha(isDark ? 60 : 35),
                        onDeleted: () => provider.setSelectedCategory(null),
                      )
                    else
                      PopupMenuButton<String?>(
                        tooltip: 'Lọc danh mục',
                        onSelected: (cat) => provider.setSelectedCategory(cat),
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: null,
                            child: Text('Tất cả danh mục'),
                          ),
                          ...AppConstants.categories.map(
                            (cat) => PopupMenuItem(
                              value: cat,
                              child: Row(
                                children: [
                                  Icon(
                                    AppConstants.getCategoryIcon(cat),
                                    color: AppColors.getCategoryColor(cat),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(AppConstants.getCategoryLabelVi(cat)),
                                ],
                              ),
                            ),
                          ),
                        ],
                        child: const Chip(
                          avatar: Icon(Icons.filter_list_rounded, size: 16),
                          label: Text('Danh mục'),
                        ),
                      ),

                    if (provider.dateRange != null) ...[
                      const SizedBox(width: 8),
                      InputChip(
                        avatar: const Icon(Icons.event_rounded, size: 16),
                        label: Text(
                          '${DateFormatter.formatForDisplay(DateFormatter.toIsoDate(provider.dateRange!.start))} - ${DateFormatter.formatForDisplay(DateFormatter.toIsoDate(provider.dateRange!.end))}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onDeleted: () => provider.setDateRange(null),
                      ),
                    ],

                    if (provider.selectedCategory != null ||
                        provider.selectedType != null ||
                        provider.dateRange != null ||
                        provider.searchQuery.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.close_rounded, size: 14),
                        label: const Text(
                          'Xóa lọc',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          provider.resetFilters();
                        },
                      ),
                    ],
                  ],
                ),
              ),

              const Divider(height: 16),

              // Transactions list
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.transactions.isEmpty
                    ? EmptyStateView(
                        icon: Icons.filter_list_off_rounded,
                        title: 'Không tìm thấy giao dịch',
                        description:
                            'Thử tìm kiếm với từ khóa khác hoặc xóa bộ lọc.',
                        actionLabel: 'Xóa bộ lọc',
                        onAction: () {
                          _searchController.clear();
                          provider.resetFilters();
                        },
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.loadTransactions(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: provider.transactions.length,
                          itemBuilder: (context, index) {
                            final tx = provider.transactions[index];
                            return RecentTransactionTile(
                              transaction: tx,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TransactionDetailScreen(
                                      transaction: tx,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
