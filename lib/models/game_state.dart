import 'package:flutter/material.dart';

class GameState {
  final int score;
  final int hits;
  final int misses;
  final bool isGameActive;
  final bool hasTarget;
  final Offset targetPosition;
  final DateTime startTime;
  final DateTime? targetSpawnTime;
  final List<int> reactionTimes;
  final int gameDuration; // seconds
  final int targetTimeout; // seconds
  final int spawnDelay; // milliseconds

  GameState({
    this.score = 0,
    this.hits = 0,
    this.misses = 0,
    this.isGameActive = true,
    this.hasTarget = false,
    this.targetPosition = const Offset(0, 0),
    DateTime? startTime,
    this.targetSpawnTime,
    this.reactionTimes = const [],
    this.gameDuration = 60,
    this.targetTimeout = 2,
    this.spawnDelay = 800,
  }) : startTime = startTime ?? DateTime.now();

  int get totalShots => hits + misses;

  double get accuracy => totalShots > 0 ? (hits / totalShots) * 100 : 0.0;

  double get averageReactionTime =>
      reactionTimes.isNotEmpty
          ? reactionTimes.reduce((a, b) => a + b) / reactionTimes.length
          : 0.0;

  GameState copyWith({
    int? score,
    int? hits,
    int? misses,
    bool? isGameActive,
    bool? hasTarget,
    Offset? targetPosition,
    DateTime? startTime,
    DateTime? targetSpawnTime,
    List<int>? reactionTimes,
    int? gameDuration,
    int? targetTimeout,
    int? spawnDelay,
  }) {
    return GameState(
      score: score ?? this.score,
      hits: hits ?? this.hits,
      misses: misses ?? this.misses,
      isGameActive: isGameActive ?? this.isGameActive,
      hasTarget: hasTarget ?? this.hasTarget,
      targetPosition: targetPosition ?? this.targetPosition,
      startTime: startTime ?? this.startTime,
      targetSpawnTime: targetSpawnTime ?? this.targetSpawnTime,
      reactionTimes: reactionTimes ?? this.reactionTimes,
      gameDuration: gameDuration ?? this.gameDuration,
      targetTimeout: targetTimeout ?? this.targetTimeout,
      spawnDelay: spawnDelay ?? this.spawnDelay,
    );
  }

  @override
  String toString() {
    return 'GameState{score: $score, hits: $hits, misses: $misses, accuracy: ${accuracy.toStringAsFixed(1)}%, avgReactionTime: ${averageReactionTime.toStringAsFixed(0)}ms}';
  }
}
