import 'dart:async';
import 'dart:io';

import 'package:flutter_common/support/support_chat.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:umivpn/app/support/support_unread_badge.dart';
import 'package:umivpn/common/common.dart';
import 'package:umivpn/l10n/app_localizations.dart';
import 'package:umivpn/main.dart';
import 'package:umivpn/utils/logger.dart';
import 'package:window_manager/window_manager.dart';

/// Fixed id so a new reply replaces the previous toast instead of stacking.
const _notificationId = 8801;
const _payload = 'support_reply';
const _channelId = 'support_reply_channel';
const _channelName = 'Support replies';
const _channelDescription = 'Notifies you when support answers your message.';

const _androidChannel = AndroidNotificationChannel(
  _channelId,
  _channelName,
  description: _channelDescription,
  importance: Importance.high,
);

Future<bool>? _initFuture;

/// System notifications for the platforms FCM never reaches: Windows, Linux and
/// Android without Play services. Where FCM works it already owns
/// [flutterLocalNotificationsPlugin], so everything here stays a no-op.
Future<bool> _ensureInitialized() => _initFuture ??= _initialize();

Future<bool> _initialize() async {
  try {
    final initialized = await flutterLocalNotificationsPlugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_stat_notify'),
        linux: LinuxInitializationSettings(defaultActionName: 'Open'),
        windows: WindowsInitializationSettings(
          appName: 'umivpn',
          appUserModelId: 'com.5vnetwork.umivpn',
          guid: 'd3f1a7c4-2b58-4e6a-9c31-7a0e5b842f19',
        ),
      ),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    if (initialized != true) {
      logger.e('Support local notifications unavailable');
      return false;
    }
    if (Platform.isAndroid) {
      final android = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.createNotificationChannel(_androidChannel);
      await android?.requestNotificationsPermission();
    }
    return true;
  } catch (error, stack) {
    logger.e(
      'Support local notifications init failed',
      error: error,
      stackTrace: stack,
    );
    return false;
  }
}

/// Shows the "support replied" toast. [preview] is the reply text, if known.
Future<void> showSupportReplyNotification({String? preview}) async {
  if (fcmEnabled) return;
  if (!await _ensureInitialized()) return;

  final context = rootNavigationKey.currentContext;
  final l10n = context != null && context.mounted
      ? AppLocalizations.of(context)
      : null;

  try {
    await flutterLocalNotificationsPlugin.show(
      id: _notificationId,
      title: l10n?.supportReplied ?? 'Support replied',
      body: _shorten(preview),
      payload: _payload,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        windows: WindowsNotificationDetails(
          duration: WindowsNotificationDuration.long,
        ),
      ),
    );
  } catch (error, stack) {
    logger.e(
      'Support local notification failed',
      error: error,
      stackTrace: stack,
    );
  }
}

Future<void> cancelSupportReplyNotification() async {
  if (fcmEnabled || _initFuture == null) return;
  if (!await _ensureInitialized()) return;
  try {
    await flutterLocalNotificationsPlugin.cancel(id: _notificationId);
  } catch (error) {
    logger.e('Support local notification cancel failed', error: error);
  }
}

String? _shorten(String? content) {
  final text = content?.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text == null || text.isEmpty) return null;
  // An image message carries a storage path, which is not worth showing.
  if (isSupportImageContent(text)) return null;
  return text.length <= 120 ? text : '${text.substring(0, 117)}...';
}

void _onNotificationTapped(NotificationResponse response) {
  if (response.payload != _payload) return;
  unawaited(_openSupportChat());
}

Future<void> _openSupportChat() async {
  if (desktopPlatforms) {
    try {
      await windowManager.show();
      await windowManager.focus();
    } catch (error) {
      logger.e('Failed to restore window for support chat', error: error);
    }
  }
  final context = rootNavigationKey.currentContext;
  if (context != null && context.mounted) {
    context.read<SupportUnreadBadgeController>().clear();
  }
  router.go('/supportChat');
}
