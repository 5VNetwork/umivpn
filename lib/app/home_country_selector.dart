part of 'home.dart';

class CountrySelector extends StatelessWidget {
  const CountrySelector({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
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
            child: const _CountryList(),
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
          buildWhen: (previous, current) => previous.country != current.country,
          builder: (ctx, state) {
            final country = state.country;
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
                      _getCountryName(context, state.country),
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

  String _getCountryName(BuildContext context, String countryCode) {
    if (countryCode.isEmpty) {
      return AppLocalizations.of(context)!.auto;
    }
    return getLocalizedCountryName(context, countryCode);
  }
}

class _CountryList extends StatefulWidget {
  const _CountryList({super.key});

  @override
  State<_CountryList> createState() => _CountryListState();
}

class _CountryListState extends State<_CountryList> {
  // final defaultCountries = Countries(popular: ['US', 'JP', 'SG'], others: []);
  // List<String> _selectableCountries = [];
  // List<String> _unselectableCountries = [];
  List<String> _recentlyUsedCountries = [];
  SharedPreferences? _pref;
  bool _fetchOnce = false;
  @override
  void initState() {
    super.initState();
    _getCountries(context.read<SharedPreferences>());
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currentCountry = context.read<ChoiceCubit>().state.country;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppLocalizations.of(context)!.selectLocation,
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
                      context.read<FetchResultProvider>().fetch();
                    },
                    icon: Icon(Icons.refresh_rounded),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Flexible(
            child: Consumer<FetchResultProvider>(
              builder: (ctx, p, child) {
                if (p.fetching) {
                  return SizedBox(
                    height: 100,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                } else if (p.fetchResult != null) {
                  final mainCountries = p.fetchResult!.mains.map(
                    (e) => e.country,
                  );
                  final fallbackCountries = p.fetchResult!.fallbacks.map(
                    (e) => e.country,
                  );
                  final allCountries = [...mainCountries, ...fallbackCountries];
                  final allCountriesSet = allCountries.toSet();
                  bool currentCountryIsUnselectable = false;
                  if (currentCountry.isNotEmpty &&
                      !allCountriesSet.contains(currentCountry)) {
                    allCountriesSet.add(currentCountry);
                    currentCountryIsUnselectable = true;
                  }
                  final sortedCountries = allCountriesSet.toList()
                    ..sort((a, b) {
                      if (_recentlyUsedCountries.contains(a)) {
                        return -1;
                      }
                      if (_recentlyUsedCountries.contains(b)) {
                        return 1;
                      }
                      return 0;
                    });
                  return ListView.builder(
                    shrinkWrap: true,
                    // one for auto, one for devider between selectable and unselectable
                    itemCount: sortedCountries.length + 1,
                    itemBuilder: (ctx, index) {
                      String country = '';
                      // the first list item is auto
                      if (index != 0) {
                        country = sortedCountries[index - 1];
                      }
                      final isCurrent = country == currentCountry;
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
                          index > 0 &&
                          isCurrent &&
                          currentCountryIsUnselectable;

                      return Container(
                        margin: EdgeInsets.only(
                          bottom: index < _recentlyUsedCountries.length - 1
                              ? 0
                              : 8,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? colorScheme.primary.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          // border: isCurrent
                          //     ? Border.all(
                          //         color: colorScheme.primary.withOpacity(0.4),
                          //         width: 1.5,
                          //       )
                          //     : null,
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
                                      color: colorScheme.error.withOpacity(
                                        0.70,
                                      ),
                                      fontSize: 12,
                                    ),
                                  )
                                : null,
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      color: isCurrent
                                          ? colorScheme.primary
                                          : colorScheme.onSurface,
                                      fontWeight: isCurrent
                                          ? FontWeight.w700
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            onTap: currentUnavailable
                                ? null
                                : () async {
                                    if (country != currentCountry) {
                                      // Update recently used
                                      if (!_recentlyUsedCountries.contains(
                                        country,
                                      )) {
                                        _recentlyUsedCountries.insert(
                                          0,
                                          country,
                                        );
                                      } else {
                                        _recentlyUsedCountries.remove(country);
                                        _recentlyUsedCountries.insert(
                                          0,
                                          country,
                                        );
                                      }
                                      // Limit to 10
                                      if (_recentlyUsedCountries.length > 10) {
                                        _recentlyUsedCountries =
                                            _recentlyUsedCountries
                                                .take(10)
                                                .toList();
                                      }
                                      _saveRecentlyUsedCountries();
                                      // Change country in cubit
                                      context.read<ChoiceCubit>().changeCountry(
                                        country,
                                      );
                                    }
                                    Navigator.pop(context);
                                  },
                          ),
                        ),
                      );
                    },
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
                          child: Text(AppLocalizations.of(context)!.retry),
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
                          child: Text('Fetch'),
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
