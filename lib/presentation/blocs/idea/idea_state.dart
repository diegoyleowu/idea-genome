import 'package:equatable/equatable.dart';
import '../../../domain/entities/idea.dart';

enum IdeaStateStatus { initial, loading, loaded, error }

class IdeaState extends Equatable {
  final IdeaStateStatus status;
  final List<Idea> ideas;
  final List<Idea> filteredIdeas;
  final String? selectedIdeaId;
  final String? filterCategoryId;
  final String? filterTag;
  final String searchQuery;
  final String? errorMessage;

  const IdeaState({
    this.status = IdeaStateStatus.initial,
    this.ideas = const [],
    this.filteredIdeas = const [],
    this.selectedIdeaId,
    this.filterCategoryId,
    this.filterTag,
    this.searchQuery = '',
    this.errorMessage,
  });

  Idea? get selectedIdea {
    if (selectedIdeaId == null) return null;
    try {
      return ideas.firstWhere((i) => i.id == selectedIdeaId);
    } catch (_) {
      return null;
    }
  }

  IdeaState copyWith({
    IdeaStateStatus? status,
    List<Idea>? ideas,
    List<Idea>? filteredIdeas,
    String? selectedIdeaId,
    String? filterCategoryId,
    String? filterTag,
    String? searchQuery,
    String? errorMessage,
  }) {
    return IdeaState(
      status: status ?? this.status,
      ideas: ideas ?? this.ideas,
      filteredIdeas: filteredIdeas ?? this.filteredIdeas,
      selectedIdeaId: selectedIdeaId ?? this.selectedIdeaId,
      filterCategoryId: filterCategoryId ?? this.filterCategoryId,
      filterTag: filterTag ?? this.filterTag,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        ideas,
        filteredIdeas,
        selectedIdeaId,
        filterCategoryId,
        filterTag,
        searchQuery,
        errorMessage,
      ];
}
