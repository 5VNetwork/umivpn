import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_common/util/country.dart';
import 'package:flutter_common/widgets/app_bar.dart';
import 'package:gap/gap.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tm/protos/vx/tun/tun.pb.dart';
import 'package:tm/x_controller.dart';
import 'package:umivpn/app/settings/general/language.dart';
import 'package:umivpn/app/settings/general/country.dart';
import 'package:umivpn/auth/auth_bloc.dart';
import 'package:umivpn/auth/user.dart';
import 'package:umivpn/common/common.dart';
import 'package:tm/ads/start_ad.dart';
import 'package:umivpn/l10n/app_localizations.dart';
import 'package:umivpn/main.dart';
import 'package:umivpn/pref_helper.dart';
import 'package:umivpn/utils/logger.dart';
import 'package:flutter_common/services/auto_update.dart';
import 'package:flutter_common/widgets/progress.dart';
import 'package:country/country.dart';

class GeneralSettingPage extends StatelessWidget {
  const GeneralSettingPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? adaptiveClosableAppBar(
              context,
              title: AppLocalizations.of(context)!.general,
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.only(top: 8, right: 8),
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.only(
                top: 10,
                bottom: 10,
                left: 16,
                right: 16,
              ),
              child: ThemeModeSetting(),
            ),
            const Divider(),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              leading: const Icon(Icons.language),
              title: Text(
                AppLocalizations.of(context)!.language,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle:
                  Language.fromCode(
                        Localizations.localeOf(context).languageCode,
                      )?.localText !=
                      null
                  ? Text(
                      Language.fromCode(
                        Localizations.localeOf(context).languageCode,
                      )!.localText,
                    )
                  : null,
              trailing: const Icon(Icons.keyboard_arrow_right_rounded),
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (ctx) {
                      return const LanguagePage();
                    },
                  ),
                );
              },
            ),
            // ListTile(
            //   shape: RoundedRectangleBorder(
            //     borderRadius: BorderRadius.circular(10),
            //   ),
            //   leading: const Icon(Icons.flag_outlined),
            //   title: Text(AppLocalizations.of(context)!.currentLocation,
            //       style: Theme.of(context).textTheme.bodyLarge),
            //   subtitle: Text(
            //     _countryLabel(context, context.read<SharedPreferences>()),
            //   ),
            //   trailing: const Icon(Icons.keyboard_arrow_right_rounded),
            //   onTap: () {
            //     Navigator.of(context).push(
            //       CupertinoPageRoute(
            //         builder: (ctx) => const CountrySelectionPage(),
            //       ),
            //     );
            //   },
            // ),
            if (context.watch<AuthRepo>().user?.plan == SubscriptionPlan.air)
              const Column(
                children: [
                  Divider(),
                  Padding(
                    padding: EdgeInsets.only(
                      top: 10,
                      bottom: 10,
                      left: 16,
                      right: 16,
                    ),
                    child: ShowHomeAdsSetting(),
                  ),
                ],
              ),
            // if (isAdPlatforms)
            //   const Column(children: [
            //     Divider(),
            //     Padding(
            //       padding:
            //           EdgeInsets.only(top: 10, bottom: 10, left: 16, right: 16),
            //       child: AppOpenAdsSetting(),
            //     ),
            //   ]),
            // if (Platform.isWindows)
            //   const Column(children: [
            //     Divider(),
            //     Padding(
            //       padding:
            //           EdgeInsets.only(top: 10, bottom: 10, left: 16, right: 16),
            //       child: StartOnBootSetting(),
            //     ),
            //     Divider(),
            //     Padding(
            //       padding:
            //           EdgeInsets.only(top: 10, bottom: 10, left: 16, right: 16),
            //       child: AlwaysOnSetting(),
            //     ),
            //   ]),
            const Divider(),
            const Padding(
              padding: EdgeInsets.only(
                top: 10,
                bottom: 10,
                left: 16,
                right: 16,
              ),
              child: Tun46Setting(),
            ),
          ],
        ),
      ),
    );
  }
}

String _countryLabel(BuildContext context, SharedPreferences pref) {
  final selectedCountry = pref.userCountry;
  if (selectedCountry == null || selectedCountry.isEmpty) {
    return AppLocalizations.of(context)!.auto;
  }
  return getLocalizedCountryName(context, selectedCountry);
}

