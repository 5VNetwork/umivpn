import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:umivpn/app/settings/general/general.dart';
import 'package:umivpn/common/common.dart';
import 'package:umivpn/iap/pro.dart';
import 'package:umivpn/l10n/app_localizations.dart';
import 'package:umivpn/app/settings/account.dart';
import 'package:umivpn/app/settings/contact.dart';
import 'package:umivpn/app/settings/general/language.dart';
import 'package:umivpn/app/settings/open_source_software_notice_screen.dart';
import 'package:umivpn/app/settings/privacy.dart';
import 'package:umivpn/auth/auth_bloc.dart';
import 'package:umivpn/auth/user.dart';
import 'package:umivpn/main.dart';
import 'package:umivpn/pref_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:umivpn/utils/debug.dart';
import 'package:umivpn/utils/logger.dart';
import 'package:umivpn/utils/path.dart';
import 'package:umivpn/widgets/pro_icon.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:flutter_common/widgets/app_bar.dart';

final InAppReview inAppReview = InAppReview.instance;

enum SettingItem {
  account(icon: Icon(Icons.person_rounded), pathSegment: 'account'),
  general(icon: Icon(Icons.settings), pathSegment: 'general'),
  privacyPolicy(icon: Icon(Icons.info), pathSegment: 'privacy'),
  contactUs(icon: Icon(Icons.email_outlined), pathSegment: 'contactUs'),
  openSourceSoftwareNotice(
      icon: Icon(Icons.code_rounded), pathSegment: 'openSourceSoftwareNotice');

  final Widget icon;
  final String pathSegment;

  const SettingItem({required this.icon, required this.pathSegment});

  static SettingItem? fromPathSegment(String pathSegment) {
    for (final se in SettingItem.values) {
      if (se.pathSegment == pathSegment) {
        return se;
      }
    }
    return null;
  }

  static SettingItem? fromFullPath(String fullPath) {
    for (final se in SettingItem.values) {
      if (fullPath.startsWith('/setting/${se.pathSegment}')) {
        return se;
      }
    }
    return null;
  }

  Widget title(BuildContext context) {
    switch (this) {
      case SettingItem.account:
        return Text(AppLocalizations.of(context)!.account);
      case SettingItem.general:
        return Text(AppLocalizations.of(context)!.general);
      case SettingItem.privacyPolicy:
        return Text(AppLocalizations.of(context)!.privacyPolicy);
      case SettingItem.contactUs:
        return Text(AppLocalizations.of(context)!.contactUs);
      case SettingItem.openSourceSoftwareNotice:
        return Text(AppLocalizations.of(context)!.openSourceSoftwareNotice);
    }
  }

  Widget? subtitle(BuildContext context) {
    switch (this) {
      case SettingItem.account:
        return null;
      case SettingItem.general:
        return null;
      case SettingItem.privacyPolicy:
        return null;
      case SettingItem.contactUs:
        return null;
      case SettingItem.openSourceSoftwareNotice:
        return null;
    }
  }
}

const String websiteUrl = 'https://umivpn.5vnetwork.com';

List<Widget> _getBottomButtons(BuildContext context, User? user) {
  return [
    const SizedBox(
      height: 5,
    ),
    Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: OutlinedButton.icon(
              onPressed: () {
                launchUrl(Uri.parse(websiteUrl));
              },
              label: Text(AppLocalizations.of(context)!.website),
              icon: const Icon(Icons.link),
            ),
          ),
        ),
      ],
    ),
    SizedBox(
      height: 5,
    ),
    Row(
      children: [
        // TODO
        if (!useStripe && (user == null /* || (user.lifetimePro == false) */))
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: OutlinedButton.icon(
                onPressed: () {
                  if (user == null) {
                    showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                              title: Text(AppLocalizations.of(context)!
                                  .loginBeforePurchase),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: Text(
                                        AppLocalizations.of(context)!.close)),
                              ],
                            ));
                  } else {
                    context.read<ProPurchases>().restore();
                  }
                },
                icon: Icon(Icons.history_rounded,
                    color: Theme.of(context).colorScheme.primary),
                label: AutoSizeText(
                  AppLocalizations.of(context)!.restoreIAP,
                  maxLines: 1,
                  minFontSize: 12,
                ),
              ),
            ),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: OutlinedButton.icon(
              onPressed: () async {
                if (await inAppReview.isAvailable()) {
                  inAppReview.requestReview();
                } else {
                  inAppReview.openStoreListing(
                      appStoreId: '6744701950',
                      microsoftStoreId: '9PHBCBZ9R1FX');
                }
              },
              label: Text(AppLocalizations.of(context)!.rateApp),
              icon: const Icon(Icons.rate_review_outlined),
            ),
          ),
        ),
      ],
    ),
    const Version(),
    if (!isProduction())
      Row(
        children: [
          IconButton(
            onPressed: saveLogToApplicationDocumentsDir,
            icon: Icon(Icons.file_copy),
          ),
          IconButton(
            onPressed: clearDatabase,
            icon: Icon(Icons.delete),
          ),
          
        ],
      )
  ];
}

class CompactSettingScreen extends StatelessWidget {
  const CompactSettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthRepo>().user;
    return Scaffold(
      appBar: adaptiveClosableAppBar(context,
          title: AppLocalizations.of(context)!.settings),
      body: ListView(
        children: SettingItem.values.map<Widget>((se) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: ListTile(
              minTileHeight: 64,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              title: se.title(context),
              subtitle: se.subtitle(context),
              trailing: const Icon(Icons.keyboard_arrow_right_rounded),
              onTap: () async {
                context.go('/setting/${se.pathSegment}');
              },
            ),
          );
        }).toList()
          ..addAll(_getBottomButtons(context, user)),
      ),
    );
  }
}

class Version extends StatelessWidget {
  const Version({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.hasError) {
          return const SizedBox();
        } else {
          final packageInfo = snapshot.data!;
          return StatefulBuilder(builder: (context, setState) {
            int tapCount = 0;
            return GestureDetector(
              onTapDown: isProduction()
                  ? null
                  : (details) {
                      tapCount++;
                      if (tapCount == 10) {
                        context.read<AuthRepo>().setTestUser();
                      }
                    },
              child: Center(
                child: Text(
                    'Version: ${packageInfo.version} (${packageInfo.buildNumber})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )),
              ),
            );
          });
        }
      },
    );
  }
}

AppBar getAdaptiveAppBar(BuildContext context, Widget? title) {
  return AppBar(
    automaticallyImplyLeading: Platform.isMacOS ? false : true,
    title: title,
    actions: [
      if (Platform.isMacOS)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
    ],
  );
}
