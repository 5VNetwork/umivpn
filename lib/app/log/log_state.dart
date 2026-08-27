part of 'log_bloc.dart';

class LogState {
  const LogState({
    required this.enableLog,
    required this.logs,
    required this.filter,
    this.showApp = true,
    this.showSessionOngoing = true,
    this.showRealtimeUsage = false,
    this.dismissDuplicateSessions = true,
  });
  final bool enableLog;
  final LogFilter filter;
  final CircularBuffer<XLog> logs;
  final bool showApp;
  final bool showSessionOngoing;
  final bool showRealtimeUsage;
  final bool dismissDuplicateSessions;

  LogState copyWith({
    bool? enableLog,
    CircularBuffer<XLog>? logs,
    LogFilter? filter,
    bool? showApp,
    bool? showHandler,
    bool? showSessionOngoing,
    bool? showRealtimeUsage,
    bool? dismissDuplicateSessions,
  }) {
    return LogState(
      enableLog: enableLog ?? this.enableLog,
      logs: logs ?? this.logs,
      filter: filter ?? this.filter,
      showApp: showApp ?? this.showApp,
      showSessionOngoing: showSessionOngoing ?? this.showSessionOngoing,
      showRealtimeUsage: showRealtimeUsage ?? this.showRealtimeUsage,
      dismissDuplicateSessions:
          dismissDuplicateSessions ?? this.dismissDuplicateSessions,
    );
  }
}

class LogFilter {
  const LogFilter({
    required this.showDirect,
    required this.showProxy,
    required this.errorOnly,
    this.substring = "",
    this.showReject = true,
  });
  final bool showDirect;
  final bool showProxy;
  final String substring;
  final bool errorOnly;
  final bool showReject;

  LogFilter copyWith({
    bool? isDirectSelected,
    bool? isProxySelected,
    String? substring,
    bool? errorOnly,
    bool? showReject,
  }) {
    return LogFilter(
      showDirect: isDirectSelected ?? showDirect,
      showProxy: isProxySelected ?? showProxy,
      substring: substring ?? this.substring,
      errorOnly: errorOnly ?? this.errorOnly,
      showReject: showReject ?? this.showReject,
    );
  }

  bool showAll() {
    return showDirect &&
        showProxy &&
        substring.isEmpty &&
        !errorOnly &&
        showReject;
  }

  bool show(XLog log) {
    if (log is SessionInfo) {
      if (!showDirect && log.tag == 'direct') {
        return false;
      }
      if (log.tag != 'direct' && !showProxy) {
        return false;
      }
      if (substring.isNotEmpty) {
        if (!log.displayDst.contains(substring)) {
          return false;
        }
      }
      if (errorOnly && !log.abnormal) {
        return false;
      }
      return true;
    } else if (log is RejectMessage && showReject) {
      if (substring.isNotEmpty) {
        if (!log.displayDst.contains(substring)) {
          return false;
        }
      }
      return true;
    }
    return false;
  }
}
