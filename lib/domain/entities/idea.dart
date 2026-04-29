import 'package:equatable/equatable.dart';

enum IdeaType { thought, project, question, inspiration }

enum SyncStatus { pending, syncing, synced, failed }

class Idea extends Equatable {
  final String id;
  final String title;
  final String content;
  final IdeaType type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? categoryId;
  final List<String> tags;
  final List<String> linkedIdeaIds;
  final bool isDeleted;
  final SyncStatus syncStatus;
  final Map<String, dynamic> metadata;
  final String? audioPath;
  final List<String> imagePaths;
  final String? videoPath;
  final String? drawingPath;

  const Idea({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.categoryId,
    this.tags = const [],
    this.linkedIdeaIds = const [],
    this.isDeleted = false,
    this.syncStatus = SyncStatus.pending,
    this.metadata = const {},
    this.audioPath,
    this.imagePaths = const [],
    this.videoPath,
    this.drawingPath,
  });

  String get displayTitle => title.isNotEmpty ? title : '无标题';

  String get summary {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }

  bool get hasTags => tags.isNotEmpty;
  bool get hasLinks => linkedIdeaIds.isNotEmpty;
  bool get hasAudio => audioPath != null && audioPath!.isNotEmpty;
  bool get hasImages => imagePaths.isNotEmpty;
  bool get hasVideo => videoPath != null && videoPath!.isNotEmpty;
  bool get hasDrawing => drawingPath != null && drawingPath!.isNotEmpty;
  bool get hasAttachments => hasAudio || hasImages || hasVideo || hasDrawing;

  Idea copyWith({
    String? id,
    String? title,
    String? content,
    IdeaType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryId,
    List<String>? tags,
    List<String>? linkedIdeaIds,
    bool? isDeleted,
    SyncStatus? syncStatus,
    Map<String, dynamic>? metadata,
    String? audioPath,
    List<String>? imagePaths,
    String? videoPath,
    String? drawingPath,
  }) {
    return Idea(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryId: categoryId ?? this.categoryId,
      tags: tags ?? this.tags,
      linkedIdeaIds: linkedIdeaIds ?? this.linkedIdeaIds,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
      metadata: metadata ?? this.metadata,
      audioPath: audioPath ?? this.audioPath,
      imagePaths: imagePaths ?? this.imagePaths,
      videoPath: videoPath ?? this.videoPath,
      drawingPath: drawingPath ?? this.drawingPath,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        type,
        createdAt,
        updatedAt,
        categoryId,
        tags,
        linkedIdeaIds,
        isDeleted,
        syncStatus,
        metadata,
      ];
}
