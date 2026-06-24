import 'dart:async';
import 'dart:io';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tm/common.dart';
import 'package:tm/fetch_result_provider.dart';
import 'package:tm/private.dart';
import 'package:tm/x_controller.dart';
import 'package:tm/status_cubit.dart';
import 'package:umivpn/app/choice_cubit.dart';
import 'package:umivpn/app/control.dart';
import 'package:umivpn/app/manage_plan.dart';
import 'package:umivpn/app/settings/general/country.dart';
import 'package:umivpn/app/support/support_unread_badge.dart';
import 'package:umivpn/auth/auth_bloc.dart';
import 'package:umivpn/auth/user.dart';
import 'package:flutter_common/util/net.dart';
import 'package:tm/ads/home_ad_provider.dart';
import 'package:umivpn/common/common.dart';
import 'package:tm/iap/pro.dart';
import 'package:umivpn/l10n/app_localizations.dart';
import 'package:umivpn/main.dart';
import 'package:umivpn/pref_helper.dart';
import 'package:umivpn/utils/default_network.dart';
import 'package:umivpn/utils/logger.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_common/common.dart';
import 'package:flutter_common/util/country.dart';
import 'package:country/country.dart';
import 'package:umivpn/theme.dart';
import 'package:tm/default.dart';
import 'package:tm/ads/ad.dart';
import 'package:ads/ad.dart' as my;
import 'package:url_launcher/url_launcher.dart';

part 'home_country_selector.dart';
part 'home_mode_selector.dart';
part 'inbound_mode_selector.dart';
part 'home_traffic_card.dart';
part 'home_button.dart';

class VpnHomePage extends StatefulWidget {
  const VpnHomePage({super.key});

  @override
  State<VpnHomePage> createState() => _VpnHomePageState();
}

class _VpnHomePageState extends State<VpnHomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  static const _directAppTutorialUrl = 'https://www.umivpn.com/add-direct-apps';

  @override
  void initState() {
    super.initState();
    final pref = context.read<SharedPreferences>();
    if (Platform.isAndroid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAndroidFirstLaunchTips();
      });
    } else if (pref.userCountry == null) {
      // WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      //   Navigator.of(context).push(CupertinoPageRoute(
      //       builder: (context) => const CountrySelectionPage(
      //             firstLaunch: true,
      //           )));
      // });
    }
  }

  Future<void> _showAndroidFirstLaunchTips() async {
    final pref = context.read<SharedPreferences>();
    if (!pref.hasShownVpnServiceInfo) {
      pref.setHasShownVpnServiceInfo(true);
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final theme = Theme.of(context);
          final l10n = AppLocalizations.of(context)!;
          return AlertDialog(
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.shield,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text('VPN Service'),
              ],
            ),
            content: Text(
              l10n.vpnServiceDesc,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  child: Text(l10n.okay),
                ),
              ),
            ],
          );
        },
      );
    }
    if (!mounted) return;
    if (!pref.hasShownDirectAppTip) {
      pref.setHasShownDirectAppTip(true);
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final theme = Theme.of(context);
          final l10n = AppLocalizations.of(context)!;
          return AlertDialog(
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.apps_outlined,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.directAppTipTitle)),
              ],
            ),
            content: Text(
              l10n.directAppTipDesc,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(_directAppTutorialUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_new),
                label: Text(l10n.viewDirectAppTutorial),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  child: Text(l10n.okay),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final settingButton = Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            icon: Icon(
              Icons.tune_rounded,
              color: colorScheme.onSurface.withOpacity(0.87),
            ),
            tooltip: AppLocalizations.of(context)!.advanced,
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.settings_rounded,
            color: colorScheme.onSurface.withOpacity(0.87),
          ),
          onPressed: () {
            context.go('/setting');
          },
        ),
        SizedBox(width: 8),
        IconButton(
          onPressed: () => context.go('/log'),
          icon: Icon(
            Icons.receipt_long_rounded,
            color: colorScheme.onSurface.withOpacity(0.87),
          ),
          tooltip: AppLocalizations.of(context)!.log,
        ),
      ],
    );
    final title = SizedBox() /*  Text(
      "UmiVPN",
      style: textTheme.titleMedium?.copyWith(
        letterSpacing: 1,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
    ) */;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: colorScheme.bgColor,
      drawer: ControlDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Platform.isMacOS ? null : settingButton,
        leadingWidth: desktopPlatform ? 148 : 168,
        title: desktopPlatform
            ? ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 24),
                child: MoveWindow(child: title),
              )
            : title,
        centerTitle: true,
        flexibleSpace: desktopPlatform
            ? MoveWindow(child: Container(color: Colors.transparent))
            : null,
        actions: [
          SupportUnreadIconButton(
            route: '/supportChat',
            icon: Icons.support_agent_rounded,
            iconColor: colorScheme.onSurface.withValues(alpha: 0.87),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              context.go('/manage-plan');
            },
            icon: Icon(
              Icons.credit_card_rounded,
              color: colorScheme.onSurface.withOpacity(0.87),
            ),
          ),
          if (Platform.isWindows || Platform.isLinux)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                onPressed: () async {
                  await windowManager.hide();
                },
                icon: Icon(
                  Icons.remove_rounded,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),
            ),
          if (Platform.isMacOS)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: settingButton,
            ),
        ],
      ),
      body: SafeArea(
        child: Consumer<AuthRepo>(
          builder: (context, authRepo, child) {
            final userProfile = authRepo.user;
            if (userProfile == null) {
              return const _ProfileLoader();
            }
            // if (userProfile.plan == SubscriptionPlan.free) {
            //   final locale = Localizations.localeOf(context).languageCode;
            //   return ChangeNotifierProvider(
            //       create: (context) => ManagePlanViewModel(
            //             proPurchases:
            //                 useStripe ? null : context.read<ProPurchases>(),
            //             authRepo: context.read<AuthRepo>(),
            //             locale: locale,
            //           ),
            //       child: Padding(
            //         padding: const EdgeInsets.all(8.0),
            //         child: const ManagePlanBody(),
            //       ));
            // }
            if (!isProduction()) {
              return Stack(
                children: [
                  _HomeBody(),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: HandlersBeingUsed(),
                  ),
                ],
              );
            }
            return const _HomeBody();
          },
        ),
      ),
    );
  }
}

