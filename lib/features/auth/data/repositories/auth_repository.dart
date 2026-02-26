import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/services/firestore_service.dart';
import '../../../../core/utils/helpers.dart';
import '../models/password_reset_result.dart';
import '../models/user_model.dart';

class AuthRepository {
  static const String _googleServerClientId =
      '587798503861-5fgrph4q88rq4f0at4ns6dk7hb557g6q.apps.googleusercontent.com';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _googleInitialized = false;
  Map<String, dynamic>? _cachedProfile;

  UserModel? get currentUser {
    final user = _auth.currentUser;
    return user == null
        ? null
        : UserModel.fromFirebase(user, profile: _cachedProfile);
  }

  Stream<UserModel?> authStateChanges() {
    final controller = StreamController<UserModel?>();
    StreamSubscription<User?>? authSub;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? profileSub;

    Future<void> bindProfile(User firebaseUser) async {
      final profile = await _fetchOrCreateUserProfile(firebaseUser);
      _cachedProfile = profile;
      controller.add(UserModel.fromFirebase(firebaseUser, profile: profile));

      await profileSub?.cancel();
      profileSub = FirestoreService.usersRef()
          .doc(firebaseUser.uid)
          .snapshots()
          .listen((snapshot) {
            final data = snapshot.data();
            if (data == null) return;
            _cachedProfile = data;
            final liveUser = _auth.currentUser ?? firebaseUser;
            controller.add(UserModel.fromFirebase(liveUser, profile: data));
          }, onError: controller.addError);
    }

    authSub = _auth.userChanges().listen((firebaseUser) {
      if (firebaseUser == null) {
        _cachedProfile = null;
        unawaited(profileSub?.cancel());
        profileSub = null;
        controller.add(null);
        return;
      }
      unawaited(bindProfile(firebaseUser));
    }, onError: controller.addError);

    controller.onCancel = () async {
      await profileSub?.cancel();
      await authSub?.cancel();
    };

    return controller.stream;
  }

  Future<bool> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required AppRole role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final createdUser = credential.user;
      if (createdUser == null) {
        Helpers.showToast('Account created but user session was not available');
        return false;
      }

