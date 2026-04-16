import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_common/widgets/app_bar.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:umivpn/common/common.dart';
import 'package:umivpn/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:umivpn/auth/auth_bloc.dart';
import 'package:umivpn/auth/user.dart';
import 'package:umivpn/utils/logger.dart';
import 'package:umivpn/widgets/pro_icon.dart';
import 'package:flutter_common/auth/auth_provider.dart';
import 'package:flutter_common/auth/sign_in_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key, this.showAppBar = true});
  final bool showAppBar;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  DateTime? _lastRefreshTime;
  static const Duration _refreshCooldown = Duration(seconds: 5);

  bool get _canRefresh {
    if (_lastRefreshTime == null) return true;
    return DateTime.now().difference(_lastRefreshTime!) >= _refreshCooldown;
  }

  void _refreshUser() {
    if (_canRefresh) {
      logger.d('refresh user');
      _lastRefreshTime = DateTime.now();
      context.read<AuthProvider>().refreshUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? adaptiveClosableAppBar(
              context,
              title: AppLocalizations.of(context)!.account,
            )
          : null,
      body: Consumer<AuthRepo>(
        builder: (context, authRepo, child) {
          if (authRepo.user == null) {
            return const SizedBox();
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.email,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AutoSizeText(
                        authRepo.user!.email,
                        maxLines: 2,
                        minFontSize: 12,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Center(
                  child: Row(
                    children: [
                      if (!isProduction())
                        ElevatedButton(
                          onPressed: () {
                            context.go('/sign-in');
                            context.read<AuthProvider>().logOut();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimary,
                          ),
                          child: Text(AppLocalizations.of(context)!.logout),
                        ),
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) {
                              var isDeleting = false;
                              return StatefulBuilder(
                                builder: (context, setDialogState) => AlertDialog(
                                  title: Text(
                                    AppLocalizations.of(context)!.deleteAccount,
                                  ),
                                  content: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.deleteAccountConfirm,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: isDeleting
                                          ? null
                                          : () => Navigator.pop(context),
                                      child: Text(
                                        AppLocalizations.of(context)!.cancel,
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                        foregroundColor: Theme.of(
                                          context,
                                        ).colorScheme.onError,
                                      ),
                                      onPressed: isDeleting
                                          ? null
                                          : () async {
                                              setDialogState(() {
                                                isDeleting = true;
                                              });

                                              try {
                                                final subscriptionInfo =
                                                    await authRepo
                                                        .fetchSubscriptionInfo();
                                                final hasActiveSubscription =
                                                    subscriptionInfo != null &&
                                                    !subscriptionInfo
                                                        .isCanceled;
                                                if (hasActiveSubscription) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          AppLocalizations.of(
                                                            context,
                                                          )!.cannotDeleteAccountWithActiveSubscription,
                                                        ),
                                                        backgroundColor:
                                                            Theme.of(
                                                              context,
                                                            ).colorScheme.error,
                                                      ),
                                                    );
                                                  }
                                                  return;
                                                }

                                                await context
                                                    .read<AuthProvider>()
                                                    .deleteAccount();
                                                if (context.mounted) {
                                                  Navigator.pop(context);
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        e.toString(),
                                                      ),
                                                      backgroundColor: Theme.of(
                                                        context,
                                                      ).colorScheme.error,
                                                    ),
                                                  );
                                                }
                                              } finally {
                                                if (context.mounted) {
                                                  setDialogState(() {
                                                    isDeleting = false;
                                                  });
                                                }
                                              }
                                            },
                                      child: isDeleting
                                          ? SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.error,
                                              ),
                                            )
                                          : Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.delete,
                                            ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onError,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.deleteAccount,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.go('/manage-plan');
                    },
                    icon: const Icon(Icons.credit_card_rounded),
                    label: Text(AppLocalizations.of(context)!.managePlan),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
