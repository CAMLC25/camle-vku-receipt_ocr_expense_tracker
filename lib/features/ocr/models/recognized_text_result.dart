/// Data model encapsulating the result of an on-device OCR scan.
class RecognizedTextResult {
  final String rawText;
  final List<String> lines;
  final List<List<String>> blocks;
  final String imagePath;

  const RecognizedTextResult({
    required this.rawText,
    required this.lines,
    required this.blocks,
    required this.imagePath,
  });

  bool get hasText => rawText.trim().isNotEmpty && lines.isNotEmpty;

  factory RecognizedTextResult.empty(String imagePath) {
    return RecognizedTextResult(
      rawText: '',
      lines: const [],
      blocks: const [],
      imagePath: imagePath,
    );
  }
}
