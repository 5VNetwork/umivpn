import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tm/x_controller.dart';
import 'package:tm/status_cubit.dart';
import 'package:umivpn/app/choice_cubit.dart';
import 'package:umivpn/auth/auth_bloc.dart';
import 'package:umivpn/auth/user.dart';
import 'package:umivpn/common/extension.dart';
import 'package:flutter_common/util/net.dart';
import 'package:tm/ads/start_ad.dart';
import 'package:umivpn/app/home_ad_provider.dart';
import 'package:umivpn/l10n/app_localizations.dart';
import 'package:umivpn/pref_helper.dart';
import 'package:umivpn/utils/default_network.dart';
import 'package:umivpn/utils/logger.dart';
import 'package:vector_graphics/vector_graphics_compat.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_common/common.dart';
import 'package:flutter_common/util/download.dart';
import 'package:flutter_common/util/country.dart';
import 'package:country/country.dart';
import 'package:umivpn/theme.dart';
import 'package:tm/default.dart';
import 'package:tm/ads/ad.dart';
part 'home_country_selector.dart';
part 'home_mode_selector.dart';
part 'home_traffic_card.dart';
part 'home_button.dart';

class VpnHomePage extends StatefulWidget {
  const VpnHomePage({super.key});

  @override
  State<VpnHomePage> createState() => _VpnHomePageState();
}

class _VpnHomePageState extends State<VpnHomePage> {
  @override
  void initState() {
    super.initState();
    final pref = context.read<SharedPreferences>();
    if (Platform.isAndroid && !pref.hasShownVpnServiceInfo || true) {
      pref.setHasShownVpnServiceInfo(true);
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        showDialog(
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
            });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final settingButton = IconButton(
      icon: Icon(Icons.settings_rounded,
          color: colorScheme.onSurface.withOpacity(0.87)),
      onPressed: () {
        context.go('/setting');
      },
    );
    return Scaffold(
      backgroundColor: colorScheme.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Platform.isMacOS ? null : settingButton,
        title: Container(
          child: Text(
            "UmiVPN",
            style: textTheme.titleMedium?.copyWith(
              letterSpacing: 1,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        centerTitle: true,
        flexibleSpace: desktopPlatform
            ? MoveWindow(
                child: Container(color: Colors.transparent),
              )
            : null,
        actions: [
          if (Platform.isWindows || Platform.isLinux)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                  onPressed: () async {
                    await windowManager.hide();
                  },
                  icon: Icon(Icons.remove_rounded,
                      color: colorScheme.onSurface.withOpacity(0.87))),
            ),
          if (Platform.isMacOS)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: settingButton,
            ),
        ],
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.bgColor,
                colorScheme.bgSecondary,
              ],
            ),
          ),
          child: Column(
            children: [
              // 1. Traffic Indicator
              // _buildTrafficCard(activeColor),
              // 2. Status Text & Timer
              const Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                ),
                child: HomeButton(),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child:
                      Consumer<AuthRepo>(builder: (context, authRepo, child) {
                    if (authRepo.userProfile == null) {
                      return const SizedBox.shrink();
                    }
                    if (authRepo.userProfile!.subscriptionPlan !=
                            SubscriptionPlan.pro &&
                        (Platform.isAndroid || Platform.isIOS)) {
                      return ChangeNotifierProvider(
                        create: (context) => HomeAdProvider(
                          defaultNetworkMonitor:
                              context.read<DefaultNetworkMonitor>(),
                          xController: context.read<XController>(),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // const Padding(
                            //   padding:
                            //       const EdgeInsets.symmetric(horizontal: 10.0),
                            //   child: Row(
                            //     children: [
                            //       Expanded(child: ModeSelector()),
                            //       Gap(10),
                            //       Expanded(child: CountrySelector())
                            //     ],
                            //   ),
                            // ),
                            SizedBox(height: 40),
                            Expanded(
                              child: BannerAdWidget(),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SingleChildScrollView(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ModeSelector(),
                          SizedBox(height: 15),
                          CountrySelector(),
                          SizedBox(height: 15),
                          _TrafficCard(),
                        ],
                      ),
                    );
                  }),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
