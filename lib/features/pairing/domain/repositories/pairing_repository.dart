// lib/features/pairing/domain/repositories/pairing_repository.dart
// Abstract interface — định nghĩa "hợp đồng" giữa Domain và Data layer.
// Domain UseCase chỉ biết interface này, không biết implementation cụ thể.

import 'package:love_lang/core/error/failures.dart';
import 'package:love_lang/features/pairing/domain/entities/couple_entity.dart';
import 'package:love_lang/features/pairing/domain/entities/invite_entity.dart';

/// Repository interface cho tính năng ghép cặp.
/// Trả về [Either] pattern bằng [({Failure? failure, T? value})] record
/// hoặc ném exception — tùy convention dự án.
/// Ở đây dùng pattern [({Failure? failure, T? data})] record để tránh phụ thuộc
/// vào package `dartz` hay `fpdart`.
abstract interface class PairingRepository {
  /// Tạo một mã mời mới cho người dùng hiện tại.
  /// Trả về [InviteEntity] nếu thành công.
  Future<InviteEntity> createInviteCode();

  /// Kết nối với người dùng khác bằng mã mời [code].
  /// Sử dụng Firestore Transaction để đảm bảo tính toàn vẹn.
  ///
  /// Ném [Failure] tương ứng nếu xảy ra các edge case:
  /// - Mã không tồn tại → [InviteNotFoundFailure]
  /// - Mã hết hạn/đã dùng → [InviteExpiredFailure]
  /// - Tự kết nối với mình → [SelfPairingFailure]
  /// - Người tạo mã đã paired → [CreatorAlreadyPairedFailure]
  /// - Mình đã paired → [AlreadyPairedFailure]
  Future<CoupleEntity> connectWithCode(String code);

  /// Lấy thông tin cặp đôi hiện tại của user.
  /// Trả về null nếu user chưa ghép cặp.
  Future<CoupleEntity?> getCurrentCouple();

  /// Stream theo dõi trạng thái cặp đôi real-time.
  Stream<CoupleEntity?> watchCurrentCouple();

  /// Hủy kết nối cặp đôi.
  Future<void> unpair();
}
