// lib/features/chat/domain/repositories/chat_repository.dart

import 'package:love_lang/features/chat/domain/entities/message_entity.dart';

abstract interface class ChatRepository {
  /// Lắng nghe danh sách tin nhắn theo thời gian thực (giới hạn số lượng để tối ưu).
  Stream<List<MessageEntity>> watchMessages(String coupleId);

  /// Gửi một tin nhắn (Text hoặc Nudge).
  Future<void> sendMessage(MessageEntity message);

  /// Tải file ghi âm lên Storage và sau đó gửi tin nhắn Voice.
  Future<void> sendVoiceMessage(
      String coupleId, String senderId, String filePath);
}
