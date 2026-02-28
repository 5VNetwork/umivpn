import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_common/common.dart';
import 'package:flutter_common/widgets/app_bar.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:provider/provider.dart';
import 'package:umivpn/auth/auth_bloc.dart';
import 'package:umivpn/auth/user.dart';
import 'package:umivpn/common/common.dart';
import 'package:umivpn/l10n/app_localizations.dart';
import 'package:umivpn/main.dart';
import 'package:umivpn/theme.dart';
import 'package:umivpn/utils/logger.dart';
import 'package:umivpn/iap/pro.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_common/auth/auth_provider.dart';
import 'package:flutter_common/widgets/dialog.dart';
import 'package:flutter_common/widgets/progress.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

part 'manage_plan_current.dart';
part 'manage_plan_all_stripe.dart';

class ManagePlanPage extends StatelessWidget {
  const ManagePlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.bgColor,
      appBar: adaptiveClosableAppBar(context,
          title: AppLocalizations.of(context)!.managePlan),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            // Current Plan Section
            const _CurrentPlan(),
            const SizedBox(height: 16),
            // Available Plans Section
            Text(
              '${AppLocalizations.of(context)!.availablePlans}',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const AllPlans(),
          ],
        ),
      ),
    );
  }
}

SubscriptionSource _source() {
  if (useStripe) {
    return SubscriptionSource.stripe;
  } else if (Platform.isAndroid) {
    return SubscriptionSource.playStore;
  } else {
    return SubscriptionSource.appStore;
  }
}

class ManagePlanViewModel extends ChangeNotifier {
  final AuthRepo authRepo;
  final ProPurchases? proPurchases;
  final String locale;
  ManagePlanViewModel(
      {required this.authRepo, this.proPurchases, this.locale = 'zh'}) {
    _fetchSubscriptionInfo();
    _fetchPlans();
    proPurchases?.addListener(_onProPurchasesChanged);
  }

  @override
  void dispose() {
    proPurchases?.removeListener(_onProPurchasesChanged);
    super.dispose();
  }

  void _onProPurchasesChanged() {
    if (proPurchases?.purchaseDetails != null &&
        proPurchases?.purchaseDetails!.status == PurchaseStatus.purchased &&
        proPurchases?.buying == false &&
        proPurchases?.verifyErrorMessage == null) {
      _fetchSubscriptionInfo();
    }
  }

  UserProfile get userProfile => authRepo.userProfile!;
  DateTime get refreshDate {
    if (userProfile.subscriptionPlan == SubscriptionPlan.free) {
      return DateTime(DateTime.now().year, DateTime.now().month + 1, 1);
    }
    return userProfile.cycleEndAt!;
  }

  bool loadingSubscriptionInfo = false;
  String? errorFetchingSubscriptionInfo;
  SubscriptionInfo? subscriptionInfo;
  Future<void> _fetchSubscriptionInfo() async {
    loadingSubscriptionInfo = true;
    notifyListeners();
    try {
      subscriptionInfo = await authRepo.fetchSubscriptionInfo();
    } catch (e) {
      errorFetchingSubscriptionInfo = e.toString();
    } finally {
      loadingSubscriptionInfo = false;
      notifyListeners();
    }
  }

  void fetchSubscriptionInfo() {
    _fetchSubscriptionInfo();
  }

  Map<SubscriptionPlan, PlanMetadata>? plans;
  bool loadingPlans = false;
  String? errorFetchingPlans;
  Future<void> _fetchPlans() async {
    loadingPlans = true;
    notifyListeners();
    try {
      final fetchedPlans = await PlanService.fetchPlans(
          'https://pub-ffc1bef2c4eb4b8fb433f0706418dabe.r2.dev/plans/${locale}.json');
      inspect(fetchedPlans);
      plans = proPurchases != null
          ? _convertToIAPPlans(fetchedPlans, proPurchases!)
          : fetchedPlans;
      loadingPlans = false;
    } catch (e) {
      errorFetchingPlans = e.toString();
      logger.e('Failed to load plans', error: e);
    } finally {
      loadingPlans = false;
      notifyListeners();
    }
  }

  Future<void> buy(BuildContext context, PriceOption priceOption,
      SubscriptionPlan plan) async {
    if (proPurchases != null) {
      if (applePlatform || subscriptionInfo == null) {
        await proPurchases!.buy(PurchaseParam(
            productDetails: priceOption.iapProduct!.productDetails));
      } else {
        // android and there is a subscription already
        // Get the old purchase details for subscription change
        final oldPurchaseDetails = await _getOldPurchaseDetails();
        if (oldPurchaseDetails == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.purchaseFailed(
                  'Unable to find current subscription purchase details')),
            ),
          );
          return;
        }
        ReplacementMode? replacementMode;
        // upgrade
        if (plan.index > (subscriptionInfo!.planAndPeriod.$1.index)) {
          replacementMode = ReplacementMode.withTimeProration;
        } else if (plan.index < (subscriptionInfo!.planAndPeriod.$1.index)) {
          // downgrade
          replacementMode = ReplacementMode.deferred;
        }

