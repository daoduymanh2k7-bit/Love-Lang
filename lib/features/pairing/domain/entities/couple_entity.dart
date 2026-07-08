// lib/features/pairing/domain/entities/couple_entity.dart
// Pure Dart entity — không import Flutter, Firebase hay bất kỳ package nào.
// Đây là "trái tim" của Domain layer, biểu diễn khái niệm nghiệp vụ thuần túy.

/// Trạng thái của một cặp đôi.
enum CoupleStatus {
  active, // Đang kết nối
  unpaired, // Đã hủy kết nối
}

/// Entity đại diện cho một cặp đôi trong hệ thống.
/// Bất biến (immutable) — mọi thay đổi tạo ra instance mới qua [copyWith].
class CoupleEntity {
  /// ID duy nhất của cặp đôi (Firestore document ID).
  final String coupleId;

  /// UID của thành viên thứ nhất (người tạo kết nối).
  final String uid1;

  /// UID của thành viên thứ hai (người chấp nhận kết nối).
  final String uid2;

  /// Thời điểm ghép cặp thành công.
  final DateTime pairedAt;

  /// Trạng thái hiện tại của cặp đôi.
  final CoupleStatus status;

  const CoupleEntity({
    required this.coupleId,
    required this.uid1,
    required this.uid2,
    required this.pairedAt,
    required this.status,
  });

  /// Kiểm tra một UID có thuộc cặp đôi này không.
  bool containsUser(String uid) => uid == uid1 || uid == uid2;

  /// Lấy UID của người kia trong cặp (đối phương).
  String partnerUidOf(String myUid) {
    assert(containsUser(myUid), 'UID $myUid không thuộc cặp đôi này.');
    return myUid == uid1 ? uid2 : uid1;
  }

  CoupleEntity copyWith({
    String? coupleId,
    String? uid1,
    String? uid2,
    DateTime? pairedAt,
    CoupleStatus? status,
  }) {
    return CoupleEntity(
      coupleId: coupleId ?? this.coupleId,
      uid1: uid1 ?? this.uid1,
      uid2: uid2 ?? this.uid2,
      pairedAt: pairedAt ?? this.pairedAt,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoupleEntity &&
          runtimeType == other.runtimeType &&
          coupleId == other.coupleId;

  @override
  int get hashCode => coupleId.hashCode;

  @override
  String toString() =>
      'CoupleEntity(coupleId: $coupleId, uid1: $uid1, uid2: $uid2, status: $status)';
}
