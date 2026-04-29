import 'package:equatable/equatable.dart';

enum LinkType { association, reference, evolution, contrast }

class IdeaLink extends Equatable {
  final String id;
  final String sourceId;
  final String targetId;
  final LinkType linkType;
  final double strength;
  final DateTime createdAt;

  const IdeaLink({
    required this.id,
    required this.sourceId,
    required this.targetId,
    required this.linkType,
    this.strength = 0.5,
    required this.createdAt,
  });

  IdeaLink copyWith({
    String? id,
    String? sourceId,
    String? targetId,
    LinkType? linkType,
    double? strength,
    DateTime? createdAt,
  }) {
    return IdeaLink(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      targetId: targetId ?? this.targetId,
      linkType: linkType ?? this.linkType,
      strength: strength ?? this.strength,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, sourceId, targetId, linkType, strength, createdAt];
}
