import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../providers/settings_provider.dart';

/// Settings screen for managing theme, app information, data reset, and privacy notes.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _confirmClearAllData(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.expenseRed),
            SizedBox(width: 8),
            Text('Xóa toàn bộ dữ liệu'),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn xóa tất cả giao dịch và ảnh hóa đơn? Toàn bộ sổ thu chi sẽ trở về trạng thái trống ban đầu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expenseRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final txProvider = Provider.of<TransactionProvider>(
                context,
                listen: false,
              );
              final dashProvider = Provider.of<DashboardProvider>(
                context,
                listen: false,
              );

              final success = await txProvider.clearAllTransactions();
              await dashProvider.loadDashboardData();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: success
                        ? AppColors.primary
                        : AppColors.expenseRed,
                    content: Text(
                      success
                          ? 'Đã xóa toàn bộ dữ liệu. Sổ thu chi đã sạch hoàn toàn!'
                          : 'Có lỗi xảy ra khi xóa dữ liệu.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Xác nhận xóa hết'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cài đặt & Thông tin',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
        children: [
          // Section: Theme
          Text(
            'CHẾ ĐỘ HIỂN THỊ',
            style: theme.textTheme.labelMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Sáng'),
                  icon: Icon(Icons.light_mode_rounded, size: 18),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Tối'),
                  icon: Icon(Icons.dark_mode_rounded, size: 18),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('Hệ thống'),
                  icon: Icon(Icons.brightness_auto_rounded, size: 18),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (newSelection) {
                settings.setThemeMode(newSelection.first);
              },
            ),
          ),
          const SizedBox(height: 24),

          // Section: Data Management
          Text(
            'QUẢN LÝ DỮ LIỆU',
            style: theme.textTheme.labelMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),

          Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
              ),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.expenseRed.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.delete_sweep_rounded,
                  color: AppColors.expenseRed,
                ),
              ),
              title: const Text(
                'Xóa toàn bộ dữ liệu giao dịch',
                style: TextStyle(
                  color: AppColors.expenseRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text('Đặt lại số dư và làm sạch tất cả hóa đơn'),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.expenseRed,
              ),
              onTap: () => _confirmClearAllData(context),
            ),
          ),
          const SizedBox(height: 24),

          // Section: Privacy & Storage Note
          Text(
            'BẢO MẬT & QUYỀN RIÊNG TƯ',
            style: theme.textTheme.labelMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.incomeGreenLight.withAlpha(isDark ? 30 : 60),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.incomeGreen.withAlpha(isDark ? 80 : 120),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.incomeGreen.withAlpha(35),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: AppColors.incomeGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '100% On-Device & Ngoại tuyến',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Tất cả tác vụ nhận dạng hóa đơn (Google ML Kit), tiền xử lý ảnh và cơ sở dữ liệu SQLite đều hoạt động độc lập ngay trên thiết bị. Không có dữ liệu hay hình ảnh hóa đơn nào bị tải lên Internet.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: About
          Text(
            'THÔNG TIN ĐỒ ÁN',
            style: theme.textTheme.labelMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Đồ án Mini-Project 3',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Trường ĐH CNTT & Truyền thông Việt - Hàn (VKU)',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.mobile_friendly_rounded,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Cross-Platform Mobile App Development',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle:
                      const Text('Flutter 3.x • Dart 3.x • SQLite • ML Kit'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primaryLight,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Phiên bản',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('1.0.0 (VKU Official Build)'),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Hoàn thiện',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }
}
