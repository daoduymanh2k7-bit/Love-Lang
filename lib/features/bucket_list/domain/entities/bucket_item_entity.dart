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
  }) {
    return BucketItemEntity(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      title: title ?? this.title,
      description: description ?? this.description,
      isDone: isDone ?? this.isDone,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      linkedAlbumId: linkedAlbumId ?? this.linkedAlbumId,
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
