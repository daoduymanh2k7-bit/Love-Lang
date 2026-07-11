import 'package:shared_preferences/shared_preferences.dart';
import 'package:love_lang/features/sound/data/models/sound_settings_model.dart';
import 'package:love_lang/features/sound/domain/entities/sound_settings_entity.dart';

abstract class SoundSettingsLocalDatasource {
  Future<SoundSettingsEntity> getSettings();
  Future<void> saveSettings(SoundSettingsEntity settings);
}

class SoundSettingsLocalDatasourceImpl implements SoundSettingsLocalDatasource {
  @override
  Future<SoundSettingsEntity> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return SoundSettingsModel.fromPrefs(prefs);
  }

  @override
  Future<void> saveSettings(SoundSettingsEntity settings) async {
    final prefs = await SharedPreferences.getInstance();
    await SoundSettingsModel.saveToPrefs(prefs, settings);
  }
}