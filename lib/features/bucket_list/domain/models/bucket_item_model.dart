// lib/features/bucket_list/domain/models/bucket_item_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../entities/bucket_item_entity.dart';

class BucketItemModel extends BucketItemEntity {
  const BucketItemModel({
    required super.id,
    required super.coupleId,
    required super.title,
    super.description,
    required super.isDone,
    super.completedAt,
    required super.createdAt,
    required super.createdBy,
    super.linkedAlbumId,
    super.completionImageUrl,
  });

  factory BucketItemModel.fromFirestore(
      DocumentSnapshot doc, String? idOverride) {
    final data = doc.data() as Map<String, dynamic>;
    return BucketItemModel(
      id: idOverride ?? doc.id,
      coupleId: data['coupleId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      isDone: data['isDone'] ?? false,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      linkedAlbumId: data['linkedAlbumId'],
      completionImageUrl: data['completionImageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'coupleId': coupleId,
        'title': title,
        'description': description,
        'isDone': isDone,
        if (completedAt != null)
          'completedAt': Timestamp.fromDate(completedAt!),
        'createdAt': Timestamp.fromDate(createdAt),
        'createdBy': createdBy,
        if (linkedAlbumId != null) 'linkedAlbumId': linkedAlbumId,
        if (completionImageUrl != null)
          'completionImageUrl': completionImageUrl,
      };

  Map<String, dynamic> toFirestoreUpdate() => {
        'title': title,
        'description': description,
        'isDone': isDone,
        if (completedAt != null)
          'completedAt': Timestamp.fromDate(completedAt!),
        if (linkedAlbumId != null) 'linkedAlbumId': linkedAlbumId,
        if (completionImageUrl != null)
          'completionImageUrl': completionImageUrl,
      };
}
