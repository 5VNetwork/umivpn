import 'package:shared_preferences/shared_preferences.dart';
import 'package:tm/custom_routing_rules.dart';
import 'package:tm/default.dart';
import 'package:tm/protos/vx/common/geo/geo.pb.dart';
import 'package:tm/protos/vx/common/geo/geo.pbenum.dart';
import 'package:tm/protos/vx/router/router.pbenum.dart';
import 'package:tm/x_controller.dart';
import 'package:umivpn/features/routing/data/routing_rules_repository.dart';
import 'package:umivpn/features/routing/data/routing_rules_service.dart';
import 'package:umivpn/pref_helper.dart';

class LogRoutingHelper {
  LogRoutingHelper({
    required SharedPreferences pref,
    required XController xController,
  }) : _pref = pref,
       _xController = xController,
       _repository = RoutingRulesRepository(RoutingRulesService(xController));

  final SharedPreferences _pref;
  final RoutingRulesRepository _repository;
  final XController _xController;

  Future<void> addDomain({
    required bool direct,
    required Domain_Type type,
    required String value,
  }) async {
    final mode = _pref.routingMode;
    final rules = await _repository.loadModeRules(mode);
    final v = value.trim();
    if (v.isEmpty) {
      return;
    }
    final target = direct ? rules.directDomains : rules.proxyDomains;
    if (target.any((e) => e.type == type && e.value == v)) {
      return;
    }
    final nextDirectDomains = List<DomainRule>.of(rules.directDomains);
    final nextProxyDomains = List<DomainRule>.of(rules.proxyDomains);
    final nextTarget = direct ? nextDirectDomains : nextProxyDomains;
    nextTarget.add(DomainRule(type: type, value: v));
    await _repository.saveModeRules(
      mode,
      ModeCustomRoutingRules(
        directDomains: nextDirectDomains,
        proxyDomains: nextProxyDomains,
        directIps: rules.directIps,
        proxyIps: rules.proxyIps,
        directApps: rules.directApps,
        proxyApps: rules.proxyApps,
      ),
    );
    await _xController.addGeoDomain(
      direct ? customDirect : customProxy,
      Domain(type: type, value: v),
    );
  }

  Future<void> addVpnBlockDomain({
    required Domain_Type type,
    required String value,
  }) async {
    final v = value.trim();
    if (v.isEmpty) {
      return;
    }
    await _xController.addGeoDomain(vpnBlock, Domain(type: type, value: v));
  }

  Future<void> addIp({required bool direct, required String cidr}) async {
    final mode = _pref.routingMode;
    final rules = await _repository.loadModeRules(mode);
    final value = cidr.trim();
    if (value.isEmpty || parseCidr(value) == null) {
      throw Exception('Invalid cidr: $value');
    }
    final target = direct ? rules.directIps : rules.proxyIps;
    if (target.contains(value)) {
      return;
    }
    final nextDirectIps = List<String>.of(rules.directIps);
    final nextProxyIps = List<String>.of(rules.proxyIps);
    final nextTarget = direct ? nextDirectIps : nextProxyIps;
    nextTarget.add(value);
    await _repository.saveModeRules(
      mode,
      ModeCustomRoutingRules(
        directDomains: rules.directDomains,
        proxyDomains: rules.proxyDomains,
        directIps: nextDirectIps,
        proxyIps: nextProxyIps,
        directApps: rules.directApps,
        proxyApps: rules.proxyApps,
      ),
    );
    _xController.updateGeo();
  }

  Future<void> addApp({
    required bool direct,
    required AppId_Type type,
    required String value,
  }) async {
    final mode = _pref.routingMode;
    final rules = await _repository.loadModeRules(mode);
    final v = value.trim();
    if (v.isEmpty) {
      return;
    }
    final target = direct ? rules.directApps : rules.proxyApps;
    if (target.any((e) => e.type == type && e.value == v)) {
      return;
    }
    final nextDirectApps = List<AppRule>.of(rules.directApps);
    final nextProxyApps = List<AppRule>.of(rules.proxyApps);
    final nextTarget = direct ? nextDirectApps : nextProxyApps;
    nextTarget.add(AppRule(type: type, value: v));
    await _repository.saveModeRules(
      mode,
      ModeCustomRoutingRules(
        directDomains: rules.directDomains,
        proxyDomains: rules.proxyDomains,
        directIps: rules.directIps,
        proxyIps: rules.proxyIps,
        directApps: nextDirectApps,
        proxyApps: nextProxyApps,
      ),
    );
    _xController.updateGeo();
  }
}
