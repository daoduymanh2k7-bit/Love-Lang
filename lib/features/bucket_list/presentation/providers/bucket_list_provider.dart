// lib/features/bucket_list/presentation/providers/bucket_list_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/bucket_item_entity.dart';
import '../../domain/repositories/bucket_list_repository.dart';
import '../../domain/usecases/watch_bucket_items_usecase.dart';
import '../../domain/usecases/add_bucket_item_usecase.dart';
import '../../domain/usecases/update_bucket_item_usecase.dart';
import '../../domain/usecases/delete_bucket_item_usecase.dart';
import '../../domain/usecases/mark_bucket_item_done_usecase.dart';
import '../../data/datasources/bucket_list_remote_datasource.dart';
import '../../data/repositories/bucket_list_repository_impl.dart';
import '../../../../core/error/failures.dart';

// ─── Infrastructure providers ─────────────────────────────────────────────────

final bucketListDataSourceProvider =
    Provider<BucketListRemoteDataSource>((ref) {
  return BucketListRemoteDataSource(FirebaseFirestore.instance);
});

final bucketListRepositoryProvider = Provider<BucketListRepository>((ref) {
  return BucketListRepositoryImpl(ref.watch(bucketListDataSourceProvider));
});

// ─── Use-case providers ───────────────────────────────────────────────────────

final watchBucketItemsUseCaseProvider =
    Provider<WatchBucketItemsUseCase>((ref) {
  return WatchBucketItemsUseCase(ref.watch(bucketListRepositoryProvider));
});

final addBucketItemUseCaseProvider = Provider<AddBucketItemUseCase>((ref) {
  return AddBucketItemUseCase(ref.watch(bucketListRepositoryProvider));
});

final updateBucketItemUseCaseProvider =
    Provider<UpdateBucketItemUseCase>((ref) {
  return UpdateBucketItemUseCase(ref.watch(bucketListRepositoryProvider));
});

final deleteBucketItemUseCaseProvider =
    Provider<DeleteBucketItemUseCase>((ref) {
  return DeleteBucketItemUseCase(ref.watch(bucketListRepositoryProvider));
});

final markBucketItemDoneUseCaseProvider =
    Provider<MarkBucketItemDoneUseCase>((ref) {
  return MarkBucketItemDoneUseCase(ref.watch(bucketListRepositoryProvider));
});

// ─── Stream provider ──────────────────────────────────────────────────────────

final bucketItemsProvider =
    StreamProvider.family<List<BucketItemEntity>, String>((ref, coupleId) {
  return ref.watch(watchBucketItemsUseCaseProvider)(coupleId);
});

// ─── Notifier ─────────────────────────────────────────────────────────────────

class BucketListNotifier extends StateNotifier<AsyncValue<void>> {
  final AddBucketItemUseCase _addUseCase;
  final UpdateBucketItemUseCase _updateUseCase;
  final DeleteBucketItemUseCase _deleteUseCase;
  final MarkBucketItemDoneUseCase _markDoneUseCase;

  BucketListNotifier({
    required AddBucketItemUseCase addUseCase,
    required UpdateBucketItemUseCase updateUseCase,
    required DeleteBucketItemUseCase deleteUseCase,
    required MarkBucketItemDoneUseCase markDoneUseCase,
  })  : _addUseCase = addUseCase,
        _updateUseCase = updateUseCase,
        _deleteUseCase = deleteUseCase,
        _markDoneUseCase = markDoneUseCase,
        super(const AsyncData(null));

  Future<void> addItem(BucketItemEntity item) async {
    state = const AsyncLoading();
    try {
      await _addUseCase(item);
      state = const AsyncData(null);
    } on Failure catch (e) {
      state = AsyncError(e, StackTrace.current);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> updateItem(BucketItemEntity item) async {
    state = const AsyncLoading();
    try {
      await _updateUseCase(item);
      state = const AsyncData(null);
    } on Failure catch (e) {
      state = AsyncError(e, StackTrace.current);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> deleteItem(String coupleId, String itemId) async {
    state = const AsyncLoading();
    try {
      await _deleteUseCase(coupleId, itemId);
      state = const AsyncData(null);
    } on Failure catch (e) {
      state = AsyncError(e, StackTrace.current);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> markDone(
    String coupleId,
    String itemId, {
    String? linkedAlbumId,
    String? completionImageUrl,
  }) async {
    state = const AsyncLoading();
    try {
      await _markDoneUseCase(coupleId, itemId,
          linkedAlbumId: linkedAlbumId, completionImageUrl: completionImageUrl);
      state = const AsyncData(null);
    } on Failure catch (e) {
      state = AsyncError(e, StackTrace.current);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}

final bucketListNotifierProvider =
    StateNotifierProvider<BucketListNotifier, AsyncValue<void>>((ref) {
  return BucketListNotifier(
    addUseCase: ref.watch(addBucketItemUseCaseProvider),
    updateUseCase: ref.watch(updateBucketItemUseCaseProvider),
    deleteUseCase: ref.watch(deleteBucketItemUseCaseProvider),
    markDoneUseCase: ref.watch(markBucketItemDoneUseCaseProvider),
  );
});
