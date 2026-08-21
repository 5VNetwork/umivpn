part of 'home.dart';

class Selector extends StatelessWidget {
  const Selector({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        final initialTab =
            context.read<ChoiceCubit>().state.serverId != 0 ? 1 : 0;
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
            child: _LocationSheet(initialTabIndex: initialTab),
          ),
        );
      },
      child: Container(
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
                        fontSize: 16,
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
  const _LocationSheet({required this.initialTabIndex});

  final int initialTabIndex;

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<String> _recentlyUsedCountries = [];
  SharedPreferences? _pref;
  bool _fetchOnce = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _getCountries(context.read<SharedPreferences>());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _getCountries(SharedPreferences pref) async {
    _pref = pref;
    _recentlyUsedCountries = pref.getStringList('recentlyUsedCountries') ?? [];
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
              Text(
                l10n.selectLocation,
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
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
                      context
                          .read<FetchResultProvider>()
                          .fetch(reason: 'refresh');
                    },
                    icon: const Icon(Icons.refresh_rounded),
                  );
                },
              ),
            ],
          ),
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
          const SizedBox(height: 8),
          Flexible(
            child: Consumer<FetchResultProvider>(
              builder: (ctx, p, child) {
                if (p.fetching) {
                  return const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (p.fetchResult != null) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _CountryTab(
                        fetchResult: p.fetchResult!,
                        currentCountry: choice.country,
                        selectingByServer: choice.serverId != 0,
                        recentlyUsedCountries: _recentlyUsedCountries,
                        onRememberCountry: _rememberCountry,
                      ),
                      _ServerTab(
                        fetchResult: p.fetchResult!,
                        currentServerId: choice.serverId,
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
  });

  final FetchResult fetchResult;
  final String currentCountry;
  final bool selectingByServer;
  final List<String> recentlyUsedCountries;
  final void Function(String country) onRememberCountry;

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
    final sortedCountries = allCountriesSet.toList()
      ..sort((a, b) {
        if (recentlyUsedCountries.contains(a)) {
          return -1;
        }
        if (recentlyUsedCountries.contains(b)) {
          return 1;
        }
        return 0;
      });

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
          icon = Icon(
            Icons.language,
            size: 28,
            color: colorScheme.onSurface,
          );
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
  });

  final FetchResult fetchResult;
  final int currentServerId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final servers = fetchResult.uniqueServers();
    final currentUnavailable = currentServerId != 0 &&
        !servers.any((s) => s.serverId == currentServerId);

    final items = <({int serverId, String country})>[
      if (currentUnavailable) (serverId: currentServerId, country: ''),
      ...servers,
    ];

    if (items.isEmpty) {
      return Center(
        child: Text(
          l10n.noServersMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.70),
          ),
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
              ? Icon(
                  Icons.dns_outlined,
                  size: 28,
                  color: colorScheme.onSurface,
                )
              : getCountryIcon(server.country, height: 28, width: 28),
          title: title,
          onTap: unavailable
              ? null
              : () async {
                  if (!isCurrent) {
                    await context
                        .read<ChoiceCubit>()
                        .changeServerId(server.serverId);
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
  });

  final bool isCurrent;
  final bool currentUnavailable;
  final Widget icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
          onTap: onTap,
        ),
      ),
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
