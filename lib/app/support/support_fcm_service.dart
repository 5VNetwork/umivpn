import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umivpn/app/support/support_device_session.dart';
import 'package:umivpn/main.dart';
import 'package:umivpn/utils/logger.dart';

const _lastUploadedSupportFcmSignatureKey =
    'support.lastUploadedFcmSignature';
const _lastUploadedSupportFcmAtKey = 'support.lastUploadedFcmAt';
const _supportFcmRefreshInterval = Duration(days: 15);

/// Registers and refreshes the device FCM token with Supabase.
class SupportFcmService {
  SupportFcmService({
    SupabaseClient? client,
    SupportDeviceSession? deviceSession,
    SharedPreferences? preferences,
  }) : _client = client ?? supabase,
       _deviceSession = deviceSession ?? SupportDeviceSession(),
       _preferencesFuture =
           preferences == null
               ? SharedPreferences.getInstance()
               : Future.value(preferences);

  final SupabaseClient _client;
  final SupportDeviceSession _deviceSession;
  final Future<SharedPreferences> _preferencesFuture;

  static bool get isMobilePlatform =>
      Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  String? _platformName() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    return null;
  }

  Future<void> registerTokenIfNeeded() async {
    if (!fcmEnabled || !isMobilePlatform) return;
    final userId = _client.auth.currentUser?.id;
    if (_client.auth.currentSession == null || userId == null) return;

    final platform = _platformName();
    if (platform == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return;

    final sessionId = await _deviceSession.getSessionId();
    final signature = '$userId|$sessionId|$platform|$token';
    final preferences = await _preferencesFuture;
    final lastUploadedAt = _lastUploadedAt(preferences);
    final alreadyUploaded =
        preferences.getString(_lastUploadedSupportFcmSignatureKey) == signature;
    final recentlyUploaded =
        lastUploadedAt != null &&
        DateTime.now().difference(lastUploadedAt) < _supportFcmRefreshInterval;
    if (alreadyUploaded && recentlyUploaded) {
      return;
    }

    await _client.rpc(
      'upsert_support_device_token',
      params: {
        'p_session_id': sessionId,
        'p_fcm_token': token,
        'p_platform': platform,
      },
    );
    await preferences.setString(_lastUploadedSupportFcmSignatureKey, signature);
    await preferences.setInt(
      _lastUploadedSupportFcmAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  DateTime? _lastUploadedAt(SharedPreferences preferences) {
    final milliseconds = preferences.getInt(_lastUploadedSupportFcmAtKey);
    if (milliseconds == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  void listenTokenRefresh() {
    if (!fcmEnabled || !isMobilePlatform) return;

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      if (token.isEmpty || _client.auth.currentSession == null) return;
      try {
        await registerTokenIfNeeded();
      } catch (error, stack) {
        logger.e('Support FCM token refresh failed', error: error, stackTrace: stack);
      }
    });
  }
}
