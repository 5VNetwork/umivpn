import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:umivpn/main.dart';
import 'package:umivpn/utils/logger.dart';
import 'package:umivpn/utils/path.dart';
import 'package:window_manager/window_manager.dart';

import 'package:umivpn/common/common.dart';
import 'package:umivpn/theme.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    late final Widget child;
    if (Platform.isMacOS || Platform.isIOS || Platform.isAndroid) {
      // final isPro = context.watch<AuthBloc>().state.pro;
      child = SizedBox(
        height: 50,
        child: Row(
          children: [
            if (!desktopPlatforms)
              SizedBox(
                  width: 80,
                  child: Image.asset(
                    'assets/icons/V.png',
                    width: 24,
                    height: 24,
                    color: Theme.of(context).colorScheme.primary,
                  )),
            Expanded(child: SizedBox()),
            IconButton(
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
                icon: const Icon(Icons.tune_rounded)),
            const Gap(10),
          ],
        ),
      );
    }
    if (Platform.isWindows || Platform.isLinux) {
      child = Row(
        children: [
          Expanded(
              child: MoveWindow(
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                  width: 80,
                  child: Image.asset(
                    'assets/icons/V.png',
                    width: 18,
                    height: 18,
                    color: Theme.of(context).colorScheme.primary,
                  )),
            ),
          )),
          // if (!isProduction())
          //   TextButton(
          //     onPressed: () async {
          //       logUploadService ??= LogUploadService(
          //         flutterLogDir: await getFlutterLogDir(),
          //         tunnelLogDir: await getTunnelLogDir(),
          //       );
          //       logUploadService?.performUpload();
          //     },
          //     child: const Text("Upload"),
          //   ),
          IconButton(
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
              icon: const Icon(Icons.tune_rounded)),
          const Gap(5),
          const WindowButtons(),
          const Gap(5),
        ],
      );
    }
    return SizedBox(height: 44, child: child);
  }
}

// Window button colors - these are desktop-specific and can be customized per theme
WindowButtonColors getWindowButtonColors(ColorScheme colorScheme) {
  return WindowButtonColors(
    iconNormal: colorScheme.borderColor,
    mouseOver: colorScheme.sidebarColor,
    mouseDown: colorScheme.borderColor,
    iconMouseOver: colorScheme.borderColor,
    iconMouseDown: colorScheme.backgroundStartColor,
  );
}

WindowButtonColors getCloseButtonColors(ColorScheme colorScheme) {
  return WindowButtonColors(
    mouseOver: const Color(0xFFD32F2F),
    mouseDown: const Color(0xFFB71C1C),
    iconNormal: colorScheme.borderColor,
    iconMouseOver: Colors.white,
  );
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
            onPressed: appWindow.minimize,
            icon: const Icon(Icons.remove_rounded)),
        const SizedBox(width: 4),
        IconButton(
            onPressed: appWindow.maximizeOrRestore,
            icon: Icon(
                size: 20,
                appWindow.isMaximized
                    ? Icons.fullscreen_exit_rounded
                    : Icons.fullscreen_rounded)),
        const SizedBox(width: 4),
        IconButton(
            onPressed: () async {
              await windowManager.hide();
            },
            icon: const Icon(Icons.close_rounded)),
      ],
    );
  }
}

class MinimizeWindowButton extends WindowButton {
  MinimizeWindowButton(
      {super.key, super.colors, VoidCallback? onPressed, bool? animate})
      : super(
            animate: animate ?? false,
            iconBuilder: (buttonContext) =>
                MinimizeIcon(color: buttonContext.iconColor),
            onPressed: onPressed ?? () => appWindow.minimize());
}
