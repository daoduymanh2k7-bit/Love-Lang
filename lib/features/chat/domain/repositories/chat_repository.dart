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

  /// Tải file ảnh lên Storage và sau đó gửi tin nhắn Image.
  Future<void> sendImageMessage(
      String coupleId, String senderId, String filePath);

  /// Tăng số lần "nudge" (chọc ghẹo) giữa 2 người trong cặp đôi.
  Future<void> incrementNudgeCount(String coupleId);

  /// Lắng nghe realtime số lần nudge hiện tại.
  Stream<int> watchNudgeCount(String coupleId);

  /// Đánh dấu đã đọc tất cả tin nhắn CHƯA đọc mà KHÔNG PHẢI do [readerId] gửi
  /// (tức tin nhắn của đối phương) trong cuộc trò chuyện [coupleId].
  Future<void> markMessagesAsRead(String coupleId, String readerId);
}