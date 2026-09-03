part of 'home.dart';

class Selector extends StatelessWidget {
  const Selector({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        final byServerEnabled =
            context.read<AuthRepo>().user?.plan != SubscriptionPlan.free;
        final initialTab =
            byServerEnabled && context.read<ChoiceCubit>().state.serverId != 0
            ? 1
            : 0;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.9,
            ),
            child: _LocationSheet(
              initialTabIndex: initialTab,
              byServerEnabled: byServerEnabled,
            ),
          ),
        );
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
        child: BlocBuilder<ChoiceCubit, Choice>(
          buildWhen: (previous, current) =>
              previous.country != current.country ||
              previous.serverId != current.serverId,
          builder: (ctx, state) {
            final country = _displayCountry(ctx, state);
            return Row(
              children: [
                getCountryIcon(country, height: 28, width: 28),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.currentLocation,
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.70),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getSelectionLabel(context, state),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: colorScheme.onSurface.withOpacity(0.70),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _displayCountry(BuildContext context, Choice state) {
    if (state.serverId != 0) {
      final result = context.read<FetchResultProvider>().fetchResult;
      if (result != null) {
        for (final s in result.uniqueServers()) {
          if (s.serverId == state.serverId) {
            return s.country;
          }
        }
      }
      return '';
    }
    return state.country;
  }

  String _getSelectionLabel(BuildContext context, Choice state) {
    final l10n = AppLocalizations.of(context)!;
    if (state.serverId != 0) {
      final country = _displayCountry(context, state);
      final countryName = country.isEmpty
          ? ''
          : getLocalizedCountryName(context, country);
      if (countryName.isEmpty) {
        return '${l10n.server} ${state.serverId}';
      }
      return '$countryName · ${state.serverId}';
    }
    if (state.country.isEmpty) {
      return l10n.auto;
    }
    return getLocalizedCountryName(context, state.country);
  }
}

class _LocationSheet extends StatefulWidget {
  const _LocationSheet({
    required this.initialTabIndex,
    required this.byServerEnabled,
  });

  final int initialTabIndex;
  final bool byServerEnabled;

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet>
    with SingleTickerProviderStateMixin {
  static const _sortBySpeedKey = 'locationSortBySpeed';

  late final TabController _tabController;
  List<String> _recentlyUsedCountries = [];
  SharedPreferences? _pref;
  bool _fetchOnce = false;
  bool _testingAllUsable = false;
  bool _testingAllSpeed = false;
  bool _sortBySpeed = false;
  final Set<String> _testingCountries = {};
  final Set<int> _testingServers = {};

  /// Speeds used for sort while a test is in progress (avoids list jumping).
  final Map<String, int> _sortSpeedByCountry = {};
  final Map<int, int> _sortSpeedByServer = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.byServerEnabled ? 2 : 1,
      vsync: this,
      initialIndex: widget.byServerEnabled
          ? widget.initialTabIndex.clamp(0, 1)
          : 0,
    );
    _loadPrefs(context.read<SharedPreferences>());
    HandlerResultsStore.instance.reload();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadPrefs(SharedPreferences pref) {
    _pref = pref;
    _recentlyUsedCountries = pref.getStringList('recentlyUsedCountries') ?? [];
    _sortBySpeed = pref.getBool(_sortBySpeedKey) ?? false;
  }

  Future<void> _setSortBySpeed(bool value) async {
    setState(() => _sortBySpeed = value);
    await _pref?.setBool(_sortBySpeedKey, value);
  }

  Future<void> _saveRecentlyUsedCountries() async {
    if (_pref != null) {
      await _pref!.setStringList(
        'recentlyUsedCountries',
        _recentlyUsedCountries,
      );
    }
  }

  void _rememberCountry(String country) {
    if (country.isEmpty) return;
    if (!_recentlyUsedCountries.contains(country)) {
      _recentlyUsedCountries.insert(0, country);
    } else {
      _recentlyUsedCountries.remove(country);
      _recentlyUsedCountries.insert(0, country);
    }
    if (_recentlyUsedCountries.length > 10) {
      _recentlyUsedCountries = _recentlyUsedCountries.take(10).toList();
    }
    _saveRecentlyUsedCountries();
  }

  Future<String?> _readFetchResultJson() async {
    return context.read<FetchResultProvider>().readFetchResultJson();
  }

  void _pinCountrySortSpeed(String country) {
    _sortSpeedByCountry.putIfAbsent(
      country,
      () => HandlerResultsStore.instance.forCountry(country).speed,
    );
  }

  void _pinServerSortSpeed(int serverId) {
    _sortSpeedByServer.putIfAbsent(
      serverId,
      () => HandlerResultsStore.instance.forServer(serverId).speed,
    );
  }

  void _pinAllSortSpeeds() {
    final result = context.read<FetchResultProvider>().fetchResult;
    if (result == null) return;
    for (final c in {
      ...result.mains.map((e) => e.country),
      ...result.fallbacks.map((e) => e.country),
    }) {
      if (c.isNotEmpty) _pinCountrySortSpeed(c);
    }
    for (final s in result.uniqueServers()) {
      _pinServerSortSpeed(s.serverId);
    }
  }

  void _releaseUnusedSortPins() {
    _sortSpeedByCountry.removeWhere(
      (c, _) =>
          !_testingCountries.contains(c) &&
          !_testingAllUsable &&
          !_testingAllSpeed,
    );
    _sortSpeedByServer.removeWhere(
      (id, _) =>
          !_testingServers.contains(id) &&
          !_testingAllUsable &&
          !_testingAllSpeed,
    );
  }

  int _sortSpeedForCountry(String country) =>
      _sortSpeedByCountry[country] ??
      HandlerResultsStore.instance.forCountry(country).speed;

  int _sortSpeedForServer(int serverId) =>
      _sortSpeedByServer[serverId] ??
      HandlerResultsStore.instance.forServer(serverId).speed;

  Future<void> _runUsableTest() async {
    if (_testingAllUsable) return;
    final fetchResultJson = await _readFetchResultJson();
    if (fetchResultJson == null || fetchResultJson.isEmpty) return;
    setState(() {
      _testingAllUsable = true;
      _pinAllSortSpeeds();
    });
    try {
      final runner = HandlerTestRunner(api: context.read<XApiClient>());
      await runner.testUsableAll(fetchResultJson);
    } on StateError catch (e) {
      logger.w('usable test skipped', error: e);
      if (mounted) snack(e.message);
    } catch (e) {
      logger.e('usable test failed', error: e);
      if (mounted) snack(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _testingAllUsable = false;
          _releaseUnusedSortPins();
        });
      }
    }
  }

  Future<void> _runSpeedTest() async {
    if (_testingAllSpeed) return;
    final fetchResultJson = await _readFetchResultJson();
    if (fetchResultJson == null || fetchResultJson.isEmpty) return;
    setState(() {
      _testingAllSpeed = true;
      _pinAllSortSpeeds();
    });
    try {
      final runner = HandlerTestRunner(api: context.read<XApiClient>());
      await runner.testSpeedAll(fetchResultJson);
    } on StateError catch (e) {
      logger.w('speed test skipped', error: e);
      if (mounted) snack(e.message);
    } catch (e) {
      logger.e('speed test failed', error: e);
      if (mounted) snack(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _testingAllSpeed = false;
          _releaseUnusedSortPins();
        });
      }
    }
  }

  Future<void> _runCountryTest(String country) async {
    if (country.isEmpty || _testingCountries.contains(country)) return;
    final fetchResultJson = await _readFetchResultJson();
    if (fetchResultJson == null || fetchResultJson.isEmpty) return;
    setState(() {
      _pinCountrySortSpeed(country);
      _testingCountries.add(country);
    });
    try {
      final runner = HandlerTestRunner(api: context.read<XApiClient>());
      await runner.testUsableAll(fetchResultJson, country: country);
      if (!mounted) return;
      await runner.testSpeedAll(fetchResultJson, country: country);
    } on StateError catch (e) {
      logger.w('country test skipped', error: e);
      if (mounted) snack(e.message);
    } catch (e) {
      logger.e('country test failed', error: e);
      if (mounted) snack(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _testingCountries.remove(country);
          _releaseUnusedSortPins();
        });
      }
    }
  }

  Future<void> _runServerTest(int serverId) async {
    if (serverId == 0 || _testingServers.contains(serverId)) return;
    final fetchResultJson = await _readFetchResultJson();
    if (fetchResultJson == null || fetchResultJson.isEmpty) return;
    setState(() {
      _pinServerSortSpeed(serverId);
      _testingServers.add(serverId);
    });
    try {
      final runner = HandlerTestRunner(api: context.read<XApiClient>());
      await runner.testUsableAll(fetchResultJson, serverId: serverId);
      if (!mounted) return;
      await runner.testSpeedAll(fetchResultJson, serverId: serverId);
    } on StateError catch (e) {
      logger.w('server test skipped', error: e);
      if (mounted) snack(e.message);
    } catch (e) {
      logger.e('server test failed', error: e);
      if (mounted) snack(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _testingServers.remove(serverId);
          _releaseUnusedSortPins();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final choice = context.read<ChoiceCubit>().state;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.selectLocation,
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.statusTest,
                onPressed: _testingAllUsable ? null : _runUsableTest,
                icon: _testingAllUsable
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      )
                    : const Icon(Icons.network_check_rounded),
              ),
              const SizedBox(width: 2),
              IconButton(
                tooltip: l10n.speedTest,
                onPressed: _testingAllSpeed ? null : _runSpeedTest,
                icon: _testingAllSpeed
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      )
                    : const Icon(Icons.speed_rounded),
              ),
              const SizedBox(width: 2),
              IconButton(
                tooltip: l10n.sort,
                onPressed: () => _setSortBySpeed(!_sortBySpeed),
                icon: Icon(
                  Icons.sort_rounded,
                  color: _sortBySpeed ? colorScheme.primary : null,
                ),
              ),
              const VerticalDivider(width: 1),
              StatefulBuilder(
                builder: (ctx, setState) {
                  if (_fetchOnce) {
                    return const SizedBox.shrink();
                  }
                  return IconButton(
                    onPressed: () {
                      setState(() {
                        _fetchOnce = true;
                      });
                      context.read<FetchResultProvider>().fetch(
                        reason: 'refresh',
                      );
                    },
                    icon: const Icon(Icons.refresh_rounded),
                  );
                },
              ),
            ],
          ),
          if (widget.byServerEnabled) ...[
            const SizedBox(height: 8),
            TabBar(
              controller: _tabController,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurface.withOpacity(0.60),
              indicatorColor: colorScheme.primary,
              tabs: [
                Tab(text: l10n.byArea),
                Tab(text: l10n.byServer),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Flexible(
            child: ListenableBuilder(
              listenable: HandlerResultsStore.instance,
              builder: (context, _) {
                return Consumer<FetchResultProvider>(
                  builder: (ctx, p, child) {
                    if (p.fetching) {
                      return const SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    } else if (p.fetchResult != null) {
                      final countryTab = _CountryTab(
                        fetchResult: p.fetchResult!,
                        currentCountry: choice.country,
                        selectingByServer:
                            widget.byServerEnabled && choice.serverId != 0,
                        recentlyUsedCountries: _recentlyUsedCountries,
                        onRememberCountry: _rememberCountry,
                        sortBySpeed: _sortBySpeed,
                        testingCountries: _testingCountries,
                        sortSpeedFor: _sortSpeedForCountry,
                        onTest: _runCountryTest,
                      );
                      if (!widget.byServerEnabled) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: countryTab,
                        );
                      }
                      return TabBarView(
                        controller: _tabController,
                        children: [
                          countryTab,
                          _ServerTab(
                            fetchResult: p.fetchResult!,
                            currentServerId: choice.serverId,
                            sortBySpeed: _sortBySpeed,
                            testingServers: _testingServers,
                            sortSpeedFor: _sortSpeedForServer,
                            onTest: _runServerTest,
                          ),
                        ],
                      );
                    } else if (p.fetchError != null) {
                      return Center(
                        child: Column(
                          children: [
                            Text(
                              p.fetchError!,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.error.withOpacity(0.70),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () async {
                                p.makeSureFetchResult();
                              },
                              child: Text(l10n.retry),
                            ),
                          ],
                        ),
                      );
                    } else {
                      logger.e('This should not happen');
                      return Center(
                        child: Column(
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                p.makeSureFetchResult();
                              },
                              child: const Text('Fetch'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryTab extends StatelessWidget {
  const _CountryTab({
    required this.fetchResult,
    required this.currentCountry,
    required this.selectingByServer,
    required this.recentlyUsedCountries,
    required this.onRememberCountry,
    required this.sortBySpeed,
    required this.testingCountries,
    required this.sortSpeedFor,
    required this.onTest,
  });

  final FetchResult fetchResult;
  final String currentCountry;
  final bool selectingByServer;
  final List<String> recentlyUsedCountries;
  final void Function(String country) onRememberCountry;
  final bool sortBySpeed;
  final Set<String> testingCountries;
  final int Function(String country) sortSpeedFor;
  final void Function(String country) onTest;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mainCountries = fetchResult.mains.map((e) => e.country);
    final fallbackCountries = fetchResult.fallbacks.map((e) => e.country);
    final allCountries = [...mainCountries, ...fallbackCountries];
    final allCountriesSet = allCountries.toSet();
    bool currentCountryIsUnselectable = false;
    if (!selectingByServer &&
        currentCountry.isNotEmpty &&
        !allCountriesSet.contains(currentCountry)) {
      allCountriesSet.add(currentCountry);
      currentCountryIsUnselectable = true;
    }
    final sortedCountries = allCountriesSet.toList();
    if (sortBySpeed) {
      sortedCountries.sort((a, b) {
        final speedA = sortSpeedFor(a);
        final speedB = sortSpeedFor(b);
        if (speedA != speedB) return speedB.compareTo(speedA);
        return getLocalizedCountryName(
          context,
          a,
        ).compareTo(getLocalizedCountryName(context, b));
      });
    } else {
      sortedCountries.sort((a, b) {
        if (recentlyUsedCountries.contains(a)) {
          return -1;
        }
        if (recentlyUsedCountries.contains(b)) {
          return 1;
        }
        return 0;
      });
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: sortedCountries.length + 1,
      itemBuilder: (ctx, index) {
        String country = '';
        if (index != 0) {
          country = sortedCountries[index - 1];
        }
        final isCurrent = !selectingByServer && country == currentCountry;
        final title = index == 0
            ? AppLocalizations.of(context)!.auto
            : getLocalizedCountryName(context, country);

        late Widget icon;
        if (index == 0) {
          icon = Icon(Icons.language, size: 28, color: colorScheme.onSurface);
        } else {
          icon = getCountryIcon(country, height: 28, width: 28);
        }

        final currentUnavailable =
            index > 0 && isCurrent && currentCountryIsUnselectable;

        return _SelectionTile(
          isCurrent: isCurrent,
          currentUnavailable: currentUnavailable,
          icon: icon,
          title: title,
          metrics: index == 0
              ? null
              : HandlerResultsStore.instance.forCountry(country),
          testing: index > 0 && testingCountries.contains(country),
          onTest: index == 0 ? null : () => onTest(country),
          onTap: currentUnavailable
              ? null
              : () async {
                  if (!isCurrent || selectingByServer) {
                    onRememberCountry(country);
                    await context.read<ChoiceCubit>().changeCountry(country);
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
        );
      },
    );
  }
}

class _ServerTab extends StatelessWidget {
  const _ServerTab({
    required this.fetchResult,
    required this.currentServerId,
    required this.sortBySpeed,
    required this.testingServers,
    required this.sortSpeedFor,
    required this.onTest,
  });

  final FetchResult fetchResult;
  final int currentServerId;
  final bool sortBySpeed;
  final Set<int> testingServers;
  final int Function(int serverId) sortSpeedFor;
  final void Function(int serverId) onTest;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final servers = fetchResult.uniqueServers();
    final currentUnavailable =
        currentServerId != 0 &&
        !servers.any((s) => s.serverId == currentServerId);

    var items = <({int serverId, String country})>[
      if (currentUnavailable) (serverId: currentServerId, country: ''),
      ...servers,
    ];

    if (sortBySpeed) {
      final pinned = currentUnavailable
          ? items.take(1).toList()
          : <({int serverId, String country})>[];
      final rest = currentUnavailable ? items.skip(1).toList() : items;
      rest.sort((a, b) {
        final speedA = sortSpeedFor(a.serverId);
        final speedB = sortSpeedFor(b.serverId);
        if (speedA != speedB) return speedB.compareTo(speedA);
        return a.serverId.compareTo(b.serverId);
      });
      items = [...pinned, ...rest];
    }

    if (items.isEmpty) {
      return Center(
        child: Text(
          l10n.noServersMessage,
          textAlign: TextAlign.center,
          style: TextStyle(color: colorScheme.onSurface.withOpacity(0.70)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: items.length,
      itemBuilder: (ctx, index) {
        final server = items[index];
        final isCurrent = server.serverId == currentServerId;
        final unavailable = isCurrent && currentUnavailable;
        final countryName = server.country.isEmpty
            ? ''
            : getLocalizedCountryName(context, server.country);
        final title = countryName.isEmpty
            ? '${l10n.server} ${server.serverId}'
            : '$countryName · ${server.serverId}';

        return _SelectionTile(
          isCurrent: isCurrent,
          currentUnavailable: unavailable,
          icon: server.country.isEmpty
              ? Icon(Icons.dns_outlined, size: 28, color: colorScheme.onSurface)
              : getCountryIcon(server.country, height: 28, width: 28),
          title: title,
          metrics: HandlerResultsStore.instance.forServer(server.serverId),
          testing: testingServers.contains(server.serverId),
          onTest: unavailable ? null : () => onTest(server.serverId),
          onTap: unavailable
              ? null
              : () async {
                  if (!isCurrent) {
                    await context.read<ChoiceCubit>().changeServerId(
                      server.serverId,
                    );
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
        );
      },
    );
  }
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.isCurrent,
    required this.currentUnavailable,
    required this.icon,
    required this.title,
    required this.onTap,
    this.metrics,
    this.onTest,
    this.testing = false,
  });

  final bool isCurrent;
  final bool currentUnavailable;
  final Widget icon;
  final String title;
  final VoidCallback? onTap;
  final AggregatedHandlerMetrics? metrics;
  final VoidCallback? onTest;
  final bool testing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: isCurrent
            ? colorScheme.primary.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Opacity(
        opacity: currentUnavailable ? 0.5 : 1.0,
        child: ListTile(
          contentPadding: const EdgeInsets.only(left: 16, right: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isCurrent
                  ? colorScheme.primary.withOpacity(0.2)
                  : colorScheme.surfaceOverlay,
              shape: BoxShape.circle,
            ),
            child: icon,
          ),
          subtitle: currentUnavailable
              ? Text(
                  'Current location is unavailable. Please select another.',
                  style: TextStyle(
                    color: colorScheme.error.withOpacity(0.70),
                    fontSize: 12,
                  ),
                )
              : null,
          title: Text(
            title,
            style: TextStyle(
              color: isCurrent ? colorScheme.primary : colorScheme.onSurface,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (metrics != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: _HandlerMetricsTrailing(metrics: metrics!),
                ),
              if (onTest != null)
                IconButton(
                  tooltip: '${l10n.statusTest} · ${l10n.speedTest}',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: testing ? null : onTest,
                  icon: testing
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        )
                      : Icon(
                          Icons.speed_outlined,
                          color: colorScheme.onSurface.withOpacity(0.55),
                        ),
                ),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _HandlerMetricsTrailing extends StatelessWidget {
  const _HandlerMetricsTrailing({required this.metrics});

  final AggregatedHandlerMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final speedText = formatSpeedBytesPerSec(metrics.speed);
    final IconData usableIcon;
    final Color usableColor;
    switch (metrics.usable) {
      case UsableStatus.ok:
        usableIcon = Icons.check_circle_outline;
        usableColor = Colors.green;
      case UsableStatus.down:
        usableIcon = Icons.cancel_outlined;
        usableColor = colorScheme.error;
      case UsableStatus.unknown:
        usableIcon = Icons.remove_circle_outline;
        usableColor = colorScheme.onSurface.withOpacity(0.35);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (metrics.usable != UsableStatus.unknown)
          Icon(usableIcon, size: 18, color: usableColor),
        if (speedText.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(
            speedText,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.70),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
  }
}

class Countries {
  List<String> popular;
  List<String> others;

  Countries({required this.popular, required this.others});

  factory Countries.fromJson(Map<String, dynamic> json) {
    return Countries(
      popular: (json['popular'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      others: (json['others'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'popular': popular, 'others': others};
  }
}
