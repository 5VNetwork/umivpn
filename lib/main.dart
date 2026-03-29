import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:ads/ads_provider.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_common/widgets/dialog.dart';
import 'package:flutter_common/widgets/progress.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:google_api_availability/google_api_availability.dart';
import 'package:http/http.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:macos_window_utils/macos/ns_window_button_type.dart';
import 'package:macos_window_utils/window_manipulator.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:tm/activate.dart';
import 'package:tm/common.dart';
import 'package:tm/root_certs.dart';
import 'package:tm/tm.dart';
import 'package:tm/x_controller.dart';
import 'package:tm/xconfig_helper.dart';
import 'package:tm/status_cubit.dart';
import 'package:tm/ads/app_lifecycle.dart';
import 'package:tm/ads/start_ad.dart';
import 'package:umivpn/app/privacy.dart';
import 'package:umivpn/auth/user.dart';
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
import 'firebase_options_staging.dart' as staging;
import 'firebase_options_dev.dart' as dev;
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
import 'package:ads/l10n/app_localizations.dart' as ads_app_localizations;
import 'package:country/l10n/app_localizations.dart'
    as country_app_localizations;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tm/secure_storage.dart';
import 'package:tm/xapi_client.dart';
import 'package:tm/http.dart';
import 'package:path/path.dart' as path;
import 'package:sentry_flutter/sentry_flutter.dart';

part 'desktop_tray.dart';
part 'router.dart';
part 'app.dart';
part 'fcm.dart';

