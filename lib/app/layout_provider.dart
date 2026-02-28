import 'package:flutter/material.dart';
import 'package:umivpn/common/common.dart';

enum Layout { compact, medium, expanded, superExpanded }

class MyLayout {
  double? width;
  double? height;
  Layout? layout;

  AppLifecycleState appstate = AppLifecycleState.resumed;
  bool get isDesktop => width == null ? false : width! >= 1200;
  bool get isCompact => width == null ? true : width! < 600;
  bool get compactOrMedium => width == null ? true : width! < 840;
  
  bool fullScreen() {
    if (desktopPlatforms && isCompact) {
      return true;
    } else if (!desktopPlatforms && compactOrMedium) {
      return true;
    } else {
      return false;
    }
  }

  void setFields(double width, double height) {
    // if (appstate == AppLifecycleState.paused) return;
    this.width = width;
    this.height = height;
  }
}
