// lib/features/pairing/presentation/providers/pairing_provider.dart
// Riverpod Provider và StateNotifier cho tính năng Pairing.
// File này cũng chứa các Dependency Injection cho feature này.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:love_lang/core/error/failures.dart';
import 'package:love_lang/features/pairing/data/datasources/pairing_remote_datasource.dart';
import 'package:love_lang/features/pairing/data/repositories/pairing_repository_impl.dart';
import 'package:love_lang/features/pairing/domain/repositories/pairing_repository.dart';
import 'package:love_lang/features/pairing/domain/usecases/join_with_invite_code_usecase.dart';
import 'package:love_lang/features/pairing/domain/usecases/create_invite_code_usecase.dart';
import 'package:love_lang/features/pairing/presentation/providers/pairing_state.dart';

import 'package:love_lang/features/pairing/domain/entities/couple_entity.dart';

// ─── Dependency Injection (Providers) ───────────────────────────────────────

/// Cung cấp instance của DataSource.
final pairingRemoteDatasourceProvider =
    Provider<PairingRemoteDatasource>((ref) {
  return PairingRemoteDatasourceImpl(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

/// Cung cấp instance của Repository.
final pairingRepositoryProvider = Provider<PairingRepository>((ref) {
  return PairingRepositoryImpl(
    remoteDatasource: ref.read(pairingRemoteDatasourceProvider),
  );
});

/// Cung cấp instance của UseCase kết nối.
final joinWithInviteCodeUsecaseProvider =
    Provider<JoinWithInviteCodeUsecase>((ref) {
  return JoinWithInviteCodeUsecase(ref.read(pairingRepositoryProvider));
});

/// Cung cấp instance của UseCase tạo mã.
final createInviteCodeUseCaseProvider =
    Provider<CreateInviteCodeUseCase>((ref) {
  return CreateInviteCodeUseCase(ref.read(pairingRepositoryProvider));
});

// ─── State Management ───────────────────────────────────────────────────────

/// Quản lý trạng thái cho màn hình "Nhập Mã Kết Nối".
class PairingNotifier extends AutoDisposeNotifier<PairingState> {
  @override
  PairingState build() {
    return const PairingInitial(); // Bắt đầu với trạng thái mặc định
  }

  /// Kích hoạt logic kết nối cặp đôi bằng mã mời.
  Future<void> connectWithCode(String code) async {
    // Cập nhật state thành Loading để UI biết mà disable nút / quay spinner
    state = const PairingLoading();

    try {
      // Đọc UseCase từ ref
      final usecase = ref.read(joinWithInviteCodeUsecaseProvider);
      final params = JoinWithInviteCodeParams(rawCode: code);

      // Gọi UseCase thực thi logic (Transaction trên Firestore)
      final couple = await usecase(params);

      // Nếu không ném lỗi -> kết nối thành công!
      state = PairingSuccess(couple);
    } on Failure catch (failure) {
      // Các lỗi nghiệp vụ (Domain failures) -> đã có message tiếng Việt
      state = PairingError(failure.message);
    } on ArgumentError catch (e) {
      // Lỗi validate input từ UseCase (vd: thiếu ký tự)
      state = PairingError(e.message);
    } catch (e) {
      // Lỗi không lường trước được (Crash, Exception lạ)
      state = PairingError('Đã có lỗi xảy ra: $e');
    }
  }

  /// Kích hoạt logic tạo mã mời kết nối.
  Future<void> generateInviteCode() async {
    state = const PairingLoading();
    try {
      final usecase = ref.read(createInviteCodeUseCaseProvider);
      final invite = await usecase();
      state = PairingInviteCreated(invite);
    } on Failure catch (failure) {
      state = PairingError(failure.message);
    } catch (e) {
      state = PairingError('Đã có lỗi xảy ra khi tạo mã mời: $e');
    }
  }
}

/// Provider chính được expose ra cho Presentation layer lắng nghe.
final pairingNotifierProvider =
    AutoDisposeNotifierProvider<PairingNotifier, PairingState>(
  PairingNotifier.new,
);

/// StreamProvider theo dõi cập nhật couple real-time.
final watchCoupleProvider =
    StreamProvider.autoDispose.family<CoupleEntity?, String>((ref, coupleId) {
  final remoteDatasource = ref.watch(pairingRemoteDatasourceProvider);
  return remoteDatasource
      .watchCouple(coupleId)
      .map((model) => model?.toEntity());
});
