import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:umivpn/utils/logger.dart';
import 'package:umivpn/common/os.dart';
import 'package:umivpn/main.dart';
import 'package:umivpn/utils/path.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter_common/util/download.dart';

const String wintunDownloadLink =
    'https://www.wintun.net/builds/wintun-0.14.1.zip';

Future<void> makeWinTunAvailable() async {
  final wintunDir = Directory(await getWintunDir());
  final arch = getCpuArch();
  logger.d('CPU Architecture: $arch');
  final dllPath = join(wintunDir.path, arch, "wintun.dll");
  // Get CPU architecture
  if (!File(dllPath).existsSync()) {
    // delete existing dir
    final eistingWintunDir =
        Directory(join((await resourceDir()).path, 'wintun'));
    if (eistingWintunDir.existsSync()) {
      eistingWintunDir.deleteSync(recursive: true);
    }
    final zipPath =
        join((await getApplicationCacheDirectory()).path, 'wintun-zip');
    await directDownloadToFile(wintunDownloadLink, zipPath);
    // Extract the zip file
    await extractFileToDisk(zipPath, (await resourceDir()).path);
    // Clean up zip file after extraction
    await File(zipPath).delete();
    logger.d('Wintun DLL downloaded and extracted to $dllPath');
  }
}

String getServiceInstallExePath() {
  final String localExePath = join('data', 'flutter_assets', 'packages',
      'tm_windows', 'assets', 'service_install.exe');
  String pathToExe =
      join(Directory(Platform.resolvedExecutable).parent.path, localExePath);
  logger.d('pathToExe: $pathToExe');
  return pathToExe;
}
