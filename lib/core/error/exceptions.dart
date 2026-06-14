// lib/core/error/exceptions.dart
// Phân cấp exception tùy chỉnh cho toàn bộ ứng dụng.
// Data layer ném các exception này; Domain/Presentation layer bắt chúng.

/// Exception gốc của ứng dụng — mọi exception đều kế thừa từ đây.
abstract class AppException implements Exception {
  final String message;
  final String? code;
  const AppException({required this.message, this.code});

  @override
  String toString() => 'AppException[$code]: $message';
}

// ─── Pairing Exceptions ───────────────────────────────────────────────────────

/// Mã mời không tồn tại trên Firestore.
class InviteNotFoundException extends AppException {
  const InviteNotFoundException()
      : super(
          message: 'Mã mời không tồn tại hoặc đã hết hạn.',
          code: 'invite-not-found',
        );
}

/// Mã mời đã được sử dụng hoặc hết hạn (status != pending).
class InviteExpiredException extends AppException {
  const InviteExpiredException()
      : super(
          message: 'Mã mời đã được sử dụng hoặc đã hết hạn.',
          code: 'invite-expired',
        );
}

/// Người dùng nhập mã mời do chính mình tạo ra.
class SelfPairingException extends AppException {
  const SelfPairingException()
      : super(
          message: 'Bạn không thể kết nối với chính mình.',
          code: 'self-pairing',
        );
}

/// Người tạo mã mời đã được ghép cặp với người khác rồi.
class CreatorAlreadyPairedException extends AppException {
  const CreatorAlreadyPairedException()
      : super(
          message: 'Người dùng này đã kết nối với người khác.',
          code: 'creator-already-paired',
        );
}

/// Người dùng hiện tại đã được ghép cặp rồi.
class AlreadyPairedException extends AppException {
  const AlreadyPairedException()
      : super(
          message: 'Bạn đã được kết nối với ai đó. Hãy hủy kết nối trước.',
          code: 'already-paired',
        );
}

// ─── Network / Firebase Exceptions ───────────────────────────────────────────

/// Lỗi mạng hoặc Firestore không phản hồi.
class NetworkException extends AppException {
  const NetworkException(
      {super.message = 'Lỗi kết nối mạng. Vui lòng thử lại.'})
      : super(code: 'network-error');
}

/// Lỗi khi Firestore transaction thất bại.
class TransactionException extends AppException {
  const TransactionException({
    super.message = 'Giao dịch thất bại. Vui lòng thử lại.',
  }) : super(code: 'transaction-failed');
}

/// Người dùng chưa đăng nhập.
class UnauthenticatedException extends AppException {
  const UnauthenticatedException()
      : super(
          message: 'Bạn cần đăng nhập để thực hiện thao tác này.',
          code: 'unauthenticated',
        );
}

/// Lỗi không xác định từ server.
class ServerException extends AppException {
  const ServerException({super.message = 'Đã có lỗi xảy ra từ phía máy chủ.'})
      : super(code: 'server-error');
}
