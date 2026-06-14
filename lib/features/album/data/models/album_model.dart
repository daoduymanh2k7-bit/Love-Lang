import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/album_entity.dart';

class AlbumModel extends AlbumEntity {
  const AlbumModel({
    required super.id,
    required super.coupleId,
    required super.title,
    required super.coverUrl,
    required super.description,
    required super.createdAt,
  });

  factory AlbumModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return AlbumModel(
      id: snapshot.id,
      coupleId: data?['coupleId'] as String? ?? '',
      title: data?['title'] as String? ?? '',
      coverUrl: data?['coverUrl'] as String? ?? '',
      description: data?['description'] as String? ?? '',
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory AlbumModel.fromEntity(AlbumEntity entity) {
    return AlbumModel(
      id: entity.id,
      coupleId: entity.coupleId,
      title: entity.title,
      coverUrl: entity.coverUrl,
      description: entity.description,
      createdAt: entity.createdAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'coupleId': coupleId,
      'title': title,
      'coverUrl': coverUrl,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
