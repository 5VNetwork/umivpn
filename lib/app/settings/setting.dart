import 'dart:ffi';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_common/common.dart';
import 'package:flutter_common/services/auto_update.dart';
import 'package:flutter_common/widgets/progress.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:tm/common.dart';
import 'package:tm/private.dart';
import 'package:tm/x_controller.dart';
import 'package:umivpn/app/settings/general/general.dart';
import 'package:umivpn/common/common.dart';
import 'package:tm/iap/pro.dart';
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
import 'package:tm_windows/tm_windows_bindings_generated.dart';

final InAppReview inAppReview = InAppReview.instance;

enum SettingItem {
  account(icon: Icon(Icons.person_rounded), pathSegment: 'account'),
  general(icon: Icon(Icons.settings), pathSegment: 'general'),
  privacyPolicy(icon: Icon(Icons.info), pathSegment: 'privacy'),
  contactUs(icon: Icon(Icons.email_outlined), pathSegment: 'contactUs'),
  openSourceSoftwareNotice(
    icon: Icon(Icons.code_rounded),
    pathSegment: 'openSourceSoftwareNotice',
  ),
  ads(icon: Icon(Icons.ads_click_outlined), pathSegment: 'ads');

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
      case SettingItem.ads:
        return Text(AppLocalizations.of(context)!.promote);
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
      case SettingItem.ads:
        return null;
    }
  }
}

const String websiteUrl = 'https://umivpn.5vnetwork.com';

List<Widget> _getBottomButtons(BuildContext context, User? user) {
  return [
    const SizedBox(height: 5),
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
    SizedBox(height: 5),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: OutlinedButton.icon(
        onPressed: () async {
          if (await inAppReview.isAvailable()) {
            inAppReview.requestReview();
          } else {
            inAppReview.openStoreListing(
              appStoreId: '6744701950',
              microsoftStoreId: '9PHBCBZ9R1FX',
            );
          }
        },
        label: Text(AppLocalizations.of(context)!.rateApp),
        icon: const Icon(Icons.rate_review_outlined),
      ),
    ),
    if (!applePlatform) ...[
      SizedBox(height: 5),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: OutlinedButton.icon(
          onPressed: () async {
            launchUrl(Uri.parse(adWantedUrl));
          },
          label: Text(AppLocalizations.of(context)!.adWanted),
          icon: const Icon(Icons.ads_click_outlined),
        ),
      ),
    ],
    if (Platform.isWindows && isWinStore) ...[
      const Gap(5),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: RemoveWindowsServiceButton(),
      ),
    ],
    const Gap(5),
    const Version(),
    const Gap(5),
    if (autoUpdateSupported) const CheckUpdateButton(),
    ...getPrivateBottomButtons(context, user),
  ];
}

const adWantedUrl = 'https://vx.5vnetwork.com/zh/advertise';

class CompactSettingScreen extends StatelessWidget {
  const CompactSettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthRepo>().user;
    return Scaffold(
      appBar: adaptiveClosableAppBar(
        context,
        title: AppLocalizations.of(context)!.settings,
      ),
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
        }).toList()..addAll(_getBottomButtons(context, user)),
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
          return StatefulBuilder(
            builder: (context, setState) {
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
                    ),
                  ),
                ),
              );
            },
          );
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

class RemoveWindowsServiceButton extends StatefulWidget {
  const RemoveWindowsServiceButton({super.key});

  @override
  State<RemoveWindowsServiceButton> createState() =>
      _RemoveWindowsServiceButtonState();
}

class _RemoveWindowsServiceButtonState
    extends State<RemoveWindowsServiceButton> {
  bool _busy = false;

  /// Uninstalls the Windows Store Umi background service (`umi`). Requires admin.
  Future<void> removeWindowsService() async {
    if (!isRunningAsAdmin) {
      snack(rootLocalizations()?.removeWindowsServiceRequiresAdmin);
      return;
    }
    try {
      final tmWindowsBindings = TmWindowsBindings(
        DynamicLibrary.open(getDllPath()),
      );
      const serviceName = "umi";
      final serviceNamePtr = serviceName.toNativeUtf8();
      try {
        final resultPtr = tmWindowsBindings.RemoveService(
          serviceNamePtr.cast<Char>(),
        );
        final result = resultPtr.cast<Utf8>().toDartString();
        tmWindowsBindings.FreeString(resultPtr);
        if (result != "") {
          snack(result);
          return;
        }
        snack(rootLocalizations()?.windowsServiceRemoved);
      } finally {
        calloc.free(serviceNamePtr);
      }
    } catch (e, st) {
      logger.e('removeWindowsService', error: e, stackTrace: st);
      snack(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OutlinedButton.icon(
      onPressed: _busy
          ? null
          : () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.removeWindowsServiceConfirmTitle),
                  content: Text(l10n.removeWindowsServiceConfirmMessage),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(l10n.removeWindowsServiceConfirm),
                    ),
                  ],
                ),
              );
              if (confirmed != true || !context.mounted) {
                return;
              }
              setState(() => _busy = true);
              try {
                await removeWindowsService();
              } finally {
                if (mounted) {
                  setState(() => _busy = false);
                }
              }
            },
      icon: _busy
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : const Icon(Icons.delete_outline_rounded),
      label: Text(l10n.removeWindowsService),
    );
  }
}

class CheckUpdateButton extends StatefulWidget {
  const CheckUpdateButton({super.key});

  @override
  State<CheckUpdateButton> createState() => _CheckUpdateButtonState();
}

class _CheckUpdateButtonState extends State<CheckUpdateButton> {
  bool _checkingUpdate = false;

  @override
  Widget build(BuildContext context) {
    final autoUpdateService = context.watch<AutoUpdateService>();
    final isDownloading = autoUpdateService.isDownloading;

    return TextButton(
      onPressed: (_checkingUpdate || isDownloading)
          ? null
          : () async {
              setState(() {
                _checkingUpdate = true;
              });
              try {
                final release = await autoUpdateService.getLatestRelease();
                if (release != null) {
                  setState(() {
                    _checkingUpdate = false;
                  });
                  await autoUpdateService.updateToRelease(release);
                } else {
                  snack(AppLocalizations.of(context)!.noNewVersion);
                }
              } catch (e, stackTrace) {
                logger.e(
                  'Error checking update',
                  error: e,
                  stackTrace: stackTrace,
                );
                snack(e.toString());
              } finally {
                if (mounted) {
                  setState(() {
                    _checkingUpdate = false;
                  });
                }
              }
            },
      child: _checkingUpdate
          ? smallCircularProgressIndicator()
          : Text(
              isDownloading
                  ? AppLocalizations.of(
                      context,
                    )!.downloading(autoUpdateService.downloadingVersion ?? '')
                  : AppLocalizations.of(context)!.checkUpdate,
            ),
    );
  }
}
