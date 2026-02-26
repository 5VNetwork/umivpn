import 'package:flutter/material.dart';

class TextDivider extends StatelessWidget {
  final String text;
  final double thickness;

  const TextDivider({
    super.key,
    required this.text,
    this.thickness = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            thickness: thickness,
            endIndent: 10.0,
          ),
        ),
        Text(
          text,
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Expanded(
          child: Divider(
            thickness: thickness,
            indent: 10.0,
          ),
        ),
      ],
    );
  }
}
