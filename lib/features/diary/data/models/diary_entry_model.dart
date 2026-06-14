import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/diary_entry_entity.dart';

class DiaryEntryModel extends DiaryEntryEntity {
  const DiaryEntryModel({
    required super.id,
    required super.authorId,
    required super.coupleId,
    required super.title,
    required super.content,
    required super.mood,
    required super.mediaUrls,
    required super.isPrivate,
    required super.createdAt,
  });

  factory DiaryEntryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return DiaryEntryModel(
      id: snapshot.id,
      authorId: data?['authorId'] as String? ?? '',
      coupleId: data?['coupleId'] as String? ?? '',
      title: data?['title'] as String? ?? '',
      content: data?['content'] as String? ?? '',
      mood: data?['mood'] as String? ?? '',
      mediaUrls: (data?['mediaUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      isPrivate: data?['isPrivate'] as bool? ?? false,
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory DiaryEntryModel.fromEntity(DiaryEntryEntity entity) {
    return DiaryEntryModel(
      id: entity.id,
      authorId: entity.authorId,
      coupleId: entity.coupleId,
      title: entity.title,
      content: entity.content,
      mood: entity.mood,
      mediaUrls: entity.mediaUrls,
      isPrivate: entity.isPrivate,
      createdAt: entity.createdAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'coupleId': coupleId,
      'title': title,
      'content': content,
      'mood': mood,
      'mediaUrls': mediaUrls,
      'isPrivate': isPrivate,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
  
  Map<String, dynamic> toFirestoreUpdate() {
    return {
      'title': title,
      'content': content,
      'mood': mood,
      'mediaUrls': mediaUrls,
      'isPrivate': isPrivate,
    };
  }
}
