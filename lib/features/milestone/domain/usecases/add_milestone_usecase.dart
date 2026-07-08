import '../repositories/milestone_repository.dart';

class AddMilestoneUseCase {
  final MilestoneRepository _repository;

  AddMilestoneUseCase(this._repository);

  Future<void> call(
    String coupleId, {
    required String title,
    required DateTime date,
  }) {
    return _repository.addMilestone(coupleId, title: title, date: date);
  }
}
