import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:umivpn/app/manage_plan.dart';
import 'package:umivpn/auth/user.dart';
import 'package:umivpn/common/common.dart';
import 'package:umivpn/main.dart';
import 'package:umivpn/utils/logger.dart';
import 'package:flutter_common/auth/auth_provider.dart';
import 'package:retry/retry.dart';
import 'package:tm/activate.dart';

const webClientId =
    "952575395446-83mgm25olhkcqqm00el2ctv65m7dkpbk.apps.googleusercontent.com";

final iosClientId = debug
    ? "952575395446-8gumjqa4av8akh8cralh8ug8kb2dckci.apps.googleusercontent.com"
    : appFlavor == "staging"
    ? "952575395446-2738klk0hmj1mq9mli50lf1u6gkcmcvi.apps.googleusercontent.com"
    : "952575395446-dts29lpnn4gnn9dbgu2aule8ja6ba7sn.apps.googleusercontent.com";

class AuthRepo extends ChangeNotifier {
  AuthRepo(this._authProvider, FlutterSecureStorage storage) {
    _userSubscription = _authProvider.sessionStreams.listen((session) {
      _user = session?.toUser;
      notifyListeners();
      if (session != null) {
        unawaited(registerUserDevice(supabase, storage));
      }
    });
  }

  User? get user => _user;
  User? _user;

  void setTestUser() {
    _user = const User(
      id: 'test',
      email: 'test@test.com',
      plan: SubscriptionPlan.free,
      cycleEndAt: null,
    );
    notifyListeners();
    // after 5 minutes, set the user to unauthenticated
    Future.delayed(const Duration(minutes: 5), () {
      _user = null;
      notifyListeners();
    });
  }

  Future<void> refreshUser() async {
    await _authProvider.refreshUser();
  }

