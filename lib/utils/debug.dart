import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:umivpn/main.dart';
import 'package:umivpn/utils/logger.dart';
import 'package:umivpn/utils/path.dart';

void saveLogToApplicationDocumentsDir() async {
  logger.d("saveLogToApplicationDocumentsDir");

  final dstDir = Platform.isAndroid
      ? ('/storage/emulated/0/Documents/umivpn')
      : (await getApplicationDocumentsDirectory()).path;
  logger.d(dstDir);
  if (!Directory(dstDir).existsSync()) {
    Directory(dstDir).createSync(recursive: true);
  }

  // copy tunnel logFile to dst dir
  final tunnelLogDir = await getTunnelLogDir();
  final dstTunnelLogDir = join(dstDir, "tunnel_logs");
  if (!Directory(dstTunnelLogDir).existsSync()) {
    Directory(dstTunnelLogDir).createSync(recursive: true);
  }
  for (final file in await tunnelLogDir.list().toList()) {
    if (file is File) {
      final fileName = basename(file.path);
      if (fileName.startsWith(".")) {
        continue;
      }
      final destinationFile = File(join(dstTunnelLogDir, fileName));
      await file.copy(destinationFile.path);
    }
  }
  rootScaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(
        "saved log to: $dstDir",
      ),
    ),
  );

  // copy flutterLogDir to ApplicationDocumentsDirectory
  final flutterLogDir = await getFlutterLogDir();
  if (await flutterLogDir.exists()) {
    final dstFlutterLogDir = join(dstDir, "flutter_logs");
    if (!Directory(dstFlutterLogDir).existsSync()) {
      Directory(dstFlutterLogDir).createSync(recursive: true);
    }
    final flutterLogFiles = await flutterLogDir.list().toList();
    for (final logFile in flutterLogFiles) {
      if (logFile is File) {
        final fileName = basename(logFile.path);
        if (fileName.startsWith(".")) {
          continue;
        }
        final destinationFile = File(join(dstFlutterLogDir, fileName));
        await logFile.copy(destinationFile.path);
      }
    }
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          "copied flutter logs to: $dstFlutterLogDir",
        ),
      ),
    );
  } else {
    logger.d("flutter log directory does not exist");
  }
}

Future<void> clearDatabase() async {
  if (kDebugMode) {
    final dbFile = File(join(resourceDirectory.path, 'x_database.sqlite'));
    if (await dbFile.exists()) {
      try {
        await dbFile.delete();
        logger.d('Deleted existing database file');
      } catch (e) {
        logger.e('Failed to delete database file: $e');
      }
    }
  }
}
