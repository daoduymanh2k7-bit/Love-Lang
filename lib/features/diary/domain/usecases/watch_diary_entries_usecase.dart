import '../entities/diary_entry_entity.dart';
import '../repositories/diary_repository.dart';

class WatchDiaryEntriesUseCase {
  final DiaryRepository _repository;

  const WatchDiaryEntriesUseCase(this._repository);

  Stream<List<DiaryEntryEntity>> call(String coupleId, String currentUserId) {
    return _repository.watchDiaryEntries(coupleId, currentUserId);
  }
}
