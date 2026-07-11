import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../domain/entities/milestone_entity.dart';
import '../../domain/usecases/watch_milestones_usecase.dart';
import '../../domain/usecases/add_milestone_usecase.dart';
import '../../domain/usecases/update_milestone_usecase.dart';
import '../../domain/usecases/delete_milestone_usecase.dart';
import '../../data/datasources/milestone_remote_datasource.dart';
import '../../data/repositories/milestone_repository_impl.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/sound_effect.dart';
import '../../../sound/presentation/providers/sound_settings_provider.dart';

// ─── Dependency wiring ─────────────────────────────────────────────────────
// Lưu ý: KHÔNG khai báo lại `firestoreProvider` dùng chung ở đây, vì
// album_provider.dart và diary_provider.dart đã mỗi nơi tự khai báo một biến
// cùng tên `firestoreProvider` — nếu milestone cũng khai báo trùng tên và có
// file nào import cả 2, Dart sẽ báo lỗi ambiguous import. Nên ở đây gọi thẳng
// FirebaseFirestore.instance cho an toàn.

final milestoneRemoteDataSourceProvider =
    Provider<MilestoneRemoteDataSource>((ref) {
  return MilestoneRemoteDataSource(FirebaseFirestore.instance);
});

final milestoneRepositoryProvider = Provider<MilestoneRepositoryImpl>((ref) {
  return MilestoneRepositoryImpl(ref.watch(milestoneRemoteDataSourceProvider));
});

final watchMilestonesUseCaseProvider =
    Provider<WatchMilestonesUseCase>((ref) {
  return WatchMilestonesUseCase(ref.watch(milestoneRepositoryProvider));
});

final addMilestoneUseCaseProvider = Provider<AddMilestoneUseCase>((ref) {
  return AddMilestoneUseCase(ref.watch(milestoneRepositoryProvider));
});

final updateMilestoneUseCaseProvider =
    Provider<UpdateMilestoneUseCase>((ref) {
  return UpdateMilestoneUseCase(ref.watch(milestoneRepositoryProvider));
});

final deleteMilestoneUseCaseProvider =
    Provider<DeleteMilestoneUseCase>((ref) {
  return DeleteMilestoneUseCase(ref.watch(milestoneRepositoryProvider));
});

// ─── Stream lắng nghe danh sách milestone theo coupleId ────────────────────
final milestonesProvider = StreamProvider.autoDispose
    .family<List<MilestoneEntity>, String>((ref, coupleId) {
  final useCase = ref.watch(watchMilestonesUseCaseProvider);
  return useCase(coupleId);
});

// ─── Lấy tên hiển thị của 1 user (dùng để in "myName" / "partnerName") ─────
final milestoneUserDocProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, uid) {
  return FirebaseFirestore.instance
      .doc(FirestorePaths.userDoc(uid))
      .snapshots()
      .map((doc) => doc.data());
});

// ─── Notifier xử lý thêm / sửa / xóa ───────────────────────────────────────
class MilestoneActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final AddMilestoneUseCase _addUseCase;
  final UpdateMilestoneUseCase _updateUseCase;
  final DeleteMilestoneUseCase _deleteUseCase;
  final Ref _ref;

  MilestoneActionsNotifier({
    required AddMilestoneUseCase addUseCase,
    required UpdateMilestoneUseCase updateUseCase,
    required DeleteMilestoneUseCase deleteUseCase,
    required Ref ref,
  })  : _addUseCase = addUseCase,
        _updateUseCase = updateUseCase,
        _deleteUseCase = deleteUseCase,
        _ref = ref,
        super(const AsyncData(null));

  void _playSfx(SoundEffect effect) {
    final settings = _ref.read(soundSettingsNotifierProvider);
    _ref.read(audioServiceProvider).playSfx(
          effect,
          volume: settings.sfxVolume,
          enabled: settings.sfxEnabled,
        );
  }

  Future<void> addMilestone(
    String coupleId, {
    required String title,
    required DateTime date,
  }) async {
    state = const AsyncLoading();
    // Optimistic: phát SFX ngay, không chờ Firestore write (chỉ ghi 1
    // document, chờ xong mới phát sẽ tạo độ trễ không cần thiết).
    _playSfx(SoundEffect.milestone);
    state = await AsyncValue.guard(
      () => _addUseCase(coupleId, title: title, date: date),
    );
  }

  Future<void> updateMilestone(
    String coupleId,
    String milestoneId, {
    required String title,
    required DateTime date,
  }) async {
    state = const AsyncLoading();
    // Optimistic: xem giải thích ở addMilestone().
    _playSfx(SoundEffect.milestone);
    state = await AsyncValue.guard(
      () => _updateUseCase(coupleId, milestoneId, title: title, date: date),
    );
  }

  Future<void> deleteMilestone(String coupleId, String milestoneId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _deleteUseCase(coupleId, milestoneId),
    );
  }
}

final milestoneActionsProvider =
    StateNotifierProvider<MilestoneActionsNotifier, AsyncValue<void>>((ref) {
  return MilestoneActionsNotifier(
    addUseCase: ref.watch(addMilestoneUseCaseProvider),
    updateUseCase: ref.watch(updateMilestoneUseCaseProvider),
    deleteUseCase: ref.watch(deleteMilestoneUseCaseProvider),
    ref: ref,
  );
});