import '../../domain/entities/milestone_entity.dart';
import '../../domain/repositories/milestone_repository.dart';
import '../datasources/milestone_remote_datasource.dart';

class MilestoneRepositoryImpl implements MilestoneRepository {
  final MilestoneRemoteDataSource _dataSource;

  MilestoneRepositoryImpl(this._dataSource);

  @override
  Stream<List<MilestoneEntity>> watchMilestones(String coupleId) {
    return _dataSource.watchMilestones(coupleId);
  }

  @override
  Future<void> addMilestone(
    String coupleId, {
    required String title,
    required DateTime date,
  }) {
    return _dataSource.addMilestone(coupleId, title: title, date: date);
  }

  @override
  Future<void> updateMilestone(
    String coupleId,
    String milestoneId, {
    required String title,
    required DateTime date,
  }) {
    return _dataSource.updateMilestone(
      coupleId,
      milestoneId,
      title: title,
      date: date,
    );
  }

  @override
  Future<void> deleteMilestone(String coupleId, String milestoneId) {
    return _dataSource.deleteMilestone(coupleId, milestoneId);
  }
}
