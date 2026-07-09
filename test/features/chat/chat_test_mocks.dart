// test/features/chat/chat_test_mocks.dart
//
// Mock/fake dùng chung cho các test của feature `chat` (usecases + repository).
// Dùng package `mocktail` — không cần code generation (build_runner).

import 'package:mocktail/mocktail.dart';
import 'package:love_lang/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:love_lang/features/chat/data/models/message_model.dart';
import 'package:love_lang/features/chat/domain/entities/message_entity.dart';
import 'package:love_lang/features/chat/domain/repositories/chat_repository.dart';

class MockChatRepository extends Mock implements ChatRepository {}

class MockChatRemoteDatasource extends Mock implements ChatRemoteDatasource {}

/// Entity mẫu dùng để đăng ký fallback value cho `any()` khi mock nhận
/// tham số kiểu [MessageEntity] (mocktail yêu cầu điều này với các kiểu
/// không phải built-in).
final fallbackMessageEntity = MessageEntity(
  id: 'fallback-id',
  senderId: 'fallback-sender',
  coupleId: 'fallback-couple',
  content: 'fallback',
  type: MessageType.text,
  timestamp: DateTime(2024, 1, 1),
);

final fallbackMessageModel = MessageModel(
  id: 'fallback-id',
  senderId: 'fallback-sender',
  coupleId: 'fallback-couple',
  content: 'fallback',
  type: MessageType.text,
  timestamp: DateTime(2024, 1, 1),
);

/// Helper tạo nhanh một [MessageEntity] hợp lệ cho test, cho phép override
/// từng field khi cần.
MessageEntity buildMessage({
  String id = 'msg-1',
  String senderId = 'user-a',
  String coupleId = 'couple-1',
  String content = 'Hello',
  MessageType type = MessageType.text,
  DateTime? timestamp,
  bool isRead = false,
}) {
  return MessageEntity(
    id: id,
    senderId: senderId,
    coupleId: coupleId,
    content: content,
    type: type,
    timestamp: timestamp ?? DateTime(2024, 1, 1),
    isRead: isRead,
  );
}