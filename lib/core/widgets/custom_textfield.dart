import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    return SizedBox(
      width: double.infinity,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        validator: validator,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          isDense: compact,
          contentPadding: compact
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
              : null,
          prefixIconConstraints: compact
              ? const BoxConstraints(minWidth: 38, minHeight: 38)
              : null,
          suffixIconConstraints: compact
              ? const BoxConstraints(minWidth: 38, minHeight: 38)
              : null,
        ),
      ),
    );
  }
}
