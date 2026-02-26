import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:umivpn/l10n/app_localizations.dart';
import 'package:umivpn/common/common.dart';
import 'package:umivpn/utils/debug.dart';
import 'package:umivpn/utils/logger.dart';

final destination = <_Destination>[
  _Destination(
    path: '/node',
    outlinedIcon: const Icon(Icons.outbond_outlined),
    filledIcon: const Icon(Icons.outbond_rounded),
    label: (ctx) => AppLocalizations.of(ctx)!.node,
  ),
  _Destination(
    path: '/log',
    outlinedIcon: const ImageIcon(
      AssetImage(
        'assets/icons/log_outline.png',
      ),
    ),
    filledIcon: const ImageIcon(
      AssetImage(
        'assets/icons/log_fill.png',
      ),
    ),
    label: (ctx) => AppLocalizations.of(ctx)!.log,
  ),
  _Destination(
    path: '/route',
    outlinedIcon: const Icon(Icons.alt_route_outlined),
    filledIcon: const Icon(Icons.alt_route_rounded),
    label: (ctx) => AppLocalizations.of(ctx)!.routing,
  ),
  _Destination(
    path: '/server',
    outlinedIcon: const Icon(Icons.cloud_done_outlined),
    filledIcon: const Icon(Icons.cloud_done_rounded),
    label: (ctx) => AppLocalizations.of(ctx)!.server,
  ),
  _Destination(
    path: '/setting',
    outlinedIcon: const Icon(Icons.settings_outlined),
    filledIcon: const Icon(Icons.settings_rounded),
    label: (ctx) => AppLocalizations.of(ctx)!.settings,
  ),
  // _Destination(
  //   path: '/guide',
  //   outlinedIcon: Icon(Icons.explore_outlined),
  //   filledIcon: Icon(Icons.explore_rounded),
  //   label: (ctx) => AppLocalizations.of(ctx)!.compass,
  // ),
  // _Destination(
  //   path: '/ad',
  //   outlinedIcon: Icon(
  //     Icons.campaign_outlined,
  //     size: 24,
  //   ),
  //   filledIcon: Icon(
  //     Icons.campaign_rounded,
  //     size: 24,
  //   ),
  //   label: (ctx) => 'AD',
  // ),
];

enum NaviDestination {
  // home(prefix: '/'),
  outbound(prefix: '/node'),
  log(prefix: '/log'),
  route(prefix: '/route'),
  server(prefix: '/server'),
  settings(prefix: '/setting'),
  // compass(prefix: '/guide'),
  // ad(prefix: '/ad')
  ;

  static NaviDestination? fromPath(String? path) {
    if (path == null) {
      return null;
    }
    // if (path == '/') {
    //   return NaviDestination.home;
    // }
    for (var e in NaviDestination.values) {
      // if (e.prefix == '/') {
      //   continue;
      // }
      if (path.startsWith(e.prefix)) {
        return e;
      }
    }
    return null;
  }

  const NaviDestination({required this.prefix});
  final String prefix;
}

class _Destination {
  const _Destination(
      {required this.path,
      required this.label,
      required this.outlinedIcon,
      required this.filledIcon});
  final String path;
  final Widget outlinedIcon;
  final Widget filledIcon;
  final String Function(BuildContext) label;
}
