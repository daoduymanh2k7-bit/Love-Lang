import 'package:love_lang/features/sound/domain/entities/sound_settings_entity.dart';

abstract class SoundSettingsRepository {
  /// Đọc cài đặt âm thanh đã lưu. Trả về [SoundSettingsEntity.defaults]
  /// nếu người dùng chưa từng lưu gì (lần đầu mở app).
  Future<SoundSettingsEntity> getSettings();

  /// Lưu toàn bộ cài đặt âm thanh xuống thiết bị.
  Future<void> saveSettings(SoundSettingsEntity settings);
}