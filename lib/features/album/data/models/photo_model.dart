import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/photo_entity.dart';

class PhotoModel extends PhotoEntity {
  const PhotoModel({
    required super.id,
    required super.albumId,
    required super.uploadedById,
    required super.url,
    super.cloudinaryPublicId = '',
    required super.description,
    required super.createdAt,
  });

  factory PhotoModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return PhotoModel(
      id: snapshot.id,
      albumId: data?['albumId'] as String? ?? '',
      uploadedById: data?['uploadedById'] as String? ?? '',
      url: data?['url'] as String? ?? '',
      cloudinaryPublicId: data?['cloudinaryPublicId'] as String? ?? '',
      description: data?['description'] as String? ?? '',
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory PhotoModel.fromEntity(PhotoEntity entity) {
    return PhotoModel(
      id: entity.id,
      albumId: entity.albumId,
      uploadedById: entity.uploadedById,
      url: entity.url,
      cloudinaryPublicId: entity.cloudinaryPublicId,
      description: entity.description,
      createdAt: entity.createdAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'albumId': albumId,
      'uploadedById': uploadedById,
      'url': url,
      'cloudinaryPublicId': cloudinaryPublicId,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
