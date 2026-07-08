// lib/features/bucket_list/domain/repositories/bucket_item_repository.dart

import '../../data/datasources/bucket_list_remote_datasource.dart';
import '../models/bucket_item_model.dart';

class BucketItemRepository {
  final BucketListRemoteDataSource _remoteDataSource;

  BucketItemRepository(this._remoteDataSource);

  /// Stream all items for a couple, most recent first.
  Stream<List<BucketItemModel>> watchItems(String coupleId) {
    return _remoteDataSource.watchItems(coupleId);
  }

  Future<void> addItem(BucketItemModel item) async {
    await _remoteDataSource.addItem(item);
  }

  Future<void> updateItem(BucketItemModel item) async {
    await _remoteDataSource.updateItem(item);
  }

  Future<void> deleteItem(String coupleId, String itemId) async {
    await _remoteDataSource.deleteItem(coupleId, itemId);
  }

  Future<void> markDone(String coupleId, String itemId,
      {String? linkedAlbumId}) async {
    await _remoteDataSource.markDone(coupleId, itemId,
        linkedAlbumId: linkedAlbumId);
  }
}
