import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:vku_receipt_ocr_expense_tracker/features/ocr/services/image_preprocessor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late String smallImagePath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('test_ocr_');
    
    // Create a synthetic small receipt image (300x400)
    final image = img.Image(width: 300, height: 400);
    img.fill(image, color: img.ColorRgb8(245, 245, 245));
    img.drawString(image, 'TỔNG CỘNG: 100.000 đ', font: img.arial14, x: 20, y: 50, color: img.ColorRgb8(50, 50, 50));
    
    final encoded = img.encodeJpg(image);
    final file = File('${tempDir.path}/small_receipt.jpg');
    await file.writeAsBytes(encoded);
    smallImagePath = file.path;
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ImagePreprocessor On-Device Enhancement Tests', () {
    test('Automatically upscales small thumbnail receipts and enhances contrast', () async {
      final enhancedPath = await ImagePreprocessor.preprocessForOcr(smallImagePath);
      expect(enhancedPath, isNot(equals(smallImagePath)));

      final enhancedFile = File(enhancedPath);
      expect(enhancedFile.existsSync(), isTrue);

      final enhancedBytes = await enhancedFile.readAsBytes();
      final enhancedImage = img.decodeImage(enhancedBytes);
      expect(enhancedImage, isNotNull);

      // Verify that width was upscaled to at least minTargetWidth (1500)
      expect(enhancedImage!.width, greaterThanOrEqualTo(1400));
      expect(enhancedImage.height, greaterThan(enhancedImage.width));

      // Clean up enhanced file
      if (enhancedFile.existsSync()) {
        await enhancedFile.delete();
      }
    });
  });
}
