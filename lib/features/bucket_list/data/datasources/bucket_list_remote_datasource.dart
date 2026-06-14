// lib/features/bucket_list/data/datasources/bucket_list_remote_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../domain/models/bucket_item_model.dart';

class BucketListRemoteDataSource {
  final FirebaseFirestore _firestore;

  BucketListRemoteDataSource(this._firestore);

  /// Stream danh sách bucket items, sắp xếp mới nhất trước.
  Stream<List<BucketItemModel>> watchItems(String coupleId) {
    return _firestore
        .collection(FirestorePaths.bucketItems(coupleId))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BucketItemModel.fromFirestore(doc, null))
            .toList());
  }

  /// Thêm item mới vào Firestore.
  Future<void> addItem(BucketItemModel item) async {
    await _firestore
        .collection(FirestorePaths.bucketItems(item.coupleId))
        .doc(item.id)
        .set(item.toFirestore());
  }

  /// Cập nhật tiêu đề và mô tả của item.
  Future<void> updateItem(BucketItemModel item) async {
    await _firestore
        .collection(FirestorePaths.bucketItems(item.coupleId))
        .doc(item.id)
        .update(item.toFirestoreUpdate());
  }

  /// Xóa item khỏi Firestore.
  Future<void> deleteItem(String coupleId, String itemId) async {
    await _firestore
        .collection(FirestorePaths.bucketItems(coupleId))
        .doc(itemId)
        .delete();
  }

  /// Đánh dấu item là hoàn thành, tuỳ chọn gắn linkedAlbumId.
  Future<void> markDone(
    String coupleId,
    String itemId, {
    String? linkedAlbumId,
  }) async {
    final Map<String, dynamic> updates = {
      'isDone': true,
      'completedAt': FieldValue.serverTimestamp(),
    };
    if (linkedAlbumId != null) {
      updates['linkedAlbumId'] = linkedAlbumId;
    }
    await _firestore
        .collection(FirestorePaths.bucketItems(coupleId))
        .doc(itemId)
        .update(updates);
  }
}
