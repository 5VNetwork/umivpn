import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_common/types/logger.dart' as common;
import 'package:umivpn/common/common.dart';
import 'package:umivpn/main.dart';
import 'package:umivpn/pref_helper.dart';
import 'package:umivpn/utils/path.dart';

Future<void> initLogger(SharedPreferences pref) async {
  if (isProduction()) {
    if (pref.shareLog == true) {
      await startShareLog();
    }
  } else {
    final redirectStdErr = !kDebugMode && (Platform.isIOS || Platform.isMacOS);
    if (redirectStdErr) {
      final logDirPath = getFlutterLogDir().path;
      logger.d("redirectStdErr: $logDirPath");
      await darwinHostApi!.redirectStdErr(join(logDirPath, "redirect.txt"));
    }
    await setDebugLoggerDevlopment();
  }
}

class LoggerWrapper implements common.Logger {
  Logger? _logger;
  LoggerWrapper({Logger? logger}) {
    _logger = logger;
  }

  set logger(Logger? value) {
    _logger?.close();
    _logger = value;
  }

  @override
  void t(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger?.t(message, time: time, error: error, stackTrace: stackTrace);
  }

  @override
  void d(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger?.d(message, time: time, error: error, stackTrace: stackTrace);
  }

  @override
  void i(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger?.i(message, time: time, error: error, stackTrace: stackTrace);
  }

  @override
  void w(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger?.w(message, time: time, error: error, stackTrace: stackTrace);
  }

  @override
  void e(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger?.e(message, time: time, error: error, stackTrace: stackTrace);
  }
}

LoggerWrapper logger = LoggerWrapper();

/// used in production to report error that do not contain personal data
LoggerWrapper reportLogger = LoggerWrapper();

class MultiOutput extends LogOutput {
  final List<LogOutput> outputs;

  MultiOutput(this.outputs);

  @override
  Future<void> init() async {
    for (var output in outputs) {
      await output.init();
    }
  }

  @override
  void output(OutputEvent event) {
    for (var output in outputs) {
      output.output(event);
    }
  }

  @override
  Future<void> destroy() async {
    for (var output in outputs) {
      await output.destroy();
    }
  }
}

const enableCrashlytics = false;
Future<void> startShareLog() async {
  if (!enableCrashlytics) {
    await setReportLogger();
  } else {
    // await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  }
  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = (FlutterErrorDetails e) {
    logger.e(
      "FlutterError: ${e.exception}. line: ${e.library}. summary: ${e.summary}.",
      error: e,
      stackTrace: e.stack,
    );
    if (enableCrashlytics) {
      // FirebaseCrashlytics.instance.recordFlutterFatalError(e);
    }
  };
  // Pass all uncaught asynchronous errors that aren't handled
  // by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    if (error.toString().contains('UUID')) {
      return false;
    }
    reportError(
      "PlatformDispatcher.instance.onError",
      error,
      stackTrace: stack,
    );
    return true;
  };
  // To catch errors that happen outside of the Flutter context,
  // install an error listener on the current Isolate
  Isolate.current.addErrorListener(
    RawReceivePort((pair) async {
      final List<dynamic> errorAndStacktrace = pair;
      reportError(
        "Isolate.errorListener",
        errorAndStacktrace.first,
        stackTrace: errorAndStacktrace.last,
      );
    }).sendPort,
  );
}

Future<void> reportError(
  String message,
  dynamic error, {
  StackTrace? stackTrace,
}) async {
  if (!enableCrashlytics) {
    reportLogger.e(message, error: error, stackTrace: stackTrace);
  } else {
    // await FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
}

Future<void> stopShareLog() async {
  if (!enableCrashlytics) {
    reportLogger.logger = null;
  } else {
    // FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  }
}

Future<void> setDebugLoggerDevlopment() async {
  final logDirPath = getFlutterLogDir().path;
  final l = Logger(
    filter: ProductionFilter(),
    printer: SimplePrinter(
        printTime:
            true) /* PrettyPrinter(
        methodCount: 2, // Number of method calls to be displayed
        errorMethodCount: 8, // Number of method calls if stacktrace is provided
        lineLength: 120, // Width of the output
        // Should each log print contain a timestamp
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
       /*  colors: true */) */
    ,
    output: MultiOutput([
      // if (!kDebugMode)
      AdvancedFileOutput(
        path: logDirPath,
        writeImmediately: [Level.debug],
        latestFileName: 'latest.txt',
      ),
      ConsoleOutput(),
    ]),
    level: Level.debug,
  );
  logger.logger = l;
  logger.d(
    'Logger initialized in debug mode - output to console and file: $logDirPath',
  );
}

Future<void> setReportLogger() async {
  final l = Logger(
    filter: ProductionFilter(),
    printer: PrettyPrinter(
      methodCount: 2, // Number of method calls to be displayed
      errorMethodCount: 8, // Number of method calls if stacktrace is provided
      lineLength: 120, // Width of the output
      // Should each log print contain a timestamp
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: Level.error,
    output: AdvancedFileOutput(
      writeImmediately: [Level.error],
      path: getFlutterLogDir().path,
      latestFileName: 'latest.txt',
      fileNameFormatter: (DateTime date) {
        return '${date.year}-${date.month}-${date.day}.txt';
      },
    ),
  );
  reportLogger.logger = l;
}

class SimplePrinter extends LogPrinter {
  static final levelPrefixes = {
    Level.trace: '[T]',
    Level.debug: '[D]',
    Level.info: '[I]',
    Level.warning: '[W]',
    Level.error: '[E]',
    Level.fatal: '[FATAL]',
  };

  static final levelColors = {
    Level.trace: AnsiColor.fg(AnsiColor.grey(0.5)),
    Level.debug: const AnsiColor.none(),
    Level.info: const AnsiColor.fg(12),
    Level.warning: const AnsiColor.fg(208),
    Level.error: const AnsiColor.fg(196),
    Level.fatal: const AnsiColor.fg(199),
  };

  final bool printTime;
  final bool colors;

  SimplePrinter({this.printTime = false, this.colors = true});

  @override
  List<String> log(LogEvent event) {
    var messageStr = _stringifyMessage(event.message);
    var errorStr = event.error != null ? '  ERROR: ${event.error}' : '';
    var timeStr = printTime ? 'TIME: ${event.time.toIso8601String()}' : '';
    var stackTraceStr =
        event.stackTrace != null ? '\n${event.stackTrace?.toString()}' : '';
    return [
      '${_labelFor(event.level)} $timeStr $messageStr$errorStr$stackTraceStr',
    ];
  }

  String _labelFor(Level level) {
    var prefix = levelPrefixes[level]!;
    var color = levelColors[level]!;

    return colors ? color(prefix) : prefix;
  }

  String _stringifyMessage(dynamic message) {
    final finalMessage = message is Function ? message() : message;
    if (finalMessage is Map || finalMessage is Iterable) {
      var encoder = const JsonEncoder.withIndent(null);
      return encoder.convert(finalMessage);
    } else {
      return finalMessage.toString();
    }
  }
}
