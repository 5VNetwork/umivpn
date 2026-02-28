import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tm/protos/api/api.pb.dart';
import 'package:tm/protos/protos/outbound.pb.dart';
import 'package:tm/x_controller.dart';
import 'package:tm/xapi_client.dart';
import 'package:tm/xconfig_helper.dart';
import 'package:umivpn/auth/auth_bloc.dart';
import 'package:umivpn/auth/user.dart';
import 'package:umivpn/common/common.dart';
import 'package:umivpn/l10n/app_localizations.dart';
import 'package:umivpn/main.dart';
import 'package:umivpn/pref_helper.dart';
import 'package:umivpn/utils/logger.dart';
import 'package:flutter_common/auth/auth_provider.dart';
import 'package:tm/default.dart';
import 'package:equatable/equatable.dart';

class Choice extends Equatable {
  final String country;
  final DefaultRouteMode routeMode;
  // when country is auto, this is the actual country that the user is connected to
  final String? realtimeCountry;

  Choice({
    required this.country,
    required this.routeMode,
    this.realtimeCountry,
  });

  @override
  List<Object?> get props => [country, routeMode, realtimeCountry];

  Choice copyWith({
    XStatus? status,
    String? country,
    DefaultRouteMode? routeMode,
    ValueGetter<String?>? realtimeCountry,
  }) {
    return Choice(
      country: country ?? this.country,
      routeMode: routeMode ?? this.routeMode,
      realtimeCountry:
          realtimeCountry != null ? realtimeCountry() : this.realtimeCountry,
    );
  }
}

class ChoiceCubit extends Cubit<Choice> {
  ChoiceCubit({
    required SharedPreferences pref,
    required FlutterSecureStorage storage,
    required XApiClient xApiClient,
    required XController xController,
    required AuthRepo authRepo,
  })  : _pref = pref,
        _storage = storage,
        _xApiClient = xApiClient,
        _xController = xController,
        _authRepo = authRepo,
        super(
            Choice(country: _getCountry(pref), routeMode: pref.routingMode)) {}

  final SharedPreferences _pref;
  final XController _xController;
  final FlutterSecureStorage _storage;
  final XApiClient _xApiClient;
  final AuthRepo _authRepo;
  StreamSubscription<XStatus>? _statusSubscription;

  @override
  Future<void> close() async {
    _statusSubscription?.cancel();
    await super.close();
    return;
  }

  Completer<void>? _completer;

  Future<void> changeCountry(String country) async {
    _pref.setSelectedCountry(country);
    emit(state.copyWith(country: country));
    // await _xController.countryChange(country);
  }

  Future<void> changeRouteMode(DefaultRouteMode routeMode) async {
    _pref.setRoutingMode(routeMode);
    emit(state.copyWith(routeMode: routeMode));
    await _xController.routingModeChange(routeMode);
  }
}

int _getPort(OutboundHandlerConfig handler) {
  if (handler.ports.isNotEmpty) {
    return handler.ports.first.from;
  }
  return handler.port;
}

class NodesSecureStorage {
  final String country;
  final List<OutboundHandlerConfig>? handlers;

  NodesSecureStorage({required this.country, this.handlers});

  /// Convert Choice to JSON map
  Map<String, dynamic> toJson() {
    return {
      'country': country,
      'handlers': handlers?.map((handler) {
        // Serialize protobuf message as base64-encoded string
        final bytes = handler.writeToBuffer();
        return base64Encode(bytes);
      }).toList(),
    };
  }

  /// Create Choice from JSON map
  factory NodesSecureStorage.fromJson(Map<String, dynamic> json) {
    return NodesSecureStorage(
      country: json['country'] as String,
      handlers: json['handlers'] != null
          ? (json['handlers'] as List<dynamic>).map((item) {
              // Deserialize base64-encoded protobuf message
              final bytes = base64Decode(item as String);
              return OutboundHandlerConfig.fromBuffer(bytes);
            }).toList()
          : null,
    );
  }

  /// Convert Choice to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create Choice from JSON string
  factory NodesSecureStorage.fromJsonString(String jsonString) {
    return NodesSecureStorage.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>);
  }
}

String _getCountry(SharedPreferences pref) {
  return pref.getString('country') ?? '';
}

Future<NodesSecureStorage?> _getNodesSecureStorage(
    FlutterSecureStorage storage) async {
  final s = await storage.read(key: 'nodes_secure_storage');
  if (s == null) {
    return null;
  }
  return NodesSecureStorage.fromJsonString(s);
}

Future<void> _saveNodesSecureStorage(
    FlutterSecureStorage storage, NodesSecureStorage nodesSecureStorage) async {
  await storage.write(
      key: 'nodes_secure_storage', value: nodesSecureStorage.toJsonString());
}

extension XStatusExtension on XStatus {
  String localizedString(BuildContext context) {
    switch (this) {
      case XStatus.disconnected:
        return AppLocalizations.of(context)!.disconnected;
      case XStatus.connecting:
        return AppLocalizations.of(context)!.connecting;
      case XStatus.connected:
        return AppLocalizations.of(context)!.connected;
      case XStatus.disconnecting:
        return AppLocalizations.of(context)!.disconnecting;
      case XStatus.reconnecting:
        return AppLocalizations.of(context)!.reconnecting;
      case XStatus.unknown:
        return AppLocalizations.of(context)!.unknown;
      case XStatus.preparing:
        return AppLocalizations.of(context)!.preparing;
    }
  }
}
