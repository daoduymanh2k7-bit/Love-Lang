// lib/features/bucket_list/domain/repositories/bucket_list_repository.dart

import '../entities/bucket_item_entity.dart';

abstract interface class BucketListRepository {
  /// Lắng nghe danh sách bucket items theo thời gian thực.
  Stream<List<BucketItemEntity>> watchItems(String coupleId);

  /// Thêm item mới.
  Future<void> addItem(BucketItemEntity item);

  /// Cập nhật tiêu đề / mô tả.
  Future<void> updateItem(BucketItemEntity item);

  /// Xóa item.
  Future<void> deleteItem(String coupleId, String itemId);

  /// Đánh dấu hoàn thành, tuỳ chọn gắn linkedAlbumId.
  Future<void> markDone(String coupleId, String itemId, {String? linkedAlbumId});
}