class _ProfileLoader extends StatefulWidget {
  const _ProfileLoader({super.key});

  @override
  State<_ProfileLoader> createState() => _ProfileLoaderState();
}

class _ProfileLoaderState extends State<_ProfileLoader> {
  late Future<SubscriptionInfo?> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AuthRepo>().fetchSubscriptionInfo();
  }

  void _retry() {
    setState(() {
      _future = context.read<AuthRepo>().fetchSubscriptionInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: FutureBuilder<SubscriptionInfo?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              snapshot.connectionState == ConnectionState.active) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
              ],
            );
          }

          // If we reach here and still no profile, treat as error.
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: colorScheme.error, size: 32),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.serverError,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(
                  context,
                )!.failedToFetchProfile(snapshot.error.toString()),
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _retry, child: const Text('Retry')),
            ],
          );
        },
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colorScheme.bgColor, colorScheme.bgSecondary],
        ),
      ),
      child: Column(
        children: [
          // 1. Traffic Indicator
          // _buildTrafficCard(activeColor),
          // 2. Status Text & Timer
          const Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: HomeButton(),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Consumer<AuthRepo>(
                  builder: (context, authRepo, child) {
                    if (authRepo.user == null) {
                      return const SizedBox.shrink();
                    }
                    if (authRepo.user!.plan == SubscriptionPlan.free) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: my.BannerAdWidget(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: const ModeSelector()),
                              if (desktopPlatform) const SizedBox(width: 10),
                              if (desktopPlatform)
                                Expanded(child: InboundModeSelector()),
                            ],
                          ),
                          // Row(
                          //   children: [
                          //     Expanded(child: ModeSelector()),
                          //     const SizedBox(width: 10),
                          //     Expanded(child: CountrySelector())
                          //   ],
                          // ),
                          const SizedBox(height: 10),
                          const _TrafficCard(),
                          const SizedBox(height: 10),
                        ],
                      );
                    }
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (authRepo.user!.plan == SubscriptionPlan.air)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 15.0),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: my.BannerAdWidget(),
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(child: const ModeSelector()),
                            if (desktopPlatform) const SizedBox(width: 10),
                            if (desktopPlatform)
                              Expanded(child: InboundModeSelector()),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: const CountrySelector(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
