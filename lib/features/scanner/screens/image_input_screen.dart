import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../ocr/models/recognized_text_result.dart';
import '../../ocr/services/mlkit_ocr_service.dart';
import '../../ocr/services/receipt_parser.dart';
import '../../ocr/widgets/raw_ocr_sheet.dart';
import '../../transactions/screens/review_screen.dart';

/// Screen managing image capture, gallery selection, image preview, and on-device OCR triggering.
class ImageInputScreen extends StatefulWidget {
  const ImageInputScreen({super.key});

  @override
  State<ImageInputScreen> createState() => _ImageInputScreenState();
}

class _ImageInputScreenState extends State<ImageInputScreen> {
  final ImagePicker _picker = ImagePicker();
  final MlkitOcrService _ocrService = MlkitOcrService();

  File? _selectedImage;
  bool _isProcessing = false;
  RecognizedTextResult? _ocrResult;
  String? _errorMessage;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 92,
      );

      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
          _ocrResult = null; // Reset previous result for new image
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể chọn ảnh: $e';
      });
    }
  }

  Future<void> _runOcr() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final result = await _ocrService.processImage(_selectedImage!.path);

      if (!mounted) return;

      setState(() {
        _ocrResult = result;
      });

      if (!result.hasText) {
        _showNoTextDialog();
      } else {
        // Parse candidate fields with heuristic engine
        final parsed = ReceiptParser.parse(result);

        // Navigate to the Review and Manual Correction Screen
        final saved = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => ReviewScreen(
              parsedReceipt: parsed,
              imagePath: _selectedImage!.path,
            ),
          ),
        );

        if (saved == true && mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Lỗi nhận diện văn bản: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showNoTextDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warningOrange),
            SizedBox(width: 8),
            Text('Không tìm thấy chữ'),
          ],
        ),
        content: const Text(
          'Google ML Kit không phát hiện được chữ hoặc số trên ảnh này. Vui lòng chụp lại ảnh với ánh sáng tốt hơn, góc chụp thẳng và rõ nét hơn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _pickImage(ImageSource.camera);
            },
            child: const Text('Chụp lại'),
          ),
        ],
      ),
    );
  }

  void _showInspectionSheet(RecognizedTextResult result) {
    RawOcrSheet.show(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quét hóa đơn / Chứng từ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_selectedImage != null)
            IconButton(
              tooltip: 'Chọn ảnh khác',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _isProcessing
                  ? null
                  : () => setState(() => _selectedImage = null),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Error banner if any
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.expenseRedLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.expenseRed.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.expenseRed,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.expenseRed,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Preview Area
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? AppColors.outlineDark
                        : AppColors.outlineLight,
                    width: 2,
                  ),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_selectedImage!, fit: BoxFit.contain),
                            if (_isProcessing)
                              Container(
                                color: Colors.black54,
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Đang phân tích & nhận diện loại ảnh...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'Bảo mật dữ liệu tuyệt đối (Offline)',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.document_scanner_rounded,
                              size: 64,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chụp hoặc chọn ảnh hóa đơn',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Text(
                                'Hỗ trợ hóa đơn mua sắm, cafe, ăn uống, và ảnh chụp chuyển khoản ngân hàng.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Source Selector Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Máy ảnh'),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Thư viện'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Confirm & Scan Button / Inspect Button
            if (_ocrResult != null && _ocrResult!.hasText) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showInspectionSheet(_ocrResult!),
                  icon: const Icon(Icons.text_snippet_rounded),
                  label: Text(
                    'Xem lại ${_ocrResult!.lines.length} dòng OCR đã đọc',
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedImage == null || _isProcessing
                    ? null
                    : _runOcr,
                icon: const Icon(Icons.bolt_rounded),
                label: Text(
                  _ocrResult != null
                      ? 'Nhận diện lại'
                      : 'Tiến hành nhận diện OCR',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
