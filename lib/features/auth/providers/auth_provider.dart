import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/helpers.dart';
import '../../../core/utils/role_routing.dart';
import '../data/models/password_reset_result.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository})
    : _repository = repository ?? AuthRepository() {
    // Avoid long splash waits: seed initial state synchronously.
    _user = _repository.currentUser;
    _isInitialized = true;
    _sub = _repository.authStateChanges().listen(
      (user) {
        final previous = _user;
        _user = user;
        _handleRoleChange(previous, user);
        notifyListeners();
      },
      onError: (_) {
        // Do not block app navigation if stream fails transiently.
        _isInitialized = true;
        notifyListeners();
      },
    );
  }

  final AuthRepository _repository;
  StreamSubscription<UserModel?>? _sub;

  UserModel? _user;
  bool _isLoading = false;
  bool _isInitialized = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _user != null;
  AppRole get role => _user?.role ?? AppRole.admin;
  bool get isAdmin => role == AppRole.admin;
  bool get isTeacher => role == AppRole.teacher;
  bool get isParent => role == AppRole.parent;
  bool get isStudent => role == AppRole.student;
  String? get teacherId => _user?.teacherId;
  List<String> get linkedStudentIds => _user?.linkedStudentIds ?? const [];
  bool get requiresEmailVerification {
    final current = _user;
    if (current == null) return false;
    return current.isPasswordUser && !current.emailVerified;
  }

  Future<bool> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required AppRole role,
  }) async {
    final ok = await _withLoading(
      () => _repository.registerWithEmail(
        name: name,
        email: email,
        password: password,
        role: role,
      ),
    );
    _syncUser();
    return ok;
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final ok = await _withLoading(
      () => _repository.signInWithEmail(email: email, password: password),
    );
    _syncUser();
    return ok;
  }

  Future<bool> signInWithGoogle() async {
    final ok = await _withLoading(_repository.signInWithGoogle);
    _syncUser();
    return ok;
  }

  Future<PasswordResetResult> sendPasswordResetEmail(String email) {
    return _withLoading(() => _repository.sendPasswordResetEmail(email));
  }

  Future<bool> resendEmailVerification() {
    return _withLoading(_repository.resendEmailVerification);
  }

  Future<bool> refreshUser() async {
    final ok = await _withLoading(_repository.refreshUser);
    _syncUser();
    return ok;
  }

  Future<void> signOut() async {
    await _withLoading(() async {
      await _repository.signOut();
      return true;
    });
    _syncUser();
  }

  Future<bool> deleteAccount() async {
    final ok = await _withLoading(_repository.deleteAccount);
    _syncUser();
    return ok;
  }

  Future<bool> changeEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    final ok = await _withLoading(
      () => _repository.changeEmail(
        newEmail: newEmail,
        currentPassword: currentPassword,
      ),
    );
    _syncUser();
    return ok;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _withLoading(
      () => _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      ),
    );
  }

  Future<T> _withLoading<T>(Future<T> Function() action) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await action();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _syncUser() {
    _user = _repository.currentUser;
    notifyListeners();
  }

  void _handleRoleChange(UserModel? previous, UserModel? current) {
    if (previous == null || current == null) return;
    if (previous.role == current.role) return;
    if (current.isPasswordUser && !current.emailVerified) return;
    final target = landingRouteForRole(current.role);
    final currentRoute = Get.currentRoute;
    if (currentRoute == target) return;

    Helpers.showToast('Role updated to ${_roleLabel(current.role)}');
    unawaited(Get.offAllNamed(target));
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

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
