import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_common/util/net.dart';
import 'package:flutter_common/widgets/app_bar.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tm/protos/vx/common/geo/geo.pbenum.dart';
import 'package:tm/protos/vx/router/router.pbenum.dart';
import 'package:tm/x_controller.dart';
import 'package:umivpn/app/choice_cubit.dart';
import 'package:umivpn/app/log/log_bloc.dart';
import 'package:umivpn/app/log/log_routing_helper.dart';
import 'package:umivpn/common/common.dart';
import 'package:umivpn/common/domain.dart';
import 'package:umivpn/common/extension.dart';
import 'package:umivpn/l10n/app_localizations.dart';
import 'package:umivpn/main.dart';
import 'package:umivpn/utils/logger.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_common/util/net.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:provider/provider.dart';
import 'package:tm/protos/vx/common/geo/geo.pb.dart';
import 'package:tm/protos/vx/router/router.pb.dart';

const XBlue = Color(0xFF208EFD);
const ShimmerPurple = Color(0xFFB433F7);
const XPink = Color(0xFFEE348B);
const ShimmerGreen = Color(0xFF30E12E);
final greenColorTheme = ColorScheme.fromSeed(seedColor: ShimmerGreen);
final pinkColorTheme = ColorScheme.fromSeed(seedColor: XPink);
final purpleColorTheme = ColorScheme.fromSeed(seedColor: ShimmerPurple);

TextStyle getChipTextStyle(BuildContext context) {
  return Theme.of(context).textTheme.labelLarge!.copyWith(
    fontWeight: FontWeight.w500,
    // color: greenColorTheme.onSecondaryContainer,
  );
}

