
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umivpn/app/settings/setting.dart';
import 'package:umivpn/main.dart';
import 'package:umivpn/pref_helper.dart';
import 'package:umivpn/l10n/app_localizations.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? getAdaptiveAppBar(context, Text(AppLocalizations.of(context)!.language))
          : null,
      body: Column(
        children: Language.values.map((l) {
          return RadioListTile(
            title: Text(l.localText),
            value: l,
            groupValue:
                Language.fromCode(Localizations.localeOf(context).languageCode),
            onChanged: (value) {
              context.read<SharedPreferences>().setLanguage(value);
              // change locale
              App.of(context)?.setLocale(value?.locale);
            },
          );
        }).toList(),
      ),
    );
  }
}
