part of 'manage_plan.dart';

class AllPlans extends StatelessWidget {
  const AllPlans({super.key});

  @override
  Widget build(BuildContext context) {
    if (true) {
      return Consumer<ProPurchases>(builder: (context, proPurchases, child) {
        if (proPurchases.purchaseDetails != null) {
          if (proPurchases.purchaseDetails!.status == PurchaseStatus.pending ||
              proPurchases.buying) {
            return const Center(
              child: SizedBox(
                  width: 24, height: 24, child: CircularProgressIndicator()),
            );
          } else if (proPurchases.purchaseDetails!.status ==
              PurchaseStatus.error) {
            return Center(
                child: Text(
              AppLocalizations.of(context)!.purchaseFailed(
                  proPurchases.purchaseDetails!.error?.message ?? ''),
              maxLines: 10,
            ));
          } else if (proPurchases.verifyErrorMessage != null) {
            if (proPurchases.verifyErrorMessage == 'Invalid Purchase') {
              return Center(
                  child: Column(
                children: [
                  Text(AppLocalizations.of(context)!.invalidPurchase),
                  Gap(10),
                  _ifYouHavePaid(context, proPurchases.purchaseDetails!),
                ],
              ));
            }
            return Column(
              children: [
                Icon(Icons.error,
                    color: Theme.of(context).colorScheme.error, size: 24),
                const Gap(5),
                Text(
                  AppLocalizations.of(context)!.purchaseVerificationFailed(
                      proPurchases.verifyErrorMessage!),
                  maxLines: 10,
                ),
                Gap(5),
                TextButton(
                    onPressed: proPurchases.reverify,
                    child: Text(AppLocalizations.of(context)!.retry)),
                Gap(10),
                _ifYouHavePaid(context, proPurchases.purchaseDetails!),
              ],
            );
          }
          return const AllPlansList();
        } else {
          if (proPurchases.storeState == StoreState.notAvailable) {
            return Center(
                child: Row(
              children: [
                const Icon(Icons.error),
                const Gap(10),
                Text(AppLocalizations.of(context)!.unableToConnectToStore),
              ],
            ));
          } else if (proPurchases.storeState == StoreState.loading ||
              proPurchases.buying) {
            return Center(
                child: SizedBox(
                    width: 24, height: 24, child: CircularProgressIndicator()));
          }
          return const AllPlansList();
        }
      });
    }
    return const AllPlansList();
  }

  Widget _ifYouHavePaid(BuildContext context, PurchaseDetails purchaseDetails) {
    return RichText(
      maxLines: 10,
      text: TextSpan(
        style: Theme.of(context).textTheme.bodySmall,
        children: [
          TextSpan(
            text: AppLocalizations.of(context)!
                .ifYouHavePaid(purchaseDetails.purchaseID ?? ''),
          ),
          WidgetSpan(
            child: IconButton(
              iconSize: 16,
              style: IconButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding: EdgeInsets.symmetric(horizontal: 5),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: Size(16, 16),
              ),
              onPressed: () {
                Pasteboard.writeText(purchaseDetails.purchaseID ?? '');
                rootScaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(
                    content:
                        Text(AppLocalizations.of(context)!.copiedToClipboard),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy),
            ),
          ),
        ],
      ),
    );
  }
}

