import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/responsive.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
    this.leading,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEFF4FF), Color(0xFFF6FCFF), Color(0xFFE9FBFF)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  const _Glow(
                    top: -120,
                    left: -40,
                    size: 250,
                    color: AppConstants.brandBlue,
                  ),
                  const _Glow(
                    bottom: -140,
                    right: -30,
                    size: 290,
                    color: AppConstants.brandCyan,
                  ),
                  Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(Responsive.pagePadding(context)),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: Responsive.contentMaxWidth(
                            context,
                            desktop: 560,
                            tablet: 560,
                          ),
                        ),
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(
                              Responsive.pagePadding(context) + 4,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (leading != null) ...[
                                  Align(
                                    alignment: Alignment.center,
                                    child: leading!,
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  subtitle,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.black54),
                                ),
                                const SizedBox(height: 24),
                                child,
                                if (footer != null) ...[
                                  const SizedBox(height: 12),
                                  footer!,
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({
    this.top,
    this.right,
    this.bottom,
    this.left,
    required this.size,
    required this.color,
  });

  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.18),
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
