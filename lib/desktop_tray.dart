part of 'main.dart';

class DesktopTray extends StatefulWidget {
  const DesktopTray({super.key, required this.child});
  final Widget child;

  @override
  State<DesktopTray> createState() => _DesktopTrayState();
}

class _DesktopTrayState extends State<DesktopTray>
    with TrayListener, WindowListener {
  late final SharedPreferences pref;
  @override
  void initState() {
    super.initState();
    pref = context.read<SharedPreferences>();
    _initTray();
    trayManager.addListener(this);
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onTrayIconMouseDown() async {
    if (Platform.isWindows) {
      await windowManager.show();
    } else {
      trayManager.popUpContextMenu();
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu(bringAppToFront: true);
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (kDebugMode) {
      print(menuItem.toJson());
    }
  }

  // on mac this is called when the window is closed
  // on windows this seems to be called when the app is exited
  @override
  void onWindowClose() async {
    if (Platform.isWindows) {
      await context.read<XController>().beforeExitCleanup();
    }
    await windowManager.hide();
    if (Platform.isMacOS) {
      await windowManager.setSkipTaskbar(true);
    }
  }

  @override
  void onWindowMove() async {
    final position = await windowManager.getPosition();
    logger.d('window move x: ${position.dx}, y: ${position.dy}');
    pref.setWindowX(position.dx);
    pref.setWindowY(position.dy);
  }

  @override
  void onWindowResize() async {
    final size = await windowManager.getSize();
    logger.d('window resize width: ${size.width}, height: ${size.height}');
    pref.setWindowWidth(size.width);
    pref.setWindowHeight(size.height);
  }

  Future<void> _setIcon(XStatus status) async {
    late String iconPath;
    if (Platform.isWindows) {
      if (status == XStatus.connected ||
          status == XStatus.connecting ||
          status == XStatus.preparing) {
        iconPath = 'assets/icons/windows_icon.ico';
      } else {
        iconPath = 'assets/icons/windows_icon_outline.ico';
      }
    } else {
      if (status == XStatus.connected ||
          status == XStatus.connecting ||
          status == XStatus.preparing) {
        iconPath = 'assets/icons/umi_fill_48.png';
      } else {
        iconPath = 'assets/icons/umi_48.png';
      }
    }
    await trayManager.setIcon(iconPath,
        isTemplate: true, iconSize: Platform.isWindows ? 12 : 16);
    if (!Platform.isLinux) {
      await trayManager.setToolTip('UmiVPN');
    }
  }

  void _initTray() async {
    // await _setIcon();
    context.read<XController>().statusStream().listen((status) async {
      await _setIcon(status);
      await _updateMenu(status);
    });
    await windowManager.setPreventClose(true);
    logger.d('tray manager initialized');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMenu(context.read<XController>().status);
  }

  Future<void> _updateMenu(XStatus status) async {
    logger.d('update menu status: $status');
    late MenuItem? connectMenuItem;
    switch (status) {
      case XStatus.connected:
        connectMenuItem = MenuItem(
            key: 'toggle_connection',
            label: AppLocalizations.of(context)!.disconnect,
            onClick: (menuItem) {
              context.read<StatusCubit>().stop();
            });
      case XStatus.disconnected:
        connectMenuItem = MenuItem(
          key: 'toggle_connection',
          label: AppLocalizations.of(context)!.connect,
          onClick: (menuItem) {
            context.read<StatusCubit>().start();
          },
        );
      case XStatus.connecting || XStatus.preparing:
        connectMenuItem = MenuItem(
            key: 'toggle_connection',
            label: AppLocalizations.of(context)!.connecting,
            disabled: true);
      case XStatus.disconnecting:
        connectMenuItem = MenuItem(
            key: 'toggle_connection',
            label: AppLocalizations.of(context)!.disconnecting,
            disabled: true);
      case XStatus.reconnecting:
        connectMenuItem = MenuItem(
            key: 'toggle_connection',
            label: AppLocalizations.of(context)!.reconnecting,
            disabled: true);
      case XStatus.unknown:
        connectMenuItem = MenuItem(
            key: 'unknown',
            label: AppLocalizations.of(context)!.unknown,
            disabled: true);
      default:
        connectMenuItem = null;
    }

    await trayManager.setContextMenu(
      Menu(
        items: [
          if (connectMenuItem != null) connectMenuItem,
          MenuItem.separator(),
          if (!Platform.isWindows)
            MenuItem(
              key: 'show_window',
              label: AppLocalizations.of(context)!.showClient,
              onClick: (menuItem) async {
                await windowManager.show();
                if (Platform.isMacOS) {
                  await windowManager.setSkipTaskbar(false);
                }
              },
            ),
          MenuItem(
            key: 'quit',
            label: AppLocalizations.of(context)!.quit,
            onClick: (menuItem) async {
              await exitCurrentApp(context.read<XController>());
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

Future<void> exitCurrentApp(XController xController) async {
  await xController.beforeExitCleanup();
  await trayManager.destroy();
  await windowManager.destroy();
}
