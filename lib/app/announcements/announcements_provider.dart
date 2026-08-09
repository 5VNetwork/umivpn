import 'dart:convert';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_common/services/periodic.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umivpn/app/announcements/announcement.dart';
import 'package:umivpn/app/announcements/announcements_service.dart';
import 'package:umivpn/utils/logger.dart';

const _lastSeenPublishedAtKey = 'announcements.lastSeenPublishedAt';
const _cachedMessagesKey = 'announcements.cachedMessages';
const _cachedLocaleKey = 'announcements.cachedLocale';
const _lastRunKey = 'announcements.lastFetch';

class AnnouncementsProvider extends ChangeNotifier {
  AnnouncementsProvider({
    required SharedPreferences preferences,
    AnnouncementsService? service,
    Duration period = const Duration(hours: 6),
  }) : _preferences = preferences,
       _service = service ?? AnnouncementsService() {
    _loadCache();
    _periodicTask = PeriodicTask(
      sharedPreferences: preferences,
      period: period,
      lastRunKey: _lastRunKey,
      task: () => refresh(force: true),
    );
  }

  final SharedPreferences _preferences;
  final AnnouncementsService _service;
  late final PeriodicTask _periodicTask;

  List<Announcement> _messages = const [];
  bool _loading = false;
  String? _error;
  DateTime? _lastSeenPublishedAt;
  bool _started = false;
  String? _locale;

  List<Announcement> get messages => _messages;
  bool get loading => _loading;
  String? get error => _error;
  int get unreadCount {
    if (_messages.isEmpty) return 0;
    final lastSeen = _lastSeenPublishedAt;
    if (lastSeen == null) return 0;
    return _messages.where((m) => m.publishedAt.isAfter(lastSeen)).length;
  }

  bool get hasUnread => unreadCount > 0;

  void start({String? locale}) {
    if (_started) return;
    _started = true;
    _locale = locale ?? PlatformDispatcher.instance.locale.languageCode;
    _periodicTask.start();
  }

  void updateLocale(String locale) {
    _locale = locale;
  }

  Future<void> refresh({bool force = false}) async {
    if (_loading) return;
    if (!force && _messages.isNotEmpty) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final locale = _locale ?? PlatformDispatcher.instance.locale.languageCode;
      final fetched = await _service.fetch(locale);
      _messages = fetched;
      _locale = locale;
      await _persistCache();
      _error = null;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to fetch announcements',
        error: e,
        stackTrace: stackTrace,
      );
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    if (_messages.isEmpty) {
      _lastSeenPublishedAt = DateTime.now().toUtc();
    } else {
      _lastSeenPublishedAt = _messages
          .map((m) => m.publishedAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
    }
    await _preferences.setString(
      _lastSeenPublishedAtKey,
      _lastSeenPublishedAt!.toIso8601String(),
    );
    notifyListeners();
  }

  void _loadCache() {
    final lastSeen = _preferences.getString(_lastSeenPublishedAtKey);
    if (lastSeen != null) {
      _lastSeenPublishedAt = DateTime.tryParse(lastSeen)?.toUtc();
    }
    // New install: baseline = now so existing announcements aren't unread.
    if (_lastSeenPublishedAt == null) {
      _lastSeenPublishedAt = DateTime.now().toUtc();
      _preferences.setString(
        _lastSeenPublishedAtKey,
        _lastSeenPublishedAt!.toIso8601String(),
      );
    }

    final cached = _preferences.getString(_cachedMessagesKey);
    if (cached == null) return;
    try {
      _messages = AnnouncementsService.parseAnnouncementsJson(cached);
      _locale = _preferences.getString(_cachedLocaleKey);
    } catch (e, stackTrace) {
      logger.e(
        'Failed to load cached announcements',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _persistCache() async {
    await _preferences.setString(
      _cachedMessagesKey,
      json.encode({
        'messages': _messages.map((m) => m.toJson()).toList(),
      }),
    );
    if (_locale != null) {
      await _preferences.setString(_cachedLocaleKey, _locale!);
    }
  }

  @override
  void dispose() {
    _periodicTask.stop();
    super.dispose();
  }
}
