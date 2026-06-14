// lib/features/chat/domain/usecases/watch_messages_usecase.dart

import 'package:love_lang/features/chat/domain/entities/message_entity.dart';
import 'package:love_lang/features/chat/domain/repositories/chat_repository.dart';

class WatchMessagesUseCase {
  final ChatRepository _repository;

  WatchMessagesUseCase(this._repository);

  Stream<List<MessageEntity>> call(String coupleId) {
    if (coupleId.isEmpty) throw ArgumentError('coupleId không hợp lệ.');
    return _repository.watchMessages(coupleId);
  }
}
