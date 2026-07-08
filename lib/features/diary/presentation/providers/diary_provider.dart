import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/diary_entry_entity.dart';
import '../../domain/usecases/watch_diary_entries_usecase.dart';
import '../../domain/usecases/create_diary_entry_usecase.dart';
import '../../domain/usecases/update_diary_entry_usecase.dart';
import '../../domain/usecases/delete_diary_entry_usecase.dart';
import '../../data/datasources/diary_remote_datasource.dart';
import '../../data/repositories/diary_repository_impl.dart';
import 'diary_state.dart';
import '../../../../core/error/failures.dart';

// Providers for dependencies
final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final diaryRemoteDataSourceProvider = Provider<DiaryRemoteDataSource>((ref) {
  return DiaryRemoteDataSource(ref.watch(firestoreProvider));
});

final diaryRepositoryProvider = Provider<DiaryRepositoryImpl>((ref) {
  return DiaryRepositoryImpl(ref.watch(diaryRemoteDataSourceProvider));
});

final watchDiaryEntriesUseCaseProvider =
    Provider<WatchDiaryEntriesUseCase>((ref) {
  return WatchDiaryEntriesUseCase(ref.watch(diaryRepositoryProvider));
});

final createDiaryEntryUseCaseProvider =
    Provider<CreateDiaryEntryUseCase>((ref) {
  return CreateDiaryEntryUseCase(ref.watch(diaryRepositoryProvider));
});

final updateDiaryEntryUseCaseProvider =
    Provider<UpdateDiaryEntryUseCase>((ref) {
  return UpdateDiaryEntryUseCase(ref.watch(diaryRepositoryProvider));
});

final deleteDiaryEntryUseCaseProvider =
    Provider<DeleteDiaryEntryUseCase>((ref) {
  return DeleteDiaryEntryUseCase(ref.watch(diaryRepositoryProvider));
});

// Stream provider for listening to diary entries
final diaryEntriesProvider = StreamProvider.family<List<DiaryEntryEntity>,
    ({String coupleId, String currentUserId})>((ref, args) {
  final watchUseCase = ref.watch(watchDiaryEntriesUseCaseProvider);
  return watchUseCase(args.coupleId, args.currentUserId);
});

class DiaryNotifier extends StateNotifier<DiaryState> {
  final CreateDiaryEntryUseCase _createUseCase;
  final UpdateDiaryEntryUseCase _updateUseCase;
  final DeleteDiaryEntryUseCase _deleteUseCase;

  DiaryNotifier({
    required CreateDiaryEntryUseCase createUseCase,
    required UpdateDiaryEntryUseCase updateUseCase,
    required DeleteDiaryEntryUseCase deleteUseCase,
  })  : _createUseCase = createUseCase,
        _updateUseCase = updateUseCase,
        _deleteUseCase = deleteUseCase,
        super(const DiaryInitial());

  Future<void> createEntry(DiaryEntryEntity entry) async {
    state = const DiaryLoading();
    try {
      await _createUseCase(entry);
      state = const DiaryLoaded();
    } on Failure catch (e) {
      state = DiaryError(e.message);
    } catch (e) {
      state = const DiaryError('Đã có lỗi xảy ra.');
    }
  }

  Future<void> updateEntry(DiaryEntryEntity entry) async {
    state = const DiaryLoading();
    try {
      await _updateUseCase(entry);
      state = const DiaryLoaded();
    } on Failure catch (e) {
      state = DiaryError(e.message);
    } catch (e) {
      state = const DiaryError('Đã có lỗi xảy ra.');
    }
  }

  Future<void> deleteEntry(String coupleId, String entryId) async {
    state = const DiaryLoading();
    try {
      await _deleteUseCase(coupleId, entryId);
      state = const DiaryLoaded();
    } on Failure catch (e) {
      state = DiaryError(e.message);
    } catch (e) {
      state = const DiaryError('Đã có lỗi xảy ra.');
    }
  }
}

final diaryNotifierProvider =
    StateNotifierProvider<DiaryNotifier, DiaryState>((ref) {
  return DiaryNotifier(
    createUseCase: ref.watch(createDiaryEntryUseCaseProvider),
    updateUseCase: ref.watch(updateDiaryEntryUseCaseProvider),
    deleteUseCase: ref.watch(deleteDiaryEntryUseCaseProvider),
  );
});