        final purchaseParam = GooglePlayPurchaseParam(
            productDetails: priceOption.iapProduct!.productDetails,
            changeSubscriptionParam: ChangeSubscriptionParam(
                oldPurchaseDetails: oldPurchaseDetails,
                replacementMode: replacementMode));
        await proPurchases!.buy(purchaseParam);
      }
    } else {
      await _createCheckoutSession(context, priceOption);
    }
    _fetchSubscriptionInfo();
  }

  Future<GooglePlayPurchaseDetails?> _getOldPurchaseDetails() async {
    if (proPurchases == null) return null;

    // First, try to get from current state if available
    if (proPurchases!.purchaseDetails != null) {
      return proPurchases!.purchaseDetails as GooglePlayPurchaseDetails;
    }

    // If not in state, restore purchases to find the active one
    try {
      await proPurchases!.restore();
      // Wait a bit for the purchase stream to update
      await Future.delayed(const Duration(milliseconds: 500));
      if (proPurchases!.purchaseDetails != null) {
        return proPurchases!.purchaseDetails as GooglePlayPurchaseDetails;
      }
    } catch (e) {
      logger.e('Error restoring purchases: $e');
    }
    return null;
  }

  Future<void> cancelSubscription() async {
    final token = await authRepo.getAccessToken();
    if (token == null) {
      throw Exception('No token found');
    }
    final response = await supabase.functions.invoke(
      'cancel-subscription',
      headers: {
        'Authorization': 'Bearer $token',
        'X-Cancel-Subscription': 'true',
      },
    );
    if (response.status != 200) {
      throw Exception(
          'Failed to cancel subscription: ${response.data['error']}');
    }
    _fetchSubscriptionInfo();
  }

  bool isReactivating = false;
  Future<void> reactivateSubscription(BuildContext context) async {
    if (subscriptionInfo == null || subscriptionInfo!.isCanceled == false) {
      throw Exception('Subscription is not canceled');
    }
    if (subscriptionInfo!.source == SubscriptionSource.appStore) {
      final uri = Uri.parse(
          'https://apps.apple.com/account/subscriptions?app-id=6751115042');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      final colorScheme = Theme.of(context).colorScheme;
      final textTheme = Theme.of(context).textTheme;

      areYouSureDialog(
          ctx: context,
          title: Text(
            AppLocalizations.of(context)!.areYouSureReactivate,
            style:
                textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
          ),
          onYes: () async {
            Navigator.pop(context);
            final token = supabase.auth.currentSession?.accessToken;
            if (token == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.noTokenFound),
                ),
              );
              return;
            }
            isReactivating = true;
            notifyListeners();
            try {
              final token = await authRepo.getAccessToken();
              if (token == null) {
                throw Exception('No token found');
              }
              final response = await supabase.functions.invoke(
                'cancel-subscription',
                headers: {
                  'Authorization': 'Bearer $token',
                  'X-Cancel-Subscription': 'false',
                },
              );
              fetchSubscriptionInfo();
              if (response.status != 200) {
                throw Exception({response.data['error']});
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      AppLocalizations.of(context)!.subscriptionReactivated),
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to reactivate subscription: $e'),
                ),
              );
            } finally {
              isReactivating = false;
              notifyListeners();
            }
          },
          onNo: () => Navigator.pop(context));
    }
  }

  void cancel(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    areYouSureDialog(
        ctx: context,
        title: Text(
          "Are you sure you want to cancel?",
          style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
        ),
        content: Text(
          "After cancellation, you will continue to have access until the end of your current billing period. ${subscriptionInfo?.source == SubscriptionSource.stripe ? 'You can reactivate your subscription at any time.' : ''}",
          style: TextStyle(color: colorScheme.onSurface.withOpacity(0.87)),
        ),
        onNo: () => Navigator.pop(context),
        onYes: () async {
          Navigator.pop(context);
          isReactivating = true;
          notifyListeners();
          try {
            await cancelSubscription();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text(AppLocalizations.of(context)!.subscriptionCancelled),
                ),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to cancel subscription: $e'),
              ),
            );
          } finally {
            isReactivating = false;
            notifyListeners();
          }
        });
  }

  bool isManaging = false;
  void _onManageSubscription(BuildContext context) async {
    if (subscriptionInfo!.source == SubscriptionSource.stripe) {
      // Open Stripe customer portal
      isManaging = true;
      notifyListeners();

      try {
        final token = supabase.auth.currentSession?.accessToken;
        if (token == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("No token found"),
            ),
          );
          return;
        }
        final response = await supabase.functions.invoke(
          'create-stripe-portal-session',
          headers: {
            'Authorization': 'Bearer $token',
          },
        );
        if (context.mounted) {
          if (response.status == 200 && response.data != null) {
            final url = response.data['url'] as String;
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              throw Exception('Could not open customer portal');
            }
          } else {
            final errorMessage =
                response.data?['error'] as String? ?? 'Unknown error';
            throw errorMessage;
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: $e"),
            ),
          );
        }
      } finally {
        isManaging = false;
        notifyListeners();
      }
    } else if (subscriptionInfo!.source == SubscriptionSource.playStore) {
      // Open Google Play subscriptions center
      final uri = Uri.parse(
          'https://play.google.com/store/account/subscriptions?sku=umivpn_${subscriptionInfo!.planAndPeriod.$1.name.toLowerCase()}&package=${androidPackageNme}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!
                .couldNotOpenPlayStoreSubscriptions),
          ),
        );
      }
    } else if (subscriptionInfo!.source == SubscriptionSource.appStore) {
      // Open App Store subscription management URL for this specific app
      // Using the app's Apple ID to go directly to this app's subscription page
      final uri = Uri.parse(
          'https://apps.apple.com/account/subscriptions?app-id=6751115042');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.couldNotOpenAppStoreSubscriptions,
              ),
            ),
          );
        }
      }
    }
  }
}

