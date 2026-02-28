import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_common/util/net.dart';
import 'package:umivpn/common/common.dart';

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

  int get data => 0;
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
  const User({required this.id, required this.email});
  final String id;
  final String email;

  @override
  List<Object?> get props => [
        id,
        email,
      ];
}

extension UserExtension on Session {
  User get toUser => User(id: user.id, email: user.email!);
}
