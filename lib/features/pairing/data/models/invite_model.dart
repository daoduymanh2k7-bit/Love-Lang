// lib/features/pairing/data/models/invite_model.dart
// Data Model: ánh xạ giữa Firestore document và InviteEntity.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:love_lang/features/pairing/domain/entities/invite_entity.dart';

/// Model tương ứng với document trong collection `invites` trên Firestore.
///
/// Schema Firestore:
/// ```json
/// {
///   "code":       "string (6 ký tự, uppercase)",
///   "creatorUid": "string",
///   "status":     "pending" | "accepted" | "expired",
///   "createdAt":  Timestamp,
///   "expiresAt":  Timestamp
/// }
/// ```
class InviteModel extends InviteEntity {
  const InviteModel({
    required super.id,
    required super.creatorUid,
    required super.code,
    required super.status,
    required super.createdAt,
    required super.expiresAt,
  });

  // ─── Factory: từ Firestore DocumentSnapshot ───────────────────────────────

  /// Parse từ Firestore DocumentSnapshot (stream hoặc get()).
  factory InviteModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Invite document ${doc.id} rỗng hoặc không tồn tại.');
    }
    return InviteModel.fromMap(data, docId: doc.id);
  }

  // ─── Factory: từ Map ──────────────────────────────────────────────────────

  /// Parse từ Map<String, dynamic> — dùng trong Transaction.
  factory InviteModel.fromMap(Map<String, dynamic> map,
      {required String docId}) {
    DateTime parseTimestamp(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      throw ArgumentError('Không thể parse timestamp: $value');
    }

    InviteStatus parseStatus(String? raw) {
      return switch (raw) {
        'pending' => InviteStatus.pending,
        'accepted' => InviteStatus.accepted,
        'expired' => InviteStatus.expired,
        _ => InviteStatus.expired, // unknown → coi như expired cho an toàn
      };
    }

    return InviteModel(
      id: docId,
      creatorUid: map['creatorUid'] as String,
      code: (map['code'] as String).toUpperCase(),
      status: parseStatus(map['status'] as String?),
      createdAt: parseTimestamp(map['createdAt']),
      expiresAt: parseTimestamp(map['expiresAt']),
    );
  }

  // ─── To Map: ghi lên Firestore ────────────────────────────────────────────

  /// Chuyển thành Map để ghi document mới.
  Map<String, dynamic> toMap() {
    return {
      'code': code.toUpperCase(),
      'creatorUid': creatorUid,
      'status': _statusToString(status),
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }

  /// Map với server timestamp — dùng khi CREATE document mới.
  /// expiresAt = createdAt + 24 giờ (tính từ server time không thể giả mạo).
  Map<String, dynamic> toMapWithServerTimestamp() {
    return {
      'code': code.toUpperCase(),
      'creatorUid': creatorUid,
      'status': _statusToString(status),
      // Server sẽ điền createdAt và expiresAt thực tế
      // expiresAt cần tính bằng Cloud Function trigger nếu muốn 100% server-side
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        // Dùng local time + 24h làm estimate; Cloud Function có thể override
        DateTime.now().add(const Duration(hours: 24)),
      ),
    };
  }

  String _statusToString(InviteStatus s) => switch (s) {
        InviteStatus.pending => 'pending',
        InviteStatus.accepted => 'accepted',
        InviteStatus.expired => 'expired',
      };

  // ─── Conversion ───────────────────────────────────────────────────────────

  InviteEntity toEntity() => InviteEntity(
        id: id,
        creatorUid: creatorUid,
        code: code,
        status: status,
        createdAt: createdAt,
        expiresAt: expiresAt,
      );

  factory InviteModel.fromEntity(InviteEntity entity) => InviteModel(
        id: entity.id,
        creatorUid: entity.creatorUid,
        code: entity.code,
        status: entity.status,
        createdAt: entity.createdAt,
        expiresAt: entity.expiresAt,
      );

  @override
  String toString() =>
      'InviteModel(id: $id, code: $code, status: $status, isValid: $isValid)';
}
