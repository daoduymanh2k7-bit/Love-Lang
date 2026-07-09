// lib/features/chat/domain/usecases/watch_nudge_count_usecase.dart

import 'package:love_lang/features/chat/domain/repositories/chat_repository.dart';

class WatchNudgeCountUseCase {
  final ChatRepository _repository;

  WatchNudgeCountUseCase(this._repository);

  Stream<int> call(String coupleId) {
    if (coupleId.isEmpty) throw ArgumentError('coupleId không hợp lệ.');
    return _repository.watchNudgeCount(coupleId);
  }
}