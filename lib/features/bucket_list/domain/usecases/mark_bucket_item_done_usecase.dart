// lib/features/bucket_list/domain/usecases/mark_bucket_item_done_usecase.dart

import '../repositories/bucket_list_repository.dart';

class MarkBucketItemDoneUseCase {
  final BucketListRepository _repository;
  const MarkBucketItemDoneUseCase(this._repository);

  Future<void> call(
    String coupleId,
    String itemId, {
    String? linkedAlbumId,
  }) {
    return _repository.markDone(coupleId, itemId, linkedAlbumId: linkedAlbumId);
  }
}
