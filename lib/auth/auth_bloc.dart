import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:umivpn/app/manage_plan.dart';
import 'package:umivpn/auth/user.dart';
import 'package:umivpn/main.dart';
import 'package:umivpn/utils/logger.dart';
import 'package:flutter_common/auth/auth_provider.dart';
import 'package:retry/retry.dart';

const webClientId =
    "952575395446-83mgm25olhkcqqm00el2ctv65m7dkpbk.apps.googleusercontent.com";

const iosClientId =
    "952575395446-dts29lpnn4gnn9dbgu2aule8ja6ba7sn.apps.googleusercontent.com";

class AuthRepo extends ChangeNotifier {
  AuthRepo(this._authProvider) {
    _userSubscription = _authProvider.sessionStreams.listen(
      (user) {
        _user = user?.toUser;
        _fetchProfile();
        notifyListeners();
      },
    );
    _startPeriodicProfileFetch();
  }

  User? get user => _user;
  User? _user;

  UserProfile? get userProfile => _userProfile;
  UserProfile? _userProfile;

  void setTestUser() {
    _user = const User(id: 'test', email: 'test@test.com');
    notifyListeners();
    // after 5 minutes, set the user to unauthenticated
    Future.delayed(const Duration(minutes: 5), () {
      _user = null;
      notifyListeners();
    });
  }

  final AuthProvider _authProvider;
  late final StreamSubscription<Session?> _userSubscription;
  Timer? _profileFetchTimer;
  late String deviceToken;

  Future<String?> getAccessToken() async {
    return _authProvider.currentSession?.accessToken;
  }

