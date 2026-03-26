import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_common/util/jwt.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_common/util/net.dart';
import 'package:umivpn/common/common.dart';
import 'package:umivpn/utils/logger.dart';

enum SubscriptionPlan {
  free,
  air,
  pro,
  ;

  String get name => switch (this) {
        free => 'Free',
        air => 'Air',
        pro => 'Pro',
      };

  int get data => 1024 * 1024 * 1024;

  static SubscriptionPlan fromString(String plan) {
    return switch (plan) {
      'free' => free,
      'air' => air,
      'pro' => pro,
      _ => free,
    };
  }
}

enum SubscriptionSource {
  stripe,
  playStore,
  appStore;

  String get name => switch (this) {
        stripe => 'Stripe',
        playStore => 'Play Store',
        appStore => 'App Store',
      };
}

class User extends Equatable {
  const User(
      {required this.id,
      required this.email,
      required this.plan,
      this.cycleEndAt});
  final String id;
  final String email;
  final SubscriptionPlan plan;
  final DateTime? cycleEndAt;

  User copyWith({
    String? id,
    String? email,
    SubscriptionPlan? plan,
    DateTime? cycleEndAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      plan: plan ?? this.plan,
      cycleEndAt: cycleEndAt ?? this.cycleEndAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        plan,
        cycleEndAt,
      ];
}

extension UserExtension on Session {
  User get toUser {
    // Decode the access token to get custom claims
    final claims = decodeJwt(accessToken);
    logger.d('JWT claims: $claims');

    // Extract the 'pro' claim from JWT
    final plan = claims['plan'] as String? ?? 'free';
    final cycleEndAt = claims['cycle_end_at'] as int?;
    return User(
      id: user.id,
      email: user.email!,
      plan: SubscriptionPlan.fromString(plan),
      cycleEndAt: cycleEndAt != null
          ? DateTime.fromMillisecondsSinceEpoch(cycleEndAt * 1000)
          : null,
    );
  }
}
