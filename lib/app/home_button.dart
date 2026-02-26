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

    // _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
    //   CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    // );

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

    _statusSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
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
    // Determine if we should be in "forward" state (preparing, connecting, or connected)
    final shouldBeForward = status == XStatus.preparing ||
        status == XStatus.connecting ||
        status == XStatus.connected;

    // Determine if we should be in "backward" state (disconnecting or disconnected)
    final shouldBeBackward =
        status == XStatus.disconnecting || status == XStatus.disconnected;

    // Get previous state
    final wasForward = _previousStatus == XStatus.preparing ||
        _previousStatus == XStatus.connecting ||
        _previousStatus == XStatus.connected;

    // Only update animations if state actually changed
    if (shouldBeForward != wasForward) {
      if (shouldBeForward) {
        // Start animations when preparing, connecting, or connected
        _buttonSlideController.forward();
        _statusController.forward();
        _pulseController.forward();
        // Start timer only when we reach connected state
        if (status == XStatus.connected) {
          _startTimer();
        }
      } else if (shouldBeBackward) {
        // Reverse animations when disconnecting or disconnected
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
      } else if (shouldBeBackward && _previousStatus == XStatus.connected) {
        // Stop timer when we transition away from connected to disconnecting/disconnected
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BlocListener<StatusCubit, UmiStatus>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, status) {
        _updateAnimations(status.status);
      },
      child: BlocBuilder<StatusCubit, UmiStatus>(
        buildWhen: (previous, current) => previous.status != current.status,
        builder: (context, status) {
          // Show connected appearance when preparing, connecting, or connected
          final isConnected = status.status == XStatus.preparing ||
              status.status == XStatus.connecting ||
              status.status == XStatus.connected;
          final isConnecting = status.status == XStatus.preparing ||
              status.status == XStatus.connecting;

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
                            children: [
                              if (isConnected && status.realtimeCountry != null)
                                getCountryIcon(status.realtimeCountry!,
                                    height: 22, width: 22),
                              const SizedBox(width: 6),
                              Text(
                                isConnecting
                                    ? AppLocalizations.of(context)!.connecting
                                    : AppLocalizations.of(context)!
                                        .securelyConnected,
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
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
                  child: GestureDetector(
                    onTap: _toggleConnection,
                    child: Container(
                      height: 180,
                      width: 180,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isConnected
                              ? colorScheme.primary.withOpacity(0.1)
                              : colorScheme.shadowLight,
                          boxShadow: [
                            if (isConnected)
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.4),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            BoxShadow(
                                color: colorScheme.shadowDark,
                                blurRadius: 20,
                                offset: const Offset(0, 10))
                          ],
                          border: Border.all(
                            color: isConnected
                                ? colorScheme.primary
                                : colorScheme.borderLight,
                            width: 2,
                          )),
                      child: Center(
                        child: Container(
                          height: 140,
                          width: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isConnected
                                ? colorScheme.primary
                                : colorScheme.inactiveColor,
                            gradient: isConnected
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                        colorScheme.primary,
                                        colorScheme.secondary,
                                      ])
                                : null,
                          ),
                          child: Icon(
                            Icons.power_settings_new_rounded,
                            size: 60,
                            color: isConnected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface.withOpacity(0.70),
                          ),
                        ),
                      ),
                    ),
                  )),
            ],
          );
        },
      ),
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
        });
  }
}
