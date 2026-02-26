// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LogData _$LogDataFromJson(Map<String, dynamic> json) => LogData(
      version: json['version'] as String,
      platform: json['platform'] as String,
      buildNumber: json['buildNumber'] as String,
      flutterLog: json['flutterLog'] as String,
      tunnelLog: json['tunnelLog'] as String,
      deviceInfo: json['deviceInfo'] as String,
      reason: json['reason'] as String?,
    );

Map<String, dynamic> _$LogDataToJson(LogData instance) => <String, dynamic>{
      'version': instance.version,
      'platform': instance.platform,
      'buildNumber': instance.buildNumber,
      'flutterLog': instance.flutterLog,
      'tunnelLog': instance.tunnelLog,
      'deviceInfo': instance.deviceInfo,
      'reason': instance.reason,
    };
