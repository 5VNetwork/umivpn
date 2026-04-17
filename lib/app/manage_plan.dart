import 'dart:developer';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_common/common.dart';
import 'package:flutter_common/widgets/app_bar.dart';
import 'package:gap/gap.dart';
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
import 'package:tm/iap/pro.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_common/widgets/dialog.dart';
import 'package:flutter_common/widgets/progress.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

part 'manage_plan_current.dart';
part 'manage_plan_all.dart';
part 'manage_plan_view_model.dart';

class ManagePlanPage extends StatelessWidget {
  const ManagePlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.bgColor,
      appBar: adaptiveClosableAppBar(
        context,
        title: AppLocalizations.of(context)!.managePlan,
      ),
      body: const Padding(padding: EdgeInsets.all(24), child: ManagePlanBody()),
    );
  }
}

class ManagePlanBody extends StatelessWidget {
  const ManagePlanBody({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
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
        if (!Platform.isIOS) const AllPlans(),
      ],
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
    builder: (context) =>
        Center(child: CircularProgressIndicator(color: colorScheme.primary)),
  );

  try {
    final token = supabase.auth.currentSession?.accessToken;
    if (token == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.noAuthenticationTokenFound,
          ),
        ),
      );
      return;
    }

    // Call the edge function to create checkout session
    final response = await supabase.functions.invoke(
      'create-stripe-checkout-session',
      headers: {
        'Authorization': 'Bearer $token',
        "User-Agent": "UmiVPN/${version}",
      },
      body: {'price_id': priceOption.priceId},
    );

    Navigator.pop(context); // Close loading dialog

    if (response.status == 200 && response.data != null) {
      final url = response.data['url'] as String?;
      if (url != null && url.isNotEmpty) {
        final uri = Uri.parse(url);
        await launchUrl(uri);
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
          content: Text(
            AppLocalizations.of(
              context,
            )!.failedToCreateCheckoutSession(errorMessage),
          ),
        ),
      );
    }
  } catch (e) {
    Navigator.pop(context); // Close loading dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(
            context,
          )!.failedToCreateCheckoutSession(e.toString()),
        ),
      ),
    );
  }
}

Map<SubscriptionPlan, PlanMetadata> _convertToIAPPlans(
  Map<SubscriptionPlan, PlanMetadata> plans,
  ProPurchases proPurchases,
) {
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
                  (product) => product.id == priceOption.appleProductId,
                );
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
