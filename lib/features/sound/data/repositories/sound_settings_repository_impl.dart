import 'package:love_lang/features/sound/data/datasources/sound_settings_local_datasource.dart';
import 'package:love_lang/features/sound/domain/entities/sound_settings_entity.dart';
import 'package:love_lang/features/sound/domain/repositories/sound_settings_repository.dart';

class SoundSettingsRepositoryImpl implements SoundSettingsRepository {
  final SoundSettingsLocalDatasource localDatasource;

  SoundSettingsRepositoryImpl(this.localDatasource);

  // Lưu ý: thao tác với SharedPreferences (đọc/ghi cục bộ trên thiết bị)
  // hiếm khi ném lỗi nghiệp vụ cần bọc thành Failure riêng như các feature
  // gọi Firestore — nếu có lỗi bất thường (đĩa lỗi, plugin lỗi...), để lỗi
  // gốc bay lên cho tầng Notifier xử lý theo đúng pattern try/catch chung
  // (on Failure / catch chung) đã dùng ở các feature khác.

  @override
  Future<SoundSettingsEntity> getSettings() {
    return localDatasource.getSettings();
  }

  @override
  Future<void> saveSettings(SoundSettingsEntity settings) {
    return localDatasource.saveSettings(settings);
  }
}