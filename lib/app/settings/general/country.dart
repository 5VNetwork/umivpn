import 'dart:convert';
import 'dart:ui';

// import 'package:country/country.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_common/util/country.dart';
import 'package:flutter_common/util/download.dart';
import 'package:flutter_common/widgets/app_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umivpn/common/common.dart';
import 'package:umivpn/l10n/app_localizations.dart';
import 'package:umivpn/pref_helper.dart';

class CountrySelectionPage extends StatefulWidget {
  const CountrySelectionPage({super.key, this.firstLaunch = false});

  final bool firstLaunch;

  @override
  State<CountrySelectionPage> createState() => _CountrySelectionPageState();
}

class _CountrySelectionPageState extends State<CountrySelectionPage> {
  String? _selectedCountry;
  final List<String> _countries = [];

  @override
  void initState() {
    super.initState();
    final pref = context.read<SharedPreferences>();
    _selectedCountry =
        pref.userCountry ?? PlatformDispatcher.instance.locale.countryCode;
  }

  Future<void> _saveSelection() async {
    if (_selectedCountry == null) return;
    final pref = context.read<SharedPreferences>();
    pref.setUserCountry(_selectedCountry!);
    if (!mounted) return;
    if (widget.firstLaunch) {
      context.go('/');
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final selected = _selectedCountry;
    return Scaffold(
      appBar: adaptiveClosableAppBar(context, title: l10n.currentLocation),
      body: SafeArea(
        child: Column(
          children: [
            if (widget.firstLaunch) const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _countries.length,
                itemBuilder: (context, index) {
                  final country = _countries[index];
                  final isSelected = country == selected;
                  return ListTile(
                    // leading: getCountryIcon(country),
                    // title: Text(getLocalizedCountryName(context, country)),
                    trailing: isSelected
                        ? Icon(Icons.check, color: colorScheme.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedCountry = country;
                      });
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selectedCountry == null ? null : _saveSelection,
                  child: Text(l10n.save),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
