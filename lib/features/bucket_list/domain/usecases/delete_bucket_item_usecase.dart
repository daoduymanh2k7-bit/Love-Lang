// lib/features/bucket_list/domain/usecases/delete_bucket_item_usecase.dart

import '../repositories/bucket_list_repository.dart';

class DeleteBucketItemUseCase {
  final BucketListRepository _repository;
  const DeleteBucketItemUseCase(this._repository);

  Future<void> call(String coupleId, String itemId) {
    return _repository.deleteItem(coupleId, itemId);
  }
}
