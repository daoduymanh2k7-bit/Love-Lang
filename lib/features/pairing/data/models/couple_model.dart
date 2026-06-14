// lib/features/pairing/data/models/couple_model.dart
// Data Model: ánh xạ giữa Firestore document và CoupleEntity.
// Model biết về JSON/Firestore; Entity thì không.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:love_lang/features/pairing/domain/entities/couple_entity.dart';

/// Model tương ứng với document trong collection `couples` trên Firestore.
///
/// Schema Firestore:
/// ```json
/// {
///   "coupleId": "string",
///   "uid1":     "string",   // Người tạo kết nối
///   "uid2":     "string",   // Người chấp nhận kết nối
///   "pairedAt": Timestamp,
///   "status":   "active" | "unpaired"
/// }
/// ```
class CoupleModel extends CoupleEntity {
  const CoupleModel({
    required super.coupleId,
    required super.uid1,
    required super.uid2,
    required super.pairedAt,
    required super.status,
  });

  // ─── Factory: từ Firestore Document Snapshot ───────────────────────────────

  /// Parse từ Firestore DocumentSnapshot.
  /// Sử dụng khi lấy dữ liệu từ Firestore stream hoặc get().
  factory CoupleModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Document ${doc.id} rỗng hoặc không tồn tại.');
    }
    return CoupleModel.fromMap(data, docId: doc.id);
  }

  // ─── Factory: từ Map (JSON) ────────────────────────────────────────────────

  /// Parse từ Map<String, dynamic> — dùng trong Transaction khi đọc data.
  /// [docId] là Firestore document ID (không lưu trong body document).
  factory CoupleModel.fromMap(Map<String, dynamic> map,
      {required String docId}) {
    // Parse Timestamp từ Firestore (có thể là Timestamp hoặc DateTime)
    DateTime parseTimestamp(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      throw ArgumentError('Không thể parse timestamp: $value');
    }

    CoupleStatus parseStatus(String? raw) {
      return switch (raw) {
        'active' => CoupleStatus.active,
        'unpaired' => CoupleStatus.unpaired,
        _ => CoupleStatus.active, // default an toàn
      };
    }

    return CoupleModel(
      coupleId: map['coupleId'] as String? ?? docId,
      uid1: map['uid1'] as String,
      uid2: map['uid2'] as String,
      pairedAt: parseTimestamp(map['pairedAt']),
      status: parseStatus(map['status'] as String?),
    );
  }

  // ─── To Map: để ghi lên Firestore ─────────────────────────────────────────

  /// Chuyển thành Map để ghi lên Firestore.
  /// Dùng [FieldValue.serverTimestamp()] cho [pairedAt] khi tạo mới
  /// để đảm bảo thời gian chính xác từ phía server.
  Map<String, dynamic> toMap() {
    return {
      'coupleId': coupleId,
      'uid1': uid1,
      'uid2': uid2,
      'pairedAt': Timestamp.fromDate(pairedAt),
      'status': _statusToString(status),
    };
  }

  /// Trả về Map với server timestamp — dùng khi CREATE document mới.
  Map<String, dynamic> toMapWithServerTimestamp() {
    return {
      'coupleId': coupleId,
      'uid1': uid1,
      'uid2': uid2,
      'pairedAt': FieldValue.serverTimestamp(), // Luôn dùng server time
      'status': _statusToString(status),
    };
  }

  String _statusToString(CoupleStatus s) => switch (s) {
        CoupleStatus.active => 'active',
        CoupleStatus.unpaired => 'unpaired',
      };

  // ─── Conversion: Model → Entity ───────────────────────────────────────────

  /// Chuyển về Entity thuần để Domain layer sử dụng.
  CoupleEntity toEntity() => CoupleEntity(
        coupleId: coupleId,
        uid1: uid1,
        uid2: uid2,
        pairedAt: pairedAt,
        status: status,
      );

  // ─── Conversion: Entity → Model ───────────────────────────────────────────

  /// Tạo Model từ Entity (khi cần ghi ngược lên Firestore).
  factory CoupleModel.fromEntity(CoupleEntity entity) => CoupleModel(
        coupleId: entity.coupleId,
        uid1: entity.uid1,
        uid2: entity.uid2,
        pairedAt: entity.pairedAt,
        status: entity.status,
      );

  @override
  String toString() =>
      'CoupleModel(coupleId: $coupleId, uid1: $uid1, uid2: $uid2, status: $status)';
}
