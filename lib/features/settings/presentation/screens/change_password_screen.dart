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

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final AuthProvider _auth = Get.find<AuthProvider>();
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
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
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    Helpers.hideKeyboard(context);
    if (!_formKey.currentState!.validate()) return;

    final ok = await _auth.changePassword(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
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
        title: const Text('Change Password'),
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
                      CustomTextField(
                        controller: _currentController,
                        label: 'Current password',
                        obscureText: _obscureCurrent,
                        prefixIcon: const Icon(Icons.lock_clock_outlined),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscureCurrent = !_obscureCurrent,
                          ),
                          icon: Icon(
                            _obscureCurrent
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                        validator: (v) => Validators.requiredField(
                          v,
                          field: 'Current password',
                        ),
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: _newController,
                        label: 'New password',
                        obscureText: _obscureNew,
                        onChanged: (_) => setState(() {}),
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _obscureNew = !_obscureNew),
                          icon: Icon(
                            _obscureNew
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                        validator: Validators.password,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: _confirmController,
                        label: 'Confirm new password',
                        obscureText: _obscureConfirm,
                        prefixIcon: const Icon(Icons.lock_person_outlined),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                        validator: (v) =>
                            Validators.confirmPassword(v, _newController.text),
                      ),
                      const SizedBox(height: 18),
                      CustomButton(
                        title: 'Update Password',
                        icon: const Icon(Icons.security_update_good_rounded),
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
