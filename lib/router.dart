part of 'main.dart';

late final GoRouter router;

void initRouter(AuthProvider authProvider) {
  router = GoRouter(
      debugLogDiagnostics: !isProduction(),
      initialLocation: '/',
      redirect: (context, state) {
        final pref = context.read<SharedPreferences>();
        // Check if privacy page should be shown
        if (Platform.isIOS &&
            !pref.hasShownPrivacyInfo &&
            state.matchedLocation != '/privacy') {
          return '/privacy';
        }

        final authProvider = context.read<AuthProvider>();
        if (authProvider.currentSession == null) {
          return '/sign-in';
        }
        if (state.matchedLocation == '/sign-in') {
          return '/';
        }
        if (!pref.hasShownWelcome && state.matchedLocation != '/welcome') {
          return '/welcome';
        }
        return null;
      },
      refreshListenable: authProvider,
      navigatorKey: rootNavigationKey,
      routes: [
        GoRoute(
            path: '/',
            pageBuilder: (context, state) {
              return CustomTransitionPage(
                key: state.pageKey,
                child: const VpnHomePage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) => child,
              );
            },
            routes: [
              GoRoute(
                parentNavigatorKey: rootNavigationKey,
                path: 'manage-plan',
                pageBuilder: (context, state) => CupertinoPage(
                    child: ChangeNotifierProvider(
                        create: (context) => ManagePlanViewModel(
                              proPurchases: useStripe
                                  ? null
                                  : context.read<ProPurchases>(),
                              authRepo: context.read<AuthRepo>(),
                              locale:
                                  Localizations.localeOf(context).languageCode,
                            ),
                        child: const ManagePlanPage())),
              ),
              GoRoute(
                path: 'setting',
                parentNavigatorKey: rootNavigationKey,
                pageBuilder: (context, state) => const CupertinoPage(
                  child: CompactSettingScreen(),
                ),
                routes: [
                  GoRoute(
                    parentNavigatorKey: rootNavigationKey,
                    path: 'account',
                    pageBuilder: (context, state) =>
                        const CupertinoPage(child: AccountPage()),
                  ),
                  GoRoute(
                    parentNavigatorKey: rootNavigationKey,
                    path: 'general',
                    pageBuilder: (context, state) =>
                        const CupertinoPage(child: GeneralSettingPage()),
                  ),
                  GoRoute(
                    parentNavigatorKey: rootNavigationKey,
                    path: 'privacy',
                    pageBuilder: (context, state) =>
                        const CupertinoPage(child: PrivacyPolicyScreen()),
                  ),
                  GoRoute(
                    parentNavigatorKey: rootNavigationKey,
                    path: 'contactUs',
                    pageBuilder: (context, state) =>
                        const CupertinoPage(child: ContactScreen()),
                  ),
                  GoRoute(
                    parentNavigatorKey: rootNavigationKey,
                    path: 'openSourceSoftwareNotice',
                    pageBuilder: (context, state) => const CupertinoPage(
                        child: OpenSourceSoftwareNoticeScreen()),
                  ),
                ],
              )
            ]),
        GoRoute(
          path: '/welcome',
          builder: (context, state) => const WelcomePage(),
        ),
        GoRoute(
          path: '/privacy',
          builder: (context, state) => const InitialPage(),
        ),
        GoRoute(
          path: '/sign-in',
          builder: (context, state) => Scaffold(
            floatingActionButton: !isProduction()
                ? FloatingActionButton(
                    onPressed: () async {
                      await supabase.auth.signInWithPassword(
                        email: 'test@example.com',
                        password: '123456789',
                      );
                    },
                    child: const Icon(Icons.arrow_back),
                  )
                : null,
            body: const Center(
              child: SignInPage(
                  showGoogle: true,
                  showMicrosoft: false,
                  showApple: false,
                  termOfServiceUrl: termOfServiceUrl,
                  privacyPolicyUrl: privacyPolicyUrl),
            ),
          ),
        ),
      ]);

  final largeScreenRouteConfig = RoutingConfig(
      redirect: (context, state) {
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const VpnHomePage(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) => child,
            );
          },
        )
      ]);
}
