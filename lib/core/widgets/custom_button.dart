import 'package:flutter/material.dart';

import 'loading_widget.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.outlined = false,
  });

  final String title;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final button = outlined
        ? OutlinedButton.icon(
            onPressed: isLoading ? null : onPressed,
            icon: icon ?? const SizedBox.shrink(),
            label: isLoading ? const LoadingWidget() : Text(title),
          )
        : FilledButton.icon(
            onPressed: isLoading ? null : onPressed,
            icon: isLoading
                ? const SizedBox.shrink()
                : (icon ?? const SizedBox.shrink()),
            label: isLoading ? const LoadingWidget() : Text(title),
          );

    return SizedBox(height: 54, width: double.infinity, child: button);
  }
}
