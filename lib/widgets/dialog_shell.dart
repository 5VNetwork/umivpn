import 'package:flutter/material.dart';

class DialogShell extends StatelessWidget {
  const DialogShell({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Card(
            clipBehavior: Clip.hardEdge,
            margin: const EdgeInsets.symmetric(vertical: 24),
            child: child),
      ),
    );
  }
}
