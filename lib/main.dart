import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:google_api_availability/google_api_availability.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:macos_window_utils/macos/ns_window_button_type.dart';
import 'package:macos_window_utils/window_manipulator.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:tm/root_certs.dart';
import 'package:tm/tm.dart';
import 'package:tm/x_controller.dart';
import 'package:tm/xconfig_helper.dart';
import 'package:tm/status_cubit.dart';
import 'package:tm/ads/app_lifecycle.dart';
import 'package:tm/ads/start_ad.dart';
import 'package:umivpn/app/privacy.dart';
import 'package:umivpn/utils/android_host_api.g.dart';
import 'package:umivpn/app/choice_cubit.dart';
import 'package:umivpn/utils/darwin_host_api.g.dart';
import 'package:umivpn/app/home.dart';
import 'package:umivpn/app/manage_plan.dart';
import 'package:umivpn/app/welcome.dart';
import 'package:umivpn/app/settings/account.dart';
import 'package:umivpn/app/settings/contact.dart';
import 'package:umivpn/app/settings/general/general.dart';
import 'package:umivpn/app/settings/open_source_software_notice_screen.dart';
import 'package:umivpn/app/settings/privacy.dart';
import 'package:umivpn/app/settings/setting.dart';
import 'package:umivpn/utils/default_network.dart';
import 'package:umivpn/utils/geodata.dart';
import 'package:umivpn/utils/windows_host_api.g.dart';
import 'package:umivpn/auth/auth_bloc.dart';
import 'package:umivpn/common/bloc_observer.dart';
import 'package:umivpn/common/common.dart';
import 'package:umivpn/iap/iap.dart';
import 'package:umivpn/iap/pro.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:umivpn/utils/root.dart';
import 'package:umivpn/utils/upload_log.dart';
import 'package:flutter_common/auth/sign_in_page.dart';
import 'package:flutter_common/common.dart';
import 'package:flutter_common/util/download.dart';
import 'package:flutter_common/util/linux.dart';
import 'package:flutter_common/util/os.dart';
import 'package:flutter_common/auth/auth_provider.dart';
import 'package:flutter_common/services/periodic.dart';
import 'firebase_options.dart';
import 'package:umivpn/utils/logger.dart';
import 'package:umivpn/pref_helper.dart';
import 'package:umivpn/utils/path.dart';
import 'package:umivpn/l10n/app_localizations.dart';
import 'package:umivpn/theme.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:win32_registry/win32_registry.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_common/services/auto_update.dart';
import 'package:flutter_common/l10n/app_localizations.dart'
    as xv_app_localizations;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tm/secure_storage.dart';
import 'package:tm/xapi_client.dart';
import 'package:tm/http.dart';

part 'desktop_tray.dart';
part 'router.dart';
part 'app.dart';

