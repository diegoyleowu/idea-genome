import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/category.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();
  @override
  List<Object?> get props => [];
}

class LoadCategories extends CategoryEvent {}

class SelectCategory extends CategoryEvent {
  final String? categoryId;
  const SelectCategory(this.categoryId);
  @override
  List<Object?> get props => [categoryId];
}

class CategoryState extends Equatable {
  final List<Category> categories;
  final String? selectedCategoryId;
  final bool isLoading;

  const CategoryState({
    this.categories = const [],
    this.selectedCategoryId,
    this.isLoading = false,
  });

  CategoryState copyWith({
    List<Category>? categories,
    String? selectedCategoryId,
    bool? isLoading,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [categories, selectedCategoryId, isLoading];
}

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  CategoryBloc() : super(const CategoryState()) {
    on<LoadCategories>(_onLoadCategories);
    on<SelectCategory>(_onSelectCategory);
  }

  void _onLoadCategories(LoadCategories event, Emitter<CategoryState> emit) {
    emit(state.copyWith(isLoading: true));
    emit(state.copyWith(
      isLoading: false,
      categories: DefaultCategories.all,
    ));
  }

  void _onSelectCategory(SelectCategory event, Emitter<CategoryState> emit) {
    emit(state.copyWith(selectedCategoryId: event.categoryId));
  }
}