class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  late Text _directText;
  late Text _proxyText;
  late Text _rejectText;
  final GlobalKey<_LogListState> _logListKey = GlobalKey<_LogListState>();
  late TextEditingController _searchController;
  late SearchBar _searchBar;
  late Text _logText;
  BlocBuilder<LogBloc, LogState>? _menuAnchor;
  late Widget _goToBottomButton;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.text = context.read<LogBloc>().state.filter.substring;
    _searchBar = SearchBar(
      controller: _searchController,
      onSubmitted: (v) => context.read<LogBloc>().add(SubstringChangedEvent(v)),
      onChanged: (v) => context.read<LogBloc>().add(SubstringChangedEvent(v)),
      trailing: [
        AnimatedBuilder(
          animation: _searchController,
          child: IconButton(
            icon: const Icon(Icons.clear_rounded),
            onPressed: () {
              _searchController.clear();
              context.read<LogBloc>().add(const SubstringChangedEvent(""));
            },
          ),
          builder: (context, child) {
            print(_searchController.text);
            if (_searchController.text.isNotEmpty) {
              return child!;
            }
            return const SizedBox.shrink();
          },
        ),
      ],
      padding: const WidgetStatePropertyAll(EdgeInsets.only(left: 16)),
      leading: const Padding(
        padding: EdgeInsets.zero,
        child: Icon(Icons.search),
      ),
      elevation: const WidgetStatePropertyAll(0),
      constraints: const BoxConstraints(
        minHeight: 40,
        maxHeight: 40,
        maxWidth: 360,
      ),
    );
    _menuAnchor = BlocBuilder<LogBloc, LogState>(
      builder: (context, state) {
        return MenuAnchor(
          menuChildren: [
            if (!Platform.isIOS)
              MenuItemButton(
                onPressed: () => context.read<LogBloc>().add(
                  AppPressedEvent(!state.showApp),
                ),
                child: Text(
                  state.showApp
                      ? AppLocalizations.of(context)!.hideApp
                      : AppLocalizations.of(context)!.showApp,
                ),
              ),
            MenuItemButton(
              onPressed: () => context.read<LogBloc>().add(
                SessionOngoingPressedEvent(!state.showSessionOngoing),
              ),
              child: Text(
                state.showSessionOngoing
                    ? AppLocalizations.of(context)!.hideSessionOngoingIndicator
                    : AppLocalizations.of(context)!.showSessionOngoingIndicator,
              ),
            ),
            MenuItemButton(
              onPressed: () => context.read<LogBloc>().add(
                RealtimeUsagePressedEvent(!state.showRealtimeUsage),
              ),
              child: Text(
                state.showRealtimeUsage
                    ? AppLocalizations.of(context)!.hideRealtimeUsage
                    : AppLocalizations.of(context)!.showRealtimeUsage,
              ),
            ),
          ],
          builder: (context, controller, child) {
            return IconButton(
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              icon: const Icon(Icons.more_vert_rounded),
            );
          },
        );
      },
    );
    _goToBottomButton = IconButton(
      onPressed: () => _logListKey.currentState?.scrollController.animateTo(
        _logListKey.currentState?.scrollController.position.maxScrollExtent ??
            0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
      icon: const Icon(Icons.keyboard_double_arrow_down_rounded),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _directText = Text(
      AppLocalizations.of(context)!.direct,
      style: Theme.of(context).textTheme.labelLarge!.copyWith(
        fontWeight: FontWeight.w500,
        color: pinkColorTheme.onSecondaryContainer,
      ),
    );
    _proxyText = Text(
      AppLocalizations.of(context)!.proxy,
      style: Theme.of(context).textTheme.labelLarge!.copyWith(
        fontWeight: FontWeight.w500,
        color: greenColorTheme.onSecondaryContainer,
      ),
    );
    _rejectText = Text(
      AppLocalizations.of(context)!.reject,
      style: Theme.of(context).textTheme.labelLarge!.copyWith(
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onErrorContainer,
      ),
    );
    _logText = Text(
      AppLocalizations.of(context)!.log,
      style: Theme.of(context).textTheme.titleLarge!.copyWith(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: _logText,
        scrolledUnderElevation: 0,
        actions: [
          BlocBuilder<LogBloc, LogState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Switch(
                  value: state.enableLog,
                  onChanged: (v) {
                    context.read<LogBloc>().add(LogSwitchPressedEvent(v));
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
            child: BlocBuilder<LogBloc, LogState>(
              builder: (context, state) {
                final chips = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilterChip(
                      selected: state.filter.showDirect,
                      surfaceTintColor: pinkColorTheme.surfaceTint,
                      checkmarkColor: pinkColorTheme.onSecondaryContainer,
                      onSelected: (v) => context.read<LogBloc>().add(
                        const DirectPressedEvent(),
                      ),
                      selectedColor: pinkColorTheme.secondaryContainer,
                      side: const BorderSide(color: Colors.transparent),
                      shape: chipBorderRadius,
                      label: _directText,
                    ),
                    const Gap(5),
                    FilterChip(
                      checkmarkColor: greenColorTheme.onSecondaryContainer,
                      selectedColor: greenColorTheme.secondaryContainer,
                      surfaceTintColor: greenColorTheme.surfaceTint,
                      selected: state.filter.showProxy,
                      onSelected: (v) => context.read<LogBloc>().add(
                        const ProxyPressedEvent(),
                      ),
                      side: const BorderSide(color: Colors.transparent),
                      shape: chipBorderRadius,
                      // backgroundColor:
                      //     Theme.of(context).colorScheme.surfaceContainerLow,
                      label: _proxyText,
                    ),
                    const Gap(5),
                    FilterChip(
                      checkmarkColor: Theme.of(
                        context,
                      ).colorScheme.onErrorContainer,
                      selectedColor: Theme.of(
                        context,
                      ).colorScheme.errorContainer,
                      surfaceTintColor: Theme.of(
                        context,
                      ).colorScheme.errorContainer,
                      selected: state.filter.showReject,
                      onSelected: (v) => context.read<LogBloc>().add(
                        const RejectPressedEvent(),
                      ),
                      side: const BorderSide(color: Colors.transparent),
                      shape: chipBorderRadius,
                      label: _rejectText,
                    ),
                    const Gap(5),
                    IconButton(
                      isSelected: state.filter.errorOnly,
                      color: state.filter.errorOnly
                          ? Theme.of(context).colorScheme.error
                          : null,
                      // padding: const EdgeInsets.all(0),
                      // visualDensity: VisualDensity.compact,
                      onPressed: () => context.read<LogBloc>().add(
                        const ErrorOnlyPressedEvent(),
                      ),
                      icon: const Icon(Icons.error_outline_rounded),
                    ),
                  ],
                );
                late final Widget filter;
                if (MediaQuery.of(context).size.width < 700) {
                  filter = Center(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(child: _searchBar),
                            const Gap(5),
                            if (_menuAnchor != null) _menuAnchor!,
                            _goToBottomButton,
                          ],
                        ),
                        const Gap(5),
                        _menuAnchor != null
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [chips],
                              )
                            : chips,
                      ],
                    ),
                  );
                } else {
                  filter = Row(
                    children: [
                      Expanded(child: _searchBar),
                      const Gap(10),
                      chips,
                      if (_menuAnchor != null) _menuAnchor!,
                      _goToBottomButton,
                    ],
                  );
                }
                if (!state.enableLog) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Show realtime logs'),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    filter,
                    const Gap(10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: 8,
                          left: 8,
                          right: 8,
                        ),
                        child: LogList(key: _logListKey),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

const chipBorderRadius = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(5)),
);

