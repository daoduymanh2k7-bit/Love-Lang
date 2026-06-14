import 'package:flutter/foundation.dart';

@immutable
class MilestoneEntity {
  final String id;
  final String title;
  final DateTime date;
  final bool isDefault;

  const MilestoneEntity({
    required this.id,
    required this.title,
    required this.date,
    this.isDefault = false,
  });

  MilestoneEntity copyWith({
    String? id,
    String? title,
    DateTime? date,
    bool? isDefault,
  }) {
    return MilestoneEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MilestoneEntity &&
        other.id == id &&
        other.title == title &&
        other.date == date &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode {
    return id.hashCode ^ title.hashCode ^ date.hashCode ^ isDefault.hashCode;
  }
}
