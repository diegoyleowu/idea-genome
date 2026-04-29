import 'package:dartz/dartz.dart';
import '../entities/idea.dart';

class Failure {
  final String message;
  const Failure(this.message);
}

abstract class IdeaRepository {
  Future<Either<Failure, List<Idea>>> getAllIdeas();
  Future<Either<Failure, Idea>> getIdeaById(String id);
  Future<Either<Failure, Idea>> createIdea(Idea idea);
  Future<Either<Failure, Idea>> updateIdea(Idea idea);
  Future<Either<Failure, void>> deleteIdea(String id);
  Future<Either<Failure, List<Idea>>> searchIdeas(String query);
  Future<Either<Failure, List<Idea>>> getIdeasByCategory(String categoryId);
  Future<Either<Failure, List<Idea>>> getIdeasByTag(String tag);
  Stream<List<Idea>> watchAllIdeas();
}
