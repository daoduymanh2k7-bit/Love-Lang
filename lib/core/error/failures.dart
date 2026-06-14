// lib/core/error/failures.dart
// Domain-level failures — được dùng bởi Repository interface và UseCase.
// Presentation layer chỉ nhìn thấy Failure, không biết gì về Exception cụ thể.

/// Failure gốc — sealed class để bắt buộc xử lý mọi trường hợp.
sealed class Failure {
  final String message;
  const Failure({required this.message});
}

// ─── Pairing Failures ─────────────────────────────────────────────────────────

/// Mã mời không hợp lệ hoặc không tồn tại.
class InviteNotFoundFailure extends Failure {
  const InviteNotFoundFailure()
      : super(message: 'Mã mời không tồn tại hoặc đã hết hạn.');
}

/// Mã mời đã hết hạn hoặc đã được dùng.
class InviteExpiredFailure extends Failure {
  const InviteExpiredFailure()
      : super(message: 'Mã mời đã được sử dụng hoặc đã hết hạn.');
}

/// Người dùng cố kết nối với chính họ.
class SelfPairingFailure extends Failure {
  const SelfPairingFailure()
      : super(message: 'Bạn không thể kết nối với chính mình.');
}

/// Người tạo mã đã được ghép cặp với người khác.
class CreatorAlreadyPairedFailure extends Failure {
  const CreatorAlreadyPairedFailure()
      : super(message: 'Người dùng này đã kết nối với người khác.');
}

/// Người dùng hiện tại đã được ghép cặp.
class AlreadyPairedFailure extends Failure {
  const AlreadyPairedFailure()
      : super(message: 'Bạn đã được kết nối với ai đó.');
}

// ─── Generic Failures ─────────────────────────────────────────────────────────

/// Lỗi mạng.
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'Lỗi kết nối mạng. Vui lòng thử lại.'});
}

/// Lỗi transaction Firestore.
class TransactionFailure extends Failure {
  const TransactionFailure({super.message = 'Giao dịch thất bại. Vui lòng thử lại.'});
}

/// Người dùng chưa đăng nhập.
class UnauthenticatedFailure extends Failure {
  const UnauthenticatedFailure()
      : super(message: 'Bạn cần đăng nhập để thực hiện thao tác này.');
}

/// Lỗi server không xác định.
class ServerFailure extends Failure {
  const ServerFailure({super.message = 'Đã có lỗi xảy ra. Vui lòng thử lại.'});
}
