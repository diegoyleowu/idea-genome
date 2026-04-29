import 'package:hive/hive.dart';
import '../../domain/entities/idea.dart';

part 'idea_model.g.dart';

@HiveType(typeId: 0)
class IdeaModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final int typeIndex;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime updatedAt;

  @HiveField(6)
  final String? categoryId;

  @HiveField(7)
  final List<String> tags;

  @HiveField(8)
  final List<String> linkedIdeaIds;

  @HiveField(9)
  final bool isDeleted;

  @HiveField(10)
  final int syncStatusIndex;

  @HiveField(11)
  final Map<String, dynamic> metadata;

  @HiveField(12)
  final String? audioPath;

  @HiveField(13)
  final List<String> imagePaths;

  @HiveField(14)
  final String? videoPath;

  @HiveField(15)
  final String? drawingPath;

  IdeaModel({
    required this.id,
    required this.title,
    required this.content,
    required this.typeIndex,
    required this.createdAt,
    required this.updatedAt,
    this.categoryId,
    required this.tags,
    required this.linkedIdeaIds,
    this.isDeleted = false,
    this.syncStatusIndex = 0,
    required this.metadata,
    this.audioPath,
    required this.imagePaths,
    this.videoPath,
    this.drawingPath,
  });

  factory IdeaModel.fromEntity(Idea idea) {
    return IdeaModel(
      id: idea.id,
      title: idea.title,
      content: idea.content,
      typeIndex: idea.type.index,
      createdAt: idea.createdAt,
      updatedAt: idea.updatedAt,
      categoryId: idea.categoryId,
      tags: idea.tags,
      linkedIdeaIds: idea.linkedIdeaIds,
      isDeleted: idea.isDeleted,
      syncStatusIndex: idea.syncStatus.index,
      metadata: idea.metadata,
      audioPath: idea.audioPath,
      imagePaths: idea.imagePaths,
      videoPath: idea.videoPath,
      drawingPath: idea.drawingPath,
    );
  }

  Idea toEntity() {
    return Idea(
      id: id,
      title: title,
      content: content,
      type: IdeaType.values[typeIndex],
      createdAt: createdAt,
      updatedAt: updatedAt,
      categoryId: categoryId,
      tags: tags,
      linkedIdeaIds: linkedIdeaIds,
      isDeleted: isDeleted,
      syncStatus: SyncStatus.values[syncStatusIndex],
      metadata: metadata,
      audioPath: audioPath,
      imagePaths: imagePaths,
      videoPath: videoPath,
      drawingPath: drawingPath,
    );
  }
}