void main() async {
  final startTime = DateTime.now();
  WidgetsFlutterBinding.ensureInitialized();

  // fonts are bundled, disable runtime fetching
  if (Platform.isLinux || Platform.isWindows) {
    GoogleFonts.config.allowRuntimeFetching = false;
  }

  final pref = await SharedPreferences.getInstance();
  resourceDirectory = await resourceDir();
  cacheDirectory = await getCacheDir();
  await initLogger(pref);

  if (enableFirebase) {
    await initializeFirebaseApp();
    _initFcm();
  }

  version = (await PackageInfo.fromPlatform()).version;

  FlutterSecureStorage storage = await getSecureStorage();
  final githubAssetName = await assetName();

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

  final apiClient = XApiClient()..init();
  final httpClient = HttpClient0(
    crts: crt,
    logger: logger,
    xApiClient: apiClient,
  );
  await _initSupabase(storage, httpClient);
  await setStartOnBoot(pref);

  final authProvider = SupabaseAuth(
      webClientId: webClientId,
      iosClientId: iosClientId,
      loginCallbackUrl: 'umivpn://login-callback');
  final proPurchases = useStripe
      ? null
      : ProPurchases(
          applePlatform ? iosProductData : androidProductData, authProvider);
  if (kDebugMode) {
    Bloc.observer = const AppBlocObserver();
  }
  initRouter(authProvider);
  boot(storage, authProvider);
  logger
      .d("App start time: ${DateTime.now().difference(startTime).inSeconds}s");

  periodicFetchCountries(pref);
  periodicFetchGeo(pref);

  final app = MultiProvider(
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
                useReportLogger: () => pref.shareLog,
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
      if (autoUpdateSupported)
        Provider(
            lazy: false,
            create: (ctx) {
              final a = AutoUpdateService(
                pref: pref,
                downloader: directDownloadToFile,
                currentVersion: version,
                assetName: githubAssetName,
                repository: '5vnetwork/umivpn',
                exitCurrentApp: () {
                  return exitCurrentApp(ctx.read<XController>());
                },
                autoCheck: true,
                autoDownload: true,
                cacheDir: cacheDirectory,
                downloadUrl: kDebugMode
                    ? 'https://localhost:21451'
                    : 'https://umivpn.r2.5vnetwork.com',
                onNewVersionAvailable: (release) {
                  if (rootNavigationKey.currentContext == null) {
                    return;
                  }
                  showDialog(
                    context: rootNavigationKey.currentContext!,
                    builder: (context) => HasNewerVersionDialog(
                        release: release,
                        setSkipCurrentVersion: () {
                          rootNavigationKey.currentContext!
                              .read<AutoUpdateService>()
                              .setSkipCurrentVersion();
                        },
                        updateToRelease: (release) async {
                          final ctx = rootNavigationKey.currentContext!;
                          final messenger = ScaffoldMessenger.of(ctx);
                          final snackBarController = messenger.showSnackBar(
                            SnackBar(
                              persist: true,
                              content: Row(
                                children: [
                                  Text(
                                    AppLocalizations.of(ctx)!
                                        .downloading(release.version),
                                  ),
                                  const SizedBox(width: 12),
                                  smallCircularProgressIndicator(),
                                ],
                              ),
                            ),
                          );
                          try {
                            await ctx
                                .read<AutoUpdateService>()
                                .updateToRelease(release);
                          } finally {
                            snackBarController.close();
                          }
                        }),
                  );
                },
                onDownloadComplete: (downloadedInstaller) {
                  if (rootNavigationKey.currentContext == null) {
                    return;
                  }
                  showDialog(
                    context: rootNavigationKey.currentContext!,
                    builder: (context) => InstallNewerVersionDialog(
                        downloadedInstaller: downloadedInstaller,
                        setSkipCurrentInstaller: rootNavigationKey
                            .currentContext!
                            .read<AutoUpdateService>()
                            .setSkipCurrentVersion,
                        installLocalInstaller: () {
                          rootNavigationKey.currentContext!
                              .read<AutoUpdateService>()
                              .installLocalInstaller();
                        }),
                  );
                },
              );
              return a;
            }),
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
          autoUpdateService:
              autoUpdateSupported ? context.read<AutoUpdateService>() : null,
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
      // if (isAdPlatforms)
      //   Provider<OpenAdManager>(
      //     create: (context) {
      //       final adManager = OpenAdManager(
      //         isTest: !isProduction(),
      //         enabledOpenAd: context.read<SharedPreferences>().enableAppOpenAds,
      //         authRepo: context.read<AuthRepo>(),
      //         xController: context.read<XController>(),
      //         defaultNetworkMonitor: context.read<DefaultNetworkMonitor>(),
      //       );
      //       return adManager;
      //     },
      //     lazy: false,
      //   ),
      ChangeNotifierProxyProvider<AuthRepo, AdsProvider>(
          create: (context) {
            final adsProvider = AdsProvider(
                adsDirectory: path.join(resourceDirectory.path, 'ads'),
                sharedPreferences: context.read<SharedPreferences>(),
                downloadFunction: directDownloadToFile,
                logger: logger);
            if (context.read<AuthRepo>().user?.plan == SubscriptionPlan.pro) {
              adsProvider.start();
            }
            return adsProvider;
          },
          update: (context, authRepo, adsProvider) {
            if (authRepo.user?.plan == SubscriptionPlan.pro) {
              adsProvider?.stop();
            } else {
              adsProvider?.start();
            }
            return adsProvider!;
          },
          lazy: false),
    ],
    child: const App(),
  );

  if (isProduction()) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.sendDefaultPii = false;
      },
      appRunner: () => runApp(SentryWidget(child: app)),
    );
    // TODO: Remove this line after sending the first sample event to sentry.
    // await Sentry.captureException(Exception('This is a sample exception.'));
  } else {
    runApp(app);
  }
}

final bool enableFirebase = !Platform.isWindows && !Platform.isLinux;
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
// final isAdPlatforms = Platform.isAndroid;

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

FirebaseOptions _firebaseOptionsForCurrentFlavor() {
  return switch (appFlavor) {
    'produdction' || 'pkg' || 'apk' => DefaultFirebaseOptions.currentPlatform,
    'staging' => staging.DefaultFirebaseOptions.currentPlatform,
    _ => dev.DefaultFirebaseOptions.currentPlatform,
  };
}

/// Safe to call from main and from FCM background isolate. Handles hot restart
/// (Dart state cleared while native `[DEFAULT]` still exists).
Future<void> ensureFirebaseInitialized() async {
  if (Firebase.apps.isNotEmpty) {
    return;
  }
  final options = _firebaseOptionsForCurrentFlavor();
  try {
    await Firebase.initializeApp(options: options);
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      throw e;
    }
  }
}

Future<void> initializeFirebaseApp() async {
  await ensureFirebaseInitialized();
}
