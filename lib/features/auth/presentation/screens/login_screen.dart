import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../config/routes/route_constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/role_routing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/auth_shell.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_textfield.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthProvider _auth = Get.find<AuthProvider>();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    Helpers.hideKeyboard(context);
    if (!_formKey.currentState!.validate()) return;

    final ok = await _auth.signInWithEmail(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (ok && mounted) {
      Get.offNamed(landingRouteForRole(_auth.role));
    }
  }

  Future<void> _google() async {
    final ok = await _auth.signInWithGoogle();
    if (ok && mounted) {
      Get.offNamed(landingRouteForRole(_auth.role));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = _auth.isLoading;

    return AuthShell(
      leading: const _LoginHeadingBadge(),
      title: 'Welcome Back',
      subtitle: 'Mission control for your school role starts here',
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('New here?'),
          TextButton(
            onPressed: loading
                ? null
                : () => Get.offNamed(RouteConstants.register),
            child: const Text('Create account'),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _LoginHero(),
            const SizedBox(height: 14),
            Text(
              'Account credentials',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _emailController,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.email_outlined),
              validator: Validators.email,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _passwordController,
              label: 'Password',
              textInputAction: TextInputAction.done,
              obscureText: _obscurePassword,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              validator: (v) => Validators.requiredField(v, field: 'Password'),
              onSubmitted: (_) => _submit(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: loading
                    ? null
                    : () => Get.toNamed(RouteConstants.forgotPassword),
                child: const Text('Forgot password?'),
              ),
            ),
            CustomButton(
              title: 'Sign In',
              icon: const Icon(Icons.login_rounded),
              isLoading: loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 14),
            const _CredentialHintCard(),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'or continue with',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 14),
            CustomButton(
              title: 'Google',
              icon: const Icon(Icons.g_mobiledata_rounded, size: 30),
              outlined: true,
              isLoading: loading,
              onPressed: _google,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _LoginTag(
                  icon: Icons.security_rounded,
                  label: 'Protected Session',
                ),
                _LoginTag(
                  icon: Icons.verified_user_rounded,
                  label: 'Role-Aware Access',
                ),
                _LoginTag(icon: Icons.bolt_rounded, label: 'Quick Recovery'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginHeadingBadge extends StatelessWidget {
  const _LoginHeadingBadge();

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
            colors: [Color(0xFF023E8A), Color(0xFF0096C7), Color(0xFF00B4D8)],
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33005FB8),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(
          Icons.lock_open_rounded,
          color: Colors.white,
          size: 38,
        ),
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF3FF), Color(0xFFE8FDFF)],
        ),
        border: Border.all(color: const Color(0x66006AB8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0x190057D9),
                ),
                child: const Icon(Icons.admin_panel_settings_outlined),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'One account. Multi-role workspace.',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Attendance, results, classes, fees and notices are organized automatically based on your role.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroMetric(label: '4 Roles'),
              _HeroMetric(label: 'Secure Auth'),
              _HeroMetric(label: 'Realtime Data'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x220057D9)),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CredentialHintCard extends StatelessWidget {
  const _CredentialHintCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.tips_and_updates_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Use the same role account you registered with for correct module access.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginTag extends StatelessWidget {
  const _LoginTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
