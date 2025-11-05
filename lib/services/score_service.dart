import 'dart:convert';
import 'package:flutter_application_1/models/difficulty.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScoreService {
  static const String _scoresKey = 'pubg_training_scores';
  static const String _scoresByDifficultyKey = 'scores_by_difficulty';

  Future<void> saveScore(
    int score,
    int hits,
    int misses, {
    Difficulty? difficulty,
  }) async {
    final gameScore = GameScore(
      score: score,
      hits: hits,
      misses: misses,
      accuracy: hits + misses > 0 ? (hits / (hits + misses)) * 100 : 0.0,
      timestamp: DateTime.now(),
      difficulty: difficulty,
    );

    final prefs = await SharedPreferences.getInstance();

    // Save to general scores
    final scores = await getScores();
    scores.add(gameScore);

    // Keep only last 100 scores to prevent storage issues
    if (scores.length > 100) {
      scores.removeRange(0, scores.length - 100);
    }

    // Sort by score descending
    scores.sort((a, b) => b.score.compareTo(a.score));

    final scoresJson = scores.map((score) => score.toJson()).toList();
    await prefs.setString(_scoresKey, jsonEncode(scoresJson));

    // Save by difficulty if provided
    if (difficulty != null) {
      await _saveScoreByDifficulty(gameScore, difficulty);
    }
  }

  Future<void> _saveScoreByDifficulty(
    GameScore score,
    Difficulty difficulty,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_scoresByDifficultyKey}_${difficulty.name}';

    final existingScores = await getScoresByDifficulty(difficulty) ?? [];
    existingScores.add(score);

    // Keep only last 50 scores per difficulty
    if (existingScores.length > 50) {
      existingScores.removeRange(0, existingScores.length - 50);
    }

    existingScores.sort((a, b) => b.score.compareTo(a.score));

    final scoresJson = existingScores.map((score) => score.toJson()).toList();
    await prefs.setString(key, jsonEncode(scoresJson));
  }

  Future<List<GameScore>> getScores() async {
    final prefs = await SharedPreferences.getInstance();
    final scoresString = prefs.getString(_scoresKey);

    if (scoresString == null) return [];

    try {
      final List<dynamic> scoresJson = jsonDecode(scoresString);
      return scoresJson.map((json) => GameScore.fromJson(json)).toList();
    } catch (e) {
      print('Error loading scores: $e');
      return [];
    }
  }

  Future<List<GameScore>?> getScoresByDifficulty(
    Difficulty difficulty, {
    int? limit,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_scoresByDifficultyKey}_${difficulty.name}';
    final scoresString = prefs.getString(key);

    if (scoresString == null) return [];

    try {
      final List<dynamic> scoresJson = jsonDecode(scoresString);
      final scores = scoresJson
          .map((json) => GameScore.fromJson(json))
          .toList();

      if (limit != null && limit > 0) {
        return scores.take(limit).toList();
      }

      return scores;
    } catch (e) {
      print('Error loading scores by difficulty: $e');
      return [];
    }
  }

  Future<List<GameScore>> getTopScores({int limit = 10}) async {
    final scores = await getScores();
    scores.sort((a, b) => b.score.compareTo(a.score));
    return scores.take(limit).toList();
  }

  Future<GameScore?> getBestScore() async {
    final scores = await getScores();
    if (scores.isEmpty) return null;
    return scores.reduce((a, b) => a.score > b.score ? a : b);
  }

  Future<double> getAverageAccuracy() async {
    final scores = await getScores();
    if (scores.isEmpty) return 0.0;
    final totalAccuracy = scores.fold(
      0.0,
      (sum, score) => sum + score.accuracy,
    );
    return totalAccuracy / scores.length;
  }

  Future<int> getTotalGames() async {
    final scores = await getScores();
    return scores.length;
  }

  Future<int> getTotalHits() async {
    final scores = await getScores();
    return scores.fold(0, (sum, score) => sum = score.hits);
  }

  Future<int> getTotalMisses() async {
    final scores = await getScores();
    return scores.fold(0, (sum, score) => sum = score.misses);
  }

  Future<void> clearScores() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear general scores
    await prefs.remove(_scoresKey);

    // Clear difficulty-specific scores
    for (final difficulty in Difficulty.values) {
      final key = '${_scoresByDifficultyKey}_${difficulty.name}';
      await prefs.remove(key);
    }
  }

  Future<List<GameScore>> getRecentScores({int days = 7}) async {
    final scores = await getScores();
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return scores
        .where((score) => score.timestamp.isAfter(cutoffDate))
        .toList();
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final scores = await getScores();

    if (scores.isEmpty) {
      return {
        'totalGames': 0,
        'bestScore': 0,
        'averageScore': 0.0,
        'averageAccuracy': 0.0,
        'totalHits': 0,
        'totalMisses': 0,
      };
    }

    final bestScore = (await getBestScore())?.score ?? 0;
    final averageScore =
        scores.fold(0, (sum, score) => sum + score.score) / scores.length;

    return {
      'totalGames': scores.length,
      'bestScore': bestScore,
      'averageScore': averageScore,
      'averageAccuracy': await getAverageAccuracy(),
      'totalHits': await getTotalHits(),
      'totalMisses': await getTotalMisses(),
    };
  }
}

class GameScore {
  final int score;
  final int hits;
  final int misses;
  final double accuracy;
  final DateTime timestamp;
  final Difficulty? difficulty;

  GameScore({
    required this.score,
    required this.hits,
    required this.misses,
    required this.accuracy,
    required this.timestamp,
    this.difficulty,
  });

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'hits': hits,
      'misses': misses,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      'difficulty': difficulty?.name,
    };
  }

  factory GameScore.fromJson(Map<String, dynamic> json) {
    Difficulty? difficulty;
    if (json['difficulty'] != null) {
      try {
        difficulty = Difficulty.values.firstWhere(
          (d) => d.name == json['difficulty'],
        );
      } catch (e) {
        difficulty = null;
      }
    }

    return GameScore(
      score: json['score'] as int,
      hits: json['hits'] as int,
      misses: json['misses'] as int,
      accuracy: (json['accuracy'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      difficulty: difficulty,
    );
  }

  int get totalShots => hits + misses;

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} kun oldin';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} soat oldin';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} daqiqa oldin';
    } else {
      return 'Hozir';
    }
  }

  @override
  String toString() {
    return 'GameScore{score: $score, hits: $hits, misses: $misses, accuracy: ${accuracy.toStringAsFixed(1)}%, difficulty: ${difficulty?.name}}';
  }
}
