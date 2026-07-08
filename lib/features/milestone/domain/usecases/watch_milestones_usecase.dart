import '../entities/milestone_entity.dart';
import '../repositories/milestone_repository.dart';

class WatchMilestonesUseCase {
  final MilestoneRepository _repository;

  WatchMilestonesUseCase(this._repository);

  Stream<List<MilestoneEntity>> call(String coupleId) {
    return _repository.watchMilestones(coupleId);
  }
}
