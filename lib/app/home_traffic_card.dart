part of 'home.dart';

class TrafficCardViewModel extends ChangeNotifier {
  TrafficCardViewModel({required this.authRepo}) {
    _fetchProfile();
  }
  final AuthRepo authRepo;
  UserProfile? get userProfile => _userProfile;
  UserProfile? _userProfile;
  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;
  DateTime? _lastManualRefreshAt;

  static const _manualRefreshCooldown = Duration(minutes: 1);

  bool get canManualRefresh =>
      _lastManualRefreshAt == null ||
      DateTime.now().difference(_lastManualRefreshAt!) >=
          _manualRefreshCooldown;

  Future<void> manualRefresh() async {
    if (!canManualRefresh || _isRefreshing) {
      return;
    }
    _isRefreshing = true;
    notifyListeners();
    try {
      await _fetchProfile();
      _lastManualRefreshAt = DateTime.now();
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> _fetchProfile() async {
    final userProfile = await authRepo.fetchProfile();
    _userProfile = userProfile;
    notifyListeners();
  }
}

class _TrafficCard extends StatelessWidget {
  const _TrafficCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ChangeNotifierProvider(
      create: (context) =>
          TrafficCardViewModel(authRepo: context.read<AuthRepo>()),
      child: Builder(
        builder: (context) {
          return GestureDetector(
            onTap: () {
              // context.go('/manage-plan');
            },
            child: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: colorScheme.brightness == Brightness.dark
                    ? colorScheme.surfaceOverlayLight
                    : colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.borderLight),
              ),
              child: Consumer<TrafficCardViewModel>(
                builder: (context, viewModel, child) {
                  if (viewModel.userProfile == null) {
                    return const SizedBox(height: 28, width: double.infinity);
                  }
                  final userProfile = viewModel.userProfile!;
                  final remainingData = bytesToReadable(
                    userProfile.remainingData,
                  );
                  final remainingParts = remainingData.split(' ');
                  return Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.data_usage_rounded,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.remainingData,
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.70),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  remainingParts[0],
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                if (remainingParts.length > 1)
                                  Text(
                                    ' ${remainingParts[1]}',
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withOpacity(
                                        0.70,
                                      ),
                                      fontSize: 14,
                                    ),
                                  ),
                                if (viewModel.canManualRefresh) ...[
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: viewModel.isRefreshing
                                        ? null
                                        : viewModel.manualRefresh,
                                    child: viewModel.isRefreshing
                                        ? SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.70),
                                            ),
                                          )
                                        : Icon(
                                            Icons.refresh_rounded,
                                            size: 18,
                                            color: colorScheme.onSurface
                                                .withOpacity(0.70),
                                          ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      // const SizedBox(width: 10),
                      // Container(
                      //   padding: const EdgeInsets.symmetric(
                      //     horizontal: 10,
                      //     vertical: 4,
                      //   ),
                      //   decoration: BoxDecoration(
                      //     gradient: LinearGradient(
                      //       begin: Alignment.topLeft,
                      //       end: Alignment.bottomRight,
                      //       colors: [
                      //         colorScheme.primary,
                      //         colorScheme.secondary,
                      //       ],
                      //     ),
                      //     borderRadius: BorderRadius.circular(10),
                      //   ),
                      //   child: Row(
                      //     mainAxisSize: MainAxisSize.min,
                      //     children: [
                      //       Icon(
                      //         Icons.rocket_launch_rounded,
                      //         size: 12,
                      //         color: colorScheme.onPrimary,
                      //       ),
                      //       const SizedBox(width: 4),
                      //       Text(
                      //         AppLocalizations.of(context)!.upgrade,
                      //         style: TextStyle(
                      //           color: colorScheme.onPrimary,
                      //           fontSize: 10,
                      //           fontWeight: FontWeight.w700,
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
