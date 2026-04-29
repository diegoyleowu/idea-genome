import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/idea.dart';
import '../../../domain/repositories/idea_repository.dart';
import '../../../core/utils/id_generator.dart';
import 'idea_event.dart';
import 'idea_state.dart';

class IdeaBloc extends Bloc<IdeaEvent, IdeaState> {
  final IdeaRepository repository;
  StreamSubscription<List<Idea>>? _ideaSubscription;

  IdeaBloc({required this.repository}) : super(const IdeaState()) {
    on<LoadIdeas>(_onLoadIdeas);
    on<CreateIdea>(_onCreateIdea);
    on<UpdateIdea>(_onUpdateIdea);
    on<DeleteIdea>(_onDeleteIdea);
    on<SearchIdeas>(_onSearchIdeas);
    on<FilterByCategory>(_onFilterByCategory);
    on<FilterByTag>(_onFilterByTag);
    on<SelectIdea>(_onSelectIdea);

    _ideaSubscription = repository.watchAllIdeas().listen((ideas) {
      add(LoadIdeas());
    });
  }

  Future<void> _onLoadIdeas(LoadIdeas event, Emitter<IdeaState> emit) async {
    emit(state.copyWith(status: IdeaStateStatus.loading));

    final result = await repository.getAllIdeas();

    result.fold(
      (failure) => emit(state.copyWith(
        status: IdeaStateStatus.error,
        errorMessage: failure.message,
      )),
      (ideas) => emit(state.copyWith(
        status: IdeaStateStatus.loaded,
        ideas: ideas,
        filteredIdeas: _applyFilters(ideas),
      )),
    );
  }

  Future<void> _onCreateIdea(CreateIdea event, Emitter<IdeaState> emit) async {
    final now = DateTime.now();
    final idea = Idea(
      id: IdGenerator.generate(),
      title: event.title,
      content: event.content,
      type: event.type,
      createdAt: now,
      updatedAt: now,
      categoryId: event.categoryId,
      tags: event.tags,
      audioPath: event.audioPath,
      imagePaths: event.imagePaths,
      videoPath: event.videoPath,
      drawingPath: event.drawingPath,
    );

    final result = await repository.createIdea(idea);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(LoadIdeas()),
    );
  }

  Future<void> _onUpdateIdea(UpdateIdea event, Emitter<IdeaState> emit) async {
    final result = await repository.updateIdea(event.idea);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(LoadIdeas()),
    );
  }

  Future<void> _onDeleteIdea(DeleteIdea event, Emitter<IdeaState> emit) async {
    final result = await repository.deleteIdea(event.id);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {
        if (state.selectedIdeaId == event.id) {
          emit(state.copyWith(selectedIdeaId: null));
        }
        add(LoadIdeas());
      },
    );
  }

  void _onSearchIdeas(SearchIdeas event, Emitter<IdeaState> emit) {
    emit(state.copyWith(
      searchQuery: event.query,
      filteredIdeas: _applyFilters(state.ideas, searchQuery: event.query),
    ));
  }

  void _onFilterByCategory(FilterByCategory event, Emitter<IdeaState> emit) {
    emit(state.copyWith(
      filterCategoryId: event.categoryId,
      filteredIdeas: _applyFilters(state.ideas, categoryId: event.categoryId),
    ));
  }

  void _onFilterByTag(FilterByTag event, Emitter<IdeaState> emit) {
    emit(state.copyWith(
      filterTag: event.tag,
      filteredIdeas: _applyFilters(state.ideas, tag: event.tag),
    ));
  }

  void _onSelectIdea(SelectIdea event, Emitter<IdeaState> emit) {
    emit(state.copyWith(selectedIdeaId: event.ideaId));
  }

  List<Idea> _applyFilters(
    List<Idea> ideas, {
    String? searchQuery,
    String? categoryId,
    String? tag,
  }) {
    var filtered = ideas;

    final query = searchQuery ?? state.searchQuery;
    if (query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      filtered = filtered.where((idea) {
        return idea.title.toLowerCase().contains(lowerQuery) ||
            idea.content.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    final catId = categoryId ?? state.filterCategoryId;
    if (catId != null) {
      filtered = filtered.where((idea) => idea.categoryId == catId).toList();
    }

    final t = tag ?? state.filterTag;
    if (t != null) {
      filtered = filtered.where((idea) => idea.tags.contains(t)).toList();
    }

    return filtered;
  }

  @override
  Future<void> close() {
    _ideaSubscription?.cancel();
    return super.close();
  }
}
