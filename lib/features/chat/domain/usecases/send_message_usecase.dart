// lib/features/chat/domain/usecases/send_message_usecase.dart

import 'package:love_lang/features/chat/domain/entities/message_entity.dart';
import 'package:love_lang/features/chat/domain/repositories/chat_repository.dart';

class SendMessageUseCase {
  final ChatRepository _repository;

  SendMessageUseCase(this._repository);

  Future<void> call(MessageEntity message) async {
    if (message.content.isEmpty && message.type != MessageType.nudge) {
      throw ArgumentError('Nội dung tin nhắn không được để trống.');
    }
    return _repository.sendMessage(message);
  }

  Future<void> sendVoice(
      String coupleId, String senderId, String filePath) async {
    if (filePath.isEmpty) throw ArgumentError('File ghi âm không tồn tại.');
    return _repository.sendVoiceMessage(coupleId, senderId, filePath);
  }

  Future<void> sendImage(
      String coupleId, String senderId, String filePath) async {
    if (filePath.isEmpty) throw ArgumentError('File ảnh không tồn tại.');
    return _repository.sendImageMessage(coupleId, senderId, filePath);
  }
}