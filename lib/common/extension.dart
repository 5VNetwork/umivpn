import 'package:flutter/material.dart';

extension BreakpointUtils on BoxConstraints {
  bool get isCompact => maxWidth < 600;
  bool get isMedium => maxWidth >= 600 && maxWidth < 840;
  bool get isExpanded => maxWidth >= 840 && maxWidth < 1200;
  bool get isLarge => maxWidth >= 1200 && maxWidth < 1600;
  bool get isSuperLarge => maxWidth >= 1600;
  // Layout get layout {
  //   if (isCompact) {
  //     return Layout.compact;
  //   }
  // }
}

extension LayoutUtils on Size {
  bool get isCompact => width < 600;
  bool get isMedium => width >= 600 && width < 840;
  bool get isExpanded => width >= 840 && width < 1200;
  bool get isLarge => width >= 1200 && width < 1600;
  bool get isSuperLarge => width >= 1600;
}

enum Layout { compact, medium, expanded, large, superLarge }
