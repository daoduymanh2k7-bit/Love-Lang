import '../entities/diary_entry_entity.dart';

abstract interface class DiaryRepository {
  Stream<List<DiaryEntryEntity>> watchDiaryEntries(
      String coupleId, String currentUserId);
  Future<void> createDiaryEntry(DiaryEntryEntity entry);
  Future<void> updateDiaryEntry(DiaryEntryEntity entry);
  Future<void> deleteDiaryEntry(String coupleId, String entryId);
}
