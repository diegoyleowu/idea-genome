import 'dart:math';
import 'package:collection/collection.dart';

class EmbeddingService {
  static const int EMBEDDING_DIMENSION = 128;

  List<double> embed(String text) {
    final words = _tokenize(text);
    if (words.isEmpty) return List.filled(EMBEDDING_DIMENSION, 0.0);

    final wordFreq = <String, int>{};
    for (final word in words) {
      wordFreq[word] = (wordFreq[word] ?? 0) + 1;
    }

    final tfidf = <String, double>{};
    final idf = _calculateIDF(words);
    for (final entry in wordFreq.entries) {
      tfidf[entry.key] = entry.value / words.length * idf[entry.key]!;
    }

    final embedding = List<double>.filled(EMBEDDING_DIMENSION, 0.0);
    var index = 0;
    for (final word in tfidf.keys.sorted()) {
      if (index >= EMBEDDING_DIMENSION) break;
      embedding[index] = tfidf[word]!;
      index++;
    }

    return _normalize(embedding);
  }

  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\u4e00-\u9fff]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 1)
        .toList();
  }

  Map<String, double> _calculateIDF(List<String> words) {
    final docFreq = <String, int>{};
    for (final word in words.toSet()) {
      docFreq[word] = 1;
    }
    return docFreq.map((key, value) => MapEntry(key, log(1 + 1 / value)));
  }

  List<double> _normalize(List<double> vector) {
    final norm = sqrt(vector.fold(0.0, (sum, v) => sum + v * v));
    if (norm == 0) return vector;
    return vector.map((v) => v / norm).toList();
  }
}

class SimilarityService {
  double cosineSimilarity(List<double> vec1, List<double> vec2) {
    if (vec1.length != vec2.length) return 0.0;

    var dotProduct = 0.0;
    var norm1 = 0.0;
    var norm2 = 0.0;

    for (var i = 0; i < vec1.length; i++) {
      dotProduct += vec1[i] * vec2[i];
      norm1 += vec1[i] * vec1[i];
      norm2 += vec2[i] * vec2[i];
    }

    final n1 = sqrt(norm1);
    final n2 = sqrt(norm2);

    if (n1 == 0 || n2 == 0) return 0.0;
    return dotProduct / (n1 * n2);
  }

  double euclideanDistance(List<double> vec1, List<double> vec2) {
    if (vec1.length != vec2.length) return double.infinity;

    var sum = 0.0;
    for (var i = 0; i < vec1.length; i++) {
      sum += pow(vec1[i] - vec2[i], 2);
    }
    return sqrt(sum);
  }
}
