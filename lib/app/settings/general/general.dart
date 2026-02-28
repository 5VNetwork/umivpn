import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_common/widgets/app_bar.dart';
import 'package:gap/gap.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umivpn/app/settings/general/language.dart';
import 'package:umivpn/common/common.dart';
import 'package:tm/ads/start_ad.dart';
import 'package:umivpn/l10n/app_localizations.dart';
import 'package:umivpn/main.dart';
import 'package:umivpn/pref_helper.dart';
import 'package:flutter_common/services/auto_update.dart';
import 'package:flutter_common/widgets/progress.dart';

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
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              leading: const Icon(Icons.language),
              title: Text(AppLocalizations.of(context)!.language,
                  style: Theme.of(context).textTheme.bodyLarge),
              subtitle: Language.fromCode(
                              Localizations.localeOf(context).languageCode)
                          ?.localText !=
                      null
                  ? Text(Language.fromCode(
                          Localizations.localeOf(context).languageCode)!
                      .localText)
                  : null,
              trailing: const Icon(Icons.keyboard_arrow_right_rounded),
              onTap: () {
                Navigator.of(context).push(CupertinoPageRoute(builder: (ctx) {
                  return const LanguagePage();
                }));
              },
            ),
            if (autoUpdateSupported)
              const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(),
                  AutoUpdateSettings(),
                ],
              ),
            if (Platform.isAndroid)
              const Column(children: [
                Divider(),
                Padding(
                  padding:
                      EdgeInsets.only(top: 10, bottom: 10, left: 16, right: 16),
                  child: AppOpenAdsSetting(),
                ),
              ]),
            if (Platform.isWindows)
              const Column(children: [
                Divider(),
                Padding(
                  padding:
                      EdgeInsets.only(top: 10, bottom: 10, left: 16, right: 16),
                  child: StartOnBootSetting(),
                ),
                Divider(),
                Padding(
                  padding:
                      EdgeInsets.only(top: 10, bottom: 10, left: 16, right: 16),
                  child: AlwaysOnSetting(),
                ),
              ]),
          ],
        ),
      ),
    );
  }
}

class AutoUpdateSettings extends StatelessWidget {
  const AutoUpdateSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AutoUpdateService>(
      builder: (context, autoUpdateService, child) {
        return Padding(
          padding:
              const EdgeInsets.only(top: 10, bottom: 10, left: 16, right: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context)!.autoUpdate,
                      style: Theme.of(context).textTheme.bodyLarge),
                  Switch(
                    value: autoUpdateService.autoUpdate,
                    onChanged: autoUpdateService.setAutoUpdate,
                  ),
                ],
              ),
              const Gap(10),
              Text(AppLocalizations.of(context)!.autoUpdateDescription,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
              if (autoUpdateService.downloadingVersion != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      const Gap(2),
                      smallCircularProgressIndicator(),
                      const Gap(10),
                      Text(
                          AppLocalizations.of(context)!.downloading(
                              autoUpdateService.downloadingVersion ?? ''),
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ))
                    ],
                  ),
                ),
              // if (!isProduction())
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextButton(
                  onPressed: () async {
                    final result = await autoUpdateService.checkForUpdates(
                      (await PackageInfo.fromPlatform()).version,
                    );
                    if (result == null) {
                      snack(AppLocalizations.of(context)!.noNewVersion);
                    } else {
                      autoUpdateService.checkAndUpdate();
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.checkAndUpdate),
                ),
              )
            ],
          ),
        );
      },
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
            Text(AppLocalizations.of(context)!.startOnBoot,
                style: Theme.of(context).textTheme.bodyLarge),
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
        Text(AppLocalizations.of(context)!.startOnBootDesc,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
      ],
    );
  }
}

class AppOpenAdsSetting extends StatefulWidget {
  const AppOpenAdsSetting({super.key});

  @override
  State<AppOpenAdsSetting> createState() => _AppOpenAdsSettingState();
}

class _AppOpenAdsSettingState extends State<AppOpenAdsSetting> {
  bool _enableAppOpenAds = false;

  @override
  void initState() {
    super.initState();
    _enableAppOpenAds = context.read<SharedPreferences>().enableAppOpenAds;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(AppLocalizations.of(context)!.enableAppOpenAds,
                style: Theme.of(context).textTheme.bodyLarge),
            const Expanded(child: SizedBox()),
            Switch(
              value: _enableAppOpenAds,
              onChanged: (value) {
                context.read<SharedPreferences>().setEnableAppOpenAds(value);
                setState(() {
                  _enableAppOpenAds = value;
                });
                context.read<OpenAdManager>().setOpenAdEnabled(value);
              },
            ),
          ],
        ),
        const Gap(10),
        Text(AppLocalizations.of(context)!.enableAppOpenAdsDesc,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
      ],
    );
  }
}

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
            Text(AppLocalizations.of(context)!.alwaysOn,
                style: Theme.of(context).textTheme.bodyLarge),
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
        Text(AppLocalizations.of(context)!.alwaysOnDesc,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
      ],
    );
  }
}
