import 'package:flutter/foundation.dart';

@immutable
class DiaryEntryEntity {
  final String id;
  final String authorId;
  final String coupleId;
  final String title;
  final String content;
  final String mood;
  final List<String> mediaUrls;
  final bool isPrivate;
  final DateTime createdAt;

  const DiaryEntryEntity({
    required this.id,
    required this.authorId,
    required this.coupleId,
    required this.title,
    required this.content,
    required this.mood,
    required this.mediaUrls,
    required this.isPrivate,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DiaryEntryEntity &&
        other.id == id &&
        other.authorId == authorId &&
        other.coupleId == coupleId &&
        other.title == title &&
        other.content == content &&
        other.mood == mood &&
        listEquals(other.mediaUrls, mediaUrls) &&
        other.isPrivate == isPrivate &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        authorId.hashCode ^
        coupleId.hashCode ^
        title.hashCode ^
        content.hashCode ^
        mood.hashCode ^
        mediaUrls.hashCode ^
        isPrivate.hashCode ^
        createdAt.hashCode;
  }
}
