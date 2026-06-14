// lib/features/bucket_list/domain/usecases/update_bucket_item_usecase.dart

import '../entities/bucket_item_entity.dart';
import '../repositories/bucket_list_repository.dart';

class UpdateBucketItemUseCase {
  final BucketListRepository _repository;
  const UpdateBucketItemUseCase(this._repository);

  Future<void> call(BucketItemEntity item) {
    return _repository.updateItem(item);
  }
}
