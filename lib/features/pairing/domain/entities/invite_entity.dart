// lib/features/pairing/domain/entities/invite_entity.dart
// Pure Dart entity cho mã mời — không phụ thuộc bất kỳ framework nào.

/// Trạng thái của một mã mời.
enum InviteStatus {
  pending,  // Đang chờ người kia nhập
  accepted, // Đã được chấp nhận
  expired,  // Đã hết hạn
}

/// Entity đại diện cho một mã mời kết nối cặp đôi.
class InviteEntity {
  /// Firestore document ID của invite.
  final String id;

  /// UID của người tạo mã mời.
  final String creatorUid;

  /// Mã mời dạng chuỗi ngắn (vd: "ABC123"), user nhập vào.
  final String code;

  /// Trạng thái hiện tại của mã.
  final InviteStatus status;

  /// Thời điểm tạo mã.
  final DateTime createdAt;

  /// Thời điểm mã hết hạn (mặc định 24h sau khi tạo).
  final DateTime expiresAt;

  const InviteEntity({
    required this.id,
    required this.creatorUid,
    required this.code,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
  });

  /// Kiểm tra mã có còn hạn và ở trạng thái pending không.
  bool get isValid =>
      status == InviteStatus.pending && DateTime.now().isBefore(expiresAt);

  InviteEntity copyWith({
    String? id,
    String? creatorUid,
    String? code,
    InviteStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return InviteEntity(
      id: id ?? this.id,
      creatorUid: creatorUid ?? this.creatorUid,
      code: code ?? this.code,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InviteEntity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'InviteEntity(id: $id, code: $code, status: $status, isValid: $isValid)';
}
