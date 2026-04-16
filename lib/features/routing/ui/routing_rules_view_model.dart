import 'package:flutter/foundation.dart';
import 'package:tm/custom_routing_rules.dart';
import 'package:tm/default.dart';
import 'package:tm/protos/vx/common/geo/geo.pbenum.dart';
import 'package:tm/protos/vx/router/router.pbenum.dart';

import '../data/routing_rules_repository.dart';

class RoutingRulesViewModel extends ChangeNotifier {
  RoutingRulesViewModel(this._repository) {
    selectedMode = DefaultRouteMode.proxyAll;
    _load(selectedMode);
  }

  final RoutingRulesRepository _repository;

  late DefaultRouteMode selectedMode;
  bool loading = false;
  bool saving = false;
  String? error;
  final Map<DefaultRouteMode, ModeCustomRoutingRules> _cache = {};

  ModeCustomRoutingRules get currentRules =>
      _cache[selectedMode] ?? ModeCustomRoutingRules();

  Future<void> changeMode(DefaultRouteMode mode) async {
    selectedMode = mode;
    await _load(mode);
  }

  Future<void> _load(DefaultRouteMode mode) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      _cache[mode] = await _repository.loadModeRules(mode);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> save({bool applyIfConnected = true}) async {
    saving = true;
    error = null;
    notifyListeners();
    try {
      await _repository.saveModeRules(
        selectedMode,
        currentRules,
        applyIfConnected: applyIfConnected,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  void addDomain({
    required bool direct,
    required Domain_Type type,
    required String value,
  }) {
    final v = value.trim();
    if (v.isEmpty) {
      return;
    }
    final rules = currentRules;
    final target = direct ? rules.directDomains : rules.proxyDomains;
    if (target.any((e) => e.type == type && e.value == v)) {
      return;
    }
    final nextDirectDomains = List<DomainRule>.of(rules.directDomains);
    final nextProxyDomains = List<DomainRule>.of(rules.proxyDomains);
    final nextTarget = direct ? nextDirectDomains : nextProxyDomains;
    nextTarget.add(DomainRule(type: type, value: v));
    _setCurrentRules(
      rules,
      directDomains: nextDirectDomains,
      proxyDomains: nextProxyDomains,
    );
  }

  void removeDomain({required bool direct, required DomainRule rule}) {
    final rules = currentRules;
    final nextDirectDomains = List<DomainRule>.of(rules.directDomains);
    final nextProxyDomains = List<DomainRule>.of(rules.proxyDomains);
    final nextTarget = direct ? nextDirectDomains : nextProxyDomains;
    nextTarget.removeWhere((e) => e.type == rule.type && e.value == rule.value);
    _setCurrentRules(
      rules,
      directDomains: nextDirectDomains,
      proxyDomains: nextProxyDomains,
    );
  }

  void addIp({required bool direct, required String cidr}) {
    final value = cidr.trim();
    if (value.isEmpty || parseCidr(value) == null) {
      return;
    }
    final rules = currentRules;
    final target = direct ? rules.directIps : rules.proxyIps;
    if (target.contains(value)) {
      return;
    }
    final nextDirectIps = List<String>.of(rules.directIps);
    final nextProxyIps = List<String>.of(rules.proxyIps);
    final nextTarget = direct ? nextDirectIps : nextProxyIps;
    nextTarget.add(value);
    _setCurrentRules(rules, directIps: nextDirectIps, proxyIps: nextProxyIps);
  }

  void removeIp({required bool direct, required String cidr}) {
    final rules = currentRules;
    final nextDirectIps = List<String>.of(rules.directIps);
    final nextProxyIps = List<String>.of(rules.proxyIps);
    final nextTarget = direct ? nextDirectIps : nextProxyIps;
    nextTarget.remove(cidr);
    _setCurrentRules(rules, directIps: nextDirectIps, proxyIps: nextProxyIps);
  }

  void addApp({
    required bool direct,
    required AppId_Type type,
    required String value,
    String? name,
  }) {
    final v = value.trim();
    if (v.isEmpty) {
      return;
    }
    final rules = currentRules;
    final target = direct ? rules.directApps : rules.proxyApps;
    if (target.any((e) => e.type == type && e.value == v)) {
      return;
    }
    final nextDirectApps = List<AppRule>.of(rules.directApps);
    final nextProxyApps = List<AppRule>.of(rules.proxyApps);
    final nextTarget = direct ? nextDirectApps : nextProxyApps;
    nextTarget.add(AppRule(type: type, value: v, name: name));
    _setCurrentRules(
      rules,
      directApps: nextDirectApps,
      proxyApps: nextProxyApps,
    );
  }

  void removeApp({required bool direct, required AppRule rule}) {
    final rules = currentRules;
    final nextDirectApps = List<AppRule>.of(rules.directApps);
    final nextProxyApps = List<AppRule>.of(rules.proxyApps);
    final nextTarget = direct ? nextDirectApps : nextProxyApps;
    nextTarget.removeWhere((e) => e.type == rule.type && e.value == rule.value);
    _setCurrentRules(
      rules,
      directApps: nextDirectApps,
      proxyApps: nextProxyApps,
    );
  }

  void _setCurrentRules(
    ModeCustomRoutingRules previous, {
    List<DomainRule>? directDomains,
    List<DomainRule>? proxyDomains,
    List<String>? directIps,
    List<String>? proxyIps,
    List<AppRule>? directApps,
    List<AppRule>? proxyApps,
  }) {
    _cache[selectedMode] = ModeCustomRoutingRules(
      directDomains:
          directDomains ?? List<DomainRule>.of(previous.directDomains),
      proxyDomains: proxyDomains ?? List<DomainRule>.of(previous.proxyDomains),
      directIps: directIps ?? List<String>.of(previous.directIps),
      proxyIps: proxyIps ?? List<String>.of(previous.proxyIps),
      directApps: directApps ?? List<AppRule>.of(previous.directApps),
      proxyApps: proxyApps ?? List<AppRule>.of(previous.proxyApps),
    );
    notifyListeners();
  }
}
