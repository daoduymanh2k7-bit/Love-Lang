// lib/features/pairing/data/repositories/pairing_repository_impl.dart
// Repository Implementation: cầu nối giữa Domain và Data layer.
//
// Nhiệm vụ:
// 1. Gọi DataSource để lấy/ghi dữ liệu.
// 2. Chuyển đổi AppException (Data) → Failure (Domain).
// 3. Chuyển đổi Model (Data) → Entity (Domain).
//
// Domain layer chỉ nhìn thấy lớp này qua interface PairingRepository.

import 'package:love_lang/core/error/exceptions.dart';
import 'package:love_lang/core/error/failures.dart';
import 'package:love_lang/features/pairing/data/datasources/pairing_remote_datasource.dart';
import 'package:love_lang/features/pairing/domain/entities/couple_entity.dart';
import 'package:love_lang/features/pairing/domain/entities/invite_entity.dart';
import 'package:love_lang/features/pairing/domain/repositories/pairing_repository.dart';

class PairingRepositoryImpl implements PairingRepository {
  final PairingRemoteDatasource _remoteDatasource;

  // coupleId hiện tại được cache trong memory sau khi user đã paired.
  // Thực tế nên lưu vào SecureStorage để persist qua app restart.
  String? _cachedCoupleId;

  PairingRepositoryImpl({
    required PairingRemoteDatasource remoteDatasource,
  }) : _remoteDatasource = remoteDatasource;

  // ─── createInviteCode ─────────────────────────────────────────────────────

  @override
  Future<InviteEntity> createInviteCode() async {
    try {
      final model = await _remoteDatasource.createInviteCode();
      return model.toEntity();
    } on UnauthenticatedException {
      throw const UnauthenticatedFailure();
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    } on AppException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  // ─── connectWithCode ──────────────────────────────────────────────────────

  @override
  Future<CoupleEntity> connectWithCode(String code) async {
    try {
      final model = await _remoteDatasource.connectWithCode(code);
      // Cache coupleId để dùng cho watchCurrentCouple
      _cachedCoupleId = model.coupleId;
      return model.toEntity();
    }
    // Chuyển từng loại exception sang Failure tương ứng
    on InviteNotFoundException {
      throw const InviteNotFoundFailure();
    }
    on InviteExpiredException {
      throw const InviteExpiredFailure();
    }
    on SelfPairingException {
      throw const SelfPairingFailure();
    }
    on CreatorAlreadyPairedException {
      throw const CreatorAlreadyPairedFailure();
    }
    on AlreadyPairedException {
      throw const AlreadyPairedFailure();
    }
    on UnauthenticatedException {
      throw const UnauthenticatedFailure();
    }
    on TransactionException catch (e) {
      throw TransactionFailure(message: e.message);
    }
    on NetworkException catch (e) {
      throw NetworkFailure(message: e.message);
    }
    on AppException catch (e) {
      // Fallback cho các exception chưa được xử lý cụ thể
      throw ServerFailure(message: e.message);
    }
  }

  // ─── getCurrentCouple ─────────────────────────────────────────────────────

  @override
  Future<CoupleEntity?> getCurrentCouple() async {
    final coupleId = _cachedCoupleId;
    if (coupleId == null) return null;

    try {
      final model = await _remoteDatasource.getCurrentCouple(coupleId);
      return model?.toEntity();
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    } on AppException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  // ─── watchCurrentCouple ───────────────────────────────────────────────────

  @override
  Stream<CoupleEntity?> watchCurrentCouple() {
    final coupleId = _cachedCoupleId;
    if (coupleId == null) {
      // Chưa có coupleId → stream rỗng (null)
      return Stream.value(null);
    }
    return _remoteDatasource.watchCouple(coupleId).map(
          (model) => model?.toEntity(),
        );
  }

  // ─── unpair ───────────────────────────────────────────────────────────────

  @override
  Future<void> unpair() async {
    final coupleId = _cachedCoupleId;
    if (coupleId == null) return;

    try {
      await _remoteDatasource.unpair(coupleId);
      _cachedCoupleId = null; // Xóa cache sau khi unpair
    } on TransactionException catch (e) {
      throw TransactionFailure(message: e.message);
    } on AppException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }
}
