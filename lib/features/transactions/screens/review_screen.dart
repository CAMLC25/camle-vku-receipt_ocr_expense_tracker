import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/parsed_receipt.dart';
import '../../../data/models/transaction_model.dart';
import '../../ocr/models/recognized_text_result.dart';
import '../../ocr/widgets/raw_ocr_sheet.dart';
import '../providers/transaction_provider.dart';

/// Mandatory verification screen allowing users to inspect and edit candidate fields before saving.
class ReviewScreen extends StatefulWidget {
  final ParsedReceipt parsedReceipt;
  final String imagePath;

  const ReviewScreen({
    super.key,
    required this.parsedReceipt,
    required this.imagePath,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _notesController;
  late TextEditingController _refController;

  late String _selectedType;
  late String _selectedCategory;
  late String _selectedPaymentMethod;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.parsedReceipt;

    _merchantController = TextEditingController(
      text: p.merchantCandidate ?? '',
    );
    _amountController = TextEditingController(
      text: p.amountCandidate != null ? p.amountCandidate.toString() : '',
    );
    _dateController = TextEditingController(
      text: p.dateCandidate ?? DateFormatter.toIsoDate(DateTime.now()),
    );
    _timeController = TextEditingController(text: p.timeCandidate ?? '');
    _notesController =
        TextEditingController(text: p.sellerAddressCandidate ?? '');
    _refController = TextEditingController(text: p.referenceCandidate ?? '');

    _selectedType = p.transactionTypeCandidate;
    _selectedCategory = AppConstants.categories.contains(p.categoryCandidate)
        ? p.categoryCandidate
        : 'Other';
    _selectedPaymentMethod = p.paymentMethodCandidate ?? 'Cash';
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _notesController.dispose();
    _refController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    DateTime initial = DateTime.now();
    try {
      final parsed = DateTime.parse(_dateController.text);
      initial = parsed;
    } catch (_) {}

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'CHỌN NGÀY GIAO DỊCH',
      cancelText: 'HỦY',
      confirmText: 'CHỌN',
    );

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormatter.toIsoDate(picked);
      });
    }
  }

  Future<void> _selectTime() async {
    TimeOfDay initial = TimeOfDay.now();
    if (_timeController.text.isNotEmpty) {
      final parts = _timeController.text.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) {
          initial = TimeOfDay(hour: h, minute: m);
        }
      }
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'CHỌN GIỜ GIAO DỊCH',
      cancelText: 'HỦY',
      confirmText: 'CHỌN',
    );

    if (picked != null) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      setState(() {
        _timeController.text = '$h:$m:00';
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedAmount = CurrencyFormatter.parseVND(_amountController.text);
    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số tiền hợp lệ lớn hơn 0.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final nowStr = DateTime.now().toIso8601String();
    final newTx = TransactionModel(
      id: const Uuid().v4(),
      merchant: _merchantController.text.trim().isEmpty
          ? 'Giao dịch không tên'
          : _merchantController.text.trim(),
      description: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      amount: parsedAmount,
      currency: 'VND',
      transactionDate: _dateController.text.trim(),
      transactionTime: _timeController.text.trim().isNotEmpty
          ? _timeController.text.trim()
          : null,
      transactionType: _selectedType,
      category: _selectedCategory,
      paymentMethod: _selectedPaymentMethod,
      referenceNumber: _refController.text.trim().isNotEmpty
          ? _refController.text.trim()
          : null,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      receiptImagePath: widget.imagePath,
      rawOcrText: widget.parsedReceipt.rawText,
      createdAt: nowStr,
      updatedAt: nowStr,
    );

    final success = await context.read<TransactionProvider>().addTransaction(
      newTx,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.incomeGreen,
          content: Text('Lưu giao dịch thành công!'),
        ),
      );
      Navigator.pop(context, true); // Pop review screen back to home
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.expenseRed,
          content: Text('Không thể lưu giao dịch. Vui lòng thử lại.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final p = widget.parsedReceipt;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Xác minh & Lưu giao dịch',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Image Preview Header & Raw OCR Button
            Container(
              padding: const EdgeInsets.all(12),
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
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: Image.file(
                        File(widget.imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.receipt_rounded, size: 36),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Document Type Detection Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _getDocTypeColor(p.detectedDocumentType)
                                .withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getDocTypeColor(p.detectedDocumentType)
                                  .withAlpha(120),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                p.documentTypeEmoji,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  p.documentTypeLabelVi,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _getDocTypeColor(
                                      p.detectedDocumentType,
                                    ),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Độ tin cậy OCR: ${(p.confidenceScore * 100).toInt()}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: p.confidenceScore >= 0.7
                                ? AppColors.incomeGreen
                                : p.confidenceScore >= 0.4
                                ? AppColors.warningOrange
                                : AppColors.expenseRed,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Vui lòng kiểm tra và chỉnh sửa trước khi lưu.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Xem văn bản OCR gốc',
                    icon: const Icon(
                      Icons.remove_red_eye_rounded,
                      color: AppColors.primaryLight,
                    ),
                    onPressed: () {
                      RawOcrSheet.show(
                        context,
                        RecognizedTextResult(
                          rawText: p.rawText,
                          lines: p.rawText.split('\n'),
                          blocks: const [],
                          imagePath: widget.imagePath,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Warnings Banner if any
            if (p.hasWarnings) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warningOrangeLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.warningOrange.withAlpha(80),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.warningOrange,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Lưu ý từ bộ nhận diện',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.warningOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...p.warnings.map(
                      (w) => Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '• $w',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9A3412),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Transaction Type Selector (Expense vs Income)
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(
                      () => _selectedType = AppConstants.typeExpense,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedType == AppConstants.typeExpense
                            ? AppColors.expenseRed
                            : (isDark
                                  ? AppColors.surfaceDark
                                  : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Chi tiêu (Tiền ra)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _selectedType == AppConstants.typeExpense
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () =>
                        setState(() => _selectedType = AppConstants.typeIncome),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedType == AppConstants.typeIncome
                            ? AppColors.incomeGreen
                            : (isDark
                                  ? AppColors.surfaceDark
                                  : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Thu nhập (Tiền vào)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _selectedType == AppConstants.typeIncome
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Amount Input
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Số tiền (VNĐ) *',
                prefixIcon: const Icon(Icons.attach_money_rounded),
                suffixText: '₫',
                suffixStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                fillColor: !p.hasAmount
                    ? AppColors.warningOrangeLight.withAlpha(50)
                    : null,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Vui lòng nhập số tiền';
                }
                final parsed = CurrencyFormatter.parseVND(val);
                if (parsed == null || parsed <= 0) {
                  return 'Số tiền phải lớn hơn 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Merchant / Recipient
            TextFormField(
              controller: _merchantController,
              decoration: const InputDecoration(
                labelText: 'Đơn vị / Người nhận *',
                prefixIcon: Icon(Icons.store_rounded),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Vui lòng nhập tên đơn vị hoặc người nhận';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category Selector
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Danh mục chi tiêu *',
                prefixIcon: Icon(Icons.category_rounded),
              ),
              items: AppConstants.categories.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Row(
                    children: [
                      Icon(
                        AppConstants.getCategoryIcon(cat),
                        color: AppColors.getCategoryColor(cat),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(AppConstants.getCategoryLabelVi(cat)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (cat) {
                if (cat != null) {
                  setState(() => _selectedCategory = cat);
                }
              },
            ),
            const SizedBox(height: 16),

            // Date & Time Row
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    onTap: _selectDate,
                    decoration: const InputDecoration(
                      labelText: 'Ngày giao dịch *',
                      prefixIcon: Icon(Icons.calendar_today_rounded),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng chọn ngày';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _timeController,
                    readOnly: true,
                    onTap: _selectTime,
                    decoration: const InputDecoration(
                      labelText: 'Giờ (tùy chọn)',
                      prefixIcon: Icon(Icons.access_time_rounded),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Payment Method
            DropdownButtonFormField<String>(
              initialValue: _selectedPaymentMethod,
              decoration: const InputDecoration(
                labelText: 'Phương thức thanh toán',
                prefixIcon: Icon(Icons.payment_rounded),
              ),
              items: AppConstants.paymentMethods.map((method) {
                return DropdownMenuItem(
                  value: method,
                  child: Text(AppConstants.getPaymentMethodLabelVi(method)),
                );
              }).toList(),
              onChanged: (method) {
                if (method != null) {
                  setState(() => _selectedPaymentMethod = method);
                }
              },
            ),
            const SizedBox(height: 16),

            // Reference code
            TextFormField(
              controller: _refController,
              decoration: const InputDecoration(
                labelText: 'Mã tham chiếu / Mã giao dịch (tùy chọn)',
                prefixIcon: Icon(Icons.tag_rounded),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Ghi chú thêm (tùy chọn)',
                prefixIcon: Icon(Icons.note_alt_rounded),
              ),
            ),
            const SizedBox(height: 28),

            // Action Buttons: Save & Cancel
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveTransaction,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: Text(_isSaving ? 'Đang lưu...' : 'Lưu giao dịch'),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isSaving ? null : () => Navigator.pop(context),
                child: const Text('Hủy / Quét lại ảnh khác'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Maps each [DetectedDocumentType] to a distinct badge color.
  Color _getDocTypeColor(DetectedDocumentType type) {
    switch (type) {
      case DetectedDocumentType.receipt:
        return const Color(0xFF0891B2); // Cyan
      case DetectedDocumentType.bankTransfer:
        return const Color(0xFF2563EB); // Blue
      case DetectedDocumentType.eWallet:
        return const Color(0xFF7C3AED); // Purple
      case DetectedDocumentType.utilityBill:
        return const Color(0xFFEA580C); // Orange
      case DetectedDocumentType.onlineOrder:
        return const Color(0xFF059669); // Emerald
      case DetectedDocumentType.atmWithdrawal:
        return const Color(0xFFDB2777); // Pink
      case DetectedDocumentType.unknown:
        return Colors.grey;
    }
  }
}
