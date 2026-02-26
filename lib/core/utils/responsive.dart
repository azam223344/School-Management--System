import 'package:flutter/material.dart';

class Responsive {
  static double pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 12;
    if (width < 700) return 16;
    if (width < 1200) return 20;
    return 24;
  }

  static double contentMaxWidth(
    BuildContext context, {
    double desktop = 1100,
    double tablet = 860,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 700) return double.infinity;
    if (width < 1200) return tablet;
    return desktop;
  }

  static double controlWidth(BuildContext context, {required double preferred}) {
    final width = MediaQuery.sizeOf(context).width;
    final available = width - (pagePadding(context) * 2);
    if (available < preferred) return available;
    return preferred;
  }
}
