import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:tm/common.dart';
import 'package:tm/x_controller.dart';
import 'package:umivpn/auth/auth_bloc.dart';
import 'package:umivpn/auth/user.dart';
import 'package:umivpn/utils/default_network.dart';
import 'package:umivpn/utils/logger.dart';

class HomeAdProvider with ChangeNotifier {
  HomeAdProvider(
      {required this.defaultNetworkMonitor, required this.xController}) {
    defaultNetworkMonitor.addListener(_setShowAd);
    // _xStatusSubscription = xController.statusStream().listen((status) {
    //   _setShowAd();
    // });
    _setShowAd();
  }
  final DefaultNetworkMonitor defaultNetworkMonitor;
  final XController xController;
  // late final StreamSubscription<XStatus> _xStatusSubscription;

  @override
  void dispose() {
    defaultNetworkMonitor.removeListener(_setShowAd);
    // _xStatusSubscription.cancel();
    super.dispose();
  }

  bool showAd = false;
  // (BannerAd, AdSize)? _bannerAd;
  // (BannerAd, AdSize)? get bannerAd {
  //   if (_showAd) {
  //     return _bannerAd;
  //   }
  //   return null;
  // }

  bool _otherVpnOn = false;
  void _setShowAd() async {
    bool newValue = true;
    if (xController.status == XStatus.connected ||
        defaultNetworkMonitor.isPhysical == true) {
      _otherVpnOn = false;
    } else if (defaultNetworkMonitor.isPhysical == false &&
        xController.status == XStatus.disconnected) {
      // other vpn is on, do not show ads
      _otherVpnOn = true;
      newValue = false;
    } else if (defaultNetworkMonitor.isPhysical == false &&
        (xController.status == XStatus.connecting ||
            xController.status == XStatus.preparing)) {
      // other vpn is on, umi vpn is connecting, do not show
      if (_otherVpnOn) {
        newValue = false;
      }
    } else if (defaultNetworkMonitor.isPhysical == false &&
        xController.status == XStatus.unknown) {
      // other vpn might be on, umi vpn is unknown, do not show
      newValue = false;
    }

    if (showAd == newValue) {
      return;
    }
    showAd = newValue;
    logger.d(
        'showAd: $showAd. status: ${xController.status}. physical: ${defaultNetworkMonitor.isPhysical}');
    // _showAd = newValue;
    // if (_showAd) {
    //   _bannerAd ??= await adManager.bannerAd;
    // }
    notifyListeners();
  }
}
