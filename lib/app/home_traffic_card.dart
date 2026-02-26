part of 'home.dart';

class _TrafficCard extends StatelessWidget {
  const _TrafficCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        // context.go('/manage-plan');
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceOverlay,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.borderLight),
        ),
        child: Consumer<AuthRepo>(builder: (context, authRepo, child) {
          if (authRepo.userProfile == null) {
            return const SizedBox.shrink();
          }

          final userProfile = authRepo.userProfile!;
          final remainingData = bytesToReadable(userProfile.remainingData);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (userProfile.subscriptionPlan != SubscriptionPlan.free)
                    Row(
                      children: [
                        Icon(Icons.data_usage,
                            size: 20,
                            color: colorScheme.onSurface.withOpacity(0.87)),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.monthlyTraffic,
                            style: TextStyle(
                                color:
                                    colorScheme.onSurface.withOpacity(0.87))),
                      ],
                    ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.shadowLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(userProfile.subscriptionPlan.name,
                        style: TextStyle(
                            color: Colors.amber,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                  if (userProfile.subscriptionPlan == SubscriptionPlan.free && false)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primary,
                            colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.rocket_launch_rounded,
                            size: 16,
                            color: colorScheme.onPrimary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Upgrade',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: colorScheme.onPrimary,
                          ),
                        ],
                      ),
                    )
                ],
              ),
              const SizedBox(height: 10),
              if (userProfile.subscriptionPlan == SubscriptionPlan.pro)
                Text(AppLocalizations.of(context)!.unlimitedData,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface))
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("${remainingData.split(' ')[0]}",
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface)),
                    Text(' ${remainingData.split(' ')[1]}',
                        style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface.withOpacity(0.70),
                            height: 1.8)),
                    const Spacer(),
                    Text(
                        "Refresh: ${userProfile.refreshDate.difference(DateTime.now()).inDays} days",
                        style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.70))),
                  ],
                ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: userProfile.subscriptionPlan == SubscriptionPlan.pro
                      ? 1
                      : (userProfile.remainingData /
                          userProfile.subscriptionPlan.data),
                  backgroundColor: colorScheme.borderLight,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  minHeight: 6,
                ),
              )
            ],
          );
        }),
      ),
    );
  }
}
