import 'dart:io';

import 'package:win32_registry/win32_registry.dart';

class DesktopAppInfo {
  DesktopAppInfo({
    required this.name,
    this.displayName,
    this.installLocation,
    this.executablePath,
    this.icon,
    this.version,
  });

  final String name;
  final String? displayName;
  final String? installLocation;
  final String? executablePath;
  final String? icon;
  final String? version;
}

class DesktopInstalledApps {
  static Future<List<DesktopAppInfo>> getInstalledApps() async {
    if (Platform.isWindows) {
      return _getWindowsInstalledApps();
    }
    if (Platform.isMacOS) {
      return _getMacOSInstalledApps();
    }
    if (Platform.isLinux) {
      return _getLinuxInstalledApps();
    }
    return [];
  }

  static Future<List<DesktopAppInfo>> _getWindowsInstalledApps() async {
    final apps = <DesktopAppInfo>[];
    final seenNames = <String>{};
    const registryPaths = [
      r'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
      r'SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
    ];

    for (final path in registryPaths) {
      try {
        final key = Registry.openPath(RegistryHive.localMachine, path: path);
        final subKeyNames = key.subkeyNames;
        for (final subKeyName in subKeyNames) {
          try {
            final subKey = Registry.openPath(
              RegistryHive.localMachine,
              path: '$path\\$subKeyName',
            );
            final displayName = _getRegistryValue(subKey, 'DisplayName');
            if (displayName == null || displayName.isEmpty) {
              subKey.close();
              continue;
            }
            if (seenNames.contains(displayName)) {
              subKey.close();
              continue;
            }
            if (_getRegistryValue(subKey, 'SystemComponent') == '1') {
              subKey.close();
              continue;
            }
            if (_getRegistryValue(subKey, 'ParentKeyName') != null) {
              subKey.close();
              continue;
            }
            final installLocation = _getRegistryValue(
              subKey,
              'InstallLocation',
            );
            final displayIcon = _getRegistryValue(subKey, 'DisplayIcon');
            final version = _getRegistryValue(subKey, 'DisplayVersion');
            String? executablePath;
            if (displayIcon != null && displayIcon.isNotEmpty) {
              final iconPath = displayIcon
                  .split(',')
                  .first
                  .trim()
                  .replaceAll('"', '');
              if (iconPath.toLowerCase().endsWith('.exe') &&
                  File(iconPath).existsSync()) {
                executablePath = iconPath;
              }
            }
            if (executablePath == null &&
                installLocation != null &&
                installLocation.isNotEmpty) {
              final dir = Directory(installLocation);
              if (dir.existsSync()) {
                final exeFiles = dir
                    .listSync(recursive: false)
                    .whereType<File>()
                    .where((f) => f.path.toLowerCase().endsWith('.exe'))
                    .toList();
                if (exeFiles.isNotEmpty) {
                  final matchingExe = exeFiles.where((f) {
                    final fileName = f.uri.pathSegments.last.toLowerCase();
                    final appNameLower = displayName.toLowerCase();
                    return fileName.contains(appNameLower.split(' ').first);
                  }).firstOrNull;
                  executablePath = (matchingExe ?? exeFiles.first).path;
                }
              }
            }
            seenNames.add(displayName);
            apps.add(
              DesktopAppInfo(
                name: subKeyName,
                displayName: displayName,
                installLocation: installLocation,
                executablePath: executablePath,
                icon: displayIcon,
                version: version,
              ),
            );
            subKey.close();
          } catch (_) {
            continue;
          }
        }
        key.close();
      } catch (_) {
        continue;
      }
    }
    apps.sort(
      (a, b) => (a.displayName ?? a.name).compareTo(b.displayName ?? b.name),
    );
    return apps;
  }

  static Future<List<DesktopAppInfo>> _getMacOSInstalledApps() async {
    final apps = <DesktopAppInfo>[];
    final applicationDirs = [
      Directory('/Applications'),
      Directory('${Platform.environment['HOME']}/Applications'),
    ];
    for (final dir in applicationDirs) {
      if (!dir.existsSync()) {
        continue;
      }
      try {
        final entities = dir.listSync(recursive: false);
        for (final entity in entities) {
          if (entity is! Directory || !entity.path.endsWith('.app')) {
            continue;
          }
          final appName = entity
              .uri
              .pathSegments[entity.uri.pathSegments.length - 2]
              .replaceAll('.app', '');
          final macosDir = Directory('${entity.path}/Contents/MacOS');
          String? executablePath;
          if (macosDir.existsSync()) {
            final executables = macosDir
                .listSync(recursive: false)
                .whereType<File>()
                .where((f) => _isExecutable(f.path))
                .toList();
            if (executables.isNotEmpty) {
              executablePath = executables.first.path;
            }
          }
          apps.add(
            DesktopAppInfo(
              name: appName,
              displayName: appName,
              installLocation: entity.path,
              executablePath: executablePath,
            ),
          );
        }
      } catch (_) {
        continue;
      }
    }
    apps.sort((a, b) => a.name.compareTo(b.name));
    return apps;
  }

  static Future<List<DesktopAppInfo>> _getLinuxInstalledApps() async {
    final apps = <DesktopAppInfo>[];
    final desktopFileDirs = [
      Directory('/usr/share/applications'),
      Directory('/usr/local/share/applications'),
      Directory('${Platform.environment['HOME']}/.local/share/applications'),
    ];
    for (final dir in desktopFileDirs) {
      if (!dir.existsSync()) {
        continue;
      }
      try {
        final entities = dir.listSync(recursive: false);
        for (final entity in entities) {
          if (entity is! File || !entity.path.endsWith('.desktop')) {
            continue;
          }
          try {
            final content = entity.readAsStringSync();
            final lines = content.split('\n');
            String? name;
            String? exec;
            String? icon;
            for (final line in lines) {
              if (line.startsWith('Name=')) {
                name = line.substring(5).trim();
              } else if (line.startsWith('Exec=')) {
                exec = line
                    .substring(5)
                    .trim()
                    .replaceAll(RegExp(r'%[a-zA-Z]'), '')
                    .trim();
              } else if (line.startsWith('Icon=')) {
                icon = line.substring(5).trim();
              }
            }
            if (name != null && name.isNotEmpty) {
              apps.add(
                DesktopAppInfo(
                  name: entity.uri.pathSegments.last.replaceAll('.desktop', ''),
                  displayName: name,
                  executablePath: exec,
                  icon: icon,
                ),
              );
            }
          } catch (_) {
            continue;
          }
        }
      } catch (_) {
        continue;
      }
    }
    apps.sort(
      (a, b) => (a.displayName ?? a.name).compareTo(b.displayName ?? b.name),
    );
    return apps;
  }

  static String? _getRegistryValue(RegistryKey key, String valueName) {
    try {
      return key.getValueAsString(valueName);
    } catch (_) {
      return null;
    }
  }

  static bool _isExecutable(String path) {
    if (Platform.isWindows) {
      return path.toLowerCase().endsWith('.exe');
    }
    try {
      final result = Process.runSync('test', ['-x', path]);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}
