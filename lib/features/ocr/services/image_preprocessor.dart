import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Service performing on-device image preprocessing to dramatically improve
/// Google ML Kit OCR text detection on low-resolution, faint, or low-contrast receipts.
class ImagePreprocessor {
  ImagePreprocessor._();

  /// Minimum width recommended for receipt OCR character stroke detection.
  static const int minTargetWidth = 1500;

  /// Maximum dimension to prevent excessive memory usage on mobile devices.
  static const int maxDimension = 2200;

  /// Analyzes and enhances an input image for OCR processing.
  /// Returns the path to the enhanced image file (or the original if already optimal).
  static Future<String> preprocessForOcr(String inputPath) async {
    return compute(_preprocessWorker, inputPath);
  }

  /// Background worker executing compute-intensive image transformations off the UI thread.
  static Future<String> _preprocessWorker(String inputPath) async {
    final file = File(inputPath);
    if (!file.existsSync()) return inputPath;

    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return inputPath;

    bool needsEnhancement = false;
    img.Image processed = image;

    final currentWidth = image.width;
    final currentHeight = image.height;

    // 1. Upscale if too small (e.g. web thumbnails 400-800px)
    if (currentWidth < minTargetWidth && currentHeight < minTargetWidth) {
      final double scale = math.min(
        minTargetWidth / currentWidth,
        maxDimension / currentHeight,
      );
      if (scale > 1.2) {
        final newWidth = (currentWidth * scale).round();
        final newHeight = (currentHeight * scale).round();
        processed = img.copyResize(
          processed,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.cubic,
        );
        needsEnhancement = true;
      }
    } else if (currentWidth > maxDimension || currentHeight > maxDimension) {
      // Downscale if astronomically large to prevent mobile OOM
      final double scale = math.min(
        maxDimension / currentWidth,
        maxDimension / currentHeight,
      );
      final newWidth = (currentWidth * scale).round();
      final newHeight = (currentHeight * scale).round();
      processed = img.copyResize(
        processed,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );
      needsEnhancement = true;
    }

    // 2. Enhance contrast & sharpen faint thermal receipt ink
    // Increase contrast by 35% to separate faint gray text from background
    processed = img.adjustColor(
      processed,
      contrast: 1.35,
      brightness: 1.02,
    );
    needsEnhancement = true;

    if (!needsEnhancement) {
      return inputPath;
    }

    // Save enhanced image to temporary directory
    final tempDir = Directory.systemTemp;
    final ext = p.extension(inputPath);
    final base = p.basenameWithoutExtension(inputPath);
    final outputPath = p.join(
      tempDir.path,
      '${base}_enhanced_${DateTime.now().millisecondsSinceEpoch}$ext',
    );

    final encoded = img.encodeJpg(processed, quality: 92);
    final outFile = File(outputPath);
    await outFile.writeAsBytes(encoded, flush: true);

    return outputPath;
  }
}
