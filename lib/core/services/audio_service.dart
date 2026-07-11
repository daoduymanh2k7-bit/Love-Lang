import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:love_lang/core/services/sound_effect.dart';

const String _backgroundMusicAsset = 'audio/bg_music.mp3';

/// Cấu hình audio context cho phép NHIỀU âm thanh phát chồng lên nhau cùng
/// lúc (nhạc nền + sound effect) mà không cái nào bị hệ điều hành tự tạm
/// dừng cái kia.
///
/// Mặc định, mỗi AudioPlayer khi play() sẽ giành "audio focus" độc quyền
/// trên Android/iOS — điều này khiến nhạc nền tự bị pause mỗi khi 1 SFX mới
/// phát. Đặt `audioFocus: AndroidAudioFocus.none` (Android) và
/// `mixWithOthers` (iOS) để tắt hành vi giành quyền đó.
final AudioContext _mixAudioContext = AudioContext(
  android: const AudioContextAndroid(
    isSpeakerphoneOn: false,
    stayAwake: false,
    contentType: AndroidContentType.music,
    usageType: AndroidUsageType.media,
    audioFocus: AndroidAudioFocus.none,
  ),
  iOS: AudioContextIOS(
    // FIX: `AVAudioSessionOptions.mixWithOthers` chỉ hợp lệ với category
    // `playback`, `playAndRecord`, hoặc `multiRoute` — audioplayers có
    // assert chặn cứng combo này. Trước đây dùng `.ambient` +
    // `mixWithOthers` khiến assert nổ ngay khi AudioService khởi tạo lần
    // đầu (assertion error văng ra ngoài try/catch vì xảy ra lúc construct
    // field, không phải trong thân hàm playMusic/playSfx), làm im lặng cả
    // nhạc nền lẫn SFX và thậm chí làm hỏng cả luồng gửi tin nhắn (vì đó
    // là nơi đầu tiên đọc audioServiceProvider).
    category: AVAudioSessionCategory.playback,
    options: const {AVAudioSessionOptions.mixWithOthers},
  ),
);

/// Quản lý phát nhạc nền và sound effect cho toàn app.
///
/// Nhạc nền dùng đúng 1 [AudioPlayer] duy nhất, loop liên tục, pause/resume
/// theo lifecycle app (xử lý ở `main_screen.dart`, service này chỉ cung cấp
/// hàm để gọi).
///
/// Sound effect: mỗi lần phát tạo 1 [AudioPlayer] mới rồi tự dispose sau khi
/// phát xong — cho phép nhiều SFX overlap ngắn khi người dùng thao tác
/// nhanh liên tiếp (ví dụ chuyển tab nhanh), thay vì bị chặn lẫn nhau.
///
/// Cả nhạc nền lẫn SFX đều dùng [_mixAudioContext] để không giành audio
/// focus của nhau — nếu không, mỗi SFX phát ra sẽ tự động pause nhạc nền.
class AudioService {
  final AudioPlayer _musicPlayer = AudioPlayer();
  bool _musicLoaded = false;

  AudioService() {
    // Set audio context mặc định cho MỌI AudioPlayer được tạo sau thời điểm
    // này (kể cả các player SFX tạo mới trong playSfx) — chỉ cần gọi 1 lần.
    //
    // Bọc try/catch: đây là nơi ĐẦU TIÊN đọc audioServiceProvider trong
    // toàn app, có thể là lúc gửi tin nhắn hoặc chuyển tab. Nếu config
    // AudioContext có vấn đề (assert của audioplayers, incompatibility
    // giữa các phiên bản...), lỗi không được phép văng ra ngoài và làm
    // hỏng luôn flow không liên quan (từng xảy ra: lỗi audio context làm
    // hiện "Lỗi gửi tin nhắn").
    try {
      AudioPlayer.global.setAudioContext(_mixAudioContext);
      _musicPlayer.setAudioContext(_mixAudioContext);
    } catch (e, st) {
      debugPrint('AudioService: LỖI không thể set AudioContext: $e');
      debugPrint('$st');
    }
  }

  /// Bắt đầu phát nhạc nền (loop). Nếu nhạc đã được load trước đó và chỉ
  /// đang tạm dừng, dùng [resumeMusic] thay vì gọi lại hàm này để tránh
  /// phát lại từ đầu.
  Future<void> playMusic({required double volume}) async {
    debugPrint('AudioService: playMusic() được gọi, musicLoaded=$_musicLoaded, volume=$volume');
    try {
      if (!_musicLoaded) {
        await _musicPlayer.setReleaseMode(ReleaseMode.loop);
        await _musicPlayer.setVolume(volume);
        await _musicPlayer.play(AssetSource(_backgroundMusicAsset));
        _musicLoaded = true;
        debugPrint('AudioService: đã gọi play() cho $_backgroundMusicAsset thành công');
      } else {
        await _musicPlayer.resume();
        debugPrint('AudioService: đã resume nhạc nền');
      }
    } catch (e, st) {
      // R10 (spec): thiếu/lỗi file âm thanh không được làm crash app.
      debugPrint('AudioService: LỖI không thể phát nhạc nền: $e');
      debugPrint('$st');
    }
  }

  Future<void> pauseMusic() async {
    try {
      await _musicPlayer.pause();
    } catch (e) {
      debugPrint('AudioService: không thể tạm dừng nhạc nền: $e');
    }
  }

  Future<void> resumeMusic() async {
    try {
      if (!_musicLoaded) return; // chưa từng phát thì không có gì để resume
      await _musicPlayer.resume();
    } catch (e) {
      debugPrint('AudioService: không thể tiếp tục phát nhạc nền: $e');
    }
  }

  Future<void> stopMusic() async {
    try {
      await _musicPlayer.stop();
      _musicLoaded = false;
    } catch (e) {
      debugPrint('AudioService: không thể dừng nhạc nền: $e');
    }
  }

  Future<void> setMusicVolume(double volume) async {
    try {
      await _musicPlayer.setVolume(volume);
    } catch (e) {
      debugPrint('AudioService: không thể chỉnh âm lượng nhạc nền: $e');
    }
  }

  /// Bật/tắt nhạc nền theo toggle của người dùng — bật thì phát/resume,
  /// tắt thì pause (không stop hẳn, để có thể resume đúng vị trí sau).
  Future<void> setMusicEnabled(bool enabled, {required double volume}) {
    return enabled ? playMusic(volume: volume) : pauseMusic();
  }

  /// Phát 1 sound effect. Không làm gì nếu [enabled] là false (người dùng
  /// đã tắt SFX trong Settings).
  Future<void> playSfx(SoundEffect effect,
      {required double volume, required bool enabled}) async {
    if (!enabled) return;
    try {
      final player = AudioPlayer();
      await player.setAudioContext(_mixAudioContext);
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(volume);
      await player.play(AssetSource(effect.assetPath));
      // Tự dispose sau khi phát xong để không rò rỉ player.
      player.onPlayerComplete.first.then((_) => player.dispose());
    } catch (e) {
      debugPrint('AudioService: không thể phát SFX ${effect.name}: $e');
    }
  }

  void dispose() {
    _musicPlayer.dispose();
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(service.dispose);
  return service;
});