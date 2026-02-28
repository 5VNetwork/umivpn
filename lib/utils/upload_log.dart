// Copyright (C) 2026 5V Network LLC <5vnetwork@proton.me>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tm/tm.dart';
import 'package:flutter_common/util/compress.dart';
import 'package:umivpn/utils/logger.dart';
import 'package:flutter_common/util/crypto.dart';
import 'package:umivpn/utils/path.dart';

part 'upload_log.g.dart';

/// A service class that periodically uploads logs to a backend server
class LogUploadService {
  static const int _defaultUploadIntervalMinutes = 60 * 5;
  static const int _defaultMaxLogSizeMB = 10;
  static const int _maxRetryAttempts = 2;
  static const Duration _retryDelay = Duration(seconds: 30);

    LogUploadService({
    required String uploadUrl,
    required Directory flutterLogDir,
    required Directory tunnelLogDir,
    required String secret,
    required HttpClient httpClient,
  })  : _flutterLogDir = flutterLogDir,
        _tunnelLogDir = tunnelLogDir,
        _uploadUrl = uploadUrl,
        _secret = secret,
        _httpClient = httpClient;

  Timer? _uploadTimer;
  final Directory _flutterLogDir;
  final Directory _tunnelLogDir;
  final String _uploadUrl;
  final String _secret;
  final HttpClient _httpClient;

  /// Initialize the log upload service with configuration
  Future<void> start() async {
    logger.d('LogUploadService starts');
    startPeriodicUpload();
  }

  /// Start periodic log uploads
  void startPeriodicUpload() {
    if (_uploadTimer?.isActive == true) {
      _uploadTimer?.cancel();
    }

    performUpload();

    _uploadTimer = Timer.periodic(
        const Duration(minutes: _defaultUploadIntervalMinutes),
        (_) => performUpload());

    logger.i(
        'Periodic log upload started - interval: $_defaultUploadIntervalMinutes minutes');
  }

  /// Stop periodic log uploads
  void stopPeriodicUpload() {
    _uploadTimer?.cancel();
    _uploadTimer = null;
    logger.i('Periodic log upload stopped');
  }

  /// Perform the actual log upload with retry logic
  Future<void> performUpload() async {
    LogData? logData;
    try {
      logData = await collectLogData();
    } catch (e) {
      logger.e('Error collecting log data: $e');
      // await FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
    }

    if (logData == null) {
      logger.d('No logs');
      return;
    }

    int attempts = 0;

    while (attempts < _maxRetryAttempts) {
      attempts++;
      try {
        await uploadLogData(logData);
        return;
      } catch (e) {
        logger.e('Upload attempt $attempts failed: $e');
        // if (attempts == 0) {
        //   await FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
        // }
        if (attempts < _maxRetryAttempts) {
          await Future.delayed(_retryDelay);
        }
      }
    }
  }

  static Future<String?> getLogsContent(Directory logDir,
      // if true, the latest log will be deleted
      {bool deleteLatest = false}) async {
    String? logZipBase64;
    List<File> logFiles = [];
    try {
      logFiles = logDir
          .listSync()
          .where((entity) => entity is File && entity.lengthSync() > 0)
          .cast<File>()
          .toList();
      if (logFiles.isNotEmpty) {
        final zipBytes = await CompressionHelper.compressFilesToBytes(logFiles
            // .where((e) {
            //   // only collect logs with error
            //   final content = e.readAsStringSync();
            //   return content.contains(tunnelLog ? 'ERR' : '⛔');
            // })
            .map((e) => e.path)
            .toList());
        logZipBase64 = base64UrlEncode(zipBytes);
      }
    } catch (e) {
      // logger.e('Error collecting flutter log data: $e');
      rethrow;
    } finally {
      final files = logDir.listSync()
        ..sort((a, b) {
          final aStat = a.statSync();
          final bStat = b.statSync();
          return aStat.modified.compareTo(bStat.modified);
        });
      // remove all files except last. for latest, delete if [deleteLatest]
      for (int i = 0; i < files.length; i++) {
        try {
          if (i == files.length - 1) {
            if (deleteLatest) {
              await files[i].delete();
            }
          } else {
            await files[i].delete();
          }
        } catch (e) {
          logger.e('Error deleting log file: $e');
        }
      }
    }
    return logZipBase64;
  }

  Future<void> _closeFlutterLogger() async {
    if (isProduction()) {
      if (reportLogger != diabledLogger) {
        final logger = reportLogger;
        reportLogger = diabledLogger;
        if (!logger.isClosed()) {
          await logger.close();
        }
      }
    } else {
      if (logger != diabledLogger) {
        final toBeClosed = logger;
        logger = diabledLogger;
        if (!toBeClosed.isClosed()) {
          await toBeClosed.close();
        }
      }
    }
  }

  Future<void> _openFlutterLogger() async {
    if (isProduction()) {
      await setReportLogger();
    } else {
      await setDebugLoggerDevlopment();
    }
  }

  /// Collect log data from various sources
  Future<LogData?> collectLogData() async {
    // flutter logs
    String? flutterLogZipBase64;
    await _closeFlutterLogger();
    try {
      flutterLogZipBase64 =
          await getLogsContent(_flutterLogDir, deleteLatest: true);
      await _openFlutterLogger();
    } catch (e) {
      await _openFlutterLogger();
      logger.e('Error collecting flutter log data: $e');
    }

    // tunnel logs
    final tunnelLogZipBase64 = await getLogsContent(_tunnelLogDir,
        deleteLatest: Tm.instance.state == TmStatus.disconnected);

    if ((flutterLogZipBase64 == null || flutterLogZipBase64.isEmpty) &&
        (tunnelLogZipBase64 == null || tunnelLogZipBase64.isEmpty)) {
      return null;
    }

    final packageInfo = await PackageInfo.fromPlatform();

    final logData = LogData(
      version: packageInfo.version,
      platform: _sanitizePlatformString(Platform.operatingSystem),
      buildNumber: packageInfo.buildNumber,
      flutterLog: flutterLogZipBase64 ?? '',
      tunnelLog: tunnelLogZipBase64 ?? '',
      deviceInfo: await getDeviceInfo(),
    );
    return logData;
  }

