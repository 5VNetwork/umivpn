import 'package:tm/custom_routing_rules.dart';
import 'package:tm/default.dart';
import 'package:tm/x_controller.dart';

class RoutingRulesService {
  RoutingRulesService(this._xController);

  final XController _xController;

  Future<ModeCustomRoutingRules> getRules(DefaultRouteMode mode) {
    return _xController.getCustomRoutingRules(mode);
  }

  Future<void> saveRules(
    DefaultRouteMode mode,
    ModeCustomRoutingRules rules, {
    bool applyIfConnected = true,
  }) {
    return _xController.setCustomRoutingRules(
      mode,
      rules,
      applyIfConnected: applyIfConnected,
    );
  }
}
