import 'package:country/country.dart';
import 'package:flutter/widgets.dart';
import 'package:tm/fetch_result_provider.dart';
import 'package:umivpn/l10n/app_localizations.dart';

/// Builds the Android VPN notification title for the active handlers.
///
/// Single handler: same title as the by-handler list in home_country_selector
/// (e.g. `United States 1a`). Multiple handlers: location + count, not names.
String? buildVpnNotificationInfo({
  required List<String> handlerTags,
  required FetchResult? fetchResult,
  BuildContext? context,
}) {
  if (handlerTags.isEmpty) return null;

  final l10n = context != null ? AppLocalizations.of(context) : null;
  final shortLabels = fetchResult?.mainHandlerShortLabels() ?? const {};
  final byTag = <String,
      ({
        String tag,
        int serverId,
        String country,
        String baseTag,
        String address,
        String remark,
      })>{
    for (final h in fetchResult?.uniqueMainHandlers() ?? const []) h.tag: h,
  };

  String localizeCountry(String code) {
    if (code.isEmpty) return '';
    if (context == null) return code;
    return getLocalizedCountryName(context, code);
  }

  String countryOf(String tag) {
    final h = byTag[tag];
    return h?.country ?? (tag.contains('-') ? tag.split('-').last : '');
  }

  int serverIdOf(String tag) {
    final h = byTag[tag];
    if (h != null) return h.serverId;
    final first = tag.split('-').first;
    return int.tryParse(first) ?? 0;
  }

  if (handlerTags.length == 1) {
    final tag = handlerTags.first;
    return formatMainHandlerTitle(
      countryName: localizeCountry(countryOf(tag)),
      serverId: serverIdOf(tag),
      shortLabel: shortLabels[tag] ?? '?',
    );
  }

  final countries = <String>{
    for (final tag in handlerTags)
      if (countryOf(tag).isNotEmpty) countryOf(tag),
  };
  final serverIds = <int>{
    for (final tag in handlerTags)
      if (serverIdOf(tag) != 0) serverIdOf(tag),
  };
  final countLabel =
      l10n?.handlerCount(handlerTags.length) ?? '${handlerTags.length} handlers';
  if (serverIds.length == 1) {
    final serverId = serverIds.first;
    if (countries.length == 1) {
      final countryName = localizeCountry(countries.first);
      if (countryName.isNotEmpty) {
        return '$countryName $serverId · $countLabel';
      }
    }
    return '$serverId · $countLabel';
  }
  if (countries.length == 1) {
    final countryName = localizeCountry(countries.first);
    return countryName.isEmpty ? countLabel : '$countryName · $countLabel';
  }
  return countLabel;
}
