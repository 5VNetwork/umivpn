import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const _sessionIdKey = 'support_device_session_id';

/// Stable per-install device session id for FCM token registration.
class SupportDeviceSession {
  SupportDeviceSession({SharedPreferences? preferences})
    : _preferencesFuture = preferences != null
          ? Future.value(preferences)
          : SharedPreferences.getInstance();

  final Future<SharedPreferences> _preferencesFuture;
  String? _cachedSessionId;

  Future<String> getSessionId() async {
    if (_cachedSessionId != null) {
      return _cachedSessionId!;
    }
    final prefs = await _preferencesFuture;
    var sessionId = prefs.getString(_sessionIdKey);
    if (sessionId == null || sessionId.isEmpty) {
      sessionId = const Uuid().v4();
      await prefs.setString(_sessionIdKey, sessionId);
    }
    _cachedSessionId = sessionId;
    return sessionId;
  }
}
