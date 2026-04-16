import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/index.dart';
import 'package:provider/provider.dart';
import 'package:tm/custom_routing_rules.dart';
import 'package:tm/default.dart';
import 'package:tm/protos/vx/common/geo/geo.pbenum.dart';
import 'package:tm/protos/vx/router/router.pbenum.dart';
import 'package:tm/x_controller.dart';
import 'package:umivpn/features/routing/data/routing_rules_repository.dart';
import 'package:umivpn/features/routing/data/routing_rules_service.dart';
import 'package:umivpn/features/routing/ui/routing_rules_view_model.dart';
import 'package:umivpn/l10n/app_localizations.dart';
import 'package:umivpn/main.dart';
import 'package:umivpn/common/common.dart';
import 'package:umivpn/utils/desktop_installed_apps.dart';

class RoutingRulesPage extends StatelessWidget {
  const RoutingRulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RoutingRulesViewModel(
        RoutingRulesRepository(
          RoutingRulesService(context.read<XController>()),
        ),
      ),
      child: const _RoutingRulesView(),
    );
  }
}

class _RoutingRulesView extends StatelessWidget {
  const _RoutingRulesView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.routing),
        actions: [
          Consumer<RoutingRulesViewModel>(
            builder: (context, vm, _) => TextButton(
              onPressed: vm.saving
                  ? null
                  : () async {
                      await vm.save();
                      if (!context.mounted) {
                        return;
                      }
                      if (vm.error == null) {
                        snack(l10n.saved);
                      } else {
                        snack(vm.error);
                      }
                    },
              child: vm.saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.save),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<RoutingRulesViewModel>(
          builder: (context, vm, _) {
            if (vm.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: SegmentedButton<DefaultRouteMode>(
                    segments: DefaultRouteMode.values
                        .map(
                          (m) => ButtonSegment(
                            value: m,
                            label: Text(m.toLocalString(l10n)),
                          ),
                        )
                        .toList(),
                    selected: {vm.selectedMode},
                    onSelectionChanged: (value) => vm.changeMode(value.first),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.routingRulesHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const _DomainSection(direct: true),
                      const SizedBox(height: 10),
                      const _DomainSection(direct: false),
                      const SizedBox(height: 10),
                      const _IpSection(direct: true),
                      const SizedBox(height: 10),
                      const _IpSection(direct: false),
                      const SizedBox(height: 10),
                      if (!Platform.isIOS) const _AppSection(direct: true),
                      if (!Platform.isIOS) const SizedBox(height: 10),
                      if (!Platform.isIOS) const _AppSection(direct: false),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DomainSection extends StatelessWidget {
  const _DomainSection({required this.direct});
  final bool direct;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _RulesCard(
      title: '${direct ? l10n.direct : l10n.proxy} ${l10n.domain}',
      onAdd: () => _showDomainDialog(context, direct),
      child: Consumer<RoutingRulesViewModel>(
        builder: (context, vm, _) {
          final list = direct
              ? vm.currentRules.directDomains
              : vm.currentRules.proxyDomains;
          if (list.isEmpty) {
            return Text(l10n.empty);
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final e = list[index];
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(_domainTypeLabel(l10n, e.type)),
                subtitle: Text(e.value, softWrap: true),
                trailing: IconButton(
                  onPressed: () => vm.removeDomain(direct: direct, rule: e),
                  icon: const Icon(Icons.close),
                  tooltip: MaterialLocalizations.of(
                    context,
                  ).deleteButtonTooltip,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showDomainDialog(BuildContext context, bool direct) async {
    final vm = context.read<RoutingRulesViewModel>();
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    Domain_Type type = Domain_Type.Plain;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l10n.add),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: l10n.domain,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Domain_Type>(
                initialValue: type,
                items: Domain_Type.values
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(_domainTypeLabel(l10n, e)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => type = v);
                  }
                },
                decoration: InputDecoration(
                  labelText: l10n.type,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                vm.addDomain(
                  direct: direct,
                  type: type,
                  value: controller.text,
                );
                Navigator.of(ctx).pop();
              },
              child: Text(l10n.add),
            ),
          ],
        ),
      ),
    );
  }
}

class _IpSection extends StatelessWidget {
  const _IpSection({required this.direct});
  final bool direct;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _RulesCard(
      title: '${direct ? l10n.direct : l10n.proxy} IP',
      onAdd: () => _showIpDialog(context, direct),
      child: Consumer<RoutingRulesViewModel>(
        builder: (context, vm, _) {
          final list = direct
              ? vm.currentRules.directIps
              : vm.currentRules.proxyIps;
          if (list.isEmpty) {
            return Text(l10n.empty);
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final e = list[index];
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(e, softWrap: true),
                trailing: IconButton(
                  onPressed: () => vm.removeIp(direct: direct, cidr: e),
                  icon: const Icon(Icons.close),
                  tooltip: MaterialLocalizations.of(
                    context,
                  ).deleteButtonTooltip,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showIpDialog(BuildContext context, bool direct) async {
    final vm = context.read<RoutingRulesViewModel>();
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.add),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'CIDR',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final cidr = controller.text.trim();
              if (parseCidr(cidr) == null) {
                snack(l10n.invalidCidr);
                return;
              }
              vm.addIp(direct: direct, cidr: cidr);
              Navigator.of(ctx).pop();
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }
}

class _AppSection extends StatelessWidget {
  const _AppSection({required this.direct});
  final bool direct;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _RulesCard(
      title: '${direct ? l10n.direct : l10n.proxy} ${l10n.app}',
      subtitle: Platform.isAndroid && direct
          ? l10n.androidDirectAppDescription
          : null,
      addMenu: _buildAddMenu(context),
      onMenuSelected: (value) => _onMenuSelected(context, value),
      child: Consumer<RoutingRulesViewModel>(
        builder: (context, vm, _) {
          final list = direct
              ? vm.currentRules.directApps
              : vm.currentRules.proxyApps;
          if (list.isEmpty) {
            return Text(l10n.empty);
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final e = list[index];
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(e.name ?? e.value),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (e.name != null) Text(e.value),
                    Text(_appTypeLabel(l10n, e.type)),
                  ],
                ),
                trailing: IconButton(
                  onPressed: () => vm.removeApp(direct: direct, rule: e),
                  icon: const Icon(Icons.close),
                  tooltip: MaterialLocalizations.of(
                    context,
                  ).deleteButtonTooltip,
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildAddMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entries = <PopupMenuEntry<String>>[
      PopupMenuItem(value: 'manual', child: Text(l10n.mannual)),
    ];
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      entries.add(
        PopupMenuItem(
          value: 'installed',
          child: Text(l10n.selectFromInstalledApps),
        ),
      );
      entries.add(
        PopupMenuItem(value: 'file', child: Text(l10n.selectFromFile)),
      );
    }
    if (Platform.isAndroid) {
      entries.add(
        PopupMenuItem(
          value: 'installed',
          child: Text(l10n.selectFromInstalledApps),
        ),
      );
    }
    return entries;
  }

  Future<void> _onMenuSelected(BuildContext context, String action) async {
    final vm = context.read<RoutingRulesViewModel>();
    if (action == 'manual') {
      await _showManualAppDialog(context, vm, direct);
      return;
    }
    if (action == 'file') {
      final picked = await FilePicker.platform.pickFiles(
        type: Platform.isWindows ? FileType.custom : FileType.any,
        allowedExtensions: Platform.isWindows ? ['exe'] : null,
      );
      final path = picked?.files.first.path;
      if (path == null || path.isEmpty) {
        return;
      }
      final type = Platform.isMacOS ? AppId_Type.Prefix : AppId_Type.Exact;
      vm.addApp(direct: direct, type: type, value: path);
      return;
    }
    if (action == 'installed') {
      if (Platform.isAndroid) {
        final existingAppPackageNames = (direct
                ? vm.currentRules.directApps
                : vm.currentRules.proxyApps)
            .where((e) => e.type == AppId_Type.Exact)
            .map((e) => e.value)
            .toSet();
        await Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (_) => _AndroidInstalledAppsScreen(
              initiallySelectedPackageNames: existingAppPackageNames,
              onSave: (values) {
                for (final v in values) {
                  vm.addApp(
                    direct: direct,
                    type: AppId_Type.Exact,
                    value: v.packageName,
                    name: v.name,
                  );
                }
              },
            ),
          ),
        );
      } else {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _DesktopInstalledAppsScreen(
              onSave: (values) {
                for (final v in values) {
                  vm.addApp(direct: direct, type: AppId_Type.Exact, value: v);
                }
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _showManualAppDialog(
    BuildContext context,
    RoutingRulesViewModel vm,
    bool direct,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    AppId_Type type = Platform.isAndroid
        ? AppId_Type.Exact
        : AppId_Type.Keyword;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l10n.add),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: l10n.app,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AppId_Type>(
                initialValue: type,
                items:
                    (Platform.isAndroid
                            ? [AppId_Type.Exact]
                            : AppId_Type.values)
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(_appTypeLabel(l10n, e)),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => type = value);
                  }
                },
                decoration: InputDecoration(
                  labelText: l10n.type,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                vm.addApp(direct: direct, type: type, value: controller.text);
                Navigator.of(ctx).pop();
              },
              child: Text(l10n.add),
            ),
          ],
        ),
      ),
    );
  }
}

class _RulesCard extends StatelessWidget {
  const _RulesCard({
    required this.title,
    required this.child,
    this.onAdd,
    this.addMenu,
    this.onMenuSelected,
    this.subtitle,
  });

  final String title;
  final Widget child;
  final VoidCallback? onAdd;
  final List<PopupMenuEntry<String>>? addMenu;
  final ValueChanged<String>? onMenuSelected;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(16);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              )
            : null,
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        collapsedShape: RoundedRectangleBorder(borderRadius: borderRadius),
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        children: [
          if (addMenu != null || onAdd != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (addMenu != null)
                    PopupMenuButton<String>(
                      onSelected: onMenuSelected,
                      itemBuilder: (_) => addMenu!,
                      icon: Icon(Icons.add),
                    )
                  else if (onAdd != null)
                    IconButton.filledTonal(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add),
                    ),
                ],
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class _AndroidInstalledAppsScreen extends StatefulWidget {
  const _AndroidInstalledAppsScreen({
    required this.onSave,
    required this.initiallySelectedPackageNames,
  });
  final void Function(List<AppInfo>) onSave;
  final Set<String> initiallySelectedPackageNames;

  @override
  State<_AndroidInstalledAppsScreen> createState() =>
      _AndroidInstalledAppsScreenState();
}

class _AndroidInstalledAppsScreenState
    extends State<_AndroidInstalledAppsScreen> {
  final Map<String, AppInfo> _selected = {};
  final Set<String> _alreadySelected = {};
  final TextEditingController _search = TextEditingController();
  List<AppInfo> _apps = [];
  List<AppInfo> _filtered = [];
  bool _loading = true;
  bool _showSystemApps = false;

  @override
  void initState() {
    super.initState();
    _alreadySelected.addAll(widget.initiallySelectedPackageNames);
    _search.addListener(_filter);
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final values = await InstalledApps.getInstalledApps(
      !_showSystemApps,
      true,
      "",
    );
    values.removeWhere((e) => e.packageName == androidPackageNme);
    setState(() {
      _apps = values;
      _filtered = values;
      _loading = false;
    });
  }

  void _filter() {
    final q = _search.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = _apps;
      } else {
        _filtered = _apps
            .where(
              (e) =>
                  e.name.toLowerCase().contains(q) ||
                  e.packageName.toLowerCase().contains(q),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            child: Text(
              _showSystemApps ? l10n.hideSystemApps : l10n.showSystemApps,
            ),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () async {
              setState(() {
                _showSystemApps = !_showSystemApps;
                _loading = true;
              });
              await _load();
            },
          ),
          TextButton(
            onPressed: () {
              widget.onSave(_selected.values.toList());
              Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SearchBar(
                    controller: _search,
                    leading: const Icon(Icons.search),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final app = _filtered[index];
                      final isAlreadySelected = _alreadySelected.contains(
                        app.packageName,
                      );
                      final checked =
                          isAlreadySelected ||
                          _selected.containsKey(app.packageName);
                      return CheckboxListTile(
                        value: checked,
                        title: AutoSizeText(app.name, maxLines: 1),
                        subtitle: Text(app.packageName),
                        secondary: app.icon == null
                            ? const Icon(Icons.android)
                            : Image.memory(app.icon!),
                        onChanged: isAlreadySelected ? null : (value) {
                          setState(() {
                            if (value == true) {
                              _selected[app.packageName] = app;
                            } else {
                              _selected.remove(app.packageName);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _DesktopInstalledAppsScreen extends StatefulWidget {
  const _DesktopInstalledAppsScreen({required this.onSave});
  final void Function(List<String>) onSave;

  @override
  State<_DesktopInstalledAppsScreen> createState() =>
      _DesktopInstalledAppsScreenState();
}

class _DesktopInstalledAppsScreenState
    extends State<_DesktopInstalledAppsScreen> {
  final Set<String> _selected = {};
  final TextEditingController _search = TextEditingController();
  List<DesktopAppInfo> _apps = [];
  List<DesktopAppInfo> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _search.addListener(_filter);
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final values = await DesktopInstalledApps.getInstalledApps();
    final filtered = values
        .where((e) => e.executablePath != null && e.executablePath!.isNotEmpty)
        .toList();
    setState(() {
      _apps = filtered;
      _filtered = filtered;
      _loading = false;
    });
  }

  void _filter() {
    final q = _search.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = _apps;
      } else {
        _filtered = _apps.where((e) {
          return (e.displayName ?? e.name).toLowerCase().contains(q) ||
              (e.executablePath ?? '').toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectFromInstalledApps),
        actions: [
          TextButton(
            onPressed: () {
              widget.onSave(_selected.toList());
              Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SearchBar(
                    controller: _search,
                    leading: const Icon(Icons.search),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final app = _filtered[index];
                      final path = app.executablePath!;
                      final checked = _selected.contains(path);
                      return CheckboxListTile(
                        value: checked,
                        title: Text(app.displayName ?? app.name),
                        subtitle: Text(path),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selected.add(path);
                            } else {
                              _selected.remove(path);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

String _domainTypeLabel(AppLocalizations l10n, Domain_Type type) {
  switch (type) {
    case Domain_Type.Plain:
      return l10n.keyword;
    case Domain_Type.Regex:
      return l10n.regularExpression;
    case Domain_Type.RootDomain:
      return l10n.rootDomain;
    case Domain_Type.Full:
      return l10n.exact;
    default:
      return l10n.keyword;
  }
}

String _appTypeLabel(AppLocalizations l10n, AppId_Type type) {
  switch (type) {
    case AppId_Type.Keyword:
      return l10n.keyword;
    case AppId_Type.Prefix:
      return l10n.prefix;
    case AppId_Type.Exact:
      return l10n.exact;
    default:
      return l10n.exact;
  }
}