  void _startPeriodicProfileFetch() async {
    // Fetch immediately if user is authenticated
    if (_user != null) {
      unawaited(
          retry(() => _fetchProfile(), retryIf: (_) => true, maxAttempts: 5));
    }
    // Then fetch every 5 minutes
    _profileFetchTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) {
        if (_user != null) {
          _fetchProfile();
        }
      },
    );
  }

  Future<void> _fetchProfile() async {
    if (_user == null) {
      return;
    }

    final userId = _user!.id;
    try {
      final response =
          await supabase.from('profiles').select().eq('id', userId).single();
      print(response);
      final remainingData = response['remaining_data'] as int;
      final plan = _parseSubscriptionPlan(response['plan'] as String);

      _userProfile = UserProfile(
        subscriptionPlan: plan,
        remainingData: remainingData,
        cycleEndAt: response['cycle_end_at'] != null
            ? DateTime.parse(response['cycle_end_at'] as String)
            : null,
      );
      notifyListeners();
    } catch (e, stackTrace) {
      logger.e('Error fetching profile', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<SubscriptionInfo?> fetchSubscriptionInfo() async {
    if (_user == null) {
      return null;
    }
    final userId = _user!.id;

    try {
      // Join profiles with subscriptions to fetch profile and its active subscription
      final response = await supabase
          .from('profiles')
          .select('*, subscriptions(*)')
          .eq('id', userId)
          .single();

      // --- Parse profile data ---
      final remainingData = response['remaining_data'] as int;
      final plan = _parseSubscriptionPlan(response['plan'] as String);
      final cycleEndAt = response['cycle_end_at'] != null
          ? DateTime.parse(response['cycle_end_at'] as String)
          : null;
      final subscriptionId = response['subscription_id'] as String?;

      _userProfile = UserProfile(
        subscriptionPlan: plan,
        remainingData: remainingData,
        cycleEndAt: cycleEndAt,
        subscriptionId: subscriptionId,
      );
      notifyListeners();

      // --- Parse subscription data (active subscription) ---
      SubscriptionInfo? subInfo;
      final subscriptionsData = response['subscriptions'];

      Map<String, dynamic>? subscriptionRow;
      if (subscriptionsData is List && subscriptionsData.isNotEmpty) {
        subscriptionRow = subscriptionsData.first as Map<String, dynamic>;
      } else if (subscriptionsData is Map) {
        subscriptionRow = subscriptionsData as Map<String, dynamic>;
      }

      if (subscriptionRow != null && subscriptionRow.isNotEmpty) {
        final periodEndAt =
            DateTime.parse(subscriptionRow['period_end_at'] as String);
        final source =
            _parseSubscriptionSource(subscriptionRow['source'] as String);

        final (SubscriptionPlan, Period) planAndPeriod =
            _parsePeriod(subscriptionRow['product_id'] as String, source);

        (SubscriptionPlan, Period)? nextPlanAndPeriod;
        if (subscriptionRow['next_product_id'] != null) {
          final nextProductId = subscriptionRow['next_product_id'] as String;
          nextPlanAndPeriod = _parsePeriod(nextProductId, source);
        }

        subInfo = SubscriptionInfo(
          planAndPeriod: planAndPeriod,
          source: source,
          periodEndAt: periodEndAt,
          isCanceled: subscriptionRow['canceled'] as bool,
          nextPlanAndPeriod: nextPlanAndPeriod,
        );
      }
      return subInfo;
    } catch (e) {
      logger.e('Error fetching subscription info', error: e);
      return null;
    }
  }

  (SubscriptionPlan, Period) _parsePeriod(
      String productId, SubscriptionSource source) {
    switch (source) {
      case SubscriptionSource.appStore ||
            SubscriptionSource.playStore ||
            SubscriptionSource.stripe:
        switch (productId) {
          case 'umivpn_air_month':
            return (SubscriptionPlan.air, Period.month);
          case 'umivpn_air_year':
            return (SubscriptionPlan.air, Period.year);
          case 'umivpn_pro_month':
            return (SubscriptionPlan.pro, Period.month);
          case 'umivpn_pro_year':
            return (SubscriptionPlan.pro, Period.year);
          default:
            throw Exception('Invalid productId: $productId');
        }
      default:
        throw Exception('Invalid source: $source');
    }
  }

  SubscriptionPlan _parseSubscriptionPlan(String plan) {
    switch (plan.toLowerCase()) {
      case 'free':
        return SubscriptionPlan.free;
      case 'air':
        return SubscriptionPlan.air;
      case 'pro':
        return SubscriptionPlan.pro;
      default:
        throw Exception('Invalid subscription plan: $plan');
    }
  }

  SubscriptionSource _parseSubscriptionSource(String source) {
    switch (source.toLowerCase()) {
      case 'stripe':
        return SubscriptionSource.stripe;
      case 'play_store':
        return SubscriptionSource.playStore;
      case 'app_store':
        return SubscriptionSource.appStore;
      default:
        throw Exception('Invalid subscription source: $source');
    }
  }

  @override
  void dispose() {
    _userSubscription.cancel();
    _profileFetchTimer?.cancel();
    return super.dispose();
  }
}

class SubscriptionInfo {
  const SubscriptionInfo(
      {required this.planAndPeriod,
      required this.source,
      required this.periodEndAt,
      required this.isCanceled,
      this.nextPlanAndPeriod});

  final (SubscriptionPlan, Period) planAndPeriod;
  final SubscriptionSource source;
  final DateTime periodEndAt;
  final bool isCanceled;
  final (SubscriptionPlan, Period)? nextPlanAndPeriod;
}

class UserProfile {
  const UserProfile({
    required this.subscriptionPlan,
    required this.remainingData,
    required this.cycleEndAt,
    this.subscriptionId,
  });

  final SubscriptionPlan subscriptionPlan;
  final int remainingData;
  final DateTime? cycleEndAt;
  final String? subscriptionId;

  DateTime get refreshDate {
    if (subscriptionPlan == SubscriptionPlan.free) {
      return DateTime(DateTime.now().year, DateTime.now().month + 1, 1);
    }
    return cycleEndAt!;
  }
}
