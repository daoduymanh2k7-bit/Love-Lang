import 'package:shared_preferences/shared_preferences.dart';
import 'package:love_lang/features/sound/domain/entities/sound_settings_entity.dart';

/// Các key dùng để lưu/đọc trong SharedPreferences. SharedPreferences không
/// hỗ trợ lưu object lồng nhau nên phải tách thành 4 key riêng lẻ.
class SoundSettingsKeys {
  static const musicEnabled = 'sound_music_enabled';
  static const sfxEnabled = 'sound_sfx_enabled';
  static const musicVolume = 'sound_music_volume';
  static const sfxVolume = 'sound_sfx_volume';
}

class SoundSettingsModel {
  /// Đọc cài đặt từ SharedPreferences. Nếu key nào chưa từng được lưu
  /// (lần đầu mở app), dùng giá trị mặc định tương ứng của field đó.
  static SoundSettingsEntity fromPrefs(SharedPreferences prefs) {
    const defaults = SoundSettingsEntity.defaults;
    return SoundSettingsEntity(
      musicEnabled:
          prefs.getBool(SoundSettingsKeys.musicEnabled) ?? defaults.musicEnabled,
      sfxEnabled:
          prefs.getBool(SoundSettingsKeys.sfxEnabled) ?? defaults.sfxEnabled,
      musicVolume:
          prefs.getDouble(SoundSettingsKeys.musicVolume) ?? defaults.musicVolume,
      sfxVolume:
          prefs.getDouble(SoundSettingsKeys.sfxVolume) ?? defaults.sfxVolume,
    );
  }

  /// Ghi toàn bộ 4 giá trị của [settings] xuống SharedPreferences.
  static Future<void> saveToPrefs(
    SharedPreferences prefs,
    SoundSettingsEntity settings,
  ) async {
    await prefs.setBool(SoundSettingsKeys.musicEnabled, settings.musicEnabled);
    await prefs.setBool(SoundSettingsKeys.sfxEnabled, settings.sfxEnabled);
    await prefs.setDouble(SoundSettingsKeys.musicVolume, settings.musicVolume);
    await prefs.setDouble(SoundSettingsKeys.sfxVolume, settings.sfxVolume);
  }
}