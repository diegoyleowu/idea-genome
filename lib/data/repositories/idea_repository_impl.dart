import 'package:dartz/dartz.dart';
import '../../domain/entities/idea.dart';
import '../../domain/repositories/idea_repository.dart';
import '../datasources/local_datasource.dart';
import '../models/idea_model.dart';

class IdeaRepositoryImpl implements IdeaRepository {
  final LocalDataSource localDataSource;

  IdeaRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Idea>>> getAllIdeas() async {
    try {
      final models = await localDataSource.getAllIdeas();
      final ideas = models.map((m) => m.toEntity()).toList();
      ideas.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return Right(ideas);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Idea>> getIdeaById(String id) async {
    try {
      final model = await localDataSource.getIdeaById(id);
      if (model == null) {
        return const Left(Failure('Idea not found'));
      }
      return Right(model.toEntity());
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Idea>> createIdea(Idea idea) async {
    try {
      final model = IdeaModel.fromEntity(idea);
      await localDataSource.saveIdea(model);
      return Right(idea);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Idea>> updateIdea(Idea idea) async {
    try {
      final updatedIdea = idea.copyWith(updatedAt: DateTime.now());
      final model = IdeaModel.fromEntity(updatedIdea);
      await localDataSource.saveIdea(model);
      return Right(updatedIdea);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteIdea(String id) async {
    try {
      await localDataSource.deleteIdea(id);
      return const Right(null);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Idea>>> searchIdeas(String query) async {
    try {
      final models = await localDataSource.searchIdeas(query);
      final ideas = models.map((m) => m.toEntity()).toList();
      return Right(ideas);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Idea>>> getIdeasByCategory(String categoryId) async {
    try {
      final models = await localDataSource.getAllIdeas();
      final ideas = models
          .where((m) => m.categoryId == categoryId)
          .map((m) => m.toEntity())
          .toList();
      return Right(ideas);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Idea>>> getIdeasByTag(String tag) async {
    try {
      final models = await localDataSource.getAllIdeas();
      final ideas = models
          .where((m) => m.tags.contains(tag))
          .map((m) => m.toEntity())
          .toList();
      return Right(ideas);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Stream<List<Idea>> watchAllIdeas() {
    return localDataSource.watchIdeas().map(
          (models) => models.map((m) => m.toEntity()).toList(),
        );
  }
}