      await createdUser.updateDisplayName(name.trim());
      await _ensureProfile(
        uid: createdUser.uid,
        name: name.trim(),
        email: createdUser.email,
        role: role,
      );
      await createdUser.sendEmailVerification();
      await createdUser.reload();
      Helpers.showToast('Account created. Verification email sent.');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'registerWithEmail verification error: ${e.code} ${e.message}',
      );
      Helpers.showToast(mapFirebaseError(e.code));
      return false;
    }
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (result.user != null && !result.user!.emailVerified) {
        await _ensureProfile(
          uid: result.user!.uid,
          name: result.user!.displayName ?? '',
          email: result.user!.email,
        );
        await result.user!.sendEmailVerification();
        Helpers.showToast('Verify email first. New link sent.');
        return true;
      }
      if (result.user != null) {
        await _ensureProfile(
          uid: result.user!.uid,
          name: result.user!.displayName ?? '',
          email: result.user!.email,
        );
      }

      Helpers.showToast('Welcome back');
      return true;
    } on FirebaseAuthException catch (e) {
      Helpers.showToast(mapFirebaseError(e.code));
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        await _auth.signInWithPopup(GoogleAuthProvider());
      } else {
        await _ensureGoogleInitialized();
        final googleUser = await _googleSignIn.authenticate();
        final idToken = googleUser.authentication.idToken;

        if (idToken == null || idToken.isEmpty) {
          throw FirebaseAuthException(code: 'missing-google-id-token');
        }

        final credential = GoogleAuthProvider.credential(idToken: idToken);
        await _auth.signInWithCredential(credential);
      }
      final user = _auth.currentUser;
      if (user != null) {
        await _ensureProfile(
          uid: user.uid,
          name: user.displayName ?? '',
          email: user.email,
        );
      }

      Helpers.showToast('Google sign-in successful');
      return true;
    } on GoogleSignInException catch (e) {
      debugPrint('GoogleSignInException: ${e.code.name} ${e.description}');
      if (e.code == GoogleSignInExceptionCode.canceled) {
        Helpers.showToast('Google sign-in canceled');
      } else {
        Helpers.showToast('Google sign-in failed (${e.code.name})');
      }
      return false;
    } on FirebaseAuthException catch (e) {
      Helpers.showToast(mapFirebaseError(e.code));
      return false;
    } catch (e) {
      debugPrint('Google sign-in unknown error: $e');
      Helpers.showToast('Google sign-in failed. Try again.');
      return false;
    }
  }

  Future<PasswordResetResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return const PasswordResetResult(
        isSuccess: true,
        message:
            'If an account exists for this email, a reset link has been sent.',
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return const PasswordResetResult(
          isSuccess: true,
          message:
              'If an account exists for this email, a reset link has been sent.',
        );
      }
      return PasswordResetResult(
        isSuccess: false,
        message: mapFirebaseError(e.code),
      );
    }
  }

  Future<bool> resendEmailVerification() async {
    final current = _auth.currentUser;
    if (current == null) {
      Helpers.showToast('Please sign in first');
      return false;
    }

    try {
      await current.sendEmailVerification();
      Helpers.showToast('Verification email sent');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('resendEmailVerification error: ${e.code} ${e.message}');
      Helpers.showToast(mapFirebaseError(e.code));
      return false;
    }
  }

  Future<bool> refreshUser() async {
    await _auth.currentUser?.reload();
    final updated = _auth.currentUser;

    if (updated?.emailVerified == true) {
      Helpers.showToast('Email verified successfully');
      return true;
    }

    Helpers.showToast('Email still not verified');
    return false;
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await _ensureGoogleInitialized();
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
      Helpers.showToast('Signed out');
    } catch (_) {
      Helpers.showToast('Could not sign out');
    }
  }

  Future<bool> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
      Helpers.showToast('Account deleted');
      return true;
    } on FirebaseAuthException catch (e) {
      Helpers.showToast(mapFirebaseError(e.code));
      return false;
    }
  }

  Future<bool> changeEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    final current = _auth.currentUser;
    if (current == null) {
      Helpers.showToast('No active session');
      return false;
    }
    if (!current.providerData.any((p) => p.providerId == 'password')) {
      Helpers.showToast('Email change requires email/password account');
      return false;
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: current.email ?? '',
        password: currentPassword,
      );
      await current.reauthenticateWithCredential(credential);
      await current.verifyBeforeUpdateEmail(newEmail.trim());
      await current.reload();
      Helpers.showToast('Verification sent to new email');
      return true;
    } on FirebaseAuthException catch (e) {
      Helpers.showToast(mapFirebaseError(e.code));
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final current = _auth.currentUser;
    if (current == null) {
      Helpers.showToast('No active session');
      return false;
    }
    if (!current.providerData.any((p) => p.providerId == 'password')) {
      Helpers.showToast('Password change requires email/password account');
      return false;
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: current.email ?? '',
        password: currentPassword,
      );
      await current.reauthenticateWithCredential(credential);
      await current.updatePassword(newPassword);
      Helpers.showToast('Password updated');
      return true;
    } on FirebaseAuthException catch (e) {
      Helpers.showToast(mapFirebaseError(e.code));
      return false;
    }
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await _googleSignIn.initialize(serverClientId: _googleServerClientId);
    _googleInitialized = true;
  }

  Future<Map<String, dynamic>> _fetchOrCreateUserProfile(User user) async {
    final ref = FirestoreService.usersRef().doc(user.uid);
    final snapshot = await ref.get();
    if (!snapshot.exists) {
      final profile = <String, dynamic>{
        'uid': user.uid,
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'role': AppRole.admin.value,
        'linkedStudentIds': const <String>[],
        'teacherId': null,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await ref.set(profile);
      return profile;
    }
    return snapshot.data() ?? <String, dynamic>{};
  }

  Future<void> _ensureProfile({
    required String uid,
    required String name,
    required String? email,
    AppRole? role,
  }) async {
    final ref = FirestoreService.usersRef().doc(uid);
    final snapshot = await ref.get();
    if (!snapshot.exists) {
      await ref.set({
        'uid': uid,
        'name': name,
        'email': email ?? '',
        'role': (role ?? AppRole.admin).value,
        'linkedStudentIds': const <String>[],
        'teacherId': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }
    await ref.set({
      'name': name,
      'email': email ?? '',
      if (role != null) 'role': role.value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String mapFirebaseError(String code) {
    switch (code) {
      case 'weak-password':
        return 'Password is too weak';
      case 'email-already-in-use':
        return 'Email already in use';
      case 'invalid-email':
        return 'Invalid email address';
      case 'invalid-credential':
        return 'Invalid email or password';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'too-many-requests':
        return 'Too many requests. Try again later';
      case 'network-request-failed':
        return 'Network error. Check your connection';
      case 'operation-not-allowed':
        return 'Email/password sign-in is disabled in Firebase';
      case 'requires-recent-login':
        return 'Please sign in again and retry';
      case 'missing-google-id-token':
        return 'Google sign-in token missing';
      default:
        return 'Something went wrong. Try again';
    }
  }
}
