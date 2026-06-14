// lib/features/pairing/domain/usecases/join_with_invite_code_usecase.dart
// UseCase: Đóng gói logic nghiệp vụ "Kết nối với mã mời".
// Là cầu nối duy nhất từ Presentation → Domain → Data.

import 'package:love_lang/features/pairing/domain/entities/couple_entity.dart';
import 'package:love_lang/features/pairing/domain/repositories/pairing_repository.dart';

/// Tham số đầu vào cho UseCase này.
class JoinWithInviteCodeParams {
  /// Mã mời người dùng nhập (sẽ được trim và uppercase trước khi gửi).
  final String rawCode;

  const JoinWithInviteCodeParams({required this.rawCode});

  /// Chuẩn hóa mã: bỏ khoảng trắng, chuyển về chữ hoa.
  String get normalizedCode => rawCode.trim().toUpperCase();
}

/// UseCase: Kết nối với người yêu bằng mã mời.
///
/// Gọi [call] với [JoinWithInviteCodeParams].
/// - Thành công → trả về [CoupleEntity]
/// - Thất bại → ném [Failure] hoặc [AppException] tuỳ theo lỗi
class JoinWithInviteCodeUsecase {
  final PairingRepository _repository;

  const JoinWithInviteCodeUsecase(this._repository);

  /// Thực thi nghiệp vụ kết nối cặp đôi.
  Future<CoupleEntity> call(JoinWithInviteCodeParams params) async {
    // Validate trước ở client để cải thiện UX (không tốn network call)
    final code = params.normalizedCode;
    if (code.isEmpty) {
      throw ArgumentError('Mã mời không được để trống.');
    }
    if (code.length != 6) {
      throw ArgumentError('Mã mời phải gồm đúng 6 ký tự.');
    }

    // Delegate hoàn toàn cho Repository — UseCase không biết Firebase tồn tại
    return _repository.connectWithCode(code);
  }
}
