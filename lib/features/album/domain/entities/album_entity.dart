import 'package:flutter/foundation.dart';

@immutable
class AlbumEntity {
  final String id;
  final String coupleId;
  final String title;
  final String coverUrl;
  final String description;
  final DateTime createdAt;

  const AlbumEntity({
    required this.id,
    required this.coupleId,
    required this.title,
    required this.coverUrl,
    required this.description,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is AlbumEntity &&
      other.id == id &&
      other.coupleId == coupleId &&
      other.title == title &&
      other.coverUrl == coverUrl &&
      other.description == description &&
      other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      coupleId.hashCode ^
      title.hashCode ^
      coverUrl.hashCode ^
      description.hashCode ^
      createdAt.hashCode;
  }
}
