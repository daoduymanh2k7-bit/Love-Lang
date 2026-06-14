// lib/features/bucket_list/domain/entities/bucket_item_entity.dart

import 'package:flutter/foundation.dart';

@immutable
class BucketItemEntity {
  final String id;
  final String coupleId;
  final String title;
  final String description;
  final bool isDone;
  final DateTime? completedAt;
  final DateTime createdAt;
  final String createdBy;
  final String? linkedAlbumId;
  final String? completionImageUrl;

  const BucketItemEntity({
    required this.id,
    required this.coupleId,
    required this.title,
    this.description = '',
    required this.isDone,
    this.completedAt,
    required this.createdAt,
    required this.createdBy,
    this.linkedAlbumId,
    this.completionImageUrl,
  });

  BucketItemEntity copyWith({
    String? id,
    String? coupleId,
    String? title,
    String? description,
    bool? isDone,
    DateTime? completedAt,
    DateTime? createdAt,
    String? createdBy,
    String? linkedAlbumId,
    String? completionImageUrl,
  }) {
    return BucketItemEntity(
      id: id ?? this.id,
      linkedAlbumId: linkedAlbumId ?? this.linkedAlbumId,
      completionImageUrl: completionImageUrl ?? this.completionImageUrl,
      coupleId: coupleId ?? this.coupleId,
      title: title ?? this.title,
      description: description ?? this.description,
      isDone: isDone ?? this.isDone,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,

    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BucketItemEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
