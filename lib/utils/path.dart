import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:umivpn/common/common.dart';
import 'package:umivpn/main.dart';
import 'package:umivpn/utils/logger.dart';

final macPkg = Platform.isMacOS && appFlavor == 'pkg';

/// dir to hold geosite, geoip, wintun.dll, unix socket
Future<Directory> resourceDir() async {
  if (Platform.isWindows || Platform.isAndroid || Platform.isLinux) {
    return await getApplicationSupportDirectory();
  }

  if (Platform.isMacOS || Platform.isIOS) {
    final appGroupPath = await darwinHostApi!.appGroupPath();
    final dir = Directory(join(appGroupPath, "Library", "Application Support"));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  throw UnimplementedError("Unsupported platform");
}

Directory getFlutterLogDir() {
  final dir = Directory(join(resourceDirectory.path, "flutter_logs"));
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return dir;
}

Directory getTunnelLogDir() {
  final dir = Directory(join(resourceDirectory.path, "tunnel_logs"));
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return dir;
}

Future<Directory> getDebugLogDir() async {
  final dir = Directory(join((await resourceDir()).path, "debug_logs"));
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return dir;
}

/// logs
Future<String> getCacheDir() async {
  if (Platform.isMacOS || Platform.isIOS) {
    final appGroupPath = await darwinHostApi!.appGroupPath();
    final dir = Directory(join(appGroupPath, "Library", "Caches"));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir.path;
  }
  // if (Platform.isIOS) {
  //   final appGroupPath = await platformHostApi.appGroupPath();
  //   return appGroupPath;
  // }
  if (Platform.isWindows || Platform.isAndroid || Platform.isLinux) {
    return (await getApplicationCacheDirectory()).path;
  }
  throw UnimplementedError("Unsupported platform");
}

Future<String> getGeositePath() async {
  String path;
  final geositeFile = File(join((await resourceDir()).path, 'geosite.dat'));
  path = geositeFile.path;
  return path;
}

Future<String> getSimplifiedGeositePath() async {
  String path;
  final geositeFile =
      File(join((await resourceDir()).path, 'geosite_simplified.dat'));
  path = geositeFile.path;
  return path;
}

Future<String> getGeoIPPath() async {
  String path;
  final geoIPFile = File(join((resourceDirectory).path, 'geoip.dat'));
  path = geoIPFile.path;
  return path;
}

Future<String> getSimplifiedGeoIPPath() async {
  String path;
  final geoIPFile =
      File(join((resourceDirectory).path, 'geoip_simplified.dat'));
  path = geoIPFile.path;
  return path;
}

Future<String> getWintunDir() async {
  return join((await resourceDir()).path, 'wintun', 'bin');
}

Future<String> configFilePath() async {
  return join((await resourceDir()).path, 'config');
}

String getDllPath() {
  // if (kReleaseMode) {
  final String localLibPath = join(
      'data', 'flutter_assets', 'packages', 'tm_windows', 'assets', 'x.dll');
  String pathToLib =
      join(Directory(Platform.resolvedExecutable).parent.path, localLibPath);
  logger.d('pathToLib: $pathToLib');
  return pathToLib;
  // } else {
  // return join(Directory.current.parent.path, 'umivpn-plugin', 'tm_windows',
  // 'assets', 'x.dll');
  // }
}

String getSoPath() {
  final String localLibPath =
      join('data', 'flutter_assets', 'packages', 'tm_linux', 'assets', 'x.so');
  String pathToLib =
      join(Directory(Platform.resolvedExecutable).parent.path, localLibPath);
  logger.d('pathToLib: $pathToLib');
  return pathToLib;
}

Future<Directory> getClashRulesDir() async {
  final dir = Directory(join((await resourceDir()).path, 'clash_rules'));
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return dir;
}

Future<String> getClashRulesPath(String url, {bool isPkg = false}) async {
  final dir = isPkg
      ? Directory('/tmp/com.5vnetwork.umivpn/geo')
      : await getClashRulesDir();
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  // hash the url
  final hash = sha256.convert(utf8.encode(url)).toString();
  return join(dir.path, hash);
}
