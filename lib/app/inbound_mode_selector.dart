part of 'home.dart';

class InboundModeSelector extends StatefulWidget {
  const InboundModeSelector({super.key});

  @override
  State<InboundModeSelector> createState() => _InboundModeSelectorState();
}

class _InboundModeSelectorState extends State<InboundModeSelector> {
  late InboundMode _currentMode;

  @override
  void initState() {
    super.initState();
    _currentMode = context.read<SharedPreferences>().inboundMode;
  }

  Future<void> _changeMode(InboundMode mode) async {
    if (mode == _currentMode) {
      Navigator.pop(context);
      return;
    }

    final pref = context.read<SharedPreferences>();
    final xController = context.read<XController>();
    final previousMode = _currentMode;

    setState(() {
      _currentMode = mode;
    });

    try {
      pref.setInboundMode(mode);
      await xController.changeInboundMode();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      pref.setInboundMode(previousMode);
      if (mounted) {
        setState(() {
          _currentMode = previousMode;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedToChangeInboundMode,
            ),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.inbound,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...InboundMode.values.map((mode) {
                    final isSelected = mode == _currentMode;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(
                                color: colorScheme.primary.withOpacity(0.3),
                                width: 1.5,
                              )
                            : null,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          mode.toLocalString(context),
                          style: TextStyle(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          mode.description(context),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: colorScheme.primary,
                                size: 24,
                              )
                            : null,
                        onTap: () async {
                          await _changeMode(mode);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceOverlayLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.settings_ethernet_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.inbound,
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.70),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _currentMode.toLocalString(context),
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Icon(
            //   Icons.keyboard_arrow_up_rounded,
            //   color: colorScheme.onSurface.withOpacity(0.70),
            // ),
          ],
        ),
      ),
    );
  }
}
