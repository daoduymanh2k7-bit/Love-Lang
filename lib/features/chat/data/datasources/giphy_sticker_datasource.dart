// lib/features/chat/data/datasources/giphy_sticker_datasource.dart
//
// Service gọi GIPHY Stickers API (https://developers.giphy.com/docs/api/endpoint#stickers).
// Chỉ dùng 2 endpoint: /stickers/trending và /stickers/search.
//
// LƯU Ý QUAN TRỌNG VỀ API KEY:
// - Lấy API key miễn phí tại https://developers.giphy.com/dashboard/ (tạo app
//   loại "API", không phải "SDK"). Free tier đủ dùng cho app cá nhân.
// - KHÔNG hardcode key thẳng vào file này khi commit lên git công khai. Cách
//   an toàn hơn: đọc qua biến môi trường lúc build bằng
//   `flutter run --dart-define=GIPHY_API_KEY=xxxx` rồi lấy qua
//   `String.fromEnvironment('GIPHY_API_KEY')`. Ở đây tạm để hằng số cho dễ
//   chạy thử trước, bạn có thể đổi lại sau.

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Đại diện 1 sticker trả về từ GIPHY.
class GiphyStickerItem {
  final String id;
  /// URL ảnh preview nhỏ, dùng để hiển thị trong lưới chọn sticker (tải nhanh).
  final String previewUrl;
  /// URL ảnh gốc chất lượng đầy đủ, dùng khi gửi tin nhắn / hiển thị trong bubble.
  final String originalUrl;

  const GiphyStickerItem({
    required this.id,
    required this.previewUrl,
    required this.originalUrl,
  });

  factory GiphyStickerItem.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as Map<String, dynamic>;
    // 'fixed_width_small' nhẹ, hợp để hiển thị lưới chọn sticker.
    final preview = images['fixed_width_small'] ?? images['fixed_width'];
    final original = images['original'];
    return GiphyStickerItem(
      id: json['id'] as String,
      previewUrl: preview['url'] as String,
      originalUrl: original['url'] as String,
    );
  }
}

class GiphyStickerDatasource {
  // TODO: thay bằng API key thật của bạn lấy từ developers.giphy.com
  static const String _apiKey = 'ckcm4UajC9sL7TCsjDrjh8knVcXRGkPj';

  static const String _baseUrl = 'https://api.giphy.com/v1/stickers';

  /// Lấy danh sách sticker thịnh hành (hiển thị mặc định khi mở picker).
  Future<List<GiphyStickerItem>> fetchTrending({int limit = 30}) async {
    final uri = Uri.parse(
      '$_baseUrl/trending?api_key=$_apiKey&limit=$limit&rating=pg',
    );
    return _fetchAndParse(uri);
  }

  /// Tìm sticker theo từ khoá (VD: "yêu", "hug", "cute cat"...).
  /// GIPHY hỗ trợ tốt tiếng Anh; tiếng Việt có kết quả nhưng hạn chế hơn.
  Future<List<GiphyStickerItem>> search(String query, {int limit = 30}) async {
    if (query.trim().isEmpty) return fetchTrending(limit: limit);
    final uri = Uri.parse(
      '$_baseUrl/search?api_key=$_apiKey&q=${Uri.encodeQueryComponent(query)}'
      '&limit=$limit&rating=pg',
    );
    return _fetchAndParse(uri);
  }

  Future<List<GiphyStickerItem>> _fetchAndParse(Uri uri) async {
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception(
          'GIPHY API lỗi (${response.statusCode}): ${response.body}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as List<dynamic>;
    return data
        .map((e) => GiphyStickerItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}