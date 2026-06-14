// lib/features/bucket_list/domain/usecases/add_bucket_item_usecase.dart

import '../entities/bucket_item_entity.dart';
import '../repositories/bucket_list_repository.dart';

class AddBucketItemUseCase {
  final BucketListRepository _repository;
  const AddBucketItemUseCase(this._repository);

  Future<void> call(BucketItemEntity item) {
    return _repository.addItem(item);
  }
}
