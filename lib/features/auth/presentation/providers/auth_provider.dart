import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:love_lang/core/constants/firestore_paths.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSubscription;

  AuthNotifier() : super(const AuthInitial()) {
    _init();
  }

  void _init() {
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        _userDocSubscription?.cancel();
        state = const Unauthenticated();
      } else {
        _listenToUserDoc(user);
      }
    });
  }

  void _listenToUserDoc(User user) {
    _userDocSubscription?.cancel();
    _userDocSubscription = _firestore
        .doc(FirestorePaths.userDoc(user.uid))
        .snapshots()
        .listen((doc) {
      if (!doc.exists) {
        state = Authenticated(
          user: user,
          pairingStatus: FirestorePaths.pairingStatusNone,
          coupleId: null,
        );
      } else {
        final data = doc.data();
        final pairingStatus = data?[FirestorePaths.userPairingStatus] as String? ??
            FirestorePaths.pairingStatusNone;
        final coupleId = data?[FirestorePaths.userCoupleId] as String?;
        state = Authenticated(
          user: user,
          pairingStatus: pairingStatus,
          coupleId: coupleId,
        );
      }
    }, onError: (error) {
      state = AuthError('Lỗi tải dữ liệu người dùng: $error');
    });
  }

  Future<void> signIn(String email, String password) async {
    state = const AuthLoading();
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      String msg = 'Đăng nhập thất bại.';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        msg = 'Tài khoản hoặc mật khẩu không chính xác.';
      } else if (e.code == 'wrong-password') {
        msg = 'Mật khẩu không chính xác.';
      } else if (e.code == 'invalid-email') {
        msg = 'Email không hợp lệ.';
      } else {
        msg = e.message ?? msg;
      }
      state = AuthError(msg);
      state = const Unauthenticated();
    } catch (e) {
      state = AuthError('Lỗi kết nối: $e');
      state = const Unauthenticated();
    }
  }

  Future<void> signUp(String email, String password) async {
    state = const AuthLoading();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        // Tạo document users/{uid}
        await _firestore.doc(FirestorePaths.userDoc(user.uid)).set({
          FirestorePaths.userCoupleId: null,
          FirestorePaths.userPairingStatus: FirestorePaths.pairingStatusNone,
        });
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Đăng ký thất bại.';
      if (e.code == 'email-already-in-use') {
        msg = 'Email đã được sử dụng bởi tài khoản khác.';
      } else if (e.code == 'weak-password') {
        msg = 'Mật khẩu quá yếu.';
      } else if (e.code == 'invalid-email') {
        msg = 'Email không hợp lệ.';
      } else {
        msg = e.message ?? msg;
      }
      state = AuthError(msg);
      state = const Unauthenticated();
    } catch (e) {
      state = AuthError('Lỗi kết nối: $e');
      state = const Unauthenticated();
    }
  }

  Future<void> signOut() async {
    state = const AuthLoading();
    try {
      await _auth.signOut();
    } catch (e) {
      state = AuthError('Đăng xuất thất bại: $e');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userDocSubscription?.cancel();
    super.dispose();
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
