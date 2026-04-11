part of 'manage_plan.dart';

class ManagePlanViewModel extends ChangeNotifier {
  final AuthRepo authRepo;
  final ProPurchases? proPurchases;
  final String locale;
  ManagePlanViewModel({
    required this.authRepo,
    this.proPurchases,
    this.locale = 'zh',
  }) {
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
        proPurchases?.buying == false &&
        proPurchases?.verifyErrorMessage == null) {
      _fetchSubscriptionInfo();
    }
  }

  User get userProfile => authRepo.user!;
  DateTime get refreshDate {
    if (userProfile.plan == SubscriptionPlan.free) {
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
      await authRepo.refreshUser();
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
        'https://umivpn.r2.5vnetwork.com/plans/${locale}.json',
      );
      inspect(fetchedPlans);
      plans = proPurchases != null
          ? _convertToIAPPlans(fetchedPlans, proPurchases!)
          : fetchedPlans;
      loadingPlans = false;
    } catch (e, stackTrace) {
      errorFetchingPlans = e.toString();
      logger.e('Failed to load plans', error: e, stackTrace: stackTrace);
    } finally {
      loadingPlans = false;
      notifyListeners();
    }
  }

  Future<void> buy(
    BuildContext context,
    PriceOption priceOption,
    SubscriptionPlan plan,
  ) async {
    if (proPurchases != null) {
      if (applePlatform || subscriptionInfo == null) {
        await proPurchases!.buy(
          PurchaseParam(productDetails: priceOption.iapProduct!.productDetails),
        );
      } else {
        // android and there is a subscription already
        // Get the old purchase details for subscription change
        final oldPurchaseDetails = await _getOldPurchaseDetails();
        if (oldPurchaseDetails == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.purchaseFailed(
                  'Unable to find current subscription purchase details',
                ),
              ),
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
            replacementMode: replacementMode,
          ),
        );
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
        'Failed to cancel subscription: ${response.data['error']}',
      );
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
        'https://apps.apple.com/account/subscriptions?app-id=6751115042',
      );
      await launchUrl(uri);
    } else {
      final colorScheme = Theme.of(context).colorScheme;
      final textTheme = Theme.of(context).textTheme;

      areYouSureDialog(
        ctx: context,
        title: Text(
          AppLocalizations.of(context)!.areYouSureReactivate,
          style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
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
                  AppLocalizations.of(context)!.subscriptionReactivated,
                ),
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.failedToReactivateSubscription,
                ),
              ),
            );
          } finally {
            isReactivating = false;
            notifyListeners();
          }
        },
        onNo: () => Navigator.pop(context),
      );
    }
  }

  void cancel(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    areYouSureDialog(
      ctx: context,
      title: Text(
        AppLocalizations.of(context)!.areYouSureCancel,
        style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.subscriptionCancelDialogBody,
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.87)),
          ),
          if (subscriptionInfo?.source == SubscriptionSource.stripe) ...[
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(
                context,
              )!.subscriptionCancelDialogStripeReactivationInfo,
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.87)),
            ),
          ],
        ],
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
                content: Text(
                  AppLocalizations.of(context)!.subscriptionCancelled,
                ),
              ),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.failedToCancelSubscription,
              ),
            ),
          );
        } finally {
          isReactivating = false;
          notifyListeners();
        }
      },
    );
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
            SnackBar(content: Text(AppLocalizations.of(context)!.noTokenFound)),
          );
          return;
        }
        final response = await supabase.functions.invoke(
          'create-stripe-portal-session',
          headers: {'Authorization': 'Bearer $token'},
        );
        if (context.mounted) {
          if (response.status == 200 && response.data != null) {
            final url = response.data['url'] as String;
            final uri = Uri.parse(url);
            await launchUrl(uri);
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
              content: Text(
                AppLocalizations.of(
                  context,
                )!.failedToOpenCustomerPortal(e.toString()),
              ),
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
        'https://play.google.com/store/account/subscriptions?sku=umivpn_${subscriptionInfo!.planAndPeriod.$1.name.toLowerCase()}&package=${androidPackageNme}',
      );
      await launchUrl(uri);
    } else if (subscriptionInfo!.source == SubscriptionSource.appStore) {
      // Open App Store subscription management URL for this specific app
      // Using the app's Apple ID to go directly to this app's subscription page
      final uri = Uri.parse(
        'https://apps.apple.com/account/subscriptions?app-id=6751115042',
      );
      await launchUrl(uri);
    }
  }
}