Future<void> _createCheckoutSession(
  BuildContext context,
  PriceOption priceOption,
) async {
  if (priceOption.priceId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.priceIdNotAvailable),
      ),
    );
    return;
  }
  final colorScheme = Theme.of(context).colorScheme;

  // Show loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Center(
      child: CircularProgressIndicator(
        color: colorScheme.primary,
      ),
    ),
  );

  try {
    final token = supabase.auth.currentSession?.accessToken;
    if (token == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.noAuthenticationTokenFound),
        ),
      );
      return;
    }

    // Call the edge function to create checkout session
    final response = await supabase.functions.invoke(
      'create-stripe-checkout-session',
      headers: {
        'Authorization': 'Bearer $token',
      },
      body: {
        'price_id': priceOption.priceId,
      },
    );

    Navigator.pop(context); // Close loading dialog

    if (response.status == 200 && response.data != null) {
      final url = response.data['url'] as String?;
      if (url != null && url.isNotEmpty) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.couldNotOpenCheckoutUrl),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.noCheckoutUrlReceived),
          ),
        );
      }
    } else {
      final errorMessage =
          response.data?['error'] as String? ?? 'Unknown error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!
              .failedToCreateCheckoutSession(errorMessage)),
        ),
      );
    }
  } catch (e) {
    Navigator.pop(context); // Close loading dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error: $e"),
      ),
    );
  }
}

Map<SubscriptionPlan, PlanMetadata> _convertToIAPPlans(
    Map<SubscriptionPlan, PlanMetadata> plans, ProPurchases proPurchases) {
  final iapProducts = proPurchases.products;
  inspect(iapProducts);
  final iapPlans = <SubscriptionPlan, PlanMetadata>{};
  for (final plan in plans.entries) {
    final planData = plan.value;
    iapPlans[plan.key] = PlanMetadata(
      name: planData.name,
      priceOptions: plan.key == SubscriptionPlan.free
          ? planData.priceOptions
          : planData.priceOptions.map((priceOption) {
              PurchasableProduct? product;
              if (Platform.isAndroid) {
                final matchingProducts = iapProducts
                    .where((product) => product.id == planData.productId)
                    .toList();
                product = matchingProducts[priceOption.subscriptionIndex];
              } else {
                product = iapProducts.firstWhere(
                    (product) => product.id == priceOption.appleProductId);
              }
              return PriceOption(
                price: product.price,
                period: priceOption.period,
                priceId: "",
                iapProduct: product,
                subscriptionIndex: priceOption.subscriptionIndex,
                appleProductId: priceOption.appleProductId,
              );
            }).toList(),
      get: planData.get,
      features: planData.features,
      unsupportedFeatures: planData.unsupportedFeatures,
      productId: planData.productId,
    );
  }
  return iapPlans;
}

class PlanMetadata {
  final String name;
  // stripe price options. Not applicable to IAP.
  final List<PriceOption> priceOptions;
  final String get;
  final List<String> features;
  final List<String> unsupportedFeatures;
  // android product id for IAP.
  final String productId;

  PlanMetadata({
    required this.name,
    required this.priceOptions,
    required this.get,
    required this.features,
    required this.unsupportedFeatures,
    required this.productId,
  });

  bool get hasDualPricing => priceOptions.length > 1;

  SubscriptionPlan get subscriptionPlan => switch (name) {
        'Air' => SubscriptionPlan.air,
        'Pro' => SubscriptionPlan.pro,
        'Free' => SubscriptionPlan.free,
        _ => throw Exception('Invalid plan name: $name'),
      };
}

enum Period {
  month,
  quarter,
  halfYear,
  year;

  String label(BuildContext context) => switch (this) {
        Period.month => AppLocalizations.of(context)!.perMonth,
        Period.quarter => AppLocalizations.of(context)!.perQuarter,
        Period.halfYear => AppLocalizations.of(context)!.perHalfYear,
        Period.year => AppLocalizations.of(context)!.perYear,
      };
}

class PriceOption {
  final String price;
  final Period period;
  final String priceId; // Stripe price ID for checkout session
  final int subscriptionIndex; // android subscription index for IAP.
  final String appleProductId;
  PurchasableProduct? iapProduct;

  PriceOption({
    required this.price,
    required this.period,
    required this.priceId,
    required this.subscriptionIndex,
    this.iapProduct,
    required this.appleProductId,
  });
}
