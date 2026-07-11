import 'package:love_lang/features/sound/domain/entities/sound_settings_entity.dart';
import 'package:love_lang/features/sound/domain/repositories/sound_settings_repository.dart';

class UpdateSoundSettingsUseCase {
  final SoundSettingsRepository repository;

  UpdateSoundSettingsUseCase(this.repository);

  Future<void> call(SoundSettingsEntity settings) {
    return repository.saveSettings(settings);
  }
}