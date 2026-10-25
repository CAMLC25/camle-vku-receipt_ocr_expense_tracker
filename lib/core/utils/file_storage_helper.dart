import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Helper managing receipt image storage in app-private directories.
/// Ensures resilient relative paths in SQLite and safe cleanup on transaction deletion.
class FileStorageHelper {
  static const String receiptFolder = 'receipt_images';

  /// Saves a captured or picked receipt image to app-private storage.
  /// Returns the relative path: `receipt_images/<uuid>.jpg`.
  static Future<String> saveReceiptImage(String sourcePath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      return sourcePath;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory(p.join(docsDir.path, receiptFolder));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    // If source file is already stored inside receipt_images, return relative path directly
    if (sourcePath.contains(receiptFolder)) {
      final fileName = p.basename(sourcePath);
      return p.join(receiptFolder, fileName).replaceAll(r'\', '/');
    }

    final ext = p.extension(sourcePath).isNotEmpty
        ? p.extension(sourcePath)
        : '.jpg';
    final newFileName = '${const Uuid().v4()}$ext';
    final targetPath = p.join(targetDir.path, newFileName);

    await sourceFile.copy(targetPath);

    return p.join(receiptFolder, newFileName).replaceAll(r'\', '/');
  }

  /// Resolves a stored relative path (e.g. `receipt_images/abc.jpg`) to an absolute File.
  /// If the path is already absolute, returns the File directly.
  static Future<File?> resolveReceiptImage(
    String? relativeOrAbsolutePath,
  ) async {
    if (relativeOrAbsolutePath == null || relativeOrAbsolutePath.isEmpty) {
      return null;
    }

    // Check if path is already absolute
    final directFile = File(relativeOrAbsolutePath);
    if (await directFile.exists()) {
      return directFile;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final fullPath = p.join(docsDir.path, relativeOrAbsolutePath);
    final file = File(fullPath);
    if (await file.exists()) {
      return file;
    }

    return null;
  }

  /// Deletes a receipt image from disk when a transaction is deleted.
  static Future<bool> deleteReceiptImage(String? relativeOrAbsolutePath) async {
    if (relativeOrAbsolutePath == null || relativeOrAbsolutePath.isEmpty) {
      return false;
    }

    try {
      File? file = await resolveReceiptImage(relativeOrAbsolutePath);
      if (file != null && await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (_) {
      // Ignore file deletion errors to prevent transaction deletion failure
    }
    return false;
  }
}
