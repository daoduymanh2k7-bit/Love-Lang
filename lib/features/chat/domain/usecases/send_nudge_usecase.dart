// lib/features/chat/domain/usecases/send_nudge_usecase.dart

import 'package:love_lang/features/chat/domain/repositories/chat_repository.dart';

/// Gửi "nudge" (chọc ghẹo đối phương).
///
/// Lưu ý: khác với tin nhắn thông thường, nudge KHÔNG tạo ra một
/// [MessageEntity] mới — nó chỉ tăng một bộ đếm (`nudgeCount`) trên
/// document của cặp đôi. Vì vậy được tách thành usecase riêng thay vì
/// tái sử dụng [SendMessageUseCase].
class SendNudgeUseCase {
  final ChatRepository _repository;

  SendNudgeUseCase(this._repository);

  Future<void> call(String coupleId) async {
    if (coupleId.isEmpty) throw ArgumentError('coupleId không hợp lệ.');
    return _repository.incrementNudgeCount(coupleId);
  }
}