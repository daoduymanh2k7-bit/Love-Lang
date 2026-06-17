import 'package:flutter/foundation.dart';

@immutable
class PhotoEntity {
  final String id;
  final String albumId;
  final String uploadedById;
  final String url;
  final String cloudinaryPublicId;
  final String description;
  final DateTime createdAt;

  const PhotoEntity({
    required this.id,
    required this.albumId,
    required this.uploadedById,
    required this.url,
    this.cloudinaryPublicId = '',
    required this.description,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PhotoEntity &&
        other.id == id &&
        other.albumId == albumId &&
        other.uploadedById == uploadedById &&
        other.url == url &&
        other.cloudinaryPublicId == cloudinaryPublicId &&
        other.description == description &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        albumId.hashCode ^
        uploadedById.hashCode ^
        url.hashCode ^
        cloudinaryPublicId.hashCode ^
        description.hashCode ^
        createdAt.hashCode;
  }
}
