import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umivpn/l10n/app_localizations.dart';
import 'package:umivpn/main.dart';
import 'package:umivpn/utils/logger.dart';

const supportUnreadNeedsRefreshPreferenceKey =
    'support.unreadBadge.needsRefresh';

class SupportUnreadBadgeController extends ChangeNotifier
    with WidgetsBindingObserver {
  SupportUnreadBadgeController({
    SupabaseClient? client,
    SharedPreferences? preferences,
  }) : _client = client ?? supabase,
       _preferencesFuture = preferences == null
           ? SharedPreferences.getInstance()
           : Future.value(preferences);

  final SupabaseClient _client;
  final Future<SharedPreferences> _preferencesFuture;
  bool _hasUnread = false;
  bool _started = false;
  bool get hasUnread => _hasUnread;

  void start() {
    if (_started) return;
    _started = true;

    WidgetsBinding.instance.addObserver(this);
    if (_client.auth.currentSession != null) {
      unawaited(refreshIfNeeded());
    }
  }

  Future<void> refreshIfNeeded() async {
    logger.d('refreshIfNeeded');
    final preferences = await _preferencesFuture;
    if (preferences.getBool(supportUnreadNeedsRefreshPreferenceKey) != true) {
      return;
    }

    await refresh();
    await preferences.setBool(supportUnreadNeedsRefreshPreferenceKey, false);
  }

  Future<void> refresh() async {
    final userId = _client.auth.currentUser?.id;
    if (_client.auth.currentSession == null || userId == null) {
      _setHasUnread(false);
      return;
    }

    final rows = await _client
        .from('support_messages')
        .select('id')
        .eq('user_id', userId)
        .eq('is_from_support', true)
        .eq('user_read', false)
        .limit(1);

    _setHasUnread(rows.isNotEmpty);
  }

  void showUnreadDot() {
    _setHasUnread(true);
  }

  void clear() {
    unawaited(_clearNeedsRefresh());
    _setHasUnread(false);
  }

  Future<void> _clearNeedsRefresh() async {
    final preferences = await _preferencesFuture;
    await preferences.setBool(supportUnreadNeedsRefreshPreferenceKey, false);
  }

  void _setHasUnread(bool value) {
    if (_hasUnread == value) return;
    _hasUnread = value;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    logger.d('!!!didChangeAppLifecycleState: $state');
    if (state == AppLifecycleState.resumed) {
      unawaited(refreshIfNeeded());
    }
  }

  @override
  void dispose() {
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
    if (!fcmEnabled) {
      return IconButton(
        tooltip: AppLocalizations.of(context)!.contactUs,
        onPressed: () {
          context.read<SupportUnreadBadgeController>().clear();
          context.go(route);
        },
        icon: Icon(icon, color: iconColor),
      );
    }

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
