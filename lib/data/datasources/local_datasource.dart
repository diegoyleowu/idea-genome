import 'package:hive_flutter/hive_flutter.dart';
import '../models/idea_model.dart';

abstract class LocalDataSource {
  Future<List<IdeaModel>> getAllIdeas();
  Future<IdeaModel?> getIdeaById(String id);
  Future<void> saveIdea(IdeaModel idea);
  Future<void> saveIdeas(List<IdeaModel> ideas);
  Future<void> deleteIdea(String id);
  Future<void> deleteIdeas(List<String> ids);
  Future<List<IdeaModel>> searchIdeas(String query);
  Stream<List<IdeaModel>> watchIdeas();
}

class HiveLocalDataSource implements LocalDataSource {
  static const String IDEA_BOX_NAME = 'ideas';
  late Box<IdeaModel> _ideaBox;

  Future<void> initialize() async {
    await Hive.initFlutter();
    Hive.registerAdapter(IdeaModelAdapter());
    _ideaBox = await Hive.openBox<IdeaModel>(IDEA_BOX_NAME);
  }

  @override
  Future<List<IdeaModel>> getAllIdeas() async {
    return _ideaBox.values.toList();
  }

  @override
  Future<IdeaModel?> getIdeaById(String id) async {
    return _ideaBox.get(id);
  }

  @override
  Future<void> saveIdea(IdeaModel idea) async {
    await _ideaBox.put(idea.id, idea);
  }

  @override
  Future<void> saveIdeas(List<IdeaModel> ideas) async {
    final map = {for (var idea in ideas) idea.id: idea};
    await _ideaBox.putAll(map);
  }

  @override
  Future<void> deleteIdea(String id) async {
    await _ideaBox.delete(id);
  }

  @override
  Future<void> deleteIdeas(List<String> ids) async {
    await _ideaBox.deleteAll(ids);
  }

  @override
  Future<List<IdeaModel>> searchIdeas(String query) async {
    final lowerQuery = query.toLowerCase();
    return _ideaBox.values.where((idea) {
      return idea.title.toLowerCase().contains(lowerQuery) ||
          idea.content.toLowerCase().contains(lowerQuery) ||
          idea.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  @override
  Stream<List<IdeaModel>> watchIdeas() {
    return _ideaBox.watch().map((_) => _ideaBox.values.toList());
  }
}
