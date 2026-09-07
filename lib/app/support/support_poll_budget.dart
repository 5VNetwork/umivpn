import 'package:shared_preferences/shared_preferences.dart';

const supportNeedPollPreferenceKeyPrefix = 'support.needPoll.';
const supportPollStepPreferenceKeyPrefix = 'support.pollStep.';
const supportLastPollAtPreferenceKeyPrefix = 'support.lastPollAt.';
const supportPollCountPreferenceKeyPrefix = 'support.pollCount.';

/// Backoff schedule + poll budget for non-FCM support reply polling.
///
/// Persists step/count/last-poll so a process restart continues the same
/// schedule instead of starting over.
class SupportPollBudget {
  SupportPollBudget({
    required SharedPreferences preferences,
    required this.userId,
    DateTime Function()? clock,
    this.maxPollCount = defaultMaxPollCount,
    List<Duration>? delays,
  }) : _preferences = preferences,
       _clock = clock ?? DateTime.now,
       delays = List.unmodifiable(delays ?? defaultDelays);

  static const defaultMaxPollCount = 15;

  static const defaultDelays = [
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(minutes: 30),
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(hours: 1),
    Duration(hours: 3),
    Duration(hours: 6),
    Duration(hours: 24),
  ];

  final SharedPreferences _preferences;
  final String userId;
  final DateTime Function() _clock;
  final int maxPollCount;
  final List<Duration> delays;

  int _step = 0;
  int _count = 0;

  int get step => _step;
  int get count => _count;
  bool get isExhausted => _count >= maxPollCount;

  String get _needPollKey => '$supportNeedPollPreferenceKeyPrefix$userId';
  String get _stepKey => '$supportPollStepPreferenceKeyPrefix$userId';
  String get _lastPollAtKey => '$supportLastPollAtPreferenceKeyPrefix$userId';
  String get _countKey => '$supportPollCountPreferenceKeyPrefix$userId';

  bool get needPoll => _preferences.getBool(_needPollKey) == true;

  Future<void> setNeedPoll(bool value) async {
    await _preferences.setBool(_needPollKey, value);
  }

  /// Loads persisted step/count. Clamps step into [0, delays.length).
  void load() {
    final rawStep = _preferences.getInt(_stepKey) ?? 0;
    if (rawStep < 0) {
      _step = 0;
    } else if (rawStep >= delays.length) {
      _step = delays.length - 1;
    } else {
      _step = rawStep;
    }

    final rawCount = _preferences.getInt(_countKey) ?? 0;
    _count = rawCount < 0 ? 0 : rawCount;
  }

  /// How long to wait before the next poll, accounting for time already elapsed
  /// since [lastPollAt]. Overdue polls return [Duration.zero].
  Duration nextWait() {
    final delay = delays[_step];
    if (delay <= Duration.zero) return Duration.zero;

    final lastAt = _lastPollAt();
    if (lastAt == null) return delay;

    final elapsed = _clock().toUtc().difference(lastAt);
    if (elapsed >= delay) return Duration.zero;
    return delay - elapsed;
  }

  /// Records that a poll just ran: bumps count, advances step (until the last
  /// delay, which repeats), and stamps last-poll time.
  Future<void> recordPoll() async {
    _count += 1;
    await _preferences.setInt(_countKey, _count);
    await _preferences.setInt(
      _lastPollAtKey,
      _clock().toUtc().millisecondsSinceEpoch,
    );

    if (_step < delays.length - 1) {
      _step += 1;
      await _preferences.setInt(_stepKey, _step);
    }
  }

  /// Clears step/count/last-poll. Used for fresh user activity, a new agent
  /// reply, or when polling stops for good.
  Future<void> reset() async {
    _step = 0;
    _count = 0;
    await _preferences.setInt(_stepKey, 0);
    await _preferences.setInt(_countKey, 0);
    await _preferences.remove(_lastPollAtKey);
  }

  DateTime? _lastPollAt() {
    final millis = _preferences.getInt(_lastPollAtKey);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }
}
