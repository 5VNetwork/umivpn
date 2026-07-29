import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tm/x_controller.dart';
import 'package:umivpn/app/vpn_block_domains.dart';
import 'package:umivpn/l10n/app_localizations.dart';
import 'package:umivpn/main.dart';
import 'package:umivpn/pref_helper.dart';
import 'package:umivpn/utils/logger.dart';

class ControlDrawer extends StatelessWidget {
  const ControlDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      backgroundColor: Platform.isWindows
          ? Theme.of(context).colorScheme.surface
          : Theme.of(context).colorScheme.surface,
      children: const [Padding(padding: EdgeInsets.all(10), child: Control())],
    );
  }
}

class Control extends StatelessWidget {
  const Control({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FakeDns(),
        const SizedBox(height: 8),
        const HysteriaRejectQuic(),
        const SizedBox(height: 8),
        const BalanceModeSwich(),
        const SizedBox(height: 8),
        const VpnBlockDomains(),
      ],
    );
  }
}

class FakeDns extends StatefulWidget {
  const FakeDns({super.key});

  @override
  State<FakeDns> createState() => _FakeDnsState();
}

class _FakeDnsState extends State<FakeDns> {
  late bool _fakeDns;

  @override
  void initState() {
    super.initState();
    _fakeDns = context.read<SharedPreferences>().fakeDns;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      child: SwitchListTile(
        title: Text(
          'Fake DNS',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          l10n.fakeDnsDesc,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        value: _fakeDns,
        onChanged: (value) async {
          setState(() {
            _fakeDns = value;
          });
          context.read<SharedPreferences>().setFakeDns(value);
          try {
            await context.read<XController>().toggleFakeDns(value);
          } catch (e) {
            logger.e('setFakeDns error', error: e);
            if (mounted) {
              setState(() {
                _fakeDns = !value;
              });
              context.read<SharedPreferences>().setFakeDns(!value);
            }
            snack(rootLocalizations()?.failedToChangeFakeDns);
          }
        },
      ),
    );
  }
}

class HysteriaRejectQuic extends StatefulWidget {
  const HysteriaRejectQuic({super.key});

  @override
  State<HysteriaRejectQuic> createState() => _HysteriaRejectQuicState();
}

class _HysteriaRejectQuicState extends State<HysteriaRejectQuic> {
  late bool _hysteriaRejectQuic;

  @override
  void initState() {
    super.initState();
    _hysteriaRejectQuic = context.read<SharedPreferences>().hysteriaRejectQuic;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      child: SwitchListTile(
        title: Text(
          l10n.hysteriaRejectQuic,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '开启后可能会提高速度，但是一些网站可能会遇到问题',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        value: _hysteriaRejectQuic,
        onChanged: (value) async {
          setState(() {
            _hysteriaRejectQuic = value;
          });
          context.read<SharedPreferences>().setHysteriaRejectQuic(value);
          try {
            await context.read<XController>().applyHysteriaRejectQuic();
          } catch (e) {
            logger.e('setHysteriaRejectQuic error', error: e);
            if (mounted) {
              setState(() {
                _hysteriaRejectQuic = !value;
              });
              context.read<SharedPreferences>().setHysteriaRejectQuic(!value);
            }
          }
        },
      ),
    );
  }
}

class BalanceModeSwich extends StatefulWidget {
  const BalanceModeSwich({super.key});

  @override
  State<BalanceModeSwich> createState() => _BalanceModeSwichState();
}

class _BalanceModeSwichState extends State<BalanceModeSwich> {
  late bool _balanceMode;

  @override
  void initState() {
    super.initState();
    _balanceMode = context.read<SharedPreferences>().balanceMode;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      child: SwitchListTile(
        title: Text(
          l10n.balanceMode,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          l10n.balanceModeDesc,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        value: _balanceMode,
        onChanged: (value) async {
          setState(() {
            _balanceMode = value;
          });
          context.read<SharedPreferences>().setBalanceMode(value);
          try {
            await context.read<XController>().toggleBalanceMode(value);
          } catch (e) {
            logger.e('setBalanceMode error', error: e);
            snack(rootLocalizations()?.failedToChangeBalanceMode);
          }
        },
      ),
    );
  }
}
