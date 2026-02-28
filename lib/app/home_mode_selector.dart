part of 'home.dart';

class ModeSelector extends StatelessWidget {
  const ModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: colorScheme.surface,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (ctx) => const _ModeList(),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceOverlayLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.borderLight),
        ),
        child: BlocSelector<ChoiceCubit, Choice, DefaultRouteMode>(
          selector: (state) => state.routeMode,
          builder: (ctx, currentMode) {
            return Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
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
                    Icons.route_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.mode,
                      style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.70),
                          fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentMode.toLocalString(AppLocalizations.of(context)!),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(Icons.keyboard_arrow_up_rounded,
                    color: colorScheme.onSurface.withOpacity(0.70))
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ModeList extends StatelessWidget {
  const _ModeList({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currentMode = context.read<ChoiceCubit>().state.routeMode;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.selectRouteMode,
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: DefaultRouteMode.values.length,
              itemBuilder: (ctx, index) {
                final mode = DefaultRouteMode.values[index];
                final isSelected = mode == currentMode;

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
                            width: 1.5)
                        : null,
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      mode.toLocalString(AppLocalizations.of(context)!),
                      style: TextStyle(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        mode.description(context),
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.70),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: colorScheme.primary,
                            size: 24,
                          )
                        : null,
                    onTap: () {
                      if (mode != currentMode) {
                        context.read<ChoiceCubit>().changeRouteMode(mode);
                      }
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
