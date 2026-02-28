import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:umivpn/utils/logger.dart';

/// A utility class for compressing and decompressing files
class CompressionHelper {
  /// Compress multiple files into a single zip archive
  ///
  /// [files] - List of file paths to compress
  /// [destinationPath] - Path where the zip file will be saved
  static Future<void> compressFiles(
      List<String> files, String destinationPath) async {
    final encoder = ZipEncoder();
    final archive = Archive();

    for (final filePath in files) {
      final file = File(filePath);
      if (!await file.exists()) {
        continue;
      }

      final bytes = await file.readAsBytes();
      final archiveFile = ArchiveFile(
        path.basename(filePath),
        bytes.length,
        bytes,
      );
      archive.addFile(archiveFile);
    }

    // Encode and write to file
    final zipData = encoder.encode(archive);
    if (zipData == null) {
      throw Exception('Failed to encode zip archive');
    }

    final zipFile = File(destinationPath);
    await zipFile.writeAsBytes(zipData);
  }
}
