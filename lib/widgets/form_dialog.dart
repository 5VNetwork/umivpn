import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:umivpn/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:umivpn/app/layout_provider.dart';

mixin FormDataGetter {
  Object? get formData;
}

Future<T> showMyAdaptiveDialog<T>(
  BuildContext context,
  Widget widget, {
  String? title,
  Function(BuildContext)? onSave,
  bool editable = true,
}) async {
  late Object? result;
  if (Provider.of<MyLayout>(context, listen: false).fullScreen()) {
    result = await Navigator.of(context, rootNavigator: true)
        .push(CupertinoPageRoute(
            builder: (ctx) => Scaffold(
                  appBar: AppBar(
                    title:
                        !Platform.isMacOS && title != null ? Text(title) : null,
                    automaticallyImplyLeading: false,
                    leading: !Platform.isMacOS
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => context.pop(),
                          )
                        : null,
                    actions: [
                      if (Platform.isMacOS)
                        TextButton(
                            onPressed: () => context.pop(),
                            child: Text(AppLocalizations.of(context)!.cancel)),
                      if (editable)
                        TextButton(
                            onPressed: () => onSave?.call(context),
                            child: Text(AppLocalizations.of(context)!.save))
                    ],
                  ),
                  body: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: widget,
                    ),
                  ),
                )));
  } else {
    result = await showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: AppLocalizations.of(context)!.edit,
        pageBuilder: (context, animation, secondaryAnimation) => AlertDialog(
              scrollable: true,
              title: title != null ? Text(title) : null,
              actions: [
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                      fixedSize: const Size(100, 40), elevation: 1),
                  onPressed: () => context.pop(),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                const SizedBox(width: 10),
                if (editable)
                  Builder(builder: (context) {
                    return FilledButton(
                      style: FilledButton.styleFrom(
                          fixedSize: const Size(100, 40), elevation: 1),
                      onPressed: () => onSave?.call(context),
                      child: Text(AppLocalizations.of(context)!.save),
                    );
                  })
              ],
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: widget,
                ),
                //       Column(
                //   mainAxisSize: MainAxisSize.min,
                //   children: [
                //     // AppBar(
                //     //   title: Text(widget.title),
                //     //   automaticallyImplyLeading: false,
                //     // ),

                //     Padding(
                //       padding: const EdgeInsets.only(right: 20, bottom: 20),
                //       child: Row(
                //         mainAxisAlignment: MainAxisAlignment.end,
                //         children: [
                //           FilledButton.tonal(
                //             style: FilledButton.styleFrom(
                //                 fixedSize: const Size(100, 40), elevation: 1),
                //             onPressed: () => context.pop(),
                //             child: Text(AppLocalizations.of(context)!.cancel),
                //           ),
                //           const SizedBox(width: 10),
                //           Builder(builder: (context) {
                //             return FilledButton(
                //               style: FilledButton.styleFrom(
                //                   fixedSize: const Size(100, 40), elevation: 1),
                //               onPressed: () => _onSave(context),
                //               child: Text(AppLocalizations.of(context)!.save),
                //             );
                //           })
                //         ],
                //       ),
                //     )
                //   ],
                // ),
              ),
            ));
  }
  return result as T;
}

Future<String?> showStringForm(BuildContext context,
    {String? initialValue,
    String? title,
    String? helperText,
    String? labelText,
    int maxLines = 1}) async {
  return await showDialog<String?>(
      context: context,
      builder: (context) => StringForm(
          initialValue: initialValue,
          title: title,
          helperText: helperText,
          maxLines: maxLines,
          labelText: labelText));
}

class StringForm extends StatefulWidget {
  const StringForm(
      {super.key,
      this.initialValue,
      this.title,
      this.helperText,
      this.maxLines = 1,
      this.labelText});
  final String? initialValue;
  final String? title;
  final String? helperText;
  final int maxLines;
  final String? labelText;
  @override
  State<StringForm> createState() => _StringFormState();
}

class _StringFormState extends State<StringForm> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _nameController.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: widget.title != null ? Text(widget.title!) : null,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _nameController,
            maxLines: widget.maxLines,
            decoration: InputDecoration(
                helperText: widget.helperText,
                labelText: widget.labelText,
                helperStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                border: const OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel)),
        TextButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty) {
                Navigator.pop(context, _nameController.text);
              }
            },
            child: Text(AppLocalizations.of(context)!.confirm)),
      ],
    );
  }
}