  // Future<void> uploadDebugLog(String reason) async {
  //   final tunnelLogZipBase64 =
  //       await getLogsContent(await getDebugTunnelLogDir(), deleteLatest: false);
  //   final flutterLogZipBase64 = await getLogsContent(
  //       await getDebugFlutterLogDir(),
  //       deleteLatest: false);
  //   if ((tunnelLogZipBase64 == null || tunnelLogZipBase64.isEmpty) &&
  //       (flutterLogZipBase64 == null || flutterLogZipBase64.isEmpty)) {
  //     return;
  //   }
  //   final packageInfo = await PackageInfo.fromPlatform();
  //   final logData = LogData(
  //     version: packageInfo.version,
  //     flutterLog: flutterLogZipBase64 ?? '',
  //     platform: _sanitizePlatformString(Platform.operatingSystem),
  //     buildNumber: packageInfo.buildNumber,
  //     tunnelLog: tunnelLogZipBase64 ?? '',
  //     deviceInfo: await getDeviceInfo(),
  //     reason: reason,
  //   );
  //   await uploadLogData(logData);
  // }

  static Future<String> getDeviceInfo() async {
    final deviceInfo = await DeviceInfoPlugin().deviceInfo;
    if (deviceInfo is AndroidDeviceInfo) {
      return json.encode({
        'brand': deviceInfo.brand,
        'model': deviceInfo.model,
        'version': deviceInfo.version.release,
        'manufacturer': deviceInfo.manufacturer,
        'isPhysicalDevice': deviceInfo.isPhysicalDevice,
        'physicalRamSize': deviceInfo.physicalRamSize,
        'availableRamSize': deviceInfo.availableRamSize,
        'product': deviceInfo.product,
        'freeDiskSize': deviceInfo.freeDiskSize
      });
    } else if (deviceInfo is IosDeviceInfo) {
      return json.encode({
        'model': deviceInfo.model,
        'version': deviceInfo.systemVersion,
        'modelName': deviceInfo.modelName,
        'systemName': deviceInfo.systemName,
        'freeDiskSize': deviceInfo.freeDiskSize
      });
    } else if (deviceInfo is WindowsDeviceInfo) {
      return json.encode({
        'majorVersion': deviceInfo.majorVersion,
        'platformId': deviceInfo.platformId,
        'productType': deviceInfo.productType,
        'productName': deviceInfo.productName,
      });
    } else if (deviceInfo is MacOsDeviceInfo) {
      return json.encode({
        'hostName': deviceInfo.hostName,
        'arch': deviceInfo.arch,
        'model': deviceInfo.model,
        'modelName': deviceInfo.modelName,
        'majorVersion': deviceInfo.majorVersion,
      });
    } else if (deviceInfo is LinuxDeviceInfo) {
      return json.encode({
        'name': deviceInfo.name,
        'version': deviceInfo.version,
        'versionId': deviceInfo.versionId,
      });
    } else {
      return '';
    }
  }

  /// Sanitize platform string to be HTTP header safe
  static String _sanitizePlatformString(String platform) {
    // Remove non-ASCII characters and replace spaces with underscores
    return platform
        .replaceAll(RegExp(r'[^\x00-\x7F]'), '') // Remove non-ASCII characters
        .replaceAll(RegExp(r'\s+'), '_') // Replace spaces with underscores
        .replaceAll(RegExp(r'[^\w\-_.]'),
            '') // Keep only alphanumeric, hyphens, underscores, and dots
        .trim();
  }

  /// Upload log data to the backend
  Future<void> uploadLogData(LogData logData) async {
    final packageInfo = await PackageInfo.fromPlatform();

    final jsonString = json.encode(logData.toJson());

    final key = generateHmacSha256(
        jsonString.substring(0, min(jsonString.length, 1024)),
        utf8.encode(_secret));

    final uri = Uri.parse(_uploadUrl);
    HttpClientRequest request;
    try {
      request = await _httpClient.postUrl(uri);
    } catch (e) {
      logger.e('Failed to create HTTP request for log upload', error: e);
      rethrow;
    }

    // Set headers
    request.headers.contentType = ContentType.json;
    request.headers.set('Authorization', key);
    request.headers.set('Version', packageInfo.version);
    request.headers.set('Content-Type', 'application/json');

    // Write body
    request.add(utf8.encode(jsonString));

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      logger
          .e('Log upload failed: ${response.statusCode}, body: $responseBody');
      throw HttpException(
        'Log upload failed with status ${response.statusCode}',
        uri: uri,
      );
    }

    logger.i('Log upload successful');
  }
}

@JsonSerializable()
class LogData {
  final String version;
  final String platform;
  final String buildNumber;
  final String flutterLog;
  final String tunnelLog;
  final String deviceInfo;
  final String? reason;

  LogData({
    required this.version,
    required this.platform,
    required this.buildNumber,
    required this.flutterLog,
    required this.tunnelLog,
    required this.deviceInfo,
    this.reason,
  });

  factory LogData.fromJson(Map<String, dynamic> json) =>
      _$LogDataFromJson(json);

  Map<String, dynamic> toJson() => _$LogDataToJson(this);
}
