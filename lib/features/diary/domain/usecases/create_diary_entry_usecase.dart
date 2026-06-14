import '../entities/diary_entry_entity.dart';
import '../repositories/diary_repository.dart';

class CreateDiaryEntryUseCase {
  final DiaryRepository _repository;

  const CreateDiaryEntryUseCase(this._repository);

  Future<void> call(DiaryEntryEntity entry) {
    return _repository.createDiaryEntry(entry);
  }
}
