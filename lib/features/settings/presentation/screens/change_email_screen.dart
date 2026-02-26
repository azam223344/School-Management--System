import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_textfield.dart';
import '../../../../core/widgets/session_menu_button.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../features/auth/providers/auth_provider.dart';

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final AuthProvider _auth = Get.find<AuthProvider>();
  final _formKey = GlobalKey<FormState>();
  final _newEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

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
    _newEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    Helpers.hideKeyboard(context);
    if (!_formKey.currentState!.validate()) return;

    final ok = await _auth.changeEmail(
      newEmail: _newEmailController.text,
      currentPassword: _passwordController.text,
    );

    if (ok && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = _auth.isLoading;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Change Email'),
        actions: const [SessionMenuButton(showHome: true)],
      ),
      body: Center(
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
                padding: EdgeInsets.all(Responsive.pagePadding(context)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'For security, confirm your current password.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _newEmailController,
                        label: 'New email',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(Icons.email_outlined),
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: _passwordController,
                        label: 'Current password',
                        obscureText: _obscure,
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                        validator: (v) => Validators.requiredField(
                          v,
                          field: 'Current password',
                        ),
                      ),
                      const SizedBox(height: 18),
                      CustomButton(
                        title: 'Update Email',
                        icon: const Icon(Icons.mark_email_read_outlined),
                        isLoading: loading,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