class ShowHomeAdsSetting extends StatelessWidget {
  const ShowHomeAdsSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final showHomeAds = context.watch<ShowHomeAdsNotifier>().show;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context)!.showHomeAds,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Expanded(child: SizedBox()),
            Switch(
              value: showHomeAds,
              onChanged: (value) {
                context.read<ShowHomeAdsNotifier>().setShow(value);
              },
            ),
          ],
        ),
        const Gap(10),
        Text(
          AppLocalizations.of(context)!.showHomeAdsDesc,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class Tun46Setting extends StatefulWidget {
  const Tun46Setting({super.key});

  @override
  State<Tun46Setting> createState() => _Tun46SettingState();
}

class _Tun46SettingState extends State<Tun46Setting> {
  late TunConfig_TUN46Setting _tun46Setting;

  @override
  void initState() {
    super.initState();
    var setting = context.read<SharedPreferences>().tun46Setting;
    if (Platform.isAndroid && setting == TunConfig_TUN46Setting.DYNAMIC) {
      setting = TunConfig_TUN46Setting.FOUR_ONLY;
      context.read<SharedPreferences>().setTun46Setting(setting);
    }
    _tun46Setting = setting;
  }

  Future<void> _onSelected(TunConfig_TUN46Setting? value) async {
    if (value == null || value == _tun46Setting) return;
    setState(() => _tun46Setting = value);
    context.read<SharedPreferences>().setTun46Setting(value);
    final xController = context.read<XController>();
    try {
      await xController.restart();
    } catch (e) {
      logger.e('setTun46Setting error', error: e);
      await xController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entries = <DropdownMenuEntry<TunConfig_TUN46Setting>>[
      DropdownMenuEntry(
        value: TunConfig_TUN46Setting.FOUR_ONLY,
        label: l10n.tun46SettingIpv4Only,
      ),
      DropdownMenuEntry(
        value: TunConfig_TUN46Setting.BOTH,
        label: l10n.tun46SettingIpv4AndIpv6,
      ),
      if (!Platform.isAndroid)
        DropdownMenuEntry(
          value: TunConfig_TUN46Setting.DYNAMIC,
          label: l10n.dependsOnDefaultNic,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.tunIpv6Settings,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const Gap(10),
        DropdownMenu<TunConfig_TUN46Setting>(
          key: ValueKey(_tun46Setting),
          initialSelection: _tun46Setting,
          requestFocusOnTap: false,
          dropdownMenuEntries: entries,
          onSelected: _onSelected,
        ),
        if (_tun46Setting == TunConfig_TUN46Setting.DYNAMIC) ...[
          const Gap(10),
          Text(
            l10n.dependsOnDefaultNicDesc,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class ThemeModeSetting extends StatefulWidget {
  const ThemeModeSetting({super.key});

  @override
  State<ThemeModeSetting> createState() => _ThemeModeSettingState();
}

class _ThemeModeSettingState extends State<ThemeModeSetting> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _themeMode = context.read<SharedPreferences>().themeMode;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.themeMode,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const Gap(10),
        DropdownMenu<ThemeMode>(
          initialSelection: _themeMode,
          requestFocusOnTap: false,
          dropdownMenuEntries: [
            DropdownMenuEntry(
              value: ThemeMode.light,
              label: AppLocalizations.of(context)!.light,
            ),
            DropdownMenuEntry(
              value: ThemeMode.dark,
              label: AppLocalizations.of(context)!.dark,
            ),
            DropdownMenuEntry(
              value: ThemeMode.system,
              label: AppLocalizations.of(context)!.system,
            ),
          ],
          onSelected: (value) {
            context.read<SharedPreferences>().setThemeMode(
              value ?? ThemeMode.system,
            );
            App.of(context)?.setThemeMode(value);
            setState(() {
              _themeMode = value ?? ThemeMode.system;
            });
          },
        ),
      ],
    );
  }
}

class StartOnBootSetting extends StatefulWidget {
  const StartOnBootSetting({super.key});

  @override
  State<StartOnBootSetting> createState() => _StartOnBootSettingState();
}

class _StartOnBootSettingState extends State<StartOnBootSetting> {
  bool _startOnBoot = false;

  @override
  void initState() {
    super.initState();
    _startOnBoot = context.read<SharedPreferences>().startOnBoot;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context)!.startOnBoot,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Expanded(child: SizedBox()),
            Switch(
              value: _startOnBoot,
              onChanged: (value) async {
                context.read<SharedPreferences>().setStartOnBoot(value);
                setState(() {
                  _startOnBoot = value;
                });
                if (value) {
                  await launchAtStartup.enable();
                } else {
                  await launchAtStartup.disable();
                }
              },
            ),
          ],
        ),
        const Gap(10),
        Text(
          AppLocalizations.of(context)!.startOnBootDesc,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// class AppOpenAdsSetting extends StatefulWidget {
//   const AppOpenAdsSetting({super.key});

//   @override
//   State<AppOpenAdsSetting> createState() => _AppOpenAdsSettingState();
// }

// class _AppOpenAdsSettingState extends State<AppOpenAdsSetting> {
//   bool _enableAppOpenAds = false;

//   @override
//   void initState() {
//     super.initState();
//     _enableAppOpenAds = context.read<SharedPreferences>().enableAppOpenAds;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Text(AppLocalizations.of(context)!.enableAppOpenAds,
//                 style: Theme.of(context).textTheme.bodyLarge),
//             const Expanded(child: SizedBox()),
//             Switch(
//               value: _enableAppOpenAds,
//               onChanged: (value) {
//                 context.read<SharedPreferences>().setEnableAppOpenAds(value);
//                 setState(() {
//                   _enableAppOpenAds = value;
//                 });
//                 context.read<OpenAdManager>().setOpenAdEnabled(value);
//               },
//             ),
//           ],
//         ),
//         const Gap(10),
//         Text(AppLocalizations.of(context)!.enableAppOpenAdsDesc,
//             style: Theme.of(context).textTheme.bodySmall!.copyWith(
//                   color: Theme.of(context).colorScheme.onSurfaceVariant,
//                 )),
//       ],
//     );
//   }
// }

class AlwaysOnSetting extends StatefulWidget {
  const AlwaysOnSetting({super.key});

  @override
  State<AlwaysOnSetting> createState() => _AlwaysOnSettingState();
}

class _AlwaysOnSettingState extends State<AlwaysOnSetting> {
  bool _alwaysOn = false;

  @override
  void initState() {
    super.initState();
    _alwaysOn = context.read<SharedPreferences>().alwaysOn;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context)!.alwaysOn,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Expanded(child: SizedBox()),
            Switch(
              value: _alwaysOn,
              onChanged: (value) {
                context.read<SharedPreferences>().setAlwaysOn(value);
                setState(() {
                  _alwaysOn = !_alwaysOn;
                });
              },
            ),
          ],
        ),
        const Gap(10),
        Text(
          AppLocalizations.of(context)!.alwaysOnDesc,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
