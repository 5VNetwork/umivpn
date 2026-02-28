part of 'manage_plan.dart';

class _CurrentPlan extends StatelessWidget {
  const _CurrentPlan({super.key});
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<ManagePlanViewModel>(
      builder: (context, value, child) {
        if (value.loadingSubscriptionInfo) {
          return Center(
              child: CircularProgressIndicator(color: colorScheme.primary));
        }
        if (value.errorFetchingSubscriptionInfo != null) {
          return Center(
              child:
                  Text(value.errorFetchingSubscriptionInfo ?? 'Unknown error'));
        }

        final subscriptionInfo = value.subscriptionInfo;
        final currentPlan = value.userProfile.subscriptionPlan;
        // Subscription renewal date (only for paid plans)
        final renewalDate = subscriptionInfo?.periodEndAt;
        final isPaidPlan = currentPlan != SubscriptionPlan.free;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withOpacity(0.2),
                colorScheme.primary.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.currentPlan,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isPaidPlan && subscriptionInfo?.isCanceled == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_rounded,
                            size: 14,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)!.cancelled,
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        currentPlan.name,
                        style: textTheme.headlineMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (subscriptionInfo?.planAndPeriod.$2 != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          subscriptionInfo!.planAndPeriod.$2.label(context),
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subscriptionInfo != null &&
                      !subscriptionInfo.isCanceled &&
                      subscriptionInfo.nextPlanAndPeriod != null &&
                      subscriptionInfo.nextPlanAndPeriod !=
                          subscriptionInfo.planAndPeriod) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: colorScheme.primary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            AppLocalizations.of(context)!.willRenewTo(
                              subscriptionInfo!.nextPlanAndPeriod!.$1.name,
                              subscriptionInfo!.nextPlanAndPeriod!.$2
                                  .label(context),
                            ),
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary.withOpacity(0.9),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceOverlay,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateRow(
                        context,
                        Icons.refresh_rounded,
                        AppLocalizations.of(context)!.dataRefresh,
                        value.refreshDate,
                      ),
                      if (currentPlan != SubscriptionPlan.free &&
                          renewalDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _buildDateRow(
                            context,
                            Icons.calendar_today_rounded,
                            subscriptionInfo?.isCanceled == true
                                ? AppLocalizations.of(context)!.endDate
                                : AppLocalizations.of(context)!.renewalDate,
                            renewalDate,
                          ),
                        ),
                      if (isPaidPlan && subscriptionInfo?.source != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _buildSourceRow(
                            context,
                            subscriptionInfo!.source,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (isPaidPlan && subscriptionInfo != null) ...[
                const SizedBox(height: 20),
                if (subscriptionInfo.source != SubscriptionSource.appStore)
                  Container(
                    padding: const EdgeInsets.only(bottom: 12),
                    width: double.infinity,
                    child: subscriptionInfo.isCanceled == true
                        //TODO: Handle reactivation for play store
                        ? subscriptionInfo.source ==
                                SubscriptionSource.playStore
                            ? null
                            : ElevatedButton(
                                onPressed: () =>
                                    value.reactivateSubscription(context),
                                child: value.isReactivating
                                    ? smallCircularProgressIndicator(
                                        color: colorScheme.onPrimary)
                                    : Text(AppLocalizations.of(context)!
                                        .dontCancelSubscription),
                              )
                        : OutlinedButton(
                            onPressed: () => value.cancel(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.error,
                              side: BorderSide(
                                  color: colorScheme.error.withOpacity(0.5)),
                            ),
                            child: value.isReactivating
                                ? smallCircularProgressIndicator(
                                    color: colorScheme.primary)
                                : Text(AppLocalizations.of(context)!
                                    .cancelSubscription),
                          ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => value._onManageSubscription(context),
                    child: value.isManaging
                        ? smallCircularProgressIndicator(
                            color: colorScheme.onPrimary)
                        : Text(
                            AppLocalizations.of(context)!.manageSubscription),
                  ),
                ),
                // Padding(
                //   padding: const EdgeInsets.only(top: 2.0, left: 2),
                //   child: Text(
                //     AppLocalizations.of(context)!.managePlanDesc,
                //     style: textTheme.bodySmall?.copyWith(
                //       color: colorScheme.onSurface.withOpacity(0.7),
                //       fontWeight: FontWeight.normal,
                //     ),
                //   ),
                // ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateRow(
    BuildContext context,
    IconData icon,
    String label,
    DateTime date,
  ) {
    // Convert to local time for display
    final localDate = date.toLocal();
    final now = DateTime.now();
    final difference = localDate.difference(now);
    final daysRemaining = difference.inDays;

    String dateText;
    if (daysRemaining < 0) {
      dateText = AppLocalizations.of(context)!.expired;
    } else {
      dateText =
          "${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')} ${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}";
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: colorScheme.onSurface.withOpacity(0.87),
        ),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.87),
            fontSize: 13,
          ),
        ),
        Text(
          dateText,
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSourceRow(
    BuildContext context,
    SubscriptionSource source,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final sourceName = source.name;

    return Row(
      children: [
        Icon(
          Icons.payment_rounded,
          size: 16,
          color: colorScheme.onSurface.withOpacity(0.87),
        ),
        const SizedBox(width: 8),
        Text(
          "${AppLocalizations.of(context)!.source}: ",
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.87),
            fontSize: 13,
          ),
        ),
        Text(
          sourceName,
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
