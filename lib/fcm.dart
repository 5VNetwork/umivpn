part of 'main.dart';

bool fcmEnabled = false;

Future<void> _initFcm() async {
  print('Initializing FCM');
  // set fcm enabled
  if (Platform.isAndroid) {
    GooglePlayServicesAvailability availability = await GoogleApiAvailability
        .instance
        .checkGooglePlayServicesAvailability();
    final googleApiAvailable =
        availability == GooglePlayServicesAvailability.success;
    fcmEnabled = googleApiAvailable;
  } else if (Platform.isIOS || Platform.isMacOS) {
    fcmEnabled = true;
  }

  // fcm
  if (fcmEnabled) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    print('FCM initialized');
    await _ensureFcmLocalNotificationsInitialized();
    print('FCM local notifications initialized');
    if (Platform.isAndroid) {
      // enable foreground notification
      androidChannel = const AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        description:
            'This channel is used for important notifications.', // description
        importance: Importance.defaultImportance,
        enableVibration: false,
        showBadge: false,
        playSound: false,
      );
      try {
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(androidChannel);
      } catch (e) {
        logger.e('createNotificationChannel', error: e);
      }
      // Android 13+ requires POST_NOTIFICATIONS runtime permission.
      try {
        final notificationSettings =
            await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        logger.d(
          'Android FCM permission: ${notificationSettings.authorizationStatus}',
        );
      } catch (e) {
        logger.e('requestPermission (android)', error: e);
      }
    } else if (Platform.isIOS || Platform.isMacOS) {
      // You may set the permission requests to "provisional" which allows the user to choose what type
      // of notifications they would like to receive once the user receives a notification.
      try {
        final notificationSettings = await FirebaseMessaging.instance
            .requestPermission(provisional: true);
        logger.d('FCM permission: ${notificationSettings.authorizationStatus}');
      } catch (e) {
        logger.e('requestPermission', error: e);
      }
      // Foreground: use flutter_local_notifications so big images work; avoid duplicate system banner.
      try {
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
          alert: false,
          badge: false,
          sound: false,
        );
      } catch (e) {
        logger.e('setForegroundNotificationPresentationOptions', error: e);
      }
    }
    if (!isProduction()) {
      FirebaseMessaging.instance.getToken().then((token) {
        logger.d('FCM token: $token');
      }).catchError((err) {
        logger.e('Error getting FCM token', error: err);
      });
      FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
        // TODO: If necessary send token to application server.
        logger.d('FCM token: $fcmToken');
        // Note: This callback is fired at each app startup and whenever a new
        // token is generated.
      }).onError((err) {
        // Error getting token.
        logger.e('Error getting FCM token', error: err);
      });
      if (Platform.isIOS || Platform.isMacOS) {
        // For apple platforms, ensure the APNS token is available before making any FCM plugin API calls
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken != null) {
          // APNS token is available, make FCM plugin API requests...
          logger.d('APNS token: $apnsToken');
        } else {
          logger.d('APNS token is not available');
        }
      }
    }
  }
}

bool _fcmLocalNotificationsInitialized = false;

Future<void> _ensureFcmLocalNotificationsInitialized() async {
  if (_fcmLocalNotificationsInitialized) {
    return;
  }
  const androidInit = AndroidInitializationSettings('@drawable/ic_stat_notify');
  const darwinInit = DarwinInitializationSettings();
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    ),
  );
  if (Platform.isIOS) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  } else if (Platform.isMacOS) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }
  _fcmLocalNotificationsInitialized = true;
}

/// Image URL from FCM `data`, Android notification, or Apple notification.
String? _fcmImageUrlFromMessage(RemoteMessage message) {
  final data = message.data;
  for (final key in ['image', 'imageUrl', 'image_url', 'picture']) {
    final v = data[key];
    if (v is String && (v.startsWith('http://') || v.startsWith('https://'))) {
      return v;
    }
  }
  final androidUrl = message.notification?.android?.imageUrl;
  if (androidUrl != null && androidUrl.isNotEmpty) {
    return androidUrl;
  }
  final appleUrl = message.notification?.apple?.imageUrl;
  if (appleUrl != null && appleUrl.isNotEmpty) {
    return appleUrl;
  }
  return null;
}

(int?, int?) _fcmImageWidthHeight(RemoteMessage message, String imageUrl) {
  int? parsePositiveInt(Object? v) {
    if (v == null) return null;
    if (v is int) return v > 0 ? v : null;
    if (v is double) return v > 0 ? v.round() : null;
    if (v is num) return v > 0 ? v.toInt() : null;
    if (v is String) {
      final n = int.tryParse(v.trim());
      return (n != null && n > 0) ? n : null;
    }
    return null;
  }

  final data = message.data;
  final dataWidth = parsePositiveInt(data['width']);
  final dataHeight = parsePositiveInt(data['height']);

  int? urlWidth;
  int? urlHeight;
  try {
    final uri = Uri.parse(imageUrl);
    urlWidth = parsePositiveInt(uri.queryParameters['width']);
    urlHeight = parsePositiveInt(uri.queryParameters['height']);
  } catch (_) {
    // Ignore malformed URLs; we'll just fall back to defaults.
  }

  return (
    dataWidth ?? urlWidth,
    dataHeight ?? urlHeight,
  );
}

