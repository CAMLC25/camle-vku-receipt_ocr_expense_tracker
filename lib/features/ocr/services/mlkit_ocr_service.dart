import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/recognized_text_result.dart';
import 'image_preprocessor.dart';

/// Helper holding an OCR text line and its bounding rectangle for spatial sorting.
class _LineBox {
  final String text;
  final Rect box;

  const _LineBox(this.text, this.box);
}

/// Service wrapping Google ML Kit Text Recognition for on-device OCR inference.
class MlkitOcrService {
  TextRecognizer? _textRecognizer;

  MlkitOcrService() {
    _initRecognizer();
  }

  void _initRecognizer() {
    _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
  }

  /// Processes an image from a local file path and extracts recognized text, lines, and blocks.
  /// Automatically runs an on-device preprocessing pass (super-resolution upscaling + contrast enhancement)
  /// whenever an image has low resolution or yields few text lines.
  Future<RecognizedTextResult> processImage(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception('Tệp ảnh không tồn tại: $imagePath');
    }

    _initRecognizer();

    // 1. Pass 1: Run OCR on the original image
    final initialResult = await _runOcrOnFile(imagePath, displayImagePath: imagePath);

    // 2. Pass 2: If the initial pass detected few lines (<= 5 lines, e.g. thumbnail or faint print),
    // run on-device super-resolution upscaling and contrast enhancement.
    if (initialResult.lines.length <= 5) {
      try {
        final enhancedPath = await ImagePreprocessor.preprocessForOcr(imagePath);
        if (enhancedPath != imagePath) {
          final enhancedResult = await _runOcrOnFile(
            enhancedPath,
            displayImagePath: imagePath,
          );
          // Prefer enhanced result if it successfully recovered more text
          if (enhancedResult.lines.length > initialResult.lines.length) {
            return enhancedResult;
          }
        }
      } catch (_) {
        // Fallback gracefully to initialResult
      }
    }

    return initialResult;
  }

  Future<RecognizedTextResult> _runOcrOnFile(
    String filePath, {
    required String displayImagePath,
  }) async {
    final inputImage = InputImage.fromFilePath(filePath);

    try {
      final RecognizedText recognizedText = await _textRecognizer!.processImage(
        inputImage,
      );

      final List<String> extractedLines = _reconstructVisualLines(
        recognizedText.blocks,
      );
      final List<List<String>> extractedBlocks = [];

      for (final block in recognizedText.blocks) {
        final List<String> blockLines = [];
        for (final line in block.lines) {
          final trimmed = line.text.trim();
          if (trimmed.isNotEmpty) {
            blockLines.add(trimmed);
          }
        }
        if (blockLines.isNotEmpty) {
          extractedBlocks.add(blockLines);
        }
      }

      final rawText = extractedLines.isNotEmpty
          ? extractedLines.join('\n')
          : recognizedText.text.trim();

      return RecognizedTextResult(
        rawText: rawText,
        lines: extractedLines,
        blocks: extractedBlocks,
        imagePath: displayImagePath,
      );
    } catch (e) {
      throw Exception('Lỗi nhận diện văn bản ML Kit: $e');
    }
  }

  /// Reconstructs visual lines from disjointed text blocks by grouping lines
  /// that share approximately the same horizontal band (Y-axis).
  List<String> _reconstructVisualLines(List<TextBlock> blocks) {
    final List<_LineBox> allLines = [];

    for (final block in blocks) {
      for (final line in block.lines) {
        final trimmed = line.text.trim();
        if (trimmed.isNotEmpty) {
          allLines.add(_LineBox(trimmed, line.boundingBox));
        }
      }
    }

    if (allLines.isEmpty) return const [];

    // Fallback if bounding boxes are unavailable
    if (allLines.every((l) => l.box == Rect.zero)) {
      return allLines.map((l) => l.text).toList();
    }

    // Sort primarily top-to-bottom
    allLines.sort((a, b) => a.box.top.compareTo(b.box.top));

    // Group into horizontal visual rows
    final List<List<_LineBox>> rows = [];
    for (final line in allLines) {
      bool placed = false;
      for (final row in rows) {
        final rowTop = row.map((l) => l.box.top).reduce(math.min);
        final rowBottom = row.map((l) => l.box.bottom).reduce(math.max);
        final rowHeight = math.max(rowBottom - rowTop, line.box.height);

        final overlap = math.min(rowBottom, line.box.bottom) - math.max(rowTop, line.box.top);
        // If lines overlap vertically by more than 35% of their height, they belong on the same line
        if (overlap > 0.35 * math.min(line.box.height, rowHeight)) {
          row.add(line);
          placed = true;
          break;
        }
      }
      if (!placed) {
        rows.add([line]);
      }
    }

    // Sort elements in each row horizontally (left to right)
    for (final row in rows) {
      row.sort((a, b) => a.box.left.compareTo(b.box.left));
    }

    // Sort rows strictly by their vertical top position
    rows.sort((a, b) {
      final aTop = a.map((l) => l.box.top).reduce(math.min);
      final bTop = b.map((l) => l.box.top).reduce(math.min);
      return aTop.compareTo(bTop);
    });

    return rows.map((r) => r.map((l) => l.text).join(' ')).toList();
  }

  /// Releases the native ML Kit TextRecognizer resources.
  Future<void> dispose() async {
    await _textRecognizer?.close();
    _textRecognizer = null;
  }
}
