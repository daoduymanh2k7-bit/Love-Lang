// lib/features/bucket_list/domain/usecases/watch_bucket_items_usecase.dart

import '../entities/bucket_item_entity.dart';
import '../repositories/bucket_list_repository.dart';

class WatchBucketItemsUseCase {
  final BucketListRepository _repository;
  const WatchBucketItemsUseCase(this._repository);

  Stream<List<BucketItemEntity>> call(String coupleId) {
    return _repository.watchItems(coupleId);
  }
}
