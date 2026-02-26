import 'package:flutter/material.dart';

class RawDialogPage extends Page {
  const RawDialogPage({super.key, required this.child});
  final Widget child;
  @override
  Route createRoute(BuildContext context) {
    return RawDialogRoute(
      barrierDismissible: false,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      settings: this,
    );
  }
}

class AddPopUpRoute<T> extends PopupRoute<T> {
  AddPopUpRoute({super.settings, required this.child}) : super();
  final Widget child;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  Color get barrierColor => Colors.black.withAlpha(0x50);

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null; //TODO

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return child;
  }
}

class AddPopUpPage extends Page {
  const AddPopUpPage({super.key, required this.child});
  final Widget child;
  @override
  Route createRoute(BuildContext context) {
    return AddPopUpRoute(
      child: child,
      settings: this,
    );
  }
}
