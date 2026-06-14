import '../repositories/diary_repository.dart';

class DeleteDiaryEntryUseCase {
  final DiaryRepository _repository;

  const DeleteDiaryEntryUseCase(this._repository);

  Future<void> call(String coupleId, String entryId) {
    return _repository.deleteDiaryEntry(coupleId, entryId);
  }
}
