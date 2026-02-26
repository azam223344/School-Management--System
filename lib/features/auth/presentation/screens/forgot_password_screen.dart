import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../config/routes/route_constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/auth_shell.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_textfield.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthProvider _auth = Get.find<AuthProvider>();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  Timer? _cooldownTimer;
  int _cooldownRemaining = 0;
  bool _hasSubmitted = false;
  String? _submittedEmail;

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
    _cooldownTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    Helpers.hideKeyboard(context);
    if (_cooldownRemaining > 0) {
      Helpers.showToast(
        'Please wait $_cooldownRemaining seconds before requesting again.',
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final result = await _auth.sendPasswordResetEmail(email);
    if (!mounted) return;

    final color = result.isSuccess
        ? Colors.green.shade700
        : Colors.red.shade700;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message), backgroundColor: color),
    );

    if (result.isSuccess) {
      setState(() {
        _hasSubmitted = true;
        _submittedEmail = email;
      });
      _startCooldown();
    }
  }

  void _startCooldown([int seconds = 30]) {
    _cooldownTimer?.cancel();
    setState(() => _cooldownRemaining = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _cooldownRemaining <= 1) {
        timer.cancel();
        if (mounted) setState(() => _cooldownRemaining = 0);
        return;
      }
      setState(() => _cooldownRemaining -= 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loading = _auth.isLoading;
    final canResend = _cooldownRemaining == 0;

    return AuthShell(
      title: 'Reset Password',
      subtitle: 'Recover your account with secure email verification',
      leading: const _ForgotHeadingBadge(),
      footer: TextButton(
        onPressed: loading ? null : () => Get.offNamed(RouteConstants.login),
        child: const Text('Back to sign in'),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _ForgotHero(),
            const SizedBox(height: 14),
            if (_hasSubmitted)
              _ResetStatusCard(
                email: _submittedEmail ?? _emailController.text.trim(),
              ),
            if (_hasSubmitted) const SizedBox(height: 12),
            Text(
              'Registered account email',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _emailController,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              validator: Validators.email,
              prefixIcon: const Icon(Icons.email_outlined),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            CustomButton(
              title: _hasSubmitted
                  ? (canResend
                        ? 'Resend Reset Link'
                        : 'Resend in ${_cooldownRemaining}s')
                  : 'Send Reset Link',
              icon: const Icon(Icons.send_outlined),
              isLoading: loading,
              onPressed: (!loading && canResend) ? _submit : null,
            ),
            if (_cooldownRemaining > 0) ...[
              const SizedBox(height: 8),
              Text(
                'For security, you can request a new email after $_cooldownRemaining seconds.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            const _RecoveryTipsCard(),
            const SizedBox(height: 12),
            const _ForgotTrustRow(),
          ],
        ),
      ),
    );
  }
}

class _ResetStatusCard extends StatelessWidget {
  const _ResetStatusCard({required this.email});

  final String email;

  String _maskEmail(String value) {
    final parts = value.split('@');
    if (parts.length != 2 || parts[0].isEmpty) return value;
    final name = parts[0];
    final maskedName = name.length <= 2
        ? '${name[0]}*'
        : '${name[0]}${'*' * (name.length - 2)}${name[name.length - 1]}';
    return '$maskedName@${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.mark_email_read_rounded, color: Colors.green.shade700),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Reset instructions were sent to ${_maskEmail(email)} if an account exists.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecoveryTipsCard extends StatelessWidget {
  const _RecoveryTipsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('If you do not receive an email:'),
            SizedBox(height: 6),
            Text('1. Check spam/junk/promotions folders.'),
            Text('2. Confirm the email address is correct.'),
            Text('3. Wait a minute, then resend once.'),
          ],
        ),
      ),
    );
  }
}

class _ForgotHeadingBadge extends StatelessWidget {
  const _ForgotHeadingBadge();

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
            colors: [Color(0xFF1D4ED8), Color(0xFF0284C7), Color(0xFF0EA5E9)],
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              color: Color(0x331D4ED8),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(
          Icons.mark_email_read_outlined,
          size: 38,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ForgotHero extends StatelessWidget {
  const _ForgotHero();

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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0x190057D9),
                ),
                child: const Icon(Icons.info_outline_rounded),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Password Reset Assistant',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your registered email and we will send a secure reset link immediately.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ForgotTrustRow extends StatelessWidget {
  const _ForgotTrustRow();

  @override
  Widget build(BuildContext context) {
    final items = const [
      ('Secure Link', Icons.link_rounded),
      ('Email Verified', Icons.verified_rounded),
      ('Fast Recovery', Icons.bolt_rounded),
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
