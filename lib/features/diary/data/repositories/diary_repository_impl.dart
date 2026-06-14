import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/diary_entry_entity.dart';
import '../../domain/repositories/diary_repository.dart';
import '../datasources/diary_remote_datasource.dart';
import '../models/diary_entry_model.dart';

class DiaryRepositoryImpl implements DiaryRepository {
  final DiaryRemoteDataSource _remoteDataSource;

  DiaryRepositoryImpl(this._remoteDataSource);

  @override
  Stream<List<DiaryEntryEntity>> watchDiaryEntries(String coupleId, String currentUserId) {
    try {
      return _remoteDataSource.watchDiaryEntries(coupleId, currentUserId);
    } catch (e) {
      // Bắt lỗi khi tạo stream (thường lỗi luồng sẽ emit qua onError, 
      // nhưng có thể ném ra lúc query builder)
      throw const ServerFailure();
    }
  }

  @override
  Future<void> createDiaryEntry(DiaryEntryEntity entry) async {
    try {
      final model = DiaryEntryModel.fromEntity(entry);
      await _remoteDataSource.createDiaryEntry(model);
    } on FirebaseException catch (e) {
      throw ServerFailure(message: e.message ?? 'Lỗi Firebase khi tạo nhật ký');
    } catch (e) {
      throw const ServerFailure();
    }
  }

  @override
  Future<void> updateDiaryEntry(DiaryEntryEntity entry) async {
    try {
      final model = DiaryEntryModel.fromEntity(entry);
      await _remoteDataSource.updateDiaryEntry(model);
    } on FirebaseException catch (e) {
      throw ServerFailure(message: e.message ?? 'Lỗi Firebase khi cập nhật nhật ký');
    } catch (e) {
      throw const ServerFailure();
    }
  }

  @override
  Future<void> deleteDiaryEntry(String coupleId, String entryId) async {
    try {
      await _remoteDataSource.deleteDiaryEntry(coupleId, entryId);
    } on FirebaseException catch (e) {
      throw ServerFailure(message: e.message ?? 'Lỗi Firebase khi xóa nhật ký');
    } catch (e) {
      throw const ServerFailure();
    }
  }
}
