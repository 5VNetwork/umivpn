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
  // AppLifecycleReactor? _appLifecycleReactor;

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
        ...ads_app_localizations.AppLocalizations.localizationsDelegates,
        // ...country_app_localizations.AppLocalizations.localizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  @override
  void initState() {
    super.initState();
    final pref = context.read<SharedPreferences>();
    // if (isAdPlatforms) {
    //   _appLifecycleReactor =
    //       AppLifecycleReactor(appOpenAdManager: context.read<OpenAdManager>())
    //         ..listenToAppStateChanges();
    // }

    if (pref.initialLaunch || true) {
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
    _setupFcm();

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
    } else if (uri.host == 'order-success') {
      context.read<AuthRepo>().fetchSubscriptionInfo();
    }
  }
}
