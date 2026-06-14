// lib/features/pairing/presentation/providers/pairing_state.dart
// Định nghĩa các trạng thái UI cho tính năng kết nối (Pairing).

import 'package:love_lang/features/pairing/domain/entities/couple_entity.dart';
import 'package:love_lang/features/pairing/domain/entities/invite_entity.dart';

/// Sealed class biểu diễn trạng thái của quá trình kết nối.
/// Giúp Riverpod UI dễ dàng map qua các trạng thái bằng `switch`.
sealed class PairingState {
  const PairingState();
}

/// Trạng thái ban đầu, chưa có hành động gì.
final class PairingInitial extends PairingState {
  const PairingInitial();
}

/// Trạng thái đang xử lý (gọi API/Transaction).
/// UI sẽ hiển thị loading spinner.
final class PairingLoading extends PairingState {
  const PairingLoading();
}

/// Trạng thái kết nối thành công.
/// Chứa thông tin cặp đôi trả về để UI cập nhật (vd: chuyển hướng, hiển thị thông báo).
final class PairingSuccess extends PairingState {
  final CoupleEntity couple;
  const PairingSuccess(this.couple);
}

/// Trạng thái tạo mã mời thành công.
final class PairingInviteCreated extends PairingState {
  final InviteEntity invite;
  const PairingInviteCreated(this.invite);
}

/// Trạng thái lỗi.
/// Chứa thông báo lỗi thân thiện với người dùng (đã được parse từ Exception/Failure).
final class PairingError extends PairingState {
  final String message;
  const PairingError(this.message);
}
