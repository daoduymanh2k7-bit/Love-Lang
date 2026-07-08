import '../entities/milestone_entity.dart';

/// Interface tầng Domain — Presentation chỉ phụ thuộc vào đây,
/// không biết gì về Firestore.
abstract class MilestoneRepository {
  Stream<List<MilestoneEntity>> watchMilestones(String coupleId);

  Future<void> addMilestone(
    String coupleId, {
    required String title,
    required DateTime date,
  });

  Future<void> updateMilestone(
    String coupleId,
    String milestoneId, {
    required String title,
    required DateTime date,
  });

  Future<void> deleteMilestone(String coupleId, String milestoneId);
}
