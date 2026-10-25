import 'package:flutter_test/flutter_test.dart';
import 'package:vku_receipt_ocr_expense_tracker/features/ocr/models/recognized_text_result.dart';
import 'package:vku_receipt_ocr_expense_tracker/features/ocr/services/mlkit_ocr_service.dart';

import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('google_mlkit_text_recognizer'),
          (MethodCall methodCall) async {
            return null;
          },
        );
  });
  group('RecognizedTextResult Model Tests', () {
    test(
      'Correctly determines hasText when lines and rawText are populated',
      () {
        const result = RecognizedTextResult(
          rawText: 'HIGHLANDS COFFEE\nTong cong: 59.000 d',
          lines: ['HIGHLANDS COFFEE', 'Tong cong: 59.000 d'],
          blocks: [
            ['HIGHLANDS COFFEE', 'Tong cong: 59.000 d'],
          ],
          imagePath: '/path/to/receipt.jpg',
        );

        expect(result.hasText, isTrue);
        expect(result.lines.length, 2);
        expect(result.rawText, contains('59.000'));
      },
    );

    test('RecognizedTextResult.empty produces hasText false', () {
      final emptyResult = RecognizedTextResult.empty('/empty.jpg');
      expect(emptyResult.hasText, isFalse);
      expect(emptyResult.lines, isEmpty);
      expect(emptyResult.rawText, isEmpty);
    });
  });

  group('MlkitOcrService Validation Tests', () {
    test('Throws exception when file does not exist', () async {
      final service = MlkitOcrService();
      expect(
        () => service.processImage('/non_existent_file_path_12345.jpg'),
        throwsException,
      );
      await service.dispose();
    });
  });
}
