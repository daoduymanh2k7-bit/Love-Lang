import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../domain/entities/milestone_entity.dart';

class MilestoneRemoteDataSource {
  final FirebaseFirestore _firestore;

  MilestoneRemoteDataSource(this._firestore);

  Stream<List<MilestoneEntity>> watchMilestones(String coupleId) {
    return _firestore
        .collection(FirestorePaths.milestones(coupleId))
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final dateVal = data['date'];
        DateTime dt = DateTime.now();
        if (dateVal is Timestamp) {
          dt = dateVal.toDate();
        } else if (dateVal is String) {
          dt = DateTime.tryParse(dateVal) ?? DateTime.now();
        }
        return MilestoneEntity(
          id: doc.id,
          title: data['title'] as String? ?? 'Cột mốc',
          date: dt,
          isDefault: data['isDefault'] as bool? ?? false,
        );
      }).toList();
    });
  }

  Future<void> addMilestone(
    String coupleId, {
    required String title,
    required DateTime date,
  }) async {
    await _firestore.collection(FirestorePaths.milestones(coupleId)).add({
      'title': title,
      'date': Timestamp.fromDate(date),
      'isDefault': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateMilestone(
    String coupleId,
    String milestoneId, {
    required String title,
    required DateTime date,
  }) async {
    await _firestore
        .collection(FirestorePaths.milestones(coupleId))
        .doc(milestoneId)
        .update({
      'title': title,
      'date': Timestamp.fromDate(date),
    });
  }

  Future<void> deleteMilestone(String coupleId, String milestoneId) async {
    await _firestore
        .collection(FirestorePaths.milestones(coupleId))
        .doc(milestoneId)
        .delete();
  }
}
