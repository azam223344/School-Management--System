import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../config/routes/route_constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/role_routing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/auth_shell.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_textfield.dart';
import '../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthProvider _auth = Get.find<AuthProvider>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  AppRole _selectedRole = AppRole.student;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    Helpers.hideKeyboard(context);
    if (!_formKey.currentState!.validate()) return;

    final ok = await _auth.registerWithEmail(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      role: _selectedRole,
    );

    if (ok && mounted) {
      Get.offNamed(RouteConstants.verifyEmail);
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
    final score = Validators.passwordStrengthScore(_passwordController.text);

    return AuthShell(
      leading: const _SignupHeadingBadge(),
      title: 'Create Account',
      subtitle: 'Build your role-ready workspace in under a minute',
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('Already have an account?'),
          TextButton(
            onPressed: loading
                ? null
                : () => Get.offNamed(RouteConstants.login),
            child: const Text('Sign in'),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RegisterHero(role: _selectedRole),
            const SizedBox(height: 14),
            const _SignupProgressStrip(),
            const SizedBox(height: 14),
            Text(
              'Select role',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppRole.values.map((role) {
                return _RoleChip(
                  role: role,
                  selected: role == _selectedRole,
                  onTap: () => setState(() => _selectedRole = role),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'Account details',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _nameController,
              label: 'Full name',
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.person_outline_rounded),
              validator: (v) => Validators.requiredField(v, field: 'Full name'),
            ),
            const SizedBox(height: 14),
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
              textInputAction: TextInputAction.next,
              obscureText: _obscurePassword,
              onChanged: (_) => setState(() {}),
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
              validator: Validators.password,
            ),
            const SizedBox(height: 8),
            _StrengthMeter(score: score),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _confirmController,
              label: 'Confirm password',
              textInputAction: TextInputAction.done,
              obscureText: _obscureConfirm,
              prefixIcon: const Icon(Icons.lock_person_outlined),
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              validator: (v) =>
                  Validators.confirmPassword(v, _passwordController.text),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 18),
            CustomButton(
              title: 'Register',
              icon: const Icon(Icons.rocket_launch_outlined),
              isLoading: loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'or',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 14),
            CustomButton(
              title: 'Sign up with Google',
              icon: const Icon(Icons.g_mobiledata_rounded, size: 30),
              outlined: true,
              isLoading: loading,
              onPressed: _google,
            ),
            const SizedBox(height: 12),
            const _SignupTrustRow(),
          ],
        ),
      ),
    );
  }
}

class _SignupHeadingBadge extends StatelessWidget {
  const _SignupHeadingBadge();

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
          Icons.person_add_alt_1_rounded,
          color: Colors.white,
          size: 38,
        ),
      ),
    );
  }
}

class _RegisterHero extends StatelessWidget {
  const _RegisterHero({required this.role});

  final AppRole role;

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(role);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
        ),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withValues(alpha: 0.18),
            ),
            child: Icon(_roleIcon(role), color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_roleLabel(role)} account selected',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  _roleDescription(role),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignupProgressStrip extends StatelessWidget {
  const _SignupProgressStrip();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _StepChip(index: 1, label: 'Role'),
        SizedBox(width: 8),
        _StepChip(index: 2, label: 'Details'),
        SizedBox(width: 8),
        _StepChip(index: 3, label: 'Security'),
      ],
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({required this.index, required this.label});

  final int index;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$index',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final AppRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(role);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.32),
            width: selected ? 1.8 : 1.1,
          ),
          gradient: selected
              ? LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.22),
                    color.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(colors: [Colors.white, Colors.white]),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_roleIcon(role), size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              _roleLabel(role),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignupTrustRow extends StatelessWidget {
  const _SignupTrustRow();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _TrustPill(
          icon: Icons.verified_rounded,
          label: 'Email Verification',
          style: style,
        ),
        _TrustPill(
          icon: Icons.lock_rounded,
          label: 'Encrypted Login',
          style: style,
        ),
        _TrustPill(
          icon: Icons.person_search_rounded,
          label: 'Role Specific',
          style: style,
        ),
      ],
    );
  }
}

class _TrustPill extends StatelessWidget {
  const _TrustPill({required this.icon, required this.label, this.style});

  final IconData icon;
  final String label;
  final TextStyle? style;

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
          Text(label, style: style),
        ],
      ),
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
            5,
            (i) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: i < score ? _barColor(score) : Colors.black12,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _label(score),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: _barColor(score)),
        ),
      ],
    );
  }

  String _label(int score) {
    if (score <= 1) return 'Weak password';
    if (score <= 3) return 'Medium password';
    return 'Strong password';
  }

  Color _barColor(int score) {
    if (score <= 1) return const Color(0xFFD93025);
    if (score <= 3) return const Color(0xFFE59E00);
    return const Color(0xFF1E8E3E);
  }
}

String _roleLabel(AppRole role) {
  switch (role) {
    case AppRole.admin:
      return 'Admin';
    case AppRole.teacher:
      return 'Teacher';
    case AppRole.parent:
      return 'Parent';
    case AppRole.student:
      return 'Student';
  }
}

String _roleDescription(AppRole role) {
  switch (role) {
    case AppRole.admin:
      return 'Complete access across all modules and settings.';
    case AppRole.teacher:
      return 'Manage assigned classes, attendance, and student academics.';
    case AppRole.parent:
      return 'Track your child progress, results, and attendance.';
    case AppRole.student:
      return 'View classes, timetable, results, and your own updates.';
  }
}

IconData _roleIcon(AppRole role) {
  switch (role) {
    case AppRole.admin:
      return Icons.admin_panel_settings_outlined;
    case AppRole.teacher:
      return Icons.menu_book_rounded;
    case AppRole.parent:
      return Icons.family_restroom_rounded;
    case AppRole.student:
      return Icons.school_outlined;
  }
}

Color _roleColor(AppRole role) {
  switch (role) {
    case AppRole.admin:
      return const Color(0xFF304FFE);
    case AppRole.teacher:
      return const Color(0xFF008A4E);
    case AppRole.parent:
      return const Color(0xFFE07A00);
    case AppRole.student:
      return const Color(0xFF0077CC);
  }
}
