import 'package:flutter/material.dart';

class Category {
  final String? id;
  final String userId;
  final String name;
  final int iconCode;

  Category({
    this.id,
    required this.userId,
    required this.name,
    required this.iconCode,
  });

  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'name': name,
      'icon_code': iconCode,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id']?.toString(),
      userId: map['user_id'] ?? '',
      name: map['name'] ?? '',
      iconCode: map['icon_code'] ?? Icons.more_horiz.codePoint,
    );
  }
}
