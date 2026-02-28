import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

final desktopPlatforms =
    Platform.isMacOS || Platform.isWindows || Platform.isLinux;

const androidPackageNme =
    appFlavor == 'staging' ? 'com.example.app' : 'com5vnetwork.umi';
const darwinBundleId = 'com.5vnetwork.umivpn';

const supabaseUrl = kDebugMode
    ? String.fromEnvironment('SUPABASE_URL')
    : 'https://tvssabmjinwlwtodgjza.supabase.co';
const supabaseApiKey = kDebugMode
    ? 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH'
    : 'sb_publishable_bSVb6AH8NMt461D2zIqSjA_Ty5tfHhZ';

const websiteUrl = 'https://www.umivpn.com';
const privacyPolicyUrl = 'https://www.umivpn.com/privacy';
const termOfServiceUrl = 'https://www.umivpn.com/terms';

final androidApkRelease =
    Platform.isAndroid && !const bool.fromEnvironment('PLAY_STORE');
const logKey = String.fromEnvironment('LOG_KEY', defaultValue: '1234567890');

final useStripe = Platform.isWindows ||
    (androidApkRelease) ||
    appFlavor == "pkg" ||
    Platform.isLinux;

const isStore = bool.fromEnvironment('STORE');
final autoUpdateSupported = (Platform.isAndroid && !isStore) ||
    (Platform.isWindows && !isStore) ||
    Platform.isLinux;

List<int> generateUniqueNumbers(int count, {int min = 1, int max = 100}) {
  final random = Random();
  final Set<int> numbers = {};

  while (numbers.length < count) {
    numbers.add(min + random.nextInt(max - min + 1));
  }

  return numbers.toList();
}

String getUserCountryFromLocale() {
  final locale = PlatformDispatcher.instance.locale;
  return locale.countryCode ?? 'Unknown';
}

final emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
final numericRegExp = RegExp(r'^\d+$');
const isPkg = appFlavor == 'pkg';
