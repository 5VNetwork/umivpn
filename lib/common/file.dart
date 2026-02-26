import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart';

/// Atomically write data to a file
Future<void> atomicWriteToFile(
    Directory dir, String name, Uint8List data) async {
  final tmpFile =
      File(join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.tmp'));
  tmpFile.writeAsBytesSync(data);
  tmpFile.renameSync(join(dir.path, name));
}
