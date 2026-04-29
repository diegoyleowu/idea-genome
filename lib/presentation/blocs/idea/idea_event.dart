import 'package:equatable/equatable.dart';
import '../../../domain/entities/idea.dart';

abstract class IdeaEvent extends Equatable {
  const IdeaEvent();

  @override
  List<Object?> get props => [];
}

class LoadIdeas extends IdeaEvent {}

class CreateIdea extends IdeaEvent {
  final String title;
  final String content;
  final IdeaType type;
  final String? categoryId;
  final List<String> tags;
  final String? audioPath;
  final List<String> imagePaths;
  final String? videoPath;
  final String? drawingPath;

  const CreateIdea({
    required this.title,
    required this.content,
    required this.type,
    this.categoryId,
    this.tags = const [],
    this.audioPath,
    this.imagePaths = const [],
    this.videoPath,
    this.drawingPath,
  });

  @override
  List<Object?> get props => [title, content, type, categoryId, tags, audioPath, imagePaths, videoPath, drawingPath];
}

class UpdateIdea extends IdeaEvent {
  final Idea idea;

  const UpdateIdea(this.idea);

  @override
  List<Object?> get props => [idea];
}

class DeleteIdea extends IdeaEvent {
  final String id;

  const DeleteIdea(this.id);

  @override
  List<Object?> get props => [id];
}

class SearchIdeas extends IdeaEvent {
  final String query;

  const SearchIdeas(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterByCategory extends IdeaEvent {
  final String? categoryId;

  const FilterByCategory(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

class FilterByTag extends IdeaEvent {
  final String tag;

  const FilterByTag(this.tag);

  @override
  List<Object?> get props => [tag];
}

class SelectIdea extends IdeaEvent {
  final String? ideaId;

  const SelectIdea(this.ideaId);

  @override
  List<Object?> get props => [ideaId];
}
