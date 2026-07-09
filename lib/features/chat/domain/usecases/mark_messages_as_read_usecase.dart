// lib/features/chat/domain/usecases/mark_messages_as_read_usecase.dart

import 'package:love_lang/features/chat/domain/repositories/chat_repository.dart';

/// Đánh dấu các tin nhắn của đối phương là đã đọc, khi người dùng hiện tại
/// đang xem màn hình chat.
class MarkMessagesAsReadUseCase {
  final ChatRepository _repository;

  MarkMessagesAsReadUseCase(this._repository);

  Future<void> call(String coupleId, String readerId) async {
    if (coupleId.isEmpty || readerId.isEmpty) return;
    return _repository.markMessagesAsRead(coupleId, readerId);
  }
}