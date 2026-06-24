import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tm/custom_routing_rules.dart';
import 'package:tm/protos/vx/common/geo/geo.pb.dart';
import 'package:tm/protos/vx/common/geo/geo.pbenum.dart';
import 'package:tm/x_controller.dart';
import 'package:umivpn/l10n/app_localizations.dart';
import 'package:umivpn/main.dart';

class VpnBlockDomains extends StatefulWidget {
  const VpnBlockDomains({super.key});

  @override
  State<VpnBlockDomains> createState() => _VpnBlockDomainsState();
}

class _VpnBlockDomainsState extends State<VpnBlockDomains> {
  List<DomainRule> _domains = [];
  bool _loading = true;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final domains = await context.read<XController>().getVpnBlockDomains();
    if (mounted) {
      setState(() {
        _domains = domains;
        _loading = false;
      });
    }
  }

  Future<void> _addDomain() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    Domain_Type type = Domain_Type.RootDomain;
    String? valueError;
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.addVpnBlockDomain),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                onChanged: (_) {
                  if (valueError != null) {
                    setDialogState(() => valueError = null);
                  }
                },
                decoration: InputDecoration(
                  labelText: l10n.domain,
                  border: const OutlineInputBorder(),
                  hintText: 'example.com',
                  errorText: valueError,
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Domain_Type>(
                initialValue: type,
                items:
                    [
                          Domain_Type.RootDomain,
                          Domain_Type.Plain,
                          Domain_Type.Full,
                        ]
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(_domainTypeLabel(l10n, e)),
                          ),
                        )
                        .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setDialogState(() => type = v);
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
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().length < 5) {
                  setDialogState(
                    () => valueError = l10n.vpnBlockDomainTooShort,
                  );
                  return;
                }
                Navigator.of(ctx).pop(true);
              },
              child: Text(l10n.add),
            ),
          ],
        ),
      ),
    );
    if (added != true || !mounted) {
      return;
    }
    final value = controller.text.trim();
    if (value.length < 5) {
      return;
    }
    try {
      await context.read<XController>().addVpnBlockDomain(
        Domain(type: type, value: value),
      );
      await _load();
      if (mounted) {
        snack(l10n.saved);
      }
    } catch (e) {
      if (mounted) {
        snack(e.toString());
      }
    }
  }

  Future<void> _removeDomain(DomainRule rule) async {
    try {
      await context.read<XController>().removeVpnBlockDomain(
        Domain(type: rule.type, value: rule.value),
      );
      await _load();
    } catch (e) {
      if (mounted) {
        snack(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      child: ExpansionTile(
        initiallyExpanded: _expanded,
        onExpansionChanged: (value) => setState(() => _expanded = value),
        title: Text(
          l10n.vpnBlockDomains,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          l10n.vpnBlockDomainsDesc,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _addDomain,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.add),
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_domains.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                l10n.empty,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              itemCount: _domains.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final rule = _domains[index];
                return ListTile(
                  dense: true,
                  title: Text(rule.value),
                  subtitle: Text(_domainTypeLabel(l10n, rule.type)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => _removeDomain(rule),
                    tooltip: l10n.delete,
                  ),
                );
              },
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
      return type.name;
  }
}
