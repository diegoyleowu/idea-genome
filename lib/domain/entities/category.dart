import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final Color color;
  final String icon;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Category copyWith({
    String? id,
    String? name,
    Color? color,
    String? icon,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, color, icon, sortOrder, createdAt, updatedAt];
}

class DefaultCategories {
  static List<Category> get all {
    final now = DateTime.now();
    return [
      Category(id: 'thought', name: '想法', color: const Color(0xFF6366F1), icon: 'lightbulb', sortOrder: 0, createdAt: now, updatedAt: now),
      Category(id: 'project', name: '项目', color: const Color(0xFF10B981), icon: 'rocket', sortOrder: 1, createdAt: now, updatedAt: now),
      Category(id: 'question', name: '问题', color: const Color(0xFFF59E0B), icon: 'help', sortOrder: 2, createdAt: now, updatedAt: now),
      Category(id: 'inspiration', name: '灵感', color: const Color(0xFFEC4899), icon: 'star', sortOrder: 3, createdAt: now, updatedAt: now),
    ];
  }
}
