import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path/path.dart';

/// Atomically write data to a file.
///
/// On Windows, replacing an existing dest via rename fails with access denied
/// when another process has the file open (or antivirus briefly locks it).
/// Retry, then fall back to an in-place overwrite.
Future<void> atomicWriteToFile(
    Directory dir, String name, Uint8List data) async {
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  final destPath = join(dir.path, name);
  final tmpFile = File(join(
    dir.path,
    '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 30)}.tmp',
  ));
  tmpFile.writeAsBytesSync(data, flush: true);

  Object? lastError;
  for (var i = 0; i < 8; i++) {
    try {
      _replaceWithRename(tmpFile, destPath);
      return;
    } on FileSystemException catch (e) {
      lastError = e;
      if (i < 7) {
        await Future<void>.delayed(Duration(milliseconds: 20 * (i + 1)));
      }
    }
  }

  try {
    File(destPath).writeAsBytesSync(data, flush: true);
    _tryDelete(tmpFile);
  } on FileSystemException {
    _tryDelete(tmpFile);
    throw lastError!;
  }
}

void _replaceWithRename(File tmpFile, String destPath) {
  try {
    tmpFile.renameSync(destPath);
    return;
  } on FileSystemException {
    if (Platform.isWindows) {
      final dest = File(destPath);
      if (dest.existsSync()) {
        dest.deleteSync();
      }
      tmpFile.renameSync(destPath);
      return;
    }
    rethrow;
  }
}

void _tryDelete(File file) {
  try {
    if (file.existsSync()) {
      file.deleteSync();
    }
  } catch (_) {}
}
