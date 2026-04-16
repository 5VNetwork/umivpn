import 'package:tm/custom_routing_rules.dart';
import 'package:tm/default.dart';

import 'routing_rules_service.dart';

class RoutingRulesRepository {
  RoutingRulesRepository(this._service);

  final RoutingRulesService _service;

  Future<ModeCustomRoutingRules> loadModeRules(DefaultRouteMode mode) {
    return _service.getRules(mode);
  }

  Future<void> saveModeRules(
    DefaultRouteMode mode,
    ModeCustomRoutingRules rules, {
    bool applyIfConnected = true,
  }) {
    return _service.saveRules(mode, rules, applyIfConnected: applyIfConnected);
  }
}