class AllPlansList extends StatelessWidget {
  const AllPlansList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagePlanViewModel>(
      builder: (context, value, child) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        final userProfile = context.watch<AuthRepo>().userProfile!;

        if (value.loadingPlans || value.loadingSubscriptionInfo) {
          return Center(
            child: CircularProgressIndicator(
              color: colorScheme.primary,
            ),
          );
        }

        if (value.errorFetchingPlans != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Failed to load plans",
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Please visit our website to view available plans.",
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final url = Uri.parse('https://umivpn.5vnetwork.com');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: Text(
                        AppLocalizations.of(context)!.visitOfficialWebsite),
                  ),
                ],
              ),
            ),
          );
        }

        final plansMap = value.plans;
        if (plansMap?.isEmpty ?? true) {
          return Center(
            child: Text(
              AppLocalizations.of(context)!.noPlansAvailable,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          );
        }
        return Column(
          children: [
            // Plans List
            ...SubscriptionPlan.values.reversed
                .where((plan) => plansMap!.containsKey(plan))
                .map((plan) {
              final planData = plansMap![plan]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildPlanCard(
                  context,
                  plan,
                  planData,
                  userProfile.subscriptionPlan,
                  userProfile,
                  value.subscriptionInfo,
                ),
              );
            }),
          ],
        );
      },
    );
  }

  String _getButtonText(
    BuildContext context,
    SubscriptionPlan plan,
    SubscriptionPlan currentPlan,
    PlanMetadata planData,
  ) {
    final localizations = AppLocalizations.of(context)!;

    // If user is on free, show the default "Get" text
    if (currentPlan == SubscriptionPlan.free) {
      return planData.get;
    }

    // Define plan hierarchy: free < air < pro
    final planOrder = {
      SubscriptionPlan.free: 0,
      SubscriptionPlan.air: 1,
      SubscriptionPlan.pro: 2,
    };

    final planLevel = planOrder[plan] ?? 0;
    final currentPlanLevel = planOrder[currentPlan] ?? 0;

    if (planLevel > currentPlanLevel) {
      return localizations.upgrade;
    } else if (planLevel == currentPlanLevel) {
      return localizations.changePeriod;
    } else {
      return localizations.downgrade;
    }
  }

  Widget _buildPlanCard(
    BuildContext context,
    SubscriptionPlan plan,
    PlanMetadata planData,
    SubscriptionPlan currentPlan,
    UserProfile userProfile,
    SubscriptionInfo? subscriptionInfo,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final consistentSub = subscriptionInfo?.source == _source();
    final userHasNoSub = userProfile.subscriptionPlan == SubscriptionPlan.free;
    final isNotAppleStoreSub = _source() != SubscriptionSource.appStore;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceOverlay,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.surfaceOverlayLighter,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    planData.name,
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (plan == currentPlan)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.current,
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              if (userHasNoSub || consistentSub) _getPriceWidget(context, planData),
            ],
          ),
          const SizedBox(height: 15),
          ...planData.features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: colorScheme.primary.withOpacity(0.8),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.87),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          if (planData.unsupportedFeatures.isNotEmpty) ...[
            ...planData.unsupportedFeatures.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cancel_rounded,
                        size: 16,
                        color: colorScheme.onSurface.withOpacity(0.38),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.38),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          if (plan != SubscriptionPlan.free &&
              (userHasNoSub || (isNotAppleStoreSub && consistentSub))) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleSubscribe(
                    context, plan, planData, userProfile, subscriptionInfo),
                child:
                    Text(_getButtonText(context, plan, currentPlan, planData)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleSubscribe(
    BuildContext context,
    SubscriptionPlan plan,
    PlanMetadata planData,
    UserProfile userProfile,
    SubscriptionInfo? subscriptionInfo,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    late SubscriptionSource source;
    if (useStripe) {
      source = SubscriptionSource.stripe;
    } else if (Platform.isAndroid) {
      source = SubscriptionSource.playStore;
    } else {
      source = SubscriptionSource.appStore;
    }

    // Check if user has a non-canceled subscription
    // TODO: handle subsciption change
    final hasSubscriptionFromOtherSouce =
        userProfile.subscriptionPlan != SubscriptionPlan.free &&
            subscriptionInfo?.source != source;
    if (hasSubscriptionFromOtherSouce) {
      if (subscriptionInfo?.isCanceled == true) {
        // let a user know the existing subscription will be lost if they subscribe to this plan
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              AppLocalizations.of(context)!.warningExistingSubscription,
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            content: Text(
              AppLocalizations.of(context)!.warningExistingSubscriptionMessage,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.87),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "OK",
                  style: TextStyle(color: colorScheme.primary),
                ),
              ),
            ],
          ),
        );
      } else {
        // Show dialog that user must cancel existing subscription from other source first
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              AppLocalizations.of(context)!.activeSubscriptionFound,
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            content: Text(
              AppLocalizations.of(context)!.activeSubscriptionFoundMessage,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.87),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "OK",
                  style: TextStyle(color: colorScheme.primary),
                ),
              ),
            ],
          ),
        );
      }
      return;
    }

    // No active or canceled subscription, proceed directly
    await _proceedWithCheckout(context, planData);
  }

  Future<void> _proceedWithCheckout(
    BuildContext context,
    PlanMetadata planData,
  ) async {
    final subscriptionInfo =
        context.read<ManagePlanViewModel>().subscriptionInfo;
    PriceOption? selectedPriceOption;
    // If there's only one price option, use it directly
    if (planData.priceOptions.length == 1) {
      selectedPriceOption = planData.priceOptions[0];
    } else {
      // If there are multiple price options, show selection dialog
      selectedPriceOption = await _showPriceSelectionDialog(
        context,
        planData,
        subscriptionInfo,
      );
      if (selectedPriceOption == null) {
        // User cancelled the dialog
        return;
      }
    }
    if (context.mounted) {
      await context
          .read<ManagePlanViewModel>()
          .buy(context, selectedPriceOption, planData.subscriptionPlan);
    }
  }

  Future<PriceOption?> _showPriceSelectionDialog(
    BuildContext context,
    PlanMetadata planData,
    SubscriptionInfo? subscriptionInfo,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Determine if any price option is the current plan
    final currentPeriod = subscriptionInfo?.planAndPeriod.$2;

    return showDialog<PriceOption>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.selectBillingPeriod,
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: planData.priceOptions.map((priceOption) {
              final isCurrentPlan = subscriptionInfo?.planAndPeriod.$1 ==
                      planData.subscriptionPlan &&
                  currentPeriod == priceOption.period;
              bool canSelectCurrent = !isCurrentPlan;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: canSelectCurrent
                      ? () => Navigator.pop(context, priceOption)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceOverlay,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.borderLight,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    priceOption.price,
                                    style: textTheme.titleMedium?.copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (isCurrentPlan) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Current',
                                        style: TextStyle(
                                          color: colorScheme.onPrimary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                priceOption.period.label(context),
                                style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _getPriceWidget(BuildContext context, PlanMetadata planData) {
  final colorScheme = Theme.of(context).colorScheme;

  return planData.hasDualPricing
      ? _buildDualPricing(context, planData)
      : Text(
          "${planData.priceOptions[0].price} ${planData.priceOptions[0].period.label(context)}",
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.87),
            fontSize: 14,
          ),
        );
}

Widget _buildDualPricing(BuildContext context, PlanMetadata planData) {
  final colorScheme = Theme.of(context).colorScheme;

  return Wrap(
    children: [
      Text(
        "${planData.priceOptions[0].price} ${planData.priceOptions[0].period.label(context)}",
        style: TextStyle(
          color: colorScheme.onSurface.withOpacity(0.87),
          fontSize: 14,
        ),
      ),
      Text(
        "  or  ",
        style: TextStyle(
          color: colorScheme.onSurface.withOpacity(0.70),
          fontSize: 12,
        ),
      ),
      Text(
        "${planData.priceOptions[1].price} ${planData.priceOptions[1].period.label(context)}",
        style: TextStyle(
          color: colorScheme.primary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class PlanService {
  static Map<SubscriptionPlan, PlanMetadata>? _cachedPlans;

  /// Fetches plans from Cloudflare R2 URL
  static Future<Map<SubscriptionPlan, PlanMetadata>> fetchPlans(
      String url) async {
    // Return cached plans if available
    if (_cachedPlans != null) {
      return _cachedPlans!;
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final plans = _parsePlansFromJson(data);

      // Cache the plans
      _cachedPlans = plans;
      return plans;
    } else {
      throw Exception('Failed to fetch plans: ${response.statusCode}');
    }
  }

  /// Parses JSON data into PlanMetadata map
  static Map<SubscriptionPlan, PlanMetadata> _parsePlansFromJson(
      Map<String, dynamic> data) {
    final plans = <SubscriptionPlan, PlanMetadata>{};

    for (final entry in data.entries) {
      final planName = entry.key.toLowerCase();
      final planData = entry.value as Map<String, dynamic>;

      SubscriptionPlan? plan;
      switch (planName) {
        case 'free':
          plan = SubscriptionPlan.free;
          break;
        case 'air':
          plan = SubscriptionPlan.air;
          break;
        case 'pro':
          plan = SubscriptionPlan.pro;
          break;
      }

      if (plan == null) continue;

      final priceOptions =
          (planData['priceOptions'] as List<dynamic>).map((po) {
        final periodStr = po['period'] as String;
        Period period;
        switch (periodStr) {
          case 'month':
            period = Period.month;
            break;
          case 'quarter':
            period = Period.quarter;
            break;
          case 'halfYear':
            period = Period.halfYear;
            break;
          case 'year':
            period = Period.year;
            break;
          default:
            period = Period.month;
        }

        return PriceOption(
          price: po['price'] as String,
          period: period,
          priceId: po['priceId'] as String,
          subscriptionIndex: po['subscriptionIndex'] as int,
          appleProductId: po['appleProductId'] as String,
        );
      }).toList();

      plans[plan] = PlanMetadata(
        name: planData['name'] as String,
        priceOptions: priceOptions,
        get: planData['get'] as String,
        features: (planData['features'] as List<dynamic>)
            .map((f) => f as String)
            .toList(),
        unsupportedFeatures: (planData['unsupportedFeatures'] as List<dynamic>?)
                ?.map((f) => f as String)
                .toList() ??
            [],
        productId: planData['productId'] as String? ?? '',
      );
    }

    return plans;
  }

  /// Clears the cached plans (useful for refreshing)
  static void clearCache() {
    _cachedPlans = null;
  }
}
