import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/file_storage_helper.dart';
import '../../../data/models/transaction_model.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../ocr/models/recognized_text_result.dart';
import '../../ocr/widgets/raw_ocr_sheet.dart';
import '../providers/transaction_provider.dart';

/// Full-detail transaction view displaying receipt image, metadata, and deletion capabilities.
class TransactionDetailScreen extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: AppColors.expenseRed),
            SizedBox(width: 8),
            Text('Xác nhận xóa'),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa giao dịch tại "${transaction.merchant}" không?\nHóa đơn và dữ liệu liên quan sẽ bị xóa vĩnh viễn.',
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
              Navigator.pop(dialogCtx); // Close dialog

              final txProvider = Provider.of<TransactionProvider>(
                context,
                listen: false,
              );
              final success = await txProvider.deleteTransaction(
                transaction.id,
              );

              if (context.mounted) {
                // Refresh dashboard summaries
                Provider.of<DashboardProvider>(
                  context,
                  listen: false,
                ).loadDashboardData();

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.primary,
                      content: Text('Đã xóa giao dịch thành công.'),
                    ),
                  );
                  Navigator.pop(context); // Return to list
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.expenseRed,
                      content: Text(
                        'Không thể xóa giao dịch. Vui lòng thử lại.',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, File imageFile) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black.withAlpha(220),
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(child: Image.file(imageFile, fit: BoxFit.contain)),
            ),
            IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isExpense = transaction.isExpense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết giao dịch'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.expenseRed,
            ),
            tooltip: 'Xóa giao dịch',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Header Card: Merchant & Amount
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 30 : 10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Category Icon Badge
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.getCategoryColor(transaction.category)
                        .withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    AppConstants.getCategoryIcon(transaction.category),
                    color: AppColors.getCategoryColor(transaction.category),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),

                // Merchant
                Text(
                  transaction.merchant,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),

                // Amount
                Text(
                  '${isExpense ? '-' : '+'}${CurrencyFormatter.formatVND(transaction.amount)}',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: isExpense
                        ? AppColors.expenseRed
                        : AppColors.incomeGreen,
                  ),
                ),
                const SizedBox(height: 10),

                // Category & Type Tags
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Chip(
                      label: Text(
                        AppConstants.getCategoryLabelVi(transaction.category),
                        style: const TextStyle(fontSize: 12),
                      ),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide.none,
                      backgroundColor: isDark
                          ? AppColors.surfaceDark
                          : AppColors.outlineLight,
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        isExpense ? 'Chi tiêu' : 'Thu nhập',
                        style: TextStyle(
                          fontSize: 12,
                          color: isExpense
                              ? AppColors.expenseRed
                              : AppColors.incomeGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide.none,
                      backgroundColor:
                          (isExpense
                                  ? AppColors.expenseRed
                                  : AppColors.incomeGreen)
                              .withAlpha(25),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Metadata Details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
              ),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Ngày giao dịch',
                  value: DateFormatter.formatForDisplay(
                    transaction.transactionDate,
                  ),
                ),
                if (transaction.transactionTime != null) ...[
                  const Divider(height: 20),
                  _buildInfoRow(
                    icon: Icons.access_time_rounded,
                    label: 'Giờ giao dịch',
                    value: transaction.transactionTime!,
                  ),
                ],
                if (transaction.paymentMethod != null) ...[
                  const Divider(height: 20),
                  _buildInfoRow(
                    icon: Icons.payment_rounded,
                    label: 'Phương thức thanh toán',
                    value: AppConstants.getPaymentMethodLabelVi(
                      transaction.paymentMethod!,
                    ),
                  ),
                ],
                if (transaction.referenceNumber != null &&
                    transaction.referenceNumber!.isNotEmpty) ...[
                  const Divider(height: 20),
                  _buildInfoRow(
                    icon: Icons.tag_rounded,
                    label: 'Mã tham chiếu / Số HĐ',
                    value: transaction.referenceNumber!,
                  ),
                ],
                if (transaction.notes != null &&
                    transaction.notes!.isNotEmpty) ...[
                  const Divider(height: 20),
                  _buildInfoRow(
                    icon: Icons.note_alt_rounded,
                    label: 'Ghi chú',
                    value: transaction.notes!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Receipt Image section
          if (transaction.receiptImagePath != null) ...[
            FutureBuilder<File?>(
              future: FileStorageHelper.resolveReceiptImage(
                transaction.receiptImagePath,
              ),
              builder: (context, snapshot) {
                final file = snapshot.data;
                if (file == null) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ảnh hóa đơn / chứng từ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _showFullScreenImage(context, file),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Image.file(
                              file,
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            Container(
                              margin: const EdgeInsets.all(10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(160),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.zoom_in_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Chạm để phóng to',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ],

          // Raw OCR Text Inspection
          if (transaction.rawOcrText != null &&
              transaction.rawOcrText!.isNotEmpty) ...[
            OutlinedButton.icon(
              icon: const Icon(Icons.document_scanner_rounded),
              label: const Text('Xem văn bản OCR đã quét'),
              onPressed: () {
                RawOcrSheet.show(
                  context,
                  RecognizedTextResult(
                    rawText: transaction.rawOcrText!,
                    lines: transaction.rawOcrText!.split('\n'),
                    blocks: const [],
                    imagePath: transaction.receiptImagePath ?? '',
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
