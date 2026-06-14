import '../entities/diary_entry_entity.dart';
import '../repositories/diary_repository.dart';

class UpdateDiaryEntryUseCase {
  final DiaryRepository _repository;

  const UpdateDiaryEntryUseCase(this._repository);

  Future<void> call(DiaryEntryEntity entry) {
    return _repository.updateDiaryEntry(entry);
  }
}
