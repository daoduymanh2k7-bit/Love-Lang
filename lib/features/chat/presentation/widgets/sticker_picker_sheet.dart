// lib/features/chat/presentation/widgets/sticker_picker_sheet.dart
//
// Bottom sheet chọn sticker từ GIPHY: mở lên tự động load "trending", có ô
// tìm kiếm để search theo từ khoá. Tap vào 1 sticker -> trả URL gốc
// (originalUrl) về cho màn hình gọi, màn hình đó chịu trách nhiệm gửi tin nhắn.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:love_lang/features/chat/data/datasources/giphy_sticker_datasource.dart';

/// Hiển thị bottom sheet chọn sticker. Trả về URL sticker (String) nếu người
/// dùng chọn 1 sticker, hoặc null nếu đóng sheet mà không chọn gì.
Future<String?> showStickerPickerSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _StickerPickerSheet(),
  );
}

class _StickerPickerSheet extends StatefulWidget {
  const _StickerPickerSheet();

  @override
  State<_StickerPickerSheet> createState() => _StickerPickerSheetState();
}

class _StickerPickerSheetState extends State<_StickerPickerSheet> {
  final _datasource = GiphyStickerDatasource();
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<GiphyStickerItem> _stickers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTrending();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTrending() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await _datasource.fetchTrending();
      if (mounted) setState(() => _stickers = result);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Không tải được sticker.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Debounce 400ms để không gọi API liên tục mỗi lần gõ 1 ký tự.
  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      try {
        final result = await _datasource.search(query);
        if (mounted) setState(() => _stickers = result);
      } catch (e) {
        if (mounted) setState(() => _errorMessage = 'Không tìm thấy sticker.');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: mediaQuery.size.height * 0.6,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tìm sticker (vd: love, cute, hug...)',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(child: _buildContent(colorScheme)),
        ],
      ),
    );
  }

  Widget _buildContent(ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!,
            style: TextStyle(color: colorScheme.error)),
      );
    }
    if (_stickers.isEmpty) {
      return const Center(child: Text('Không có sticker nào.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _stickers.length,
      itemBuilder: (context, index) {
        final sticker = _stickers[index];
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).pop(sticker.originalUrl),
          child: Hero(
            tag: sticker.id,
            child: CachedNetworkImage(
              imageUrl: sticker.previewUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.broken_image_outlined),
            ),
          ),
        );
      },
    );
  }
}