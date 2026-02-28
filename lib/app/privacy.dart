import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umivpn/l10n/app_localizations.dart';
import 'package:umivpn/pref_helper.dart';

class InitialPage extends StatelessWidget {
  const InitialPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text(l10n.privacyPolicy)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        Text(
                          l10n.personalDataWeCollect,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 24),
                        _PrivacySection(
                          icon: Icons.email_outlined,
                          iconColor: colorScheme.primary,
                          title: l10n.privacy0,
                          description: l10n.privacy0Desc,
                          theme: theme,
                        ),
                        _PrivacySection(
                          icon: Icons.person_outline,
                          iconColor: colorScheme.primary,
                          title: l10n.privacy1,
                          description: l10n.privacy1Desc,
                          theme: theme,
                        ),
                        _PrivacySection(
                          icon: Icons.location_city,
                          iconColor: colorScheme.primary,
                          title: l10n.privacy2,
                          description: l10n.privacy2Desc,
                          theme: theme,
                        ),
                        _PrivacySection(
                          icon: Icons.data_usage_outlined,
                          iconColor: colorScheme.primary,
                          title: l10n.privacy3,
                          description: l10n.privacy3Desc,
                          theme: theme,
                        ),
                        _PrivacySection(
                          icon: Icons.devices_outlined,
                          iconColor: colorScheme.primary,
                          title: l10n.privacy4,
                          description: l10n.privacy4Desc,
                          theme: theme,
                        ),
                        _PrivacySection(
                          icon: Icons.schedule_outlined,
                          iconColor: colorScheme.primary,
                          title: l10n.privacy5,
                          description: l10n.privacy5Desc,
                          theme: theme,
                        ),
                        const SizedBox(height: 16),
                        _AssuranceSection(
                          icon: Icons.shield_outlined,
                          title: l10n.privacyAssurance0,
                          description: l10n.privacyAssurance1,
                          theme: theme,
                          colorScheme: colorScheme,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final pref = context.read<SharedPreferences>();
                        pref.setHasShownPrivacyInfo(true);
                        context.go('/');
                      },
                      child: Text(l10n.gotIt),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.theme,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssuranceSection extends StatelessWidget {
  const _AssuranceSection({
    required this.icon,
    required this.title,
    required this.description,
    required this.theme,
    required this.colorScheme,
  });

  final IconData icon;
  final String title;
  final String description;
  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
