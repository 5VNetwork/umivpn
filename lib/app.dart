part of 'main.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();

  static _AppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_AppState>();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  Locale? _locale;
  late final AppLifecycleListener _listener;
  final appLinks = AppLinks();
  late AppLifecycleReactor _appLifecycleReactor;

  void setLocale(Locale? value) {
    setState(() {
      _locale = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      locale: _locale,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: darkTheme(_locale),
      darkTheme: darkTheme(_locale),
      builder: desktopPlatforms
          ? (context, child) => DesktopTray(
                child: child!,
              )
          : null,
      routerConfig: router,
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        ...xv_app_localizations.AppLocalizations.localizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  @override
  void initState() {
    super.initState();
    final pref = context.read<SharedPreferences>();
    _appLifecycleReactor =
        AppLifecycleReactor(appOpenAdManager: context.read<OpenAdManager>())
          ..listenToAppStateChanges();
    if (pref.initialLaunch) {
      pref.setInitialLaunch();
      androidHostApi?.requestAddTile();
    }
    _locale = pref.language?.locale;
    WidgetsBinding.instance.addObserver(this);
    // app link
    if (Platform.isWindows && !isRunningAsAdmin) {
      _register('umivpn');
    }
    appLinks.uriLinkStream.listen(handlerAppLinks);
    if (fcmEnabled) {
      // fcm foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        logger.d('Got a message whilst in the foreground! ${message.data}');

        if (message.notification != null) {
          logger.d(
              'Message also contained a notification: ${message.notification}');
          final notification = message.notification;
          final android = message.notification?.android;
          if (notification != null && android != null) {}
        }
      });
      // Run code required to handle interacted messages in an async function
      // as initState() must not be async
      setupInteractedMessage();
    }

    _listener = AppLifecycleListener(
      onExitRequested: () async {
        logger.d('exit requested');
        if (isPkg) {
          await context.read<XController>().beforeExitCleanup();
        }
        return AppExitResponse.exit;
      },
      // This fires for each state change. Callbacks above fire only for
      // specific state transitions.
      // onStateChange: (state) => logger.d('state change: $state'),
    );
  }

  // It is assumed that all messages contain a data field with the key 'type'
  Future<void> setupInteractedMessage() async {
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
    logger.d('FCM message: ${message.data}');
  }

  Future<void> _register(String scheme) async {
    String appPath = Platform.resolvedExecutable;

    String protocolRegKey = 'Software\\Classes\\$scheme';
    RegistryValue protocolRegValue = const RegistryValue.string(
      'URL Protocol',
      '',
    );
    String protocolCmdRegKey = 'shell\\open\\command';
    RegistryValue protocolCmdRegValue = RegistryValue.string(
      '',
      '"$appPath" "%1"',
    );

    final regKey = Registry.currentUser.createKey(protocolRegKey);
    regKey.createValue(protocolRegValue);
    regKey.createKey(protocolCmdRegKey).createValue(protocolCmdRegValue);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _listener.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    logger.d(state);
    super.didChangeAppLifecycleState(state);
  }

  void handlerAppLinks(Uri uri) {
    logger.d(uri);
    if (uri.host == 'login-callback') {
      // Handle Supabase auth callback
      logger.d('Auth callback received: $uri');
      snack(AppLocalizations.of(context)?.loginSuccess);
      // The Supabase client should handle this automatically
    }
  }
}
