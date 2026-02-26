import 'package:flutter/material.dart';

/// A TextFormField that runs validator onChange
class VTextFormField extends StatefulWidget {
  const VTextFormField({
    super.key,
    required this.validator,
    required this.onChanged,
    required this.decoration,
    this.controller,
  });

  final String? Function(String?) validator;
  final void Function(String?) onChanged;
  final InputDecoration decoration;
  final TextEditingController? controller;
  @override
  State<VTextFormField> createState() => _VTextFormFieldState();
}

class _VTextFormFieldState extends State<VTextFormField> {
  String? _errorText;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      decoration: widget.decoration.copyWith(errorText: _errorText),
      onChanged: (value) {
        widget.onChanged(value);
        final errorText = widget.validator(value);
        if (errorText != null) {
          setState(() {
            _errorText = errorText;
          });
        }
      },
    );
  }
}
