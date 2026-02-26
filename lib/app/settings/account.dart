import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_common/widgets/app_bar.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
          ? adaptiveClosableAppBar(context,
              title: AppLocalizations.of(context)!.account)
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
                    Text(AppLocalizations.of(context)!.email,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AutoSizeText(authRepo.user!.email,
                          maxLines: 2,
                          minFontSize: 12,
                          style: Theme.of(context).textTheme.bodyLarge),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Center(
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          context.go('/sign-in');
                          context.read<AuthProvider>().logOut();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                        ),
                        child: Text(AppLocalizations.of(context)!.logout),
                      ),
                      Gap(10),
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                  AppLocalizations.of(context)!.deleteAccount),
                              content: Text(AppLocalizations.of(context)!
                                  .deleteAccountConfirm),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                        AppLocalizations.of(context)!.cancel)),
                                TextButton(
                                    onPressed: () async {
                                      final userProfile = authRepo.userProfile;

                                      // Check if user has a non-canceled subscription
                                      final hasSubscription =
                                          userProfile!.subscriptionPlan !=
                                              SubscriptionPlan.free;

                                      if (hasSubscription) {
                                        // Close the confirmation dialog
                                        Navigator.pop(context);

                                        // Show error message
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                AppLocalizations.of(context)!
                                                    .cannotDeleteAccountWithActiveSubscription,
                                              ),
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                            ),
                                          );
                                        }
                                        return;
                                      }

                                      // Proceed with account deletion
                                      context
                                          .read<AuthProvider>()
                                          .deleteAccount();
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                        AppLocalizations.of(context)!.delete))
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor:
                              Theme.of(context).colorScheme.onError,
                        ),
                        child:
                            Text(AppLocalizations.of(context)!.deleteAccount),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // SizedBox(
                //   width: double.infinity,
                //   child: OutlinedButton.icon(
                //     onPressed: () {
                //       context.go('/manage-plan');
                //     },
                //     icon: const Icon(Icons.credit_card_rounded),
                //     label: Text(AppLocalizations.of(context)!.managePlan),
                //   ),
                // ),
              ],
            ),
          );
        },
      ),
    );
  }
}
