part of 'home.dart';

class InboundModeController extends ChangeNotifier {
  InboundModeController({
    required SharedPreferences pref,
    required XController xController,
  }) : _pref = pref,
       _xController = xController {
    _currentMode = pref.inboundMode;
  }

  final SharedPreferences _pref;
  final XController _xController;

  late InboundMode _currentMode;
  InboundMode get currentMode => _currentMode;

  bool _isChanging = false;
  bool get isChanging => _isChanging;

  Future<void> changeMode(InboundMode mode) async {
    if (_isChanging || mode == _currentMode) {
      return;
    }

    final previousMode = _currentMode;
    _isChanging = true;
    _currentMode = mode;
    notifyListeners();

    try {
      _pref.setInboundMode(mode);
      await _xController.changeInboundMode();
    } catch (e) {
      _pref.setInboundMode(previousMode);
      _currentMode = previousMode;
      rethrow;
    } finally {
      _isChanging = false;
      notifyListeners();
    }
  }
}

class InboundModeSelector extends StatelessWidget {
  const InboundModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<InboundModeController>(
      builder: (context, controller, child) {
        final colorScheme = Theme.of(context).colorScheme;
        final isChanging = controller.isChanging;

        return Opacity(
          opacity: isChanging ? 0.6 : 1,
          child: GestureDetector(
            onTap: isChanging
                ? null
                : () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: colorScheme.surface,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (ctx) => const SafeArea(
                        child: _InboundModeList(),
                      ),
                    );
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: colorScheme.brightness == Brightness.dark
                    ? colorScheme.surfaceOverlayLight
                    : colorScheme.surfaceContainerHigh,
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
                    child: isChanging
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          )
                        : Icon(
                            Icons.settings_ethernet_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
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
                          isChanging
                              ? AppLocalizations.of(context)!.changingInboundMode
                              : controller.currentMode.toLocalString(context),
                          style: TextStyle(
                            color: isChanging
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InboundModeList extends StatelessWidget {
  const _InboundModeList();

  Future<void> _changeMode(BuildContext context, InboundMode mode) async {
    final controller = context.read<InboundModeController>();
    if (controller.isChanging) {
      return;
    }
    if (mode == controller.currentMode) {
      Navigator.pop(context);
      return;
    }

    try {
      await controller.changeMode(mode);
      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
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

    return Consumer<InboundModeController>(
      builder: (context, controller, child) {
        final isChanging = controller.isChanging;
        final currentMode = controller.currentMode;

        return Padding(
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
              if (isChanging) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)!.changingInboundMode,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              ...InboundMode.values.map((mode) {
                final isSelected = mode == currentMode;
                final titleColor = isChanging
                    ? colorScheme.onSurface.withOpacity(0.38)
                    : isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface;
                final subtitleColor = isChanging
                    ? colorScheme.onSurface.withOpacity(0.28)
                    : colorScheme.onSurfaceVariant;

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
                    enabled: !isChanging,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(
                      mode.toLocalString(context),
                      style: TextStyle(
                        color: titleColor,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      mode.description(context),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: subtitleColor,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: isChanging
                                ? colorScheme.primary.withOpacity(0.45)
                                : colorScheme.primary,
                            size: 24,
                          )
                        : null,
                    onTap: isChanging
                        ? null
                        : () async {
                            await _changeMode(context, mode);
                          },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
