import 'package:flutter/material.dart';
import 'package:flutter_common/widgets/app_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:umivpn/app/announcements/announcement.dart';
import 'package:umivpn/app/announcements/announcements_provider.dart';
import 'package:umivpn/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AnnouncementsProvider>();
      final locale = Localizations.localeOf(context).languageCode;
      provider.updateLocale(locale);
      provider.refresh(force: true).then((_) {
        if (mounted) {
          provider.markAllRead();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<AnnouncementsProvider>();

    return Scaffold(
      appBar: adaptiveClosableAppBar(context, title: l10n.announcements),
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.refresh(force: true);
          await provider.markAllRead();
        },
        child: _buildBody(context, provider, l10n),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AnnouncementsProvider provider,
    AppLocalizations l10n,
  ) {
    if (provider.loading && provider.messages.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 200),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (provider.error != null && provider.messages.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.campaign_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.failedToLoadAnnouncements,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton(
              onPressed: () => provider.refresh(force: true),
              child: Text(l10n.retry),
            ),
          ),
        ],
      );
    }

    if (provider.messages.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.campaign_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noAnnouncements,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: provider.messages.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _AnnouncementCard(message: provider.messages[index]);
      },
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.message});

  final Announcement message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dateText = DateFormat.yMMMd(locale).add_jm().format(
      message.publishedAt.toLocal(),
    );

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Text(message.body, style: theme.textTheme.bodyMedium),
            if (message.link != null && message.link!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse(message.link!),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(AppLocalizations.of(context)!.learnMore),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AnnouncementsUnreadIconButton extends StatelessWidget {
  const AnnouncementsUnreadIconButton({
    super.key,
    required this.route,
    required this.icon,
    this.iconColor,
  });

  final String route;
  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.select<AnnouncementsProvider, int>(
      (controller) => controller.unreadCount,
    );
    final l10n = AppLocalizations.of(context)!;
    final label = unreadCount > 99 ? '99+' : '$unreadCount';

    return IconButton(
      tooltip: l10n.announcements,
      onPressed: () => context.go(route),
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text(label),
        backgroundColor: Colors.redAccent,
        child: Icon(icon, color: iconColor),
      ),
    );
  }
}