class LogList extends StatefulWidget {
  const LogList({super.key});

  @override
  State<LogList> createState() => _LogListState();
}

class _LogListState extends State<LogList> {
  late Chip _directChip;
  late Chip _errorChip;
  late Chip _vChip;
  final ScrollController scrollController = ScrollController();
  bool _isScrolledToBottom = true;
  late Text _directText;
  late Text _proxyText;
  // late Text _errorText;
  late Text _vText;
  XLog? _lastLog;
  late Chip _proxyChip;
  late Chip _rejectChip;
  final double extent = desktopPlatforms ? 36 : 40;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _directText = Text(
      AppLocalizations.of(context)!.direct,
      style: Theme.of(context).textTheme.labelLarge!.copyWith(
        fontWeight: FontWeight.w500,
        color: pinkColorTheme.onSecondaryContainer,
      ),
    );
    _proxyText = Text(
      AppLocalizations.of(context)!.proxy,
      style: Theme.of(context).textTheme.labelLarge!.copyWith(
        fontWeight: FontWeight.w500,
        color: greenColorTheme.onSecondaryContainer,
      ),
    );
    // _errorText = Text('ERROR',
    //     style: Theme.of(context).textTheme.labelLarge!.copyWith(
    //         fontWeight: FontWeight.w500,
    //         color: Theme.of(context).colorScheme.onErrorContainer));
    _vText = Text(
      'UMI',
      style: Theme.of(context).textTheme.labelLarge!.copyWith(
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
    );
    _vChip = Chip(
      side: const BorderSide(color: Colors.transparent),
      shape: chipBorderRadius,
      // padding: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 0),
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      label: _vText,
    );
    _directChip = Chip(
      side: const BorderSide(color: Colors.transparent),
      shape: chipBorderRadius,
      padding: const EdgeInsets.symmetric(horizontal: 0),
      backgroundColor: pinkColorTheme.secondaryContainer,
      label: _directText,
    );
    _proxyChip = Chip(
      side: const BorderSide(color: Colors.transparent),
      shape: chipBorderRadius,
      padding: const EdgeInsets.symmetric(horizontal: 0),
      backgroundColor: greenColorTheme.secondaryContainer,
      label: _proxyText,
    );
    _rejectChip = Chip(
      side: const BorderSide(color: Colors.transparent),
      shape: chipBorderRadius,
      padding: const EdgeInsets.symmetric(horizontal: 0),
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
      label: Text(
        AppLocalizations.of(context)!.reject,
        style: Theme.of(context).textTheme.labelLarge!.copyWith(
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
    );
  }

  void _adgustScrollPosition() {
    if (!scrollController.hasClients) return;
    // print(_scrollController.position.pixels);
    if (_isScrolledToBottom) {
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    }
  }

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (scrollController.hasClients) {
      final maxScroll = scrollController.position.maxScrollExtent;
      final currentScroll = scrollController.position.pixels;
      // Allow for a small threshold to consider "at bottom"
      _isScrolledToBottom = (maxScroll - currentScroll) < 1.0;
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  Widget _getSelectorWidget(String tag) {
    return Row(
      children: [
        Text(
          AppLocalizations.of(context)!.selector,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
            color: XBlue,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Gap(10),
        Text("Proxy"),
      ],
    );
  }

  bool _showTrailing(SessionInfo route, bool isDirect) {
    if (route.error.contains('XTLS rejected QUIC') ||
        route.error.contains('reject quic over hysteria2')) {
      return false;
    }
    return true;
  }

  /// when a user tap on a log item, show the detail dialog
  void _onTap(SessionInfo sessionInfo, bool isDirect, bool compact) {
    final showTrailing = _showTrailing(sessionInfo, isDirect);
    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isProduction())
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: TextButton(
              onPressed: () =>
                  Pasteboard.writeText(sessionInfo.sessionId.toString()),
              child: Text(sessionInfo.sessionId.toString()),
            ),
          ),
        if (sessionInfo.error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
            child: Text(
              sessionInfo.error,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        if (sessionInfo.up != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.trafficStats,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: XBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Gap(5),
                const Icon(Icons.arrow_upward_rounded, size: 18),
                const Gap(5),
                Text(
                  sessionInfo.up.toString(),
                  style: Theme.of(context).textTheme.bodyLarge!,
                ),
                const Gap(5),
                const Icon(Icons.arrow_downward_rounded, size: 18),
                const Gap(5),
                Text(
                  sessionInfo.down.toString(),
                  style: Theme.of(context).textTheme.bodyLarge!,
                ),
              ],
            ),
          ),

        _getAddressListTile(
          sessionInfo.dst,
          isDirect: isDirect,
          showTrailing: showTrailing,
          resolver: sessionInfo.resolver,
        ),
        if (sessionInfo.sniffDomain.isNotEmpty &&
            sessionInfo.sniffDomain != sessionInfo.dst)
          _getDomainListTile(
            AppLocalizations.of(context)!.sniffDomain,
            sessionInfo.sniffDomain,
            isDirect: isDirect,
            showTrailing: showTrailing,
          ),
        if (sessionInfo.sniffDomain.isEmpty &&
            sessionInfo.ipToDomain.isNotEmpty)
          Column(
            children: [
              _getDomainListTile(
                AppLocalizations.of(context)!.ipToDomain,
                sessionInfo.ipToDomain,
                isDirect: isDirect,
                showTrailing: showTrailing,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  AppLocalizations.of(context)!.ipToDomainDesc,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            ],
          ),
        if (sessionInfo.app.isNotEmpty)
          _getAppListTile(
            sessionInfo.app,
            isDirect: isDirect,
            showTrailing: showTrailing,
          ),
        if (sessionInfo.appName.isNotEmpty && !Platform.isAndroid)
          _getAppNameListTile(
            sessionInfo.appName,
            isDirect: isDirect,
            showTrailing: showTrailing,
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sessionInfo.inboundTag?.isNotEmpty ?? false)
                Padding(
                  padding: const EdgeInsets.only(right: 15.0),
                  child: Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.inbound,
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: XBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Gap(5),
                      Text(sessionInfo.inboundTag!),
                    ],
                  ),
                ),
              if (sessionInfo.sniffProtocol?.isNotEmpty ?? false)
                Padding(
                  padding: const EdgeInsets.only(right: 15.0),
                  child: Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.protocol,
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: XBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Gap(5),
                      Text(sessionInfo.sniffProtocol!),
                    ],
                  ),
                ),
              if ((sessionInfo.network?.isNotEmpty ?? false) && !compact)
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.network,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: XBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Gap(5),
                    Text(sessionInfo.network!),
                  ],
                ),
            ],
          ),
        ),
        if ((sessionInfo.network?.isNotEmpty ?? false) && compact)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.network,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: XBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Gap(5),
                Text(sessionInfo.network!),
              ],
            ),
          ),
        if (sessionInfo.source?.isNotEmpty ?? false)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.source,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: XBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Gap(10),
                Text(sessionInfo.source!),
              ],
            ),
          ),
      ],
    );
    if (MediaQuery.of(context).size.isCompact) {
      showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        scrollControlDisabledMaxHeightRatio: 0.8,
        constraints: const BoxConstraints(maxWidth: 500),
        useSafeArea: true,
        isScrollControlled: true,
        builder: (ctx) {
          return Padding(
            padding: const EdgeInsets.only(
              left: 8,
              right: 8,
              top: 24,
              bottom: 8,
            ),
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollUpdateNotification) {
                  final metrics = notification.metrics;
                  // Dismiss when scrolling down at the top
                  // scrollDelta > 0 means scrolling down (content moving up)
                  if (metrics.pixels <= 0 &&
                      notification.scrollDelta != null &&
                      notification.scrollDelta! > 0) {
                    Navigator.of(ctx).pop();
                    return true;
                  }
                }
                return false;
              },
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showTrailing)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          (isDirect
                              ? AppLocalizations.of(context)!.addToProxy
                              : AppLocalizations.of(context)!.addToDirect),
                          style: Theme.of(context).textTheme.titleLarge!
                              .copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                    SafeArea(child: child),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } else {
      showDialog(
        useRootNavigator: true,
        context: context,
        builder: (ctx) {
          return AlertDialog(
            icon: showTrailing || !sessionInfo.abnormal
                ? null
                : Icon(
                    Icons.error_outline_rounded,
                    size: 32,
                    color: Theme.of(context).colorScheme.error,
                  ),
            title: showTrailing
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      (isDirect
                          ? AppLocalizations.of(context)!.addToProxy
                          : AppLocalizations.of(context)!.addToDirect),
                    ),
                  )
                : null,
            scrollable: true,
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: child,
            ),
            // actions: [
            //   TextButton(
            //       onPressed: () => Navigator.of(context).pop(),
            //       child: Text(AppLocalizations.of(context)!.cancel)),
            // ],
          );
        },
      );
    }
  }

  void _onRejectMessageTap(RejectMessage log) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.reject),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 8,
                    left: 16,
                    right: 16,
                  ),
                  child: FutureBuilder<String>(
                    future: _formatRejectReason(log.reason),
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data ?? log.reason,
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      );
                    },
                  ),
                ),
                _getAddressListTile(log.dst, showTrailing: false),
                if (log.domain.isNotEmpty)
                  _getDomainListTile(
                    AppLocalizations.of(context)!.domain,
                    log.domain,
                    showTrailing: false,
                  ),
                if (log.app.isNotEmpty)
                  _getAppListTile(log.app, showTrailing: false, icon: log.icon),
                if (log.appName.isNotEmpty && !Platform.isAndroid)
                  _getAppNameListTile(log.appName, showTrailing: false),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String> _formatRejectReason(String reason) async {
    final ipv6UnsupportedPattern = RegExp(
      r'^handler not support ipv6:\s*(\d+)$',
    );
    final match = ipv6UnsupportedPattern.firstMatch(reason);
    if (match == null) {
      return reason;
    }

    final handlerId = match.group(1);
    if (handlerId == null || handlerId.isEmpty) {
      return reason;
    }

    return reason;
  }

  Widget _getDomainListTile(
    String title,
    String domain, {
    bool isDirect = false,
    bool showTrailing = true,
  }) {
    bool domainAdded = false;
    bool vpnBlockAdded = false;
    return ListTile(
      title: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: XBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Gap(10),
        ],
      ),
      subtitle: Text(domain, style: Theme.of(context).textTheme.bodyLarge),
      trailing: !showTrailing
          ? null
          : StatefulBuilder(
              builder: (context, setState) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.filledTonal(
                      icon: vpnBlockAdded
                          ? const Icon(Icons.check_rounded, size: 18)
                          : const Icon(Icons.vpn_key_off_rounded, size: 18),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                      tooltip: AppLocalizations.of(context)!.addToVpnBlock,
                      onPressed: vpnBlockAdded
                          ? null
                          : () async {
                              final xController = context.read<XController>();
                              final domains = domain.contains(',')
                                  ? domain.split(',')
                                  : [domain];
                              for (final d in domains) {
                                if (isDomain(d)) {
                                  await xController.addVpnBlockDomain(
                                    Domain(
                                      type: Domain_Type.RootDomain,
                                      value: d,
                                    ),
                                  );
                                }
                              }
                              setState(() {
                                vpnBlockAdded = true;
                              });
                            },
                    ),
                    Gap(5),
                    IconButton.filledTonal(
                      icon: domainAdded
                          ? const Icon(Icons.check_rounded, size: 18)
                          : const Icon(Icons.add_rounded, size: 18),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: domainAdded
                          ? null
                          : () async {
                              final xController = context.read<XController>();
                              List<String> domains = [];
                              if (domain.contains(',')) {
                                domains = domain.split(',');
                              } else {
                                domains.add(domain);
                              }
                              final logRoutingHelper = LogRoutingHelper(
                                pref: context.read<SharedPreferences>(),
                                xController: xController,
                              );
                              for (var domain in domains) {
                                if (isDomain(domain)) {
                                  await logRoutingHelper.addDomain(
                                    direct: !isDirect,
                                    type: Domain_Type.RootDomain,
                                    value: domain,
                                  );
                                }
                              }
                              setState(() {
                                domainAdded = true;
                              });
                            },
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _getAddressListTile(
    String destination, {
    bool isDirect = false,
    bool showTrailing = true,
    String resolver = '',
  }) {
    bool domainAdded = false;
    bool vpnBlockAdded = false;
    final isDomainDestination = isDomain(destination);
    final destinationTextStyle = Theme.of(context).textTheme.bodyLarge;
    final dst = Text(destination, maxLines: 3, style: destinationTextStyle);
    return ListTile(
      title: Row(
        children: [
          Text(
            AppLocalizations.of(context)!.address,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: XBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Gap(10),
        ],
      ),
      subtitle: (resolver.isNotEmpty)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                dst,
                Text(
                  'DNS: $resolver',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            )
          : dst,
      trailing: !showTrailing
          ? null
          : StatefulBuilder(
              builder: (context, setState) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isDomainDestination)
                      IconButton.filledTonal(
                        icon: vpnBlockAdded
                            ? const Icon(Icons.check_rounded, size: 18)
                            : const Icon(Icons.vpn_key_off_rounded, size: 18),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                        tooltip: AppLocalizations.of(context)!.addToVpnBlock,
                        onPressed: vpnBlockAdded
                            ? null
                            : () async {
                                try {
                                  final xController = context
                                      .read<XController>();
                                  await xController.addVpnBlockDomain(
                                    Domain(
                                      type: Domain_Type.RootDomain,
                                      value: destination,
                                    ),
                                  );
                                  setState(() {
                                    vpnBlockAdded = true;
                                  });
                                } catch (e) {
                                  logger.d(
                                    'add vpn block domain error',
                                    error: e,
                                  );
                                }
                              },
                      ),
                    Gap(5),
                    IconButton.filledTonal(
                      icon: domainAdded
                          ? const Icon(Icons.check_rounded, size: 18)
                          : const Icon(Icons.add_rounded, size: 18),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: domainAdded
                          ? null
                          : () async {
                              try {
                                final xController = context.read<XController>();
                                final logRoutingHelper = LogRoutingHelper(
                                  pref: context.read<SharedPreferences>(),
                                  xController: xController,
                                );
                                if (isDomainDestination) {
                                  await logRoutingHelper.addDomain(
                                    direct: !isDirect,
                                    type: Domain_Type.RootDomain,
                                    value: destination,
                                  );
                                } else {
                                  final normalizedIp = normalizeIp(destination);
                                  if (isValidIp(normalizedIp)) {
                                    await logRoutingHelper.addIp(
                                      direct: !isDirect,
                                      cidr: ipToCidrString(normalizedIp),
                                    );
                                  }
                                }
                                setState(() {
                                  domainAdded = true;
                                });
                              } catch (e) {
                                logger.d('add address error', error: e);
                              }
                            },
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _getAppNameListTile(
    String appName, {
    bool isDirect = false,
    bool showTrailing = true,
  }) {
    bool appNameAdded = false;
    return ListTile(
      title: Row(
        children: [
          Text(
            AppLocalizations.of(context)!.appKeyword,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: XBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Gap(10),
        ],
      ),
      subtitle: Text(appName, style: Theme.of(context).textTheme.bodyLarge),
      trailing: !showTrailing
          ? null
          : StatefulBuilder(
              builder: (context, setState) {
                return IconButton.filledTonal(
                  icon: appNameAdded
                      ? const Icon(Icons.check_rounded, size: 18)
                      : const Icon(Icons.add_rounded, size: 18),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: appNameAdded
                      ? null
                      : () async {
                          try {
                            final xController = context.read<XController>();
                            final logRoutingHelper = LogRoutingHelper(
                              pref: context.read<SharedPreferences>(),
                              xController: xController,
                            );
                            await logRoutingHelper.addApp(
                              direct: !isDirect,
                              type: AppId_Type.Keyword,
                              value: appName,
                            );
                            setState(() {
                              appNameAdded = true;
                            });
                          } catch (e) {
                            logger.d('add app name error', error: e);
                          }
                        },
                );
              },
            ),
    );
  }

  Widget _getAppListTile(
    String app, {
    bool isDirect = false,
    bool showTrailing = true,
    Uint8List? icon,
  }) {
    bool appAdded = false;
    return ListTile(
      title: Row(
        children: [
          Text(
            AppLocalizations.of(context)!.app,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: XBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Gap(10),
        ],
      ),
      subtitle: Tooltip(
        message: AppLocalizations.of(context)!.copy,
        child: InkWell(
          onTap: () => Pasteboard.writeText(app),
          child: Text(
            app,
            maxLines: 8,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
      trailing: !showTrailing
          ? null
          : StatefulBuilder(
              builder: (context, setState) {
                return IconButton.filledTonal(
                  icon: appAdded
                      ? const Icon(Icons.check_rounded, size: 18)
                      : const Icon(Icons.add_rounded, size: 18),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: appAdded
                      ? null
                      : () async {
                          try {
                            final xController = context.read<XController>();
                            final logRoutingHelper = LogRoutingHelper(
                              pref: context.read<SharedPreferences>(),
                              xController: xController,
                            );
                            await logRoutingHelper.addApp(
                              direct: !isDirect,
                              type: AppId_Type.Exact,
                              value: app,
                            );
                            setState(() {
                              appAdded = true;
                            });
                          } catch (e) {
                            logger.d('add exact app id error', error: e);
                          }
                        },
                );
              },
            ),
    );
  }

  String formatTime(DateTime dateTime, bool compact) {
    return DateFormat(compact ? 'HH:mm' : 'HH:mm:ss').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final compact = constraints.maxWidth < 400;
        final textStyle = compact
            ? Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontFeatures: [const FontFeature.tabularFigures()],
              )
            : Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontFeatures: [const FontFeature.tabularFigures()],
              );
        // print(constraints.maxWidth);
        return BlocBuilder<LogBloc, LogState>(
          builder: (context, state) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _adgustScrollPosition();
            });
            // To maintain a static view when a user is viewing log history
            if (!_isScrolledToBottom &&
                !scrollController.position.isScrollingNotifier.value &&
                state.logs.length == maxLogSize &&
                scrollController.position.pixels >= extent) {
              int v = state.logs.indexOfBackwards(_lastLog!);
              if (v == -1) {
                v = 1;
              } else {
                v = maxLogSize - 1 - v;
              }
              scrollController.jumpTo(
                scrollController.position.pixels - extent * v,
              );
            }
            _lastLog = state.logs.lastOrNull;

            return ListView.builder(
              controller: scrollController,
              // TODO: findChildIndexCallback: ,
              itemBuilder: (context, index) {
                XLog log = state.logs[index]!;
                late Widget child;

                switch (log.runtimeType) {
                  case SessionInfo:
                    final l = log as SessionInfo;
                    final isDirect = l.tag == 'direct';
                    late Widget frontChip;
                    if (l.fallbackTag != null && l.fallbackTag!.isNotEmpty) {
                      frontChip = _getSelectorChip(l.selector);
                    } else if (!isDirect) {
                      frontChip = _getSelectorChip(l.selector);
                    } else {
                      frontChip = Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: _directChip,
                      );
                    }
                    Widget ink = InkWell(
                      borderRadius: BorderRadius.circular(15),
                      overlayColor: const WidgetStatePropertyAll(
                        Colors.transparent,
                      ),
                      onTap: () => _onTap(l, isDirect, compact),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Row(
                          children: [
                            if (state.showApp && l.icon != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Image.memory(l.icon!),
                                ),
                              ),
                            if (l.abnormal)
                              Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: Icon(
                                  Icons.error_outline_rounded,
                                  size: 18,
                                  color: l.abnormalColor(context),
                                ),
                              ),
                            if (state.showApp &&
                                l.icon == null &&
                                l.appName.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: Text(
                                  l.appName,
                                  style: textStyle.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                  ),
                                ),
                              ),
                            Text(l.displayDst, style: textStyle),
                            if (state.showRealtimeUsage &&
                                l.up != null &&
                                l.down != null &&
                                !compact)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  '↑${l.up}  ↓${l.down}',
                                  style: Theme.of(context).textTheme.labelSmall!
                                      .copyWith(
                                        fontFeatures: [
                                          const FontFeature.tabularFigures(),
                                        ],
                                      )
                                      .copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.secondary,
                                      ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                    if (state.showRealtimeUsage &&
                        l.up != null &&
                        l.down != null &&
                        compact) {
                      ink = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ink,
                          Text(
                            ' ↑${l.up}  ↓${l.down}',
                            style: Theme.of(context).textTheme.labelSmall!
                                .copyWith(
                                  fontFeatures: [
                                    const FontFeature.tabularFigures(),
                                  ],
                                  fontSize: 8,
                                )
                                .copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                          ),
                        ],
                      );
                    }
                    child = Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          formatTime(l.timestamp, compact),
                          style: textStyle,
                        ),
                        const Gap(10),
                        frontChip,
                        if (state.showSessionOngoing && !l.ended)
                          Padding(
                            padding: const EdgeInsets.only(left: 2, right: 2),
                            child: Icon(
                              Icons.circle,
                              size: 8,
                              color: ShimmerPurple,
                            ),
                          ),
                        ink,
                        // Gap(5),
                        // const Icon(Icons.east, size: 24, color: Colors.grey),
                        // Gap(5),
                        // Text(l.tag, style: textStyle),
                      ],
                    );
                  case XStatusLog:
                    final l = log as XStatusLog;
                    child = Row(
                      children: [
                        Text(
                          formatTime(l.timestamp, compact),
                          style: textStyle,
                        ),
                        const Gap(10),
                        _vChip,
                        const Gap(10),
                        Text(
                          l.status.localizedString(context),
                          style: textStyle,
                        ),
                      ],
                    );
                  case ErrorMessage:
                    final l = log as ErrorMessage;
                    child = Row(
                      children: [
                        Text(
                          formatTime(l.timestamp, compact),
                          style: textStyle,
                        ),
                        const Gap(10),
                        _errorChip,
                        const Gap(10),
                        Text(l.message, style: textStyle),
                      ],
                    );
                  case RejectMessage:
                    final l = log as RejectMessage;
                    child = InkWell(
                      borderRadius: BorderRadius.circular(15),
                      overlayColor: const WidgetStatePropertyAll(
                        Colors.transparent,
                      ),
                      onTap: () => _onRejectMessageTap(l),
                      child: Row(
                        children: [
                          Text(
                            formatTime(l.timestamp, compact),
                            style: textStyle,
                          ),
                          const Gap(10),
                          _rejectChip,
                          const Gap(10),
                          if (state.showApp && l.icon != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 5),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: Image.memory(l.icon!),
                              ),
                            ),
                          if (state.showApp &&
                              l.icon == null &&
                              l.appName.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 5),
                              child: Text(
                                l.appName,
                                style: textStyle.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          Text(l.displayDst, style: textStyle),
                        ],
                      ),
                    );
                }
                return OverflowBox(
                  alignment: Alignment.centerLeft,
                  maxWidth: double.infinity,
                  child: child,
                );
              },
              itemCount: state.logs.length,
              itemExtent: extent,
            );
          },
        );
      },
    );
  }

  Widget _getSelectorChip(String name) {
    return Padding(padding: const EdgeInsets.only(right: 5), child: _proxyChip);
  }

  // one of tag and name must be not null
}
