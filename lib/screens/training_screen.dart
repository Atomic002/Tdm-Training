import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/models/difficulty.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'package:flutter_application_1/services/admob_service.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:math';
import '../utils/app_colors.dart';
import '../models/game_state.dart';
import '../services/score_service.dart';

class TrainingScreen extends StatefulWidget {
  final Difficulty difficulty;

  const TrainingScreen({super.key, required this.difficulty});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen>
    with TickerProviderStateMixin {
  final ScoreService _scoreService = ScoreService();
  final FirestoreService _firestoreService = FirestoreService();
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  GameState _gameState = GameState();

  Timer? _gameTimer;
  Timer? _targetTimer;
  Timer? _countdownTimer;
  Timer? _multiTargetTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _coinAnimationController;
  late Animation<double> _coinScaleAnimation;
  late Animation<Offset> _coinSlideAnimation;

  // Flappy Bird uchun
  late AnimationController _birdController;
  late Animation<double> _birdAnimation;
  double _birdPosition = 0.0;
  double _birdVelocity = 0.0;
  final double _gravity = 0.8;
  final double _jumpStrength = -12.0;
  final List<Offset> _pipes = [];
  Timer? _pipeTimer;
  bool _isFlappyBirdMode = false;
  int _passedPipes = 0;

  final Random _random = Random();
  final int _coinsEarned = 1;
  bool _canPlayGame = true;
  bool _isWaitingToStart = true;
  int _currentMatch = 1;
  int _totalMatches = 0;
  int _timeLeft = 0;

  // Ko'p nishonlar uchun
  final List<TargetInfo> _targets = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkGamePermission();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    _coinAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _coinScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _coinAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    _coinSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _coinAnimationController,
            curve: Curves.easeOut,
          ),
        );

    // Flappy Bird animatsiyasi
    _birdController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _birdAnimation = Tween<double>(begin: 0, end: 1).animate(_birdController);
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _targetTimer?.cancel();
    _countdownTimer?.cancel();
    _multiTargetTimer?.cancel();
    _pipeTimer?.cancel();
    _pulseController.dispose();
    _coinAnimationController.dispose();
    _birdController.dispose();
    super.dispose();
  }

  Future<void> _checkGamePermission() async {
    final canPlay = _uid != null ? await _firestoreService.canPlayGame(_uid!, isMiniPubg: false) : false;
    setState(() {
      _canPlayGame = canPlay;
      _isWaitingToStart = canPlay;
    });

    if (!canPlay) {
      _showGameLimitDialog();
    }
  }

  void _showGameLimitDialog() {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.danger, size: 28),
            const SizedBox(width: 12),
            Text(
              l.dailyLimit,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.dailyLimitReached,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    l.dailyGameLimitInfo(FirestoreService.maxDailyReactionGames),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.tryAgainTomorrow,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Dialog
              Navigator.pop(
                context,
              ); // Training Screen - darajalar sahifasiga qaytadi
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(l.ok),
          ),
        ],
      ),
    );
  }

  void _startGame() {
    // Flappy Bird rejimini aniqlash (Expert darajada)
    _isFlappyBirdMode = widget.difficulty.name.toLowerCase() == 'expert';

    setState(() {
      _gameState = GameState();
      _gameState = _gameState.copyWith(
        gameDuration: _getDifficultyDuration(),
        targetTimeout: _getDifficultyTargetTimeout(),
        spawnDelay: _getDifficultySpawnDelay(),
      );
      _timeLeft = _gameState.gameDuration;
      _coinAnimationController.reset();
      _targets.clear();
      _passedPipes = 0;

      if (_isFlappyBirdMode) {
        _birdPosition = 0.0;
        _birdVelocity = 0.0;
        _pipes.clear();
        _startFlappyBird();
      }
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0 && _gameState.isGameActive) {
        setState(() {
          _timeLeft--;
        });
      } else {
        timer.cancel();
        if (_gameState.isGameActive) {
          _endGame();
        }
      }
    });

    if (!_isFlappyBirdMode) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _gameState.isGameActive) {
          _spawnMultipleTargets();
        }
      });
    }
  }

  void _startFlappyBird() {
    // Birinchi pipe'ni keyinroq spawn qilish
    Future.delayed(const Duration(seconds: 2), () {
      if (_gameState.isGameActive) {
        _spawnPipe();
      }
    });

    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_gameState.isGameActive) {
        timer.cancel();
        return;
      }

      setState(() {
        // Qush harakati
        _birdVelocity += _gravity;
        _birdPosition += _birdVelocity;

        // Pipe harakati
        for (int i = 0; i < _pipes.length; i++) {
          _pipes[i] = Offset(_pipes[i].dx - 3, _pipes[i].dy);
        }

        // O'tgan pipe'larni sanash
        for (var pipe in _pipes) {
          if (pipe.dx < 45 && pipe.dx > 42) {
            // Qush o'tdi
            _passedPipes++;
            _gameState = _gameState.copyWith(
              hits: _gameState.hits + 1,
              score: _gameState.score + 10,
            );
          }
        }

        // Eski pipe'larni olib tashlash
        _pipes.removeWhere((pipe) => pipe.dx < -100);

        // Collision detection
        _checkBirdCollision();
      });
    });

    // Pipe spawn timer
    _pipeTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (_gameState.isGameActive) {
        _spawnPipe();
      } else {
        timer.cancel();
      }
    });
  }

  void _spawnPipe() {
    final screenHeight = MediaQuery.of(context).size.height;
    const pipeGap = 180.0;
    final minPipeHeight = 150.0;
    final maxPipeHeight = screenHeight - 350.0;
    final pipeHeight =
        minPipeHeight + _random.nextDouble() * (maxPipeHeight - minPipeHeight);

    _pipes.add(Offset(MediaQuery.of(context).size.width, pipeHeight));
  }

  void _jump() {
    if (_isFlappyBirdMode && _gameState.isGameActive) {
      setState(() {
        _birdVelocity = _jumpStrength;
      });
      HapticFeedback.lightImpact();
      _birdController.forward().then((_) => _birdController.reverse());
    }
  }

  void _checkBirdCollision() {
    final screenHeight = MediaQuery.of(context).size.height;

    // Yer va osmon bilan collision
    if (_birdPosition <= -screenHeight * 0.35 ||
        _birdPosition >= screenHeight * 0.25) {
      _gameState = _gameState.copyWith(misses: _gameState.misses + 1);
      _resetBirdPosition();
      return;
    }

    // Pipe bilan collision
    const birdSize = 40.0;
    const pipeWidth = 80.0;
    const pipeGap = 180.0;

    for (var pipe in _pipes) {
      if (pipe.dx < 90 && pipe.dx > -40) {
        // Qush pipe yonida
        final birdTop =
            (MediaQuery.of(context).size.height * 0.5 + _birdPosition) -
            birdSize / 2;
        final birdBottom =
            (MediaQuery.of(context).size.height * 0.5 + _birdPosition) +
            birdSize / 2;

        final topPipeBottom = pipe.dy;
        final bottomPipeTop = pipe.dy + pipeGap;

        if (birdTop < topPipeBottom || birdBottom > bottomPipeTop) {
          _gameState = _gameState.copyWith(misses: _gameState.misses + 1);
          _resetBirdPosition();
          return;
        }
      }
    }
  }

  void _resetBirdPosition() {
    setState(() {
      _birdPosition = 0.0;
      _birdVelocity = 0.0;
    });
  }

  int _getDifficultyDuration() {
    switch (widget.difficulty.name.toLowerCase()) {
      case 'easy':
        return 52;
      case 'medium':
        return 67;
      case 'hard':
        return 82;
      case 'expert':
        return 112;
      default:
        return 52;
    }
  }

  int _getDifficultyTargetTimeout() {
    switch (widget.difficulty.name.toLowerCase()) {
      case 'easy':
        return 3;
      case 'medium':
        return 2;
      case 'hard':
        return 1;
      case 'expert':
        return 1;
      default:
        return 3;
    }
  }

  int _getDifficultySpawnDelay() {
    switch (widget.difficulty.name.toLowerCase()) {
      case 'easy':
        return 1000;
      case 'medium':
        return 700;
      case 'hard':
        return 400;
      case 'expert':
        return 300;
      default:
        return 1000;
    }
  }

  int _getTargetCount() {
    switch (widget.difficulty.name.toLowerCase()) {
      case 'easy':
        return 2;
      case 'medium':
        return 4;
      case 'hard':
        return 6;
      case 'expert':
        return 0;
      default:
        return 2;
    }
  }

  void _spawnMultipleTargets() {
    if (!_gameState.isGameActive || !mounted || _isFlappyBirdMode) return;

    final targetCount = _getTargetCount();
    _targets.clear();

    for (int i = 0; i < targetCount; i++) {
      _spawnSingleTarget(i);
    }

    _multiTargetTimer = Timer(Duration(seconds: _gameState.targetTimeout), () {
      if (mounted) {
        _onTargetsTimeout();
      }
    });
  }

  void _spawnSingleTarget(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_gameState.isGameActive) return;

      final size = MediaQuery.of(context).size;
      final screenWidth = size.width;
      final screenHeight = size.height;

      const margin = 60.0;
      final targetSize = _getDifficultyTargetSize();
      const topMargin = 100.0;
      const bottomMargin = 120.0;

      final maxX = screenWidth - 2 * margin - targetSize;
      final maxY = screenHeight - topMargin - bottomMargin - targetSize;

      if (maxX <= 0 || maxY <= 0) return;

      Offset position;
      int attempts = 0;
      do {
        final x = margin + _random.nextDouble() * maxX;
        final y = topMargin + _random.nextDouble() * maxY;
        position = Offset(x, y);
        attempts++;
      } while (_isPositionTooClose(position, targetSize) && attempts < 100);

      final target = TargetInfo(
        id: index,
        position: position,
        spawnTime: DateTime.now(),
        size: targetSize,
      );

      setState(() {
        _targets.add(target);
      });
    });
  }

  bool _isPositionTooClose(Offset newPosition, double targetSize) {
    const minDistance = 80.0;
    for (var target in _targets) {
      final distance = (newPosition - target.position).distance;
      if (distance < minDistance) {
        return true;
      }
    }
    return false;
  }

  void _onTargetHit(int targetId) {
    if (!_gameState.isGameActive || !mounted) return;

    final targetIndex = _targets.indexWhere((t) => t.id == targetId);
    if (targetIndex == -1) return;

    final target = _targets[targetIndex];
    final reactionTime = DateTime.now()
        .difference(target.spawnTime)
        .inMilliseconds;

    HapticFeedback.lightImpact();

    setState(() {
      _targets.removeAt(targetIndex);
      _gameState = _gameState.copyWith(
        score: _gameState.score + _calculateScore(reactionTime),
        hits: _gameState.hits + 1,
        reactionTimes: [..._gameState.reactionTimes, reactionTime],
      );
    });

    // Agar barcha nishonlar bosilgan bo'lsa
    if (_targets.isEmpty) {
      _multiTargetTimer?.cancel();
      Future.delayed(Duration(milliseconds: _gameState.spawnDelay), () {
        if (mounted && _gameState.isGameActive) {
          _spawnMultipleTargets();
        }
      });
    }
  }

  void _onTargetsTimeout() {
    if (!_gameState.isGameActive || !mounted) return;

    setState(() {
      _gameState = _gameState.copyWith(
        misses: _gameState.misses + _targets.length,
      );
      _targets.clear();
    });

    Future.delayed(Duration(milliseconds: _gameState.spawnDelay), () {
      if (mounted && _gameState.isGameActive) {
        _spawnMultipleTargets();
      }
    });
  }

  double _getDifficultyTargetSize() {
    switch (widget.difficulty.name.toLowerCase()) {
      case 'easy':
        return 70.0;
      case 'medium':
        return 55.0;
      case 'hard':
        return 40.0;
      case 'expert':
        return 30.0;
      default:
        return 60.0;
    }
  }

  int _calculateScore(int reactionTime) {
    final baseScore = _getBaseScore(reactionTime);
    final difficultyMultiplier = _getDifficultyMultiplier();
    return (baseScore * difficultyMultiplier).round();
  }

  int _getBaseScore(int reactionTime) {
    if (reactionTime < 200) return 100;
    if (reactionTime < 300) return 80;
    if (reactionTime < 400) return 60;
    if (reactionTime < 500) return 40;
    return 20;
  }

  double _getDifficultyMultiplier() {
    switch (widget.difficulty.name.toLowerCase()) {
      case 'easy':
        return 1.0;
      case 'medium':
        return 1.5;
      case 'hard':
        return 2.0;
      case 'expert':
        return 3.0;
      default:
        return 1.0;
    }
  }

  String _getDifficultyName(AppLocalizations l) {
    switch (widget.difficulty.name.toLowerCase()) {
      case 'easy':
        return l.diffEasy;
      case 'medium':
        return l.diffMedium;
      case 'hard':
        return l.diffHard;
      case 'expert':
        return l.diffExpert;
      default:
        return widget.difficulty.name.toUpperCase();
    }
  }

  void _endGame() {
    if (!mounted) return;

    setState(() {
      _gameState = _gameState.copyWith(isGameActive: false);
    });

    _gameTimer?.cancel();
    _targetTimer?.cancel();
    _countdownTimer?.cancel();
    _multiTargetTimer?.cancel();
    _pipeTimer?.cancel();

    _scoreService.saveScore(
      _gameState.score,
      _gameState.hits,
      _gameState.misses,
      difficulty: widget.difficulty,
    );

    // Reaksiya o'yini uchun 1 coin qo'shish
    if (_uid != null) {
      _firestoreService.addCoinsForGameDirect(_uid!, 1, isMiniPubg: false);
    }
    _totalMatches++;

    _coinAnimationController.forward();

    _showGameOverDialog();
  }

  /// Keyingi match uchun majburiy reklama ko'rsatib, keyin o'yinni boshlash
  Future<void> _showAdThenStartNextGame() async {
    final canPlay = _uid != null
        ? await _firestoreService.canPlayGame(_uid!, isMiniPubg: false)
        : false;

    if (!canPlay) {
      _showGameLimitDialog();
      return;
    }

    // Loading dialog
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                l.gamePreparingLoading,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      if (AdMobService.isInterstitialAdReady) {
        await AdMobService.showInterstitialAd();
        if (mounted) {
          Navigator.pop(context); // Loading dialogni yopish
          setState(() {
            _currentMatch++;
            _isWaitingToStart = true;
          });
        }
      } else {
        AdMobService.loadInterstitialAd();
        await Future.delayed(const Duration(seconds: 3));

        if (!mounted) return;

        if (AdMobService.isInterstitialAdReady) {
          await AdMobService.showInterstitialAd();
          if (mounted) {
            Navigator.pop(context);
            setState(() {
              _currentMatch++;
              _isWaitingToStart = true;
            });
          }
        } else {
          Navigator.pop(context);
          if (mounted) {
            final l2 = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l2.adFailedRetry),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        final l2 = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l2.adFailedRetry),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showGameOverDialog() {
    final l = AppLocalizations.of(context)!;
    final accuracy = _gameState.totalShots > 0
        ? ((_gameState.hits / _gameState.totalShots) * 100).toStringAsFixed(1)
        : '0.0';

    final avgReactionTime = _gameState.reactionTimes.isNotEmpty
        ? (_gameState.reactionTimes.reduce((a, b) => a + b) /
                  _gameState.reactionTimes.length)
              .toStringAsFixed(0)
        : '0';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.emoji_events, color: AppColors.accent, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.matchFinishedTitle(_currentMatch),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade400, Colors.orange.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l.coinEarnedGame,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildStatRow(
                        l.score,
                        '${_gameState.score}',
                        AppColors.accent,
                      ),
                      if (!_isFlappyBirdMode) ...[
                        _buildStatRow(
                          l.accuracy,
                          '$accuracy%',
                          AppColors.success,
                        ),
                        _buildStatRow(
                          l.averageTimeLabel,
                          '${avgReactionTime}ms',
                          AppColors.info,
                        ),
                      ],
                      _buildStatRow(
                        _isFlappyBirdMode ? l.passedLabel : l.hitsLabel,
                        '${_gameState.hits}',
                        AppColors.success,
                      ),
                      _buildStatRow(
                        _isFlappyBirdMode ? l.crashedLabel : l.missesLabel,
                        '${_gameState.misses}',
                        AppColors.danger,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<Map<String, dynamic>?>(
                  future: _uid != null ? _firestoreService.getDailyStatus(_uid!, isMiniPubg: false) : Future.value(null),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      final status = snapshot.data!;
                      final remaining =
                          status['maxGames'] - status['gamesPlayed'];
                      final l2 = AppLocalizations.of(context)!;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.info.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.info,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l2.remainingMatchesInfo(remaining),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context); // Dialog
                Navigator.pop(
                  context,
                ); // Training Screen - darajalar sahifasiga qaytadi
              },
              icon: const Icon(
                Icons.arrow_back,
                color: AppColors.textSecondary,
              ),
              label: Text(
                l.backToLevels,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showAdThenStartNextGame();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: Text(
                l.nextMatch,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              _getDifficultyName(l),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              _isFlappyBirdMode
                  ? l.flappyModeMatch(_currentMatch)
                  : l.matchLabel(_currentMatch),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: Colors.amber,
                  size: 18,
                ),
                const SizedBox(width: 4),
                FutureBuilder<int>(
                  future: _firestoreService.getCoins(),
                  builder: (context, snapshot) {
                    return Text(
                      '${snapshot.data ?? 0}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isWaitingToStart && _canPlayGame
          ? _buildStartScreen(l)
          : GestureDetector(
        onTap: _isFlappyBirdMode ? _jump : null,
        child: Stack(
          children: [
            if (_gameState.isGameActive) ...[
              // Game UI
              Positioned(
                top: 20,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: AppColors.accent,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_gameState.score}',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: size.width < 360 ? 14 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Timer
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _timeLeft <= 10
                              ? AppColors.danger
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer,
                              color: _timeLeft <= 10
                                  ? Colors.white
                                  : AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_timeLeft}s',
                              style: TextStyle(
                                color: _timeLeft <= 10
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontSize: size.width < 360 ? 14 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!_isFlappyBirdMode)
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.gps_fixed,
                                color: AppColors.success,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_gameState.totalShots > 0 ? ((_gameState.hits / _gameState.totalShots) * 100).toStringAsFixed(0) : '0'}%',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: size.width < 360 ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Flappy Bird rejimi
              if (_isFlappyBirdMode) ...[
                // Qush
                AnimatedBuilder(
                  animation: _birdAnimation,
                  builder: (context, child) {
                    return Positioned(
                      left: 50,
                      top: size.height * 0.5 + _birdPosition,
                      child: Transform.scale(
                        scale: 1.0 + (_birdAnimation.value * 0.2),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Colors.yellow.shade400,
                                Colors.orange.shade600,
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.sports_baseball,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Pipe'lar
                ..._pipes.map((pipe) => _buildPipe(pipe)),

                // Tap ko'rsatmasi
                if (_pipes.isEmpty)
                  Positioned(
                    top: size.height * 0.3,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.touch_app,
                              color: AppColors.primary,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l.tapToJump,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l.passThroughPipes,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],

              // Oddiy nishonlar rejimi
              if (!_isFlappyBirdMode)
                ..._targets.map((target) => _buildTarget(target)),
            ],

            if (!_gameState.isGameActive && !_canPlayGame)
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),

            // Coin animatsiyasi
            AnimatedBuilder(
              animation: _coinAnimationController,
              builder: (context, child) {
                return Positioned(
                  top: size.height * 0.3,
                  left: size.width * 0.5 - 50,
                  child: SlideTransition(
                    position: _coinSlideAnimation,
                    child: ScaleTransition(
                      scale: _coinScaleAnimation,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.shade400,
                              Colors.orange.shade600,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.monetization_on,
                                color: Colors.white,
                                size: 32,
                              ),
                              Text(
                                '+1',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartScreen(AppLocalizations l) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background,
            AppColors.primary.withOpacity(0.1),
            AppColors.background,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Daraja nomi
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _getDifficultyName(l),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.matchLabel(_currentMatch),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // START tugmasi
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                setState(() {
                  _isWaitingToStart = false;
                });
                _startGame();
              },
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, AppColors.accent],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 64,
                            ),
                            Text(
                              l.startGame,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),

            // Qisqacha ma'lumot
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  _buildStartInfoRow(
                    Icons.timer,
                    l.timeLabel,
                    '${_getDifficultyDuration()}s',
                  ),
                  const SizedBox(height: 8),
                  _buildStartInfoRow(
                    Icons.gps_fixed,
                    l.targetsLabel,
                    _getDifficultyTargetSize() <= 40 ? l.targetSmall : l.targetLarge,
                  ),
                  const SizedBox(height: 8),
                  _buildStartInfoRow(
                    Icons.monetization_on,
                    l.rewardLabel,
                    l.rewardCoins(1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartInfoRow(IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTarget(TargetInfo target) {
    // Rangli nishonlar uchun ranglar ro'yxati
    final colors = [
      [Colors.red.shade400, Colors.red.shade600],
      [Colors.blue.shade400, Colors.blue.shade600],
      [Colors.green.shade400, Colors.green.shade600],
      [Colors.purple.shade400, Colors.purple.shade600],
      [Colors.orange.shade400, Colors.orange.shade600],
      [Colors.teal.shade400, Colors.teal.shade600],
    ];

    final colorIndex = target.id % colors.length;
    final targetColors = colors[colorIndex];

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Positioned(
          left: target.position.dx,
          top: target.position.dy,
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: GestureDetector(
              onTap: () => _onTargetHit(target.id),
              child: Container(
                width: target.size,
                height: target.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [targetColors[0], targetColors[1]],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: targetColors[1].withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${target.id + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPipe(Offset pipe) {
    final screenHeight = MediaQuery.of(context).size.height;
    const pipeWidth = 80.0;
    const pipeGap = 180.0;

    return Stack(
      children: [
        // Yuqori pipe
        Positioned(
          left: pipe.dx,
          top: 120,
          child: Container(
            width: pipeWidth,
            height: pipe.dy - 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade500, Colors.green.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              border: Border.all(color: Colors.green.shade800, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
          ),
        ),
        // Pastki pipe
        Positioned(
          left: pipe.dx,
          top: pipe.dy + pipeGap,
          child: Container(
            width: pipeWidth,
            height: screenHeight - pipe.dy - pipeGap - 150,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade500, Colors.green.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border.all(color: Colors.green.shade800, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// TargetInfo class
class TargetInfo {
  final int id;
  final Offset position;
  final DateTime spawnTime;
  final double size;

  TargetInfo({
    required this.id,
    required this.position,
    required this.spawnTime,
    required this.size,
  });
}
