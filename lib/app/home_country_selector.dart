part of 'home.dart';

const countryUrl =
    'https://pub-ffc1bef2c4eb4b8fb433f0706418dabe.r2.dev/countries.json';

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
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
          color: colorScheme.surfaceOverlayLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.borderLight),
        ),
        child: BlocBuilder<ChoiceCubit, Choice>(
          buildWhen: (previous, current) =>
              previous.country != current.country ||
              previous.realtimeCountry != current.realtimeCountry,
          builder: (ctx, state) {
            final country = state.realtimeCountry ?? state.country;
            return Row(
              children: [
                getCountryIcon(country, height: 28, width: 28),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.currentLocation,
                        style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.70),
                            fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(_getCountryName(context, state.country),
                        style: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ],
                ),
                const Spacer(),
                Icon(Icons.keyboard_arrow_up_rounded,
                    color: colorScheme.onSurface.withOpacity(0.70))
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
  final defaultCountries = Countries(popular: [
    'US',
    // 'JP',
    // 'SG',
  ], others: []);
  List<String> _selectableCountries = [];
  List<String> _unselectableCountries = [];
  List<String> _recentlyUsedCountries = [];
  SharedPreferences? _pref;

  @override
  void initState() {
    super.initState();
    _getCountries(context.read<SharedPreferences>());
  }

  void _getCountries(SharedPreferences pref) async {
    _pref = pref;
    final countries = pref.countries ?? defaultCountries;
    _recentlyUsedCountries = pref.getStringList('recentlyUsedCountries') ?? [];
    setState(() {});
    final userPlan = context.read<AuthRepo>().userProfile!.subscriptionPlan;

    if (userPlan == SubscriptionPlan.free) {
      _unselectableCountries = countries.popular..addAll(countries.others);
    } else if (userPlan == SubscriptionPlan.air) {
      _selectableCountries = countries.popular;
      _unselectableCountries = countries.others;
    } else {
      _selectableCountries = countries.popular..addAll(countries.others);
    }
    _selectableCountries.sort((a, b) {
      if (_recentlyUsedCountries.contains(a)) {
        return -1;
      }
      if (_recentlyUsedCountries.contains(b)) {
        return 1;
      }
      return 0;
    });
  }

  Future<void> _saveRecentlyUsedCountries() async {
    if (_pref != null) {
      await _pref!
          .setStringList('recentlyUsedCountries', _recentlyUsedCountries);
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
          Text("Select Location",
              style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              // one for auto, one for devider between selectable and unselectable
              itemCount: _selectableCountries.length +
                  _unselectableCountries.length +
                  2,
              itemBuilder: (ctx, index) {
                if (index == _selectableCountries.length + 1) {
                  return const Divider();
                }

                String country = '';
                bool isRecentlyUsed = false;
                if (index != 0) {
                  if (index <= _selectableCountries.length) {
                    country = _selectableCountries[index - 1];
                    // Check if this country is in recently used (excluding current country position)
                    isRecentlyUsed = _recentlyUsedCountries.contains(country) &&
                        country != currentCountry;
                  } else {
                    country = _unselectableCountries[
                        index - _selectableCountries.length - 2];
                  }
                }
                final isCurrent = country == currentCountry;
                final isUnselectable =
                    index > 0 && index > _selectableCountries.length + 1;

                final title = index == 0
                    ? AppLocalizations.of(context)!.auto
                    : getLocalizedCountryName(context, country);

                late Widget icon;
                if (index == 0) {
                  icon = Icon(Icons.language,
                      size: 28, color: colorScheme.onSurface);
                } else {
                  icon = getCountryIcon(country, height: 28, width: 28);
                }

                return Container(
                  margin: EdgeInsets.only(
                    bottom: index < _recentlyUsedCountries.length - 1 ? 0 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? colorScheme.primary.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isCurrent
                        ? Border.all(
                            color: colorScheme.primary.withOpacity(0.4),
                            width: 1.5)
                        : null,
                  ),
                  child: Opacity(
                    opacity: isUnselectable ? 0.5 : 1.0,
                    child: ListTile(
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
                          if (isRecentlyUsed && !isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceOverlayLighter,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "Recent",
                                style: TextStyle(
                                  color:
                                      colorScheme.onSurface.withOpacity(0.70),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onTap: isUnselectable
                          ? null
                          : () async {
                              if (country != currentCountry) {
                                // Update recently used
                                if (!_recentlyUsedCountries.contains(country)) {
                                  _recentlyUsedCountries.insert(0, country);
                                } else {
                                  _recentlyUsedCountries.remove(country);
                                  _recentlyUsedCountries.insert(0, country);
                                }
                                // Limit to 10
                                if (_recentlyUsedCountries.length > 10) {
                                  _recentlyUsedCountries =
                                      _recentlyUsedCountries.take(10).toList();
                                }
                                await _saveRecentlyUsedCountries();

                                // Change country in cubit
                                await context
                                    .read<ChoiceCubit>()
                                    .changeCountry(country);
                              }
                              Navigator.pop(context);
                            },
                    ),
                  ),
                );
              },
            ),
          )
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
      popular:
          (json['popular'] as List<dynamic>).map((e) => e as String).toList(),
      others:
          (json['others'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'popular': popular,
      'others': others,
    };
  }
}
