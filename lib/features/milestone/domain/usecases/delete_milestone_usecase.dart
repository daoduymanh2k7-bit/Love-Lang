import '../repositories/milestone_repository.dart';

class DeleteMilestoneUseCase {
  final MilestoneRepository _repository;

  DeleteMilestoneUseCase(this._repository);

  Future<void> call(String coupleId, String milestoneId) {
    return _repository.deleteMilestone(coupleId, milestoneId);
  }
}
