// lib/features/bucket_list/data/repositories/bucket_list_repository_impl.dart

import 'package:firebase_core/firebase_core.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/bucket_item_entity.dart';
import '../../domain/repositories/bucket_list_repository.dart';
import '../datasources/bucket_list_remote_datasource.dart';
import '../../domain/models/bucket_item_model.dart';

class BucketListRepositoryImpl implements BucketListRepository {
  final BucketListRemoteDataSource _remoteDataSource;

  BucketListRepositoryImpl(this._remoteDataSource);

  @override
  Stream<List<BucketItemEntity>> watchItems(String coupleId) {
    try {
      return _remoteDataSource.watchItems(coupleId);
    } catch (e) {
      throw const ServerFailure();
    }
  }

  @override
  Future<void> addItem(BucketItemEntity item) async {
    try {
      final model = BucketItemModel(
          id: item.id,
          coupleId: item.coupleId,
          title: item.title,
          description: item.description,
          isDone: item.isDone,
          completedAt: item.completedAt,
          createdAt: item.createdAt,
          createdBy: item.createdBy,
          linkedAlbumId: item.linkedAlbumId,
        );
      await _remoteDataSource.addItem(model);
    } on FirebaseException catch (e) {
      throw ServerFailure(message: e.message ?? 'Lỗi khi thêm mục tiêu');
    } catch (e) {
      throw const ServerFailure();
    }
  }

  @override
  Future<void> updateItem(BucketItemEntity item) async {
    try {
      final model = BucketItemModel(
          id: item.id,
          coupleId: item.coupleId,
          title: item.title,
          description: item.description,
          isDone: item.isDone,
          completedAt: item.completedAt,
          createdAt: item.createdAt,
          createdBy: item.createdBy,
          linkedAlbumId: item.linkedAlbumId,
        );
      await _remoteDataSource.updateItem(model);
    } on FirebaseException catch (e) {
      throw ServerFailure(message: e.message ?? 'Lỗi khi cập nhật mục tiêu');
    } catch (e) {
      throw const ServerFailure();
    }
  }

  @override
  Future<void> deleteItem(String coupleId, String itemId) async {
    try {
      await _remoteDataSource.deleteItem(coupleId, itemId);
    } on FirebaseException catch (e) {
      throw ServerFailure(message: e.message ?? 'Lỗi khi xóa mục tiêu');
    } catch (e) {
      throw const ServerFailure();
    }
  }

  @override
  Future<void> markDone(
    String coupleId,
    String itemId, {
    String? linkedAlbumId,
  }) async {
    try {
      await _remoteDataSource.markDone(coupleId, itemId,
          linkedAlbumId: linkedAlbumId);
    } on FirebaseException catch (e) {
      throw ServerFailure(message: e.message ?? 'Lỗi khi đánh dấu hoàn thành');
    } catch (e) {
      throw const ServerFailure();
    }
  }
}
