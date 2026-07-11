import 'package:love_lang/features/sound/domain/entities/sound_settings_entity.dart';
import 'package:love_lang/features/sound/domain/repositories/sound_settings_repository.dart';

class GetSoundSettingsUseCase {
  final SoundSettingsRepository repository;

  GetSoundSettingsUseCase(this.repository);

  Future<SoundSettingsEntity> call() {
    return repository.getSettings();
  }
}