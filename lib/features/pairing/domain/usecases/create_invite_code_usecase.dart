import 'package:love_lang/features/pairing/domain/entities/invite_entity.dart';
import 'package:love_lang/features/pairing/domain/repositories/pairing_repository.dart';

class CreateInviteCodeUseCase {
  final PairingRepository _repository;

  const CreateInviteCodeUseCase(this._repository);

  Future<InviteEntity> call() async {
    return _repository.createInviteCode();
  }
}
