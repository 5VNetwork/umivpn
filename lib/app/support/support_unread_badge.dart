import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umivpn/app/support/support_chat_repository.dart';
import 'package:umivpn/app/support/support_notification.dart';
import 'package:umivpn/app/support/support_poll_budget.dart';
import 'package:umivpn/common/common.dart';
import 'package:umivpn/l10n/app_localizations.dart';
import 'package:umivpn/main.dart';
import 'package:umivpn/utils/logger.dart';
import 'package:window_manager/window_manager.dart';

const supportUnreadNeedsRefreshPreferenceKey =
    'support.unreadBadge.needsRefresh';

/// Persists across restarts. Cleared only when the user opens/reads support.
const supportUnreadHasUnreadPreferenceKey = 'support.unreadBadge.hasUnread';

class SupportUnreadBadgeController extends ChangeNotifier
    with WidgetsBindingObserver {
  SupportUnreadBadgeController({
    SupabaseClient? client,
    SharedPreferences? preferences,
    SupportChatRepository? repository,
  }) : _client = client ?? supabase,
       _repository = repository ?? SupportChatRepository(client: client),
       _preferencesFuture = preferences == null
           ? SharedPreferences.getInstance()
           : Future.value(preferences);

  final SupabaseClient _client;
  final SupportChatRepository _repository;
  final Future<SharedPreferences> _preferencesFuture;
  bool _hasUnread = false;
  bool _started = false;
  bool _waitingForReply = false;
  bool _pollInFlight = false;
  SupportPollBudget? _budget;
  Timer? _pollTimer;
  StreamSubscription<AuthState>? _authSubscription;
  bool get hasUnread => _hasUnread;

  @visibleForTesting
  bool get isPolling => _waitingForReply && _pollTimer != null;

  @visibleForTesting
  SupportPollBudget? get debugBudget => _budget;

  void start() {
    if (_started) return;
    _started = true;

    WidgetsBinding.instance.addObserver(this);
    _authSubscription = _client.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        unawaited(_restorePersistedUnread());
        unawaited(refreshIfNeeded());
        unawaited(_syncWaitingPoll());
      } else {
        _stopPoll();
        _setHasUnread(false);
      }
    });
    if (_client.auth.currentSession != null) {
      unawaited(_restorePersistedUnread());
      unawaited(refreshIfNeeded());
      unawaited(_syncWaitingPoll());
    }
  }

  Future<void> _restorePersistedUnread() async {
    final preferences = await _preferencesFuture;
    await preferences.reload();
    if (preferences.getBool(supportUnreadHasUnreadPreferenceKey) == true) {
      _setHasUnread(true, persist: false);
    }
  }

  /// Remember that a conversation exists so we can poll after leaving chat.
  /// [needPoll] is kept even when FCM works, so polling can start later if the
  /// user turns notifications off.
  void markConversationActive() {
    if (_client.auth.currentSession == null) return;
    unawaited(() async {
      final budget = await _budgetForCurrentUser();
      if (budget == null) return;
      await budget.setNeedPoll(true);
      // Fresh activity: start the backoff over from the first delay.
      await budget.reset();
    }());
  }

  /// Start backoff polling when the user leaves chat (or on app start).
  void startPollingIfNeeded() {
    if (_client.auth.currentSession == null) return;
    if (_isOnSupportChat()) return;
    unawaited(_syncWaitingPoll());
  }

  /// Chat page is open; its own watch covers new messages.
  void pausePolling() {
    _stopPoll();
  }

  /// Conversation deleted or poll budget exhausted — stop polling for good.
  void stopWaitingForReply() {
    unawaited(() async {
      final budget = await _budgetForCurrentUser();
      if (budget != null) {
        await budget.setNeedPoll(false);
        await budget.reset();
      }
    }());
    _stopPoll();
  }

  Future<void> refreshIfNeeded() async {
    logger.d('refreshIfNeeded');
    final preferences = await _preferencesFuture;
    await preferences.reload();
    if (preferences.getBool(supportUnreadNeedsRefreshPreferenceKey) != true) {
      return;
    }

    await refresh();
    await preferences.setBool(supportUnreadNeedsRefreshPreferenceKey, false);
  }

  Future<String?> refresh() async {
    final userId = _client.auth.currentUser?.id;
    if (_client.auth.currentSession == null || userId == null) {
      _setHasUnread(false);
      return null;
    }

    try {
      String? preview;
      for (final message in await _repository.fetchMissedMessages()) {
        if (message.isFromSupport) {
          preview = message.content;
        }
      }
      if (preview != null) {
        // Fetch advances the local watermark; persist so a restart still shows
        // the dot until the user opens/reads support.
        _setHasUnread(true);
        // Agent activity: drop back to the fast end of the backoff schedule.
        final budget = await _budgetForCurrentUser();
        await budget?.reset();
      }
      // Do not clear on empty: watermark may already be past unread messages.
      return preview;
    } catch (error, stack) {
      logger.e(
        'Support unread refresh failed',
        error: error,
        stackTrace: stack,
      );
      return null;
    }
  }

  void showUnreadDot() {
    _setHasUnread(true);
  }

  /// Unread badge plus an in-app banner (or system notification if not focused).
  void notifySupportReply({String? preview}) {
    if (_isOnSupportChat()) {
      clear();
      return;
    }
    showUnreadDot();
    unawaited(_informUser(preview));
  }

  void clear() {
    unawaited(_clearPersistedUnreadFlags());
    unawaited(cancelSupportReplyNotification());
    _setHasUnread(false, persist: false);
  }

  Future<void> _clearPersistedUnreadFlags() async {
    final preferences = await _preferencesFuture;
    await preferences.setBool(supportUnreadNeedsRefreshPreferenceKey, false);
    await preferences.setBool(supportUnreadHasUnreadPreferenceKey, false);
  }

  void _setHasUnread(bool value, {bool persist = true}) {
    if (_hasUnread == value) {
      if (persist) {
        unawaited(_persistHasUnread(value));
      }
      return;
    }
    _hasUnread = value;
    notifyListeners();
    if (persist) {
      unawaited(_persistHasUnread(value));
    }
  }

  Future<void> _persistHasUnread(bool value) async {
    final preferences = await _preferencesFuture;
    await preferences.setBool(supportUnreadHasUnreadPreferenceKey, value);
  }

  Future<SupportPollBudget?> _budgetForCurrentUser() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return null;

    if (_budget?.userId == userId) return _budget;

    final preferences = await _preferencesFuture;
    _budget = SupportPollBudget(preferences: preferences, userId: userId);
    _budget!.load();
    return _budget;
  }

  Future<void> _syncWaitingPoll() async {
    if (_client.auth.currentSession == null) return;
    if (await canRelyOnFcmForSupportUnread()) {
      _stopPoll();
      return;
    }
    if (_isOnSupportChat()) return;
    final budget = await _budgetForCurrentUser();
    if (budget == null || !budget.needPoll) {
      _stopPoll();
      return;
    }
    _waitingForReply = true;
    await _startPoll(budget);
  }

  Future<void> _startPoll(SupportPollBudget budget) async {
    if (await canRelyOnFcmForSupportUnread()) {
      _stopPoll();
      return;
    }
    if (_pollTimer != null) return;

    budget.load();
    if (budget.isExhausted) {
      stopWaitingForReply();
      return;
    }
    await _schedulePollStep(budget);
  }

  Future<void> _schedulePollStep(SupportPollBudget budget) async {
    if (!_waitingForReply) return;

    final wait = budget.nextWait();
    _pollTimer = Timer(wait, () => unawaited(_onPollTimer(budget)));
  }

  Future<void> _onPollTimer(SupportPollBudget budget) async {
    _pollTimer = null;
    if (!_waitingForReply) return;
    await _pollOnce();
    if (!_waitingForReply) return;

    await budget.recordPoll();
    if (budget.isExhausted) {
      logger.d('Support poll budget exhausted (${budget.maxPollCount})');
      stopWaitingForReply();
      return;
    }

    await _schedulePollStep(budget);
  }

  void _stopPoll() {
    _waitingForReply = false;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _pollOnce() async {
    if (!_waitingForReply || _pollInFlight) return;
    logger.d('pollOnce');
    _pollInFlight = true;
    try {
      final wasUnread = _hasUnread;
      final status = await _repository.fetchConversationStatus();
      final preview = await refresh();

      if (status == null) {
        logger.d('status is null. Stopping poll and forgetting conversation');
        _repository.forgetConversation();
        stopWaitingForReply();
      }

      if (_isOnSupportChat()) return;
      if (_hasUnread && !wasUnread) {
        await _informUser(preview ?? status?.lastMessage);
      }
    } catch (error, stack) {
      logger.e('Support wait poll failed', error: error, stackTrace: stack);
    } finally {
      _pollInFlight = false;
    }
  }

  bool _isOnSupportChat() {
    try {
      return router.routeInformationProvider.value.uri.path.endsWith(
        '/supportChat',
      );
    } catch (_) {
      return false;
    }
  }

  bool _supportReplyDialogShowing = false;

  /// A dialog is useless when the app sits in the tray or the background, so
  /// fall back to a system notification unless focused.
  Future<void> _informUser(String? preview) async {
    if (!await _appIsInForeground()) {
      await showSupportReplyNotification(preview: preview);
      return;
    }
    final ctx = rootNavigationKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    if (_supportReplyDialogShowing) return;

    final l10n = AppLocalizations.of(ctx);
    final title = l10n?.supportReplied ?? 'Support replied';
    final body = preview?.replaceAll(RegExp(r'\s+'), ' ').trim();
    final bodyText = (body == null || body.isEmpty)
        ? null
        : (body.length <= 120 ? body : '${body.substring(0, 117)}...');

    _supportReplyDialogShowing = true;
    await showDialog<void>(
      context: ctx,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.support_agent),
          title: Text(title),
          content: bodyText == null ? null : Text(bodyText),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n?.close ?? 'Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                clear();
                router.go('/supportChat');
              },
              child: Text(l10n?.openSupportChat ?? 'Open'),
            ),
          ],
        );
      },
    ).whenComplete(() {
      _supportReplyDialogShowing = false;
    });
  }

  Future<bool> _appIsInForeground() async {
    if (desktopPlatforms) {
      // Desktop lifecycle events are unreliable while the window is hidden to
      // the tray, so ask the window itself.
      try {
        return await windowManager.isVisible() &&
            await windowManager.isFocused();
      } catch (error) {
        logger.e('Failed to read window visibility', error: error);
        return false;
      }
    }
    return WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    logger.d('!!!didChangeAppLifecycleState: $state');
    if (state == AppLifecycleState.resumed) {
      unawaited(refreshIfNeeded());
      // Permission may have changed in Settings; start or stop polling.
      unawaited(_syncWaitingPoll());
    }
  }

  @override
  void dispose() {
    _stopPoll();
    _authSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class SupportUnreadIconButton extends StatelessWidget {
  const SupportUnreadIconButton({
    super.key,
    required this.route,
    required this.icon,
    this.iconColor,
  });

  final String route;
  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final hasUnread = context.select<SupportUnreadBadgeController, bool>(
      (controller) => controller.hasUnread,
    );

    return IconButton(
      tooltip: AppLocalizations.of(context)!.contactUs,
      onPressed: () {
        context.read<SupportUnreadBadgeController>().clear();
        context.go(route);
      },
      icon: Badge(
        isLabelVisible: hasUnread,
        smallSize: 8,
        backgroundColor: Colors.redAccent,
        child: Icon(icon, color: iconColor),
      ),
    );
  }
}
