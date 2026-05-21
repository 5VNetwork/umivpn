import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umivpn/utils/logger.dart';
import 'package:umivpn/common/const.dart';
import 'package:umivpn/pref_helper.dart';
import 'package:umivpn/utils/path.dart';
import 'package:flutter_common/common.dart';
import 'package:flutter_common/util/download.dart';

Future<void> writeStaticGeo() async {
  logger.d('writeStaticGeo');
  final geoFile = await rootBundle.load('assets/geo/simplified_geosite.dat');
  final geoIP = await rootBundle.load('assets/geo/simplified_geoip.dat');
  // write to file
  File(await getSimplifiedGeositePath())
      .writeAsBytesSync(geoFile.buffer.asUint8List());
  File(await getSimplifiedGeoIPPath())
      .writeAsBytesSync(geoIP.buffer.asUint8List());
}

const geoipUrl = 'https://cdn.jsdelivr.net/gh/5VNetwork/process-geo@release/simplified_geoip.dat';
const geositeUrl = 'https://cdn.jsdelivr.net/gh/5VNetwork/process-geo@release/simplified_geosite.dat';

Future<void>? _fetchGeoInFlight;

Future<void> fetchGeo() async {
  if (_fetchGeoInFlight != null) {
    return _fetchGeoInFlight;
  }
  final run = _fetchGeoOnce();
  _fetchGeoInFlight = run;
  try {
    await run;
  } finally {
    _fetchGeoInFlight = null;
  }
}

Future<void> _fetchGeoOnce() async {
  logger.d('fetchGeo start');
  await Future.wait([
    directDownloadToFile(geoipUrl, await getSimplifiedGeoIPPath()),
    directDownloadToFile(geositeUrl, await getSimplifiedGeositePath()),
  ]);
  logger.d('fetchGeo done');
}