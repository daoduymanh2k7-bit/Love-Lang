import '../repositories/milestone_repository.dart';

class UpdateMilestoneUseCase {
  final MilestoneRepository _repository;

  UpdateMilestoneUseCase(this._repository);

  Future<void> call(
    String coupleId,
    String milestoneId, {
    required String title,
    required DateTime date,
  }) {
    return _repository.updateMilestone(
      coupleId,
      milestoneId,
      title: title,
      date: date,
    );
  }
}
