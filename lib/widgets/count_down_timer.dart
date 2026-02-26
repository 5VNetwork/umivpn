import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:umivpn/l10n/app_localizations.dart';

class CountdownTimer extends StatefulWidget {
  final int startSeconds;
  final VoidCallback? onFinished;
  final TextStyle? textStyle;

  const CountdownTimer({
    super.key,
    this.startSeconds = 60,
    this.textStyle,
    this.onFinished,
  });

  @override
  _CountdownTimerState createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late int _secondsRemaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.startSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
          widget.onFinished?.call();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '${_secondsRemaining}s',
      style: widget.textStyle,
    );
  }
}