void main() async {
  final startTime = DateTime.now();
  WidgetsFlutterBinding.ensureInitialized();
  // unawaited(MobileAds.instance.initialize());

  // fonts are bundled, disable runtime fetching
  if (Platform.isLinux || Platform.isWindows) {
    GoogleFonts.config.allowRuntimeFetching = false;
  }

  if (enableFirebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  final pref = await SharedPreferences.getInstance();
  resourceDirectory = await resourceDir();
  cacheDirectory = await getCacheDir();
  version = (await PackageInfo.fromPlatform()).version;

  FlutterSecureStorage storage = await getSecureStorage();
  // storage.deleteAll();
  final githubAssetName = await assetName();

  final apiClient = XApiClient()..init();
  await initLogger();
  final httpClient = HttpClient0(
    crts: crt,
    logger: logger,
    xApiClient: apiClient,
  );
  // await _initFcm();
  await _initSupabase(storage, httpClient);
  await setStartOnBoot(pref);

  await Future.wait([
    _initWindow(pref),
    Future(() async {
      if (Platform.isWindows) {
        isRunningAsAdmin = await windowsHostApi!.isRunningAsAdmin();
      } else if (Platform.isLinux) {
        isRunningAsAdmin = await checkLinuxRootPrivileges();
      }
      logger.d('isRunningAsAdmin: $isRunningAsAdmin');
    }),
  ]);

  final authProvider = SupabaseAuth(
      webClientId: webClientId,
      iosClientId: iosClientId,
      loginCallbackUrl: 'umivpn://login-callback');
  final proPurchases = false
      ? null
      : ProPurchases(
          applePlatform ? iosProductData : androidProductData, authProvider);
  if (kDebugMode) {
    Bloc.observer = const AppBlocObserver();
  }
  initRouter(authProvider);
  logger
      .d("App start time: ${DateTime.now().difference(startTime).inSeconds}s");

  periodicFetchCountries(pref);
  periodicFetchGeo(pref);

  runApp(MultiProvider(
    providers: [
      Provider.value(value: apiClient),
      if (proPurchases != null)
        ChangeNotifierProvider.value(value: proPurchases),
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider.value(value: AuthRepo(authProvider)),
      Provider.value(value: pref),
      Provider.value(value: storage),
      Provider<LogUploadService>(
          lazy: false,
          create: (ctx) {
            final logUploadService = LogUploadService(
                flutterLogDir: getFlutterLogDir(),
                tunnelLogDir: getTunnelLogDir(),
                secret: logKey,
                httpClient: HttpClient(),
                uploadUrl: kDebugMode
                    ? 'https://127.0.0.1:11111/api/upload-logs'
                    : 'https://umibackend.5vnetwork.com/api/upload-logs');
            if (pref.shareLog) {
              logUploadService.start();
            }
            return logUploadService;
          }),
      ChangeNotifierProvider(
        create: (ctx) {
          final controller = XController(
              httpClient: httpClient,
              pref: pref,
              xApiClient: ctx.read<XApiClient>(),
              supabase: supabase,
              onDisconnectedUnexpectedly: (error) {
                dialog(rootLocalizations()?.disconnectedUnexpectedly(error!));
                logger.e("disconnected!", error: error);
                reportError("disconnected due to", error);
                if (pref.shareLog) {
                  ctx.read<LogUploadService>().performUpload();
                }
              },
              secureStorage: storage,
              authRepo: ctx.read<AuthRepo>());
          if (Platform.isWindows) {
            MessageFlutterApi.setUp(controller);
          }
          return controller;
        },
        lazy: false,
      ),
      BlocProvider(
        create: (context) => ChoiceCubit(
          pref: context.read<SharedPreferences>(),
          storage: context.read<FlutterSecureStorage>(),
          xApiClient: context.read<XApiClient>(),
          xController: context.read<XController>(),
          authRepo: context.read<AuthRepo>(),
        ),
      ),
      BlocProvider(
        create: (context) => StatusCubit(
          xController: context.read<XController>(),
          authBloc: context.read<AuthRepo>(),
          pref: context.read<SharedPreferences>(),
        ),
      ),
      if (Platform.isAndroid)
        ChangeNotifierProvider(
          create: (context) {
            final vpnMonitor =
                DefaultNetworkMonitor(androidHostApi: androidHostApi);
            return vpnMonitor;
          },
          lazy: false,
        ),
      if (Platform.isAndroid || Platform.isIOS)
        Provider<OpenAdManager>(
          create: (context) {
            final adManager = OpenAdManager(
              isTest: !isProduction(),
              enabledOpenAd: context.read<SharedPreferences>().enableAppOpenAds,
              authRepo: context.read<AuthRepo>(),
              xController: context.read<XController>(),
              defaultNetworkMonitor: context.read<DefaultNetworkMonitor>(),
            );
            return adManager;
          },
          lazy: false,
        ),
      if (androidApkRelease ||
          (Platform.isWindows && !isStore) ||
          Platform.isLinux)
        ChangeNotifierProvider(
            lazy: false,
            create: (ctx) {
              final a = AutoUpdateService(
                  pref: pref,
                  downloader: directDownloadToFile,
                  currentVersion: version,
                  assetName: githubAssetName,
                  repository: '5vnetwork/vx',
                  exitCurrentApp: () {
                    return exitCurrentApp(ctx.read<XController>());
                  },
                  cacheDir: cacheDirectory);
              a.addListener(a.getListener(rootNavigationKey));
              return a;
            }),
    ],
    child: const App(),
  ));
}

final bool enableFirebase = !Platform.isWindows && !Platform.isLinux;
bool googleApiAvailable = false;
bool fcmEnabled = false;
late final AndroidNotificationChannel androidChannel;
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
// late final Directory appCache;
final WindowsHostApi? windowsHostApi =
    Platform.isWindows ? WindowsHostApi() : null;
bool isRunningAsAdmin = false;
final DarwinHostApi? darwinHostApi =
    Platform.isIOS || Platform.isMacOS ? DarwinHostApi() : null;
final AndroidHostApi? androidHostApi =
    Platform.isAndroid ? AndroidHostApi() : null;
late final Directory resourceDirectory;
late final String cacheDirectory;
late final String version;
// Router
final rootNavigationKey = GlobalKey<NavigatorState>();
final supabase = Supabase.instance.client;
final isAdPlatforms = Platform.isAndroid || Platform.isIOS;

void snack(
  String? message, {
  Duration? duration,
}) {
  if (message == null) {
    return;
  }
  rootScaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
    content: Text(message),
    duration: duration ?? const Duration(seconds: 4),
  ));
}

void dialog(
  String? title,
) {
  if (title == null) {
    return;
  }
  showDialog(
      context: rootNavigationKey.currentContext!,
      builder: (context) => AlertDialog(
            title: Text(title),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ));
}

