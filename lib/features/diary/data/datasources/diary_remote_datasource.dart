import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../models/diary_entry_model.dart';

class DiaryRemoteDataSource {
  final FirebaseFirestore _firestore;

  DiaryRemoteDataSource(this._firestore);

  Stream<List<DiaryEntryModel>> watchDiaryEntries(String coupleId, String currentUserId) {
    // QUAN TRỌNG: Lọc dữ liệu nhật ký bí mật.
    // Nếu isPrivate == true, hệ thống chỉ đẩy về client nếu authorId == currentUserId.
    // Dùng Filter.or của Firestore để kết hợp 2 điều kiện:
    // 1. isPrivate == false (công khai, cả 2 đều xem được)
    // 2. authorId == currentUserId (của riêng mình, cả công khai lẫn bí mật đều xem được)
    return _firestore
        .collection(FirestorePaths.diaryEntries(coupleId))
        .where(
          Filter.or(
            Filter('isPrivate', isEqualTo: false),
            Filter('authorId', isEqualTo: currentUserId),
          ),
        )
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DiaryEntryModel.fromFirestore(doc, null))
          .toList();
    });
  }

  Future<void> createDiaryEntry(DiaryEntryModel entry) async {
    final docRef = _firestore
        .collection(FirestorePaths.diaryEntries(entry.coupleId))
        .doc(entry.id);
    await docRef.set(entry.toFirestore());
  }

  Future<void> updateDiaryEntry(DiaryEntryModel entry) async {
    final docRef = _firestore
        .collection(FirestorePaths.diaryEntries(entry.coupleId))
        .doc(entry.id);
    await docRef.update(entry.toFirestoreUpdate());
  }

  Future<void> deleteDiaryEntry(String coupleId, String entryId) async {
    final docRef = _firestore
        .collection(FirestorePaths.diaryEntries(coupleId))
        .doc(entryId);
    await docRef.delete();
  }
}
