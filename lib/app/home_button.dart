part of 'home.dart';

class HomeButton extends StatefulWidget {
  const HomeButton({super.key});

  @override
  State<HomeButton> createState() => _HomeButtonState();
}

class _HomeButtonState extends State<HomeButton> with TickerProviderStateMixin {
  int _secondsConnected = 0;
  Timer? _timer;
  XStatus? _previousStatus;

  // Animation controllers
  late AnimationController _pulseController;
  // late Animation<double> _pulseAnimation;
  late AnimationController _statusController;
  late AnimationController _buttonSlideController;
  late Animation<double> _statusFadeAnimation;
  late Animation<Offset> _statusSlideAnimation;
  late Animation<Offset> _buttonSlideAnimation;

  @override
  void initState() {
    super.initState();

    // Setup breathing animation for the button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        final currentStatus = context.read<StatusCubit>().state;
        if (currentStatus.status == XStatus.preparing ||
            currentStatus.status == XStatus.connecting ||
            currentStatus.status == XStatus.connected) {
          _pulseController.forward();
        }
      }
    });

    // Initialize animations based on current status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentStatus = context.read<StatusCubit>().state;
      _previousStatus = currentStatus.status;
      _updateAnimations(currentStatus.status);
    });

    // Setup status appearance animation
    _statusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _statusFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _statusController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _statusSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _statusController,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
          ),
        );

    // Setup button slide down animation
    _buttonSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _buttonSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _buttonSlideController,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
          ),
        );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _statusController.dispose();
    _buttonSlideController.dispose();
    super.dispose();
  }

  void _toggleConnection() {
    final currentStatus = context.read<StatusCubit>().state;

    if (currentStatus.status == XStatus.connected) {
      context.read<StatusCubit>().stop();
    } else {
      context.read<StatusCubit>().start();
    }
  }

  void _updateAnimations(XStatus status) {
    // Keep status/button forward while disconnecting; reverse only when disconnected.
    final shouldBeForward =
        status == XStatus.preparing ||
        status == XStatus.connecting ||
        status == XStatus.connected ||
        status == XStatus.disconnecting;

    // Get previous state
    final wasForward =
        _previousStatus == XStatus.preparing ||
        _previousStatus == XStatus.connecting ||
        _previousStatus == XStatus.connected ||
        _previousStatus == XStatus.disconnecting;

    // Only update animations if state actually changed
    if (shouldBeForward != wasForward) {
      if (shouldBeForward) {
        // Start animations when preparing, connecting, connected, or disconnecting
        _buttonSlideController.forward();
        _statusController.forward();
        if (status == XStatus.preparing ||
            status == XStatus.connecting ||
            status == XStatus.connected) {
          _pulseController.forward();
        }
        // Start timer only when we reach connected state
        if (status == XStatus.connected) {
          _startTimer();
        }
      } else {
        // Reverse animations when disconnected
        _buttonSlideController.reverse();
        _statusController.reverse();
        _pulseController.reset();
        _stopTimer();
      }
    } else {
      // Handle timer start/stop for transitions within the same forward/backward state
      if (status == XStatus.connected && _previousStatus != XStatus.connected) {
        // Start timer when we transition to connected (from preparing/connecting)
        _startTimer();
      } else if (status == XStatus.disconnecting &&
          _previousStatus == XStatus.connected) {
        // Stop pulsing and timer when disconnect begins
        _pulseController.reset();
        _stopTimer();
      }
    }

    _previousStatus = status;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsConnected++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _secondsConnected = 0;
    });
  }

  List<Widget> _buildStatusRowChildren(
    BuildContext context,
    ColorScheme colorScheme,
    UmiStatus status,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final textStyle = TextStyle(
      color: colorScheme.primary,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.5,
    );

    if (status.changingCountry) {
      return [Text(l10n.changingCountry, style: textStyle)];
    }

    return switch (status.status) {
      XStatus.preparing ||
      XStatus.connecting => [Text(l10n.connecting, style: textStyle)],
      XStatus.disconnecting => [Text(l10n.disconnecting, style: textStyle)],
      XStatus.connected when status.realtimeCountry != null => [
        getCountryIcon(status.realtimeCountry!, height: 22, width: 22),
        const SizedBox(width: 6),
        Text(l10n.securelyConnected, style: textStyle),
      ],
      XStatus.connected => [Text(l10n.securelyConnected, style: textStyle)],
      XStatus.disconnected => [Text(l10n.disconnected, style: textStyle)],
      _ => [Text(l10n.unknown, style: textStyle)],
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BlocListener<StatusCubit, UmiStatus>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, status) {
        _updateAnimations(status.status);
      },
      child: BlocBuilder<StatusCubit, UmiStatus>(
        builder: (context, status) {
          // Show connected appearance when connected or disconnecting
          final isConnected = status.status == XStatus.connected;
          final isDisconnecting = status.status == XStatus.disconnecting;
          final isConnectedAppearance = isConnected || isDisconnecting;
          final isButtonDisabled =
              status.status == XStatus.preparing ||
              status.status == XStatus.connecting ||
              status.status == XStatus.disconnecting;
          return Column(
            children: [
              AnimatedBuilder(
                animation: _statusController,
                builder: (context, child) {
                  // Only show content when connected or animation is in progress
                  // if (!isConnected && _statusController.value == 0) {
                  //   return const SizedBox.shrink();
                  // }
                  // Always render the widget to maintain layout space
                  // FadeTransition will handle visibility smoothly without layout jumps
                  return FadeTransition(
                    opacity: _statusFadeAnimation,
                    child: SlideTransition(
                      position: _statusSlideAnimation,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: _buildStatusRowChildren(
                              context,
                              colorScheme,
                              status,
                            ),
                          ),
                          if (isConnected) ...[
                            const SizedBox(height: 8),
                            const _RealtimeTraffic(),
                          ],
                          const SizedBox(height: 10),
                          const _Timer(),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // 3. Connect Button
              SlideTransition(
                position: _buttonSlideAnimation,
                child: Opacity(
                  opacity: isButtonDisabled ? 0.6 : 1,
                  child: GestureDetector(
                    onTap: isButtonDisabled ? null : _toggleConnection,
                    child: Container(
                      height: 180,
                      width: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnectedAppearance
                            ? colorScheme.connectButtonConnectedOuter
                            : colorScheme.connectButtonDisconnectedOuter,
                        boxShadow: [
                          if (isConnectedAppearance)
                            BoxShadow(
                              color: colorScheme.connectButtonConnectedGlow,
                              blurRadius:
                                  colorScheme.brightness == Brightness.dark
                                  ? 40
                                  : 32,
                              spreadRadius:
                                  colorScheme.brightness == Brightness.dark
                                  ? 10
                                  : 2,
                            ),
                          BoxShadow(
                            color: colorScheme.shadowDark,
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(
                          color: isConnectedAppearance
                              ? colorScheme.connectButtonConnectedBorder
                              : colorScheme.connectButtonDisconnectedBorder,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          height: 140,
                          width: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isConnectedAppearance
                                ? null
                                : colorScheme.connectButtonDisconnectedFill,
                            gradient: isConnectedAppearance
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      colorScheme
                                          .connectButtonConnectedFillStart,
                                      colorScheme.connectButtonConnectedFillEnd,
                                    ],
                                  )
                                : null,
                            boxShadow:
                                isConnectedAppearance &&
                                    colorScheme.brightness == Brightness.light
                                ? [
                                    BoxShadow(
                                      color: colorScheme
                                          .connectButtonConnectedInnerShadow,
                                      blurRadius: 14,
                                      offset: const Offset(0, 5),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            Icons.power_settings_new_rounded,
                            size: 60,
                            color: isConnectedAppearance
                                ? colorScheme.connectButtonConnectedIcon
                                : colorScheme.connectButtonDisconnectedIcon,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RealtimeTraffic extends StatelessWidget {
  const _RealtimeTraffic();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final style = TextStyle(
      color: colorScheme.onSurface.withOpacity(0.70),
      fontSize: 13,
      fontWeight: FontWeight.w500,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return ValueListenableBuilder(
      valueListenable: context.read<XController>().trafficRate,
      builder: (context, rate, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.arrow_upward_rounded,
              size: 14,
              color: colorScheme.onSurface.withOpacity(0.70),
            ),
            const SizedBox(width: 2),
            Text('${bytesToReadable(rate.up)}/s', style: style),
            const SizedBox(width: 10),
            Icon(
              Icons.arrow_downward_rounded,
              size: 14,
              color: colorScheme.onSurface.withOpacity(0.70),
            ),
            const SizedBox(width: 2),
            Text('${bytesToReadable(rate.down)}/s', style: style),
          ],
        );
      },
    );
  }
}

class _Timer extends StatelessWidget {
  const _Timer({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BlocSelector<StatusCubit, UmiStatus, String>(
      selector: (state) => state.connected,
      builder: (context, duration) {
        return Text(
          duration,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 40,
            fontWeight: FontWeight.w300,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
      },
    );
  }
}