AppLocalizations? rootLocalizations() {
  if (rootNavigationKey.currentContext == null) {
    return null;
  }
  return AppLocalizations.of(rootNavigationKey.currentContext!);
}

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// customize window
Future<void> _initWindow(SharedPreferences pref) async {
  if (desktopPlatforms) {
    if (desktopPlatforms) {
      await windowManager.ensureInitialized();
    }
    if (Platform.isMacOS) {
      await WindowManipulator.initialize();

      WindowManipulator.hideTitle();
      WindowManipulator.makeTitlebarTransparent();
      WindowManipulator.enableFullSizeContentView();
      WindowManipulator.overrideStandardWindowButtonPosition(
          buttonType: NSWindowButtonType.closeButton,
          offset: const Offset(15, 20));
      WindowManipulator.overrideStandardWindowButtonPosition(
          buttonType: NSWindowButtonType.miniaturizeButton,
          offset: const Offset(35, 20));
      WindowManipulator.overrideStandardWindowButtonPosition(
          buttonType: NSWindowButtonType.zoomButton,
          offset: const Offset(55, 20));
    }
    if (Platform.isWindows || Platform.isLinux) {
      WindowOptions windowOptions = WindowOptions(
        titleBarStyle: TitleBarStyle.hidden,
        alwaysOnTop: false,
        skipTaskbar: false,
        size: Size(pref.windowWidth, pref.windowHeight),
      );
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        if (pref.windowX != null && pref.windowY != null) {
          await windowManager.setPosition(Offset(pref.windowX!, pref.windowY!));
        } else {
          await windowManager.center();
        }
        await windowManager.show();
      });
    } else {
      if (pref.windowX != null && pref.windowY != null) {
        await windowManager.setPosition(Offset(pref.windowX!, pref.windowY!));
      } else {
        await windowManager.center();
      }
      await windowManager.setSize(Size(pref.windowWidth, pref.windowHeight));
    }
  }

  logger.d('window initialized');
}

Future<void> _initSupabase(
    FlutterSecureStorage storage, Client httpClient) async {
  await Supabase.initialize(
    authOptions: FlutterAuthClientOptions(
        localStorage: MySecureStorage(storage: storage)),
    headers: Platform.isWindows
        ? {
            'X-Supabase-Client-Platform-Version': 'Windows',
          }
        : null,
    httpClient: httpClient,
    url: supabaseUrl,
    anonKey: supabaseApiKey,
  );
}

Future<void> setStartOnBoot(SharedPreferences pref) async {
  if (Platform.isWindows) {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      launchAtStartup.setup(
        appName: packageInfo.appName,
        appPath: Platform.resolvedExecutable,
        // Set packageName parameter to support MSIX.
        packageName: packageInfo.packageName,
      );
      if (pref.startOnBoot && !await launchAtStartup.isEnabled()) {
        await launchAtStartup.enable();
      }
    } catch (e) {
      logger.e('Error setting up launch at startup', error: e);
    }
  }
}

Future<void> _initFcm() async {
  // set fcm enabled
  if (Platform.isAndroid) {
    GooglePlayServicesAvailability availability = await GoogleApiAvailability
        .instance
        .checkGooglePlayServicesAvailability();
    googleApiAvailable = availability == GooglePlayServicesAvailability.success;
    fcmEnabled = googleApiAvailable;
  } else if (Platform.isIOS || Platform.isMacOS) {
    fcmEnabled = true;
  }

  // fcm
  if (fcmEnabled) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    if (Platform.isAndroid) {
      // Android applications are not required to request permission.
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
      try {
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
          alert: true, // Required to display a heads up notification
          badge: true,
          sound: true,
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

void periodicFetchCountries(SharedPreferences pref) async {
  PeriodicTask(
          task: () async {
            try {
              final response = await directDownloadMemory(countryUrl);
              pref.setCountries(utf8.decode(response));
            } catch (e) {
              logger.e('Error fetching countries', error: e);
            }
          },
          sharedPreferences: pref,
          period: const Duration(hours: 6),
          lastRunKey: 'last_country_fetch')
      .start();
}

void periodicFetchGeo(SharedPreferences pref) {
  ScheduledTask(
          task: fetchGeo,
          sharedPreferences: pref,
          timeZone: 8,
          hour: 8,
          lastRunKey: 'last_geo_fetch')
      .start();
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  // await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId}");
}

Future<String> assetName() async {
  if (Platform.isAndroid) {
    return 'umivpn-arm64-v8a.apk.zip';
  } else if (Platform.isWindows) {
    // final ar = await arch();
    return 'UmiVPNInstaller.exe';
  } else if (isRpm()) {
    final ar = await arch();
    if (ar.contains('arm64')) {
      return 'umivpn-arm64.rpm';
    }
    return 'umivpn-x64.rpm';
  } else {
    final ar = await arch();
    if (ar.contains('arm64')) {
      return 'umivpn-arm64.deb';
    }
    return 'umivpn-x64.deb';
  }
}
