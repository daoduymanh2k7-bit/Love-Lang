// lib/features/pairing/data/datasources/pairing_remote_datasource.dart
// Data Source: giao tiếp trực tiếp với Firebase Firestore.
// Đây là nơi DUY NHẤT trong feature này được phép import cloud_firestore.
//
// ★ ĐIỂM QUAN TRỌNG: connectWithCode() dùng runTransaction() để đảm bảo
//   ACID — nếu bất kỳ bước nào thất bại, toàn bộ thao tác bị rollback.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:love_lang/core/constants/firestore_paths.dart';
import 'package:love_lang/core/error/exceptions.dart';
import 'package:love_lang/features/pairing/data/models/couple_model.dart';
import 'package:love_lang/features/pairing/data/models/invite_model.dart';
import 'package:love_lang/features/pairing/domain/entities/couple_entity.dart';
import 'package:love_lang/features/pairing/domain/entities/invite_entity.dart';

// ─── Abstract Interface ────────────────────────────────────────────────────────

abstract interface class PairingRemoteDatasource {
  /// Tạo mã mời mới cho user hiện tại.
  Future<InviteModel> createInviteCode();

  /// Kết nối bằng mã mời [code] — dùng Firestore Transaction.
  Future<CoupleModel> connectWithCode(String code);

  /// Lấy thông tin cặp đôi hiện tại của user.
  Future<CoupleModel?> getCurrentCouple(String coupleId);

  /// Stream theo dõi real-time.
  Stream<CoupleModel?> watchCouple(String coupleId);

  /// Hủy kết nối.
  Future<void> unpair(String coupleId);
}

// ─── Implementation ────────────────────────────────────────────────────────────

