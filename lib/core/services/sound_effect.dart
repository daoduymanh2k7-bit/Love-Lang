/// Danh sách các sound effect có trong app và đường dẫn asset tương ứng.
/// Thêm SFX mới cho hành động mới chỉ cần thêm 1 dòng ở đây.
enum SoundEffect {
  message('audio/sfx_message.mp3'),
  nudge('audio/sfx_nudge.mp3'),
  album('audio/sfx_album.mp3'),
  milestone('audio/sfx_milestone.mp3'),
  bucketList('audio/sfx_bucket_list.mp3'),
  tabSwitch('audio/sfx_tab_switch.mp3');

  final String assetPath;
  const SoundEffect(this.assetPath);
}