import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../config/routes/route_constants.dart';
import '../../../../core/utils/role_routing.dart';
import '../../../../core/widgets/auth_shell.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../providers/auth_provider.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthProvider>();
    return AnimatedBuilder(
      animation: auth,
      builder: (context, _) {
        final email = auth.user?.email ?? 'your email address';
        return AuthShell(
          title: 'Verify Your Email',
          subtitle: 'Action required for: $email',
          leading: const _VerifyHeadingBadge(),
          footer: TextButton(
            onPressed: auth.isLoading
                ? null
                : () async {
                    await auth.signOut();
                    if (context.mounted) {
                      Get.offNamed(RouteConstants.login);
                    }
                  },
            child: const Text('Use a different account'),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _VerifyHero(),
              const SizedBox(height: 14),
              CustomButton(
                title: 'Resend Verification Email',
                icon: const Icon(Icons.send_outlined),
                isLoading: auth.isLoading,
                onPressed: auth.resendEmailVerification,
              ),
              const SizedBox(height: 12),
              CustomButton(
                title: 'I Verified, Continue',
                icon: const Icon(Icons.check_circle_outline_rounded),
                outlined: true,
                isLoading: auth.isLoading,
                onPressed: () async {
                  final ok = await auth.refreshUser();
                  if (ok && context.mounted) {
                    Get.offNamed(landingRouteForRole(auth.role));
                  }
                },
              ),
              const SizedBox(height: 12),
              const _VerifyStatusRow(),
            ],
          ),
        );
      },
    );
  }
}

class _VerifyHeadingBadge extends StatelessWidget {
  const _VerifyHeadingBadge();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.94, end: 1),
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeOutBack,
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F766E), Color(0xFF0891B2), Color(0xFF0EA5E9)],
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              color: Color(0x330F766E),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(
          Icons.verified_outlined,
          size: 38,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _VerifyHero extends StatelessWidget {
  const _VerifyHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE7FFFA), Color(0xFFE8F8FF)],
        ),
        border: Border.all(color: const Color(0x66008A97)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Complete Verification',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            '1. Open inbox\n2. Click verification link\n3. Return and continue',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _VerifyStatusRow extends StatelessWidget {
  const _VerifyStatusRow();

  @override
  Widget build(BuildContext context) {
    final items = const [
      ('Inbox Link', Icons.mail_outline_rounded),
      ('One Tap Verify', Icons.touch_app_rounded),
      ('Secure Access', Icons.security_rounded),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.08),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.$2, size: 16),
                  const SizedBox(width: 6),
                  Text(item.$1, style: Theme.of(context).textTheme.labelMedium),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