(String?, String?) _fcmTitleBody(RemoteMessage message) {
  final n = message.notification;
  if (n != null) {
    return (n.title, n.body);
  }
  final data = message.data;
  final title = data['title'];
  final body = data['body'];
  return (
    title is String ? title : null,
    body is String ? body : null,
  );
}

bool _fcmDialogShowing = false;

Future<void> _schedulePresentFcmMessageUi(
  RemoteMessage message, {
  required bool preloadImage,
}) async {
  final ctx = rootNavigationKey.currentContext;
  if (ctx == null || !ctx.mounted) {
    return;
  }
  if (preloadImage) {
    final imageUrl = _fcmImageUrlFromMessage(message);
    if (imageUrl != null) {
      try {
        await precacheImage(
          NetworkImage(imageUrl),
          ctx,
        ).timeout(const Duration(seconds: 2));
      } catch (e, st) {
        logger.d('FCM image precache skipped: $e');
        if (kDebugMode) {
          logger.d('$st');
        }
      }
    }
  }
  // Foreground delivery: show ASAP. Using a microtask avoids calling `showDialog`
  // re-entrantly inside other callbacks while not waiting for an extra rebuild/frame.
  Future<void>.microtask(() {
    _presentFcmMessageDialog(message);
  });
}

void _presentFcmMessageDialog(RemoteMessage message) {
  final ctx = rootNavigationKey.currentContext;
  if (ctx == null || !ctx.mounted) {
    return;
  }
  if (_fcmDialogShowing) {
    return;
  }
  final (title, body) = _fcmTitleBody(message);
  if (title == null && body == null) {
    return;
  }
  final imageUrl = _fcmImageUrlFromMessage(message);
  _fcmDialogShowing = true;
  showDialog<void>(
    context: ctx,
    builder: (dialogContext) {
      return AlertDialog(
        title: title != null ? Text(title) : null,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (body != null) Text(body),
              if (imageUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Builder(
                    builder: (context) {
                      final (srcW, srcH) =
                          _fcmImageWidthHeight(message, imageUrl);
                      final aspectRatio =
                          (srcW != null && srcH != null && srcH > 0)
                              ? (srcW / srcH)
                              : (16 / 9);

                      // Avoid LayoutBuilder here: AlertDialog may ask for intrinsic sizes.
                      // Pick a reasonable decode target from screen width.
                      final mq = MediaQuery.of(context);
                      final dpr = mq.devicePixelRatio;
                      final logicalTargetW =
                          (mq.size.width * 0.70).clamp(240.0, 420.0);
                      final targetPxW = (logicalTargetW * dpr).round();
                      final targetPxH = (targetPxW / aspectRatio).round();

                      final cacheW =
                          srcW != null ? srcW.clamp(1, targetPxW) : targetPxW;
                      final cacheH =
                          srcH != null ? srcH.clamp(1, targetPxH) : targetPxH;

                      return AspectRatio(
                        aspectRatio: aspectRatio,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          cacheWidth: cacheW,
                          cacheHeight: cacheH,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) {
                              return child;
                            }
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    },
  ).whenComplete(() {
    _fcmDialogShowing = false;
  });
}

Future<void> _setupFcm() async {
  if (fcmEnabled) {
    // listen foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (kDebugMode) {
        inspect(message);
      }
      logger.d('Got a message whilst in the foreground! ${message.data}');

      await _schedulePresentFcmMessageUi(
        message,
        preloadImage: true,
      );
    });
    // handle interacted messages when a user clicks on a notification
    _setupInteractedMessage();
  }
}

// It is assumed that all messages contain a data field with the key 'type'
Future<void> _setupInteractedMessage() async {
  // Get any messages which caused the application to open from
  // a terminated state.
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();

  // If the message also contains a data property with a "type" of "chat",
  // navigate to a chat screen
  if (initialMessage != null) {
    _handleMessage(initialMessage);
  }
  // Also handle any interaction when the app is in the background via a
  // Stream listener
  FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
}

void _handleMessage(RemoteMessage message) {
  if (kDebugMode) {
    inspect(message);
  }
  logger.d('Interacted FCM message: ${message.data}');
  final notification = message.notification;
  if (notification != null) {
    logger.d(
      'Interacted FCM notification: ${notification.title} ${notification.body}',
    );
  }
  // When user taps a notification, show dialog immediately (no preloading).
  _schedulePresentFcmMessageUi(
    message,
    preloadImage: false,
  );
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId}");
}
