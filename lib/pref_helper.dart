import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umivpn/app/home.dart';
import 'package:umivpn/common/common.dart';
import 'package:umivpn/l10n/app_localizations.dart';
import 'package:umivpn/utils/logger.dart';
import 'package:tm/default.dart';

extension PrefHelperExtension on SharedPreferences {
  bool get initialLaunch {
    return getBool('initialLaunch') ?? false;
  }

  void setInitialLaunch() {
    setBool('initialLaunch', true);
  }

  bool get hasShownVpnServiceInfo {
    return getBool('hasShownVpnServiceInfo') ?? false;
  }
  
  void setHasShownVpnServiceInfo(bool value) {
    setBool('hasShownVpnServiceInfo', value);
  }

  bool get hasShownPrivacyInfo {
    return getBool('hasShownPrivacyInfo') ?? false;
  }

  void setHasShownPrivacyInfo(bool value) {
    setBool('hasShownPrivacyInfo', value);
  }

  // return either a string or a RouteMode
  DefaultRouteMode get routingMode {
    final mode = getInt('routingMode');
    if (mode == null) {
      return DefaultRouteMode.proxyAll;
    }
    return DefaultRouteMode.values[mode];
  }

  void setRoutingMode(DefaultRouteMode mode) {
    setInt('routingMode', mode.index);
  }

  bool get enableDebugLog {
    return getBool('enableDebugLog') ?? false;
  }

  void setEnableDebugLog(bool enable) {
    setBool('enableDebugLog', enable);
  }

  bool get showApp {
    return getBool('showApp') ?? false;
  }

  DateTime? get lastGeoUpdate {
    final time = getInt('lastGeoUpdate');
    if (time == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(time);
  }

  void setLastGeoUpdate(DateTime time) {
    setInt('lastGeoUpdate', time.millisecondsSinceEpoch);
  }

  bool get autoUpdate {
    return getBool('autoUpdate') ?? true;
  }

  void setAutoUpdate(bool enable) {
    setBool('autoUpdate', enable);
  }

  /// Last time the app checked for updates (stored as milliseconds since epoch)
  int? get lastUpdateCheckTime {
    return getInt('lastUpdateCheckTime');
  }

  void setLastUpdateCheckTime(int timestamp) {
    setInt('lastUpdateCheckTime', timestamp);
  }

  String? get downloadedInstallerPath {
    return getString('downloadedInstallerPath');
  }

  void setDownloadedInstallerPath(String? path) {
    if (path == null) {
      remove('downloadedInstallerPath');
    } else {
      setString('downloadedInstallerPath', path);
    }
  }

  String? get skipVersion {
    return getString('skipVersion');
  }

  void setSkipVersion(String version) {
    setString('skipVersion', version);
  }

  Language? get language {
    final i = getInt('language');
    if (i == null) return null;
    return Language.values[i];
  }

  void setLanguage(Language? language) {
    if (language == null) {
      remove('language');
    } else {
      setInt('language', language.index);
    }
  }

  bool get hasShownOnce {
    return getBool('hasShownOnce') ?? false;
  }

  void setHasShownOnce(bool show) {
    setBool('hasShownOnce', show);
  }

  bool get hasShownWelcome {
    return getBool('hasShownWelcome') ?? false;
  }

  void setHasShownWelcome(bool show) {
    setBool('hasShownWelcome', show);
  }

  double? get windowX {
    return getDouble('windowX');
  }

  void setWindowX(double x) {
    setDouble('windowX', x);
  }

  double? get windowY {
    return getDouble('windowY');
  }

  void setWindowY(double x) {
    setDouble('windowY', x);
  }

  double get windowWidth {
    return getDouble('windowWidth') ?? 350;
  }

  void setWindowWidth(double x) {
    setDouble('windowWidth', x);
  }

  double get windowHeight {
    return getDouble('windowHeight') ?? 740;
  }

  void setWindowHeight(double x) {
    setDouble('windowHeight', x);
  }

  bool get shareLog {
    if (isPkg) {
      return false;
    }
    return getBool('shareLog') ?? isProduction();
  }

  void setShareLog(bool enable) {
    setBool('shareLog', enable);
  }

  DateTime? get lastUploadTime {
    final time = getInt('lastLogUploadTime');
    if (time == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(time);
  }

  void setLastUploadTime(DateTime time) {
    setInt('lastLogUploadTime', time.millisecondsSinceEpoch);
  }

  ThemeMode get themeMode {
    final mode = getInt('themeMode');
    if (mode == null) return ThemeMode.system;
    return ThemeMode.values[mode];
  }

  void setThemeMode(ThemeMode mode) {
    setInt('themeMode', mode.index);
  }

  bool get alwaysOn {
    if (Platform.isMacOS || Platform.isAndroid || Platform.isIOS) {
      return false;
    }
    return getBool('alwaysOn') ?? false;
  }

  void setAlwaysOn(bool enable) {
    setBool('alwaysOn', enable);
  }

  bool get startOnBoot {
    return getBool('startOnBoot') ?? false;
  }

  void setStartOnBoot(bool enable) {
    setBool('startOnBoot', enable);
  }

  // if a user clicks connect, set this to true.
  // if a user clicks disconnect, set this to false.
  bool get connect {
    return getBool('connect') ?? false;
  }

  void setConnect(bool enable) {
    setBool('connect', enable);
  }

  Countries? get countries {
    final json = getString('countries');
    if (json == null) return null;
    return Countries.fromJson(jsonDecode(json));
  }

  void setCountries(String json) {
    setString('countries', json);
  }

  InboundMode get inboundMode {
    final mode = getInt('inboundMode');
    if (mode == null) return InboundMode.tun;
    return InboundMode.values[mode];
  }

  void setInboundMode(InboundMode mode) {
    setInt('inboundMode', mode.index);
  }

  String get selectedCountry {
    return getString('selectedCountry') ?? '';
  }

  void setSelectedCountry(String country) {
    setString('selectedCountry', country);
  }

  bool get enableAppOpenAds {
    return getBool('enableAppOpenAds') ?? true;
  }

  void setEnableAppOpenAds(bool enable) {
    setBool('enableAppOpenAds', enable);
  }
}

enum InboundMode {
  tun(),
  systemProxy(),
  wfp();

  const InboundMode();

  String toLocalString(BuildContext ctx) {
    switch (this) {
      case InboundMode.wfp:
        return 'WFP';
      case InboundMode.systemProxy:
        return AppLocalizations.of(ctx)!.systemProxy;
      case InboundMode.tun:
        return 'TUN';
    }
  }
}

enum Language {
  zh(Locale('zh', 'CN'), '简体中文(中国)'),
  en(Locale('en'), 'English(United States)');

  final Locale locale;
  final String localText;

  static Language? fromCode(String code) {
    if (code == 'zh') return zh;
    if (code == 'en') return en;
    return null;
  }

  const Language(this.locale, this.localText);
}
