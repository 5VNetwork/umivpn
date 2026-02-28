import 'package:flutter/material.dart';

class DragHandle extends StatelessWidget {
  const DragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      width: 32,
      child: Center(
        child: Container(
          height: 4,
          width: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4 / 2),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
