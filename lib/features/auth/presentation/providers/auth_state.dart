import 'package:firebase_auth/firebase_auth.dart';

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  final User user;
  final String pairingStatus; // 'none' or 'paired'
  final String? coupleId;

  /// true nếu user đã thấy màn "Đặt tên & avatar" (dù đã lưu hay bấm bỏ
  /// qua) — dùng để quyết định có cần chèn ProfileSetupScreen trước khi
  /// vào EnterInviteScreen hay không. Xem main.dart.
  final bool profileSetupPrompted;

  const Authenticated({
    required this.user,
    required this.pairingStatus,
    this.coupleId,
    this.profileSetupPrompted = false,
  });
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}