class PairingRemoteDatasourceImpl implements PairingRemoteDatasource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PairingRemoteDatasourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Lấy UID của user hiện tại, ném exception nếu chưa đăng nhập.
  String get _currentUid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const UnauthenticatedException();
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _invitesRef =>
      _firestore.collection(FirestorePaths.invites);

  CollectionReference<Map<String, dynamic>> get _couplesRef =>
      _firestore.collection(FirestorePaths.couples);

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(FirestorePaths.users);

  // ─── createInviteCode ──────────────────────────────────────────────────────

  @override
  Future<InviteModel> createInviteCode() async {
    final uid = _currentUid;

    // Tạo mã 6 ký tự ngẫu nhiên (alphanumeric, uppercase)
    final code = _generateCode();
    final now = DateTime.now();

    final inviteData = InviteModel(
      id: code, // Dùng chính code làm document ID
      creatorUid: uid,
      code: code,
      status: InviteStatus.pending, // từ entity
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
    );

    try {
      // Ghi invite lên Firestore tại invites/{code}
      final docRef = _invitesRef.doc(code);
      await docRef.set(
        inviteData.toMapWithServerTimestamp(),
      );

      // Trả về model với ID thực tế là code
      return inviteData;
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Không thể tạo mã mời.');
    }
  }

  // ─── connectWithCode ───────────────────────────────────────────────────────

  /// Kết nối với người yêu bằng mã mời.
  ///
  /// ★ SỬ DỤNG FIRESTORE TRANSACTION để đảm bảo:
  ///   1. Đọc invite → kiểm tra hợp lệ (atomic)
  ///   2. Kiểm tra trạng thái người tạo mã (chưa paired)
  ///   3. Tạo couple document + cập nhật invite + cập nhật 2 user documents
  ///   → Tất cả 4 thao tác thành công cùng lúc HOẶC không có thao tác nào xảy ra.
  @override
  Future<CoupleModel> connectWithCode(String code) async {
    final joinerUid = _currentUid; // UID của người đang nhập mã

    // ─── BƯỚC 1: Tìm invite document theo code ──────────────────────────────
    // Phải query trước khi vào transaction vì query không được phép trong transaction
    final inviteQuery = await _invitesRef
        .where(FirestorePaths.inviteCode, isEqualTo: code.toUpperCase())
        .where(FirestorePaths.inviteStatus,
            isEqualTo: FirestorePaths.statusPending)
        .limit(1)
        .get();

    // Edge Case 1: Mã không tồn tại hoặc không còn pending
    if (inviteQuery.docs.isEmpty) {
      throw const InviteNotFoundException();
    }

    final inviteDoc = inviteQuery.docs.first;
    final invite = InviteModel.fromFirestore(inviteDoc);

    // Edge Case 2: Kiểm tra thời hạn mã (client-side check, server rules cũng kiểm tra)
    if (!invite.isValid) {
      throw const InviteExpiredException();
    }

    // Edge Case 3: Người dùng tự nhập mã của chính mình
    if (invite.creatorUid == joinerUid) {
      throw const SelfPairingException();
    }

    final creatorUid = invite.creatorUid;

    // ─── BƯỚC 2: Chạy Firestore Transaction ──────────────────────────────────
    // Transaction đảm bảo tính ACID — mọi thao tác đọc/ghi là atomic.
    // Nếu có conflict (race condition), Firestore tự động retry transaction.
    try {
      final coupleModel = await _firestore.runTransaction<CoupleModel>(
        (transaction) async {
          // ── ĐỌC DỮ LIỆU (Phần Read của Transaction) ──────────────────────
          // LƯU Ý: Trong transaction, phải đọc TẤT CẢ trước, rồi mới ghi.
          // Đây là quy tắc của Firestore Transaction.

          // Đọc document user của người TẠO mã
          final creatorUserRef = _usersRef.doc(creatorUid);
          final creatorUserSnap = await transaction.get(creatorUserRef);

          // Đọc document user của người NHẬP mã (joiner = mình)
          final joinerUserRef = _usersRef.doc(joinerUid);
          final joinerUserSnap = await transaction.get(joinerUserRef);

          // Đọc lại invite document trong transaction để đảm bảo consistency
          final inviteRef = _invitesRef.doc(inviteDoc.id);
          final inviteSnap = await transaction.get(inviteRef);

          // ── KIỂM TRA ĐIỀU KIỆN (Validation trong Transaction) ─────────────

          // Kiểm tra invite vẫn còn pending (race condition: ai đó vừa dùng mã này)
          final currentStatus =
              inviteSnap.data()?[FirestorePaths.inviteStatus] as String?;
          if (currentStatus != FirestorePaths.statusPending) {
            // Ném exception để abort transaction
            throw const InviteExpiredException();
          }

          // Edge Case 4: Người tạo mã đã được kết nối với người khác rồi
          // Kiểm tra field 'pairingStatus' trong user document của creator
          final creatorPairingStatus = creatorUserSnap
              .data()?[FirestorePaths.userPairingStatus] as String?;
          if (creatorPairingStatus == FirestorePaths.pairingStatusPaired) {
            throw const CreatorAlreadyPairedException();
          }

          // Edge Case 5: Người nhập mã (mình) đã được kết nối rồi
          final joinerPairingStatus = joinerUserSnap
              .data()?[FirestorePaths.userPairingStatus] as String?;
          if (joinerPairingStatus == FirestorePaths.pairingStatusPaired) {
            throw const AlreadyPairedException();
          }

          // ── GHI DỮ LIỆU (Phần Write của Transaction) ──────────────────────
          // Chỉ ghi sau khi tất cả validation đã pass.

          // Tạo ID cho couple document mới
          final coupleRef = _couplesRef.doc();
          final coupleId = coupleRef.id;
          final now = DateTime.now();

          // Tạo CoupleModel
          final couple = CoupleModel(
            coupleId: coupleId,
            uid1: creatorUid, // Người tạo mã là uid1
            uid2: joinerUid, // Người nhập mã là uid2
            pairedAt: now,
            status: CoupleStatus.active,
          );

          // Ghi 1: Tạo document couple mới
          transaction.set(coupleRef, couple.toMapWithServerTimestamp());

          // Ghi 2: Đánh dấu invite là 'accepted'
          transaction.update(inviteRef, {
            FirestorePaths.inviteStatus: FirestorePaths.statusAccepted,
          });

          // Ghi 3: Cập nhật user document của creator
          // Gắn coupleId và đổi pairingStatus thành 'paired'
          transaction.update(creatorUserRef, {
            FirestorePaths.userCoupleId: coupleId,
            FirestorePaths.userPairingStatus:
                FirestorePaths.pairingStatusPaired,
          });

          // Ghi 4: Cập nhật user document của joiner (mình)
          transaction.update(joinerUserRef, {
            FirestorePaths.userCoupleId: coupleId,
            FirestorePaths.userPairingStatus:
                FirestorePaths.pairingStatusPaired,
          });

          // Transaction kết thúc — nếu mọi thứ OK, Firestore commit tất cả 4 thao tác.
          return couple;
        },
        // maxAttempts: tối đa 5 lần retry nếu có conflict
        maxAttempts: 5,
      );

      return coupleModel;
    }
    // Bắt các AppException mà ta tự ném trong transaction body (abort)
    on InviteExpiredException {
      rethrow;
    } on SelfPairingException {
      rethrow;
    } on CreatorAlreadyPairedException {
      rethrow;
    } on AlreadyPairedException {
      rethrow;
    }
    // Bắt lỗi từ Firebase (network, permission, v.v.)
    on FirebaseException catch (e) {
      throw TransactionException(
        message: 'Không thể kết nối: ${e.message ?? e.code}',
      );
    }
    // Bắt lỗi không xác định
    catch (e) {
      throw TransactionException(
        message: 'Đã xảy ra lỗi không mong muốn: $e',
      );
    }
  }

  // ─── getCurrentCouple ─────────────────────────────────────────────────────

  @override
  Future<CoupleModel?> getCurrentCouple(String coupleId) async {
    try {
      final snap = await _couplesRef.doc(coupleId).get();
      if (!snap.exists || snap.data() == null) return null;
      return CoupleModel.fromFirestore(snap);
    } on FirebaseException catch (e) {
      throw ServerException(
          message: e.message ?? 'Không thể lấy thông tin cặp đôi.');
    }
  }

  // ─── watchCouple ──────────────────────────────────────────────────────────

  @override
  Stream<CoupleModel?> watchCouple(String coupleId) {
    return _couplesRef.doc(coupleId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return CoupleModel.fromFirestore(snap);
    });
  }

  // ─── unpair ───────────────────────────────────────────────────────────────

  @override
  Future<void> unpair(String coupleId) async {
    final uid = _currentUid;
    try {
      await _firestore.runTransaction((transaction) async {
        final coupleRef = _couplesRef.doc(coupleId);
        final coupleSnap = await transaction.get(coupleRef);

        final data = coupleSnap.data();
        if (data == null) return;

        final uid1 = data[FirestorePaths.coupleUid1] as String;
        final uid2 = data[FirestorePaths.coupleUid2] as String;

        // Chỉ thành viên của cặp mới được unpair
        if (uid != uid1 && uid != uid2) {
          throw const UnauthenticatedException();
        }

        // Đánh dấu couple là 'unpaired'
        transaction.update(coupleRef, {
          FirestorePaths.coupleStatus: FirestorePaths.coupleStatusUnpaired,
        });

        // Reset pairingStatus cho cả 2 thành viên
        for (final memberUid in [uid1, uid2]) {
          transaction.update(_usersRef.doc(memberUid), {
            FirestorePaths.userCoupleId: FieldValue.delete(),
            FirestorePaths.userPairingStatus: FirestorePaths.pairingStatusNone,
          });
        }
      });
    } on FirebaseException catch (e) {
      throw TransactionException(
        message: 'Không thể hủy kết nối: ${e.message ?? e.code}',
      );
    }
  }

  // ─── Helper: tạo mã ngẫu nhiên ───────────────────────────────────────────

  /// Tạo mã 6 ký tự ngẫu nhiên dạng alphanumeric (A-Z, 0-9).
  /// Loại bỏ các ký tự dễ nhầm lẫn: 0, O, I, 1.
  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    // Dùng combination của timestamp + hash để tạo ngẫu nhiên không cần package
    final buffer = StringBuffer();
    var seed = random;
    for (int i = 0; i < 6; i++) {
      seed = (seed * 1664525 + 1013904223) & 0xFFFFFFFF; // LCG algorithm
      buffer.write(chars[seed % chars.length]);
    }
    return buffer.toString();
  }
}