  UserProfile? get userProfile => _userProfile;
  UserProfile? _userProfile;
  Future<UserProfile?> fetchProfile() async {
    if (_user == null) {
      return null;
    }
    final token = await getValidAccessToken();
    if (token == null) {
      return null;
    }
    try {
      final response = await supabase.functions.invoke(
        'get-profile',
        headers: {
          'Authorization': 'Bearer $token',
          'User-Agent': 'UmiVPN/$version',
        },
      );
      if (response.status != 200 || response.data == null) {
        throw Exception(
          'get-profile failed: ${response.status} ${response.data}',
        );
      }
      final profile = UserProfile.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      _userProfile = profile;
      _updateStaleUser(profile);
      return profile;
    } catch (e, stackTrace) {
      logger.e('Error fetching profile', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  void _updateStaleUser(UserProfile profile) {
    // this means user data is old, so refresh session
    // This happens when a user upgrades or downgrades their plan, but the session hasn't been refreshed yet
    if (_user!.plan != profile.plan) {
      logger.w('User plan has changed, updating user');
      _user = _user!.copyWith(
        plan: profile.plan,
        cycleEndAt: profile.cycleEndAt,
      );
      notifyListeners();
      _authProvider.refreshUser();
    }
  }

  final AuthProvider _authProvider;
  late final StreamSubscription<Session?> _userSubscription;
  late String deviceToken;

  /// Returns a non-expired access token, refreshing the Supabase session
  /// when the current one is expired or about to expire.
  Future<String?> getValidAccessToken() async {
    var session = _authProvider.currentSession;
    if (session == null) {
      return null;
    }
    // Refresh a bit before the actual expiry to avoid races with the server.
    const skewSeconds = 60;
    final expiresAt = session.expiresAt;
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final needsRefresh =
        session.isExpired ||
        (expiresAt != null && expiresAt - nowSeconds <= skewSeconds);
    if (needsRefresh) {
      try {
        logger?.i('Refreshing Supabase session');
        await _authProvider.refreshUser();
        session = _authProvider.currentSession;
      } catch (e) {
        logger?.e('Failed to refresh Supabase session', error: e);
        return null;
      }
    }
    return session?.accessToken;
  }

  Future<SubscriptionInfo?> fetchSubscriptionInfo() async {
    if (_user == null) {
      return null;
    }
    final token = await getValidAccessToken();
    if (token == null) {
      return null;
    }

    try {
      final response = await supabase.functions.invoke(
        'get-profile',
        headers: {
          'Authorization': 'Bearer $token',
          'User-Agent': 'UmiVPN/$version',
        },
        body: {'include_subscription': true},
      );
      if (response.status != 200 || response.data == null) {
        logger.e(
          'get-profile (subscription) failed',
          error: '${response.status} ${response.data}',
        );
        return null;
      }

      final data = Map<String, dynamic>.from(response.data as Map);
      _updateStaleUser(UserProfile.fromJson(data));

      SubscriptionInfo? subInfo;
      final subscriptionsData = data['subscriptions'];

      Map<String, dynamic>? subscriptionRow;
      if (subscriptionsData is List && subscriptionsData.isNotEmpty) {
        subscriptionRow = Map<String, dynamic>.from(
          subscriptionsData.first as Map,
        );
      } else if (subscriptionsData is Map) {
        subscriptionRow = Map<String, dynamic>.from(subscriptionsData);
      }

      if (subscriptionRow != null && subscriptionRow.isNotEmpty) {
        final periodEndAt = DateTime.parse(
          subscriptionRow['period_end_at'] as String,
        );
        final source = _parseSubscriptionSource(
          subscriptionRow['source'] as String,
        );

        final (SubscriptionPlan, Period) planAndPeriod = _parsePeriod(
          subscriptionRow['product_id'] as String,
          source,
        );

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
    String productId,
    SubscriptionSource source,
  ) {
    switch (source) {
      case SubscriptionSource.appStore ||
          SubscriptionSource.playStore ||
          SubscriptionSource.stripe ||
          SubscriptionSource.others:
        switch (productId) {
          case 'umivpn_air_month' || 'umi_air_month':
            return (SubscriptionPlan.air, Period.month);
          case 'umivpn_air_year' || 'umi_air_year':
            return (SubscriptionPlan.air, Period.year);
          case 'umivpn_pro_month' || 'umi_pro_month':
            return (SubscriptionPlan.pro, Period.month);
          case 'umivpn_pro_year' || 'umi_pro_year':
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
        return SubscriptionSource.others;
    }
  }

  @override
  void dispose() {
    _userSubscription.cancel();
    return super.dispose();
  }
}

class SubscriptionInfo {
  const SubscriptionInfo({
    required this.planAndPeriod,
    required this.source,
    required this.periodEndAt,
    required this.isCanceled,
    this.nextPlanAndPeriod,
  });

  final (SubscriptionPlan, Period) planAndPeriod;
  final SubscriptionSource source;
  final DateTime periodEndAt;
  final bool isCanceled;
  final (SubscriptionPlan, Period)? nextPlanAndPeriod;
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    this.stripeCustomerId,
    required this.plan,
    required this.remainingData,
    this.cycleEndAt,
    this.subscriptionId,
    required this.dataUsed,
  });

  final String id;
  final String email;
  final String? stripeCustomerId;
  final SubscriptionPlan plan;
  final int remainingData;
  final DateTime? cycleEndAt;
  final String? subscriptionId;
  final int dataUsed;

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.tryParse(value.toString());
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final remainingData = json['remaining_data'];
    final dataUsed = json['data_used'];
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      stripeCustomerId: json['stripe_customer_id'] as String?,
      plan: SubscriptionPlan.fromString((json['plan'] as String)),
      remainingData: remainingData is int
          ? remainingData
          : int.parse(remainingData.toString()),
      cycleEndAt: _parseDateTime(json['cycle_end_at']),
      subscriptionId: json['subscription_id'] as String?,
      dataUsed: dataUsed is int ? dataUsed : int.parse(dataUsed.toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'stripe_customer_id': stripeCustomerId,
      'plan': plan.name.toLowerCase(),
      'remaining_data': remainingData,
      'cycle_end_at': cycleEndAt?.toIso8601String(),
      'subscription_id': subscriptionId,
      'data_used': dataUsed,
    };
  }
}
