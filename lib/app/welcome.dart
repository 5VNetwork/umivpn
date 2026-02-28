import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umivpn/l10n/app_localizations.dart';
import 'package:umivpn/pref_helper.dart';
import 'package:umivpn/theme.dart';
import 'package:gap/gap.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Welcome Message
              Text(
                l10n.welcomeToUmiVPN,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(24),

              // Information Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.bgSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                        const Gap(8),
                        Text(
                          l10n.umivpnIsFreeToUse,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const Gap(10),
                    Text(
                      l10n.welcomeConnectionInfo,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.87),
                        height: 1.5,
                      ),
                    ),
                    const Gap(16),
                    Row(
                      children: [
                        Icon(
                          Icons.do_disturb_alt_rounded,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                        const Gap(8),
                        Text(
                          l10n.noTorrect,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const Gap(10),
                    Text(
                      l10n.noTorrectDesc,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.87),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(32),

              // Get Started Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final pref = context.read<SharedPreferences>();
                    pref.setHasShownWelcome(true);
                    context.go('/');
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(l10n.gotIt),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
