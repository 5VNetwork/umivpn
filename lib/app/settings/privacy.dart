import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umivpn/common/common.dart';
import 'package:umivpn/l10n/app_localizations.dart';
import 'package:gap/gap.dart';
import 'package:umivpn/pref_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:umivpn/app/settings/setting.dart';
import 'package:umivpn/main.dart';
import 'package:umivpn/utils/logger.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool _shareLog = false;

  @override
  void initState() {
    super.initState();
    _shareLog = context.read<SharedPreferences>().shareLog;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? getAdaptiveAppBar(
              context, Text(AppLocalizations.of(context)!.privacyPolicy))
          : null,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.privacyPolicySummary),
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
              onPressed: () {
                launchUrl(Uri.parse(privacyPolicyUrl));
              },
              child: Text(AppLocalizations.of(context)!.privacyPolicy),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(AppLocalizations.of(context)!
                    .shareDiagnosticLogWithDeveloper),
                const Spacer(),
                Switch(
                    value: _shareLog,
                    onChanged: isPkg
                        ? null
                        : (value) {
                            setState(() {
                              _shareLog = value;
                            });
                            setShareLog(_shareLog);
                          }),
              ],
            ),
            const Gap(5),
            Text(
                AppLocalizations.of(context)!
                    .diagnosticLogDoesNotContainPersonalData,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ))
          ],
        ),
      ),
    );
  }
}
