import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import '../utils/app_colors.dart';
import '../services/firestore_service.dart';
import '../services/admob_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MiniPubgGameScreen extends StatefulWidget {
  final VoidCallback onUpdate;

  const MiniPubgGameScreen({super.key, required this.onUpdate});

  @override
  State<MiniPubgGameScreen> createState() => _MiniPubgGameScreenState();
}

class _MiniPubgGameScreenState extends State<MiniPubgGameScreen>
    with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // Game state
  GameLevel _currentLevel = GameLevel.easy;
  GameState _gameState = GameState.menu;
  int _score = 0;
  int _lives = 3;
  int _maxLives = 3;
  int _enemiesKilled = 0;
  int _waveNumber = 1;
  int _gamesPlayedToday = 0;
  bool _isLoadingGames = true;
  int _combo = 0;
  double _comboTimer = 0;
  int _maxCombo = 0;

  // Player
  Offset _playerPosition = const Offset(0.5, 0.85);
  double _playerSize = 0.08;

  // Game objects
  final List<Enemy> _enemies = [];
  final List<Bullet> _bullets = [];
  final List<Explosion> _explosions = [];
  final List<PowerUp> _powerUps = [];
  final List<DamageText> _damageTexts = [];
  Timer? _gameLoop;
  Timer? _spawnTimer;
  Timer? _powerUpTimer;
  final Random _random = Random();

  // Power-up effects
  bool _hasShield = false;
  bool _hasRapidFire = false;
  bool _hasDoublePoints = false;
  double _shieldTimer = 0;
  double _rapidFireTimer = 0;
  double _doublePointsTimer = 0;

  // Screen shake
  Offset _screenShake = Offset.zero;
  double _shakeIntensity = 0;

  // Auto-fire
  bool _autoFire = false;
  Timer? _autoFireTimer;
  int _bulletsFired = 0;

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Difficulty settings
  Map<String, dynamic> get _difficulty {
    switch (_currentLevel) {
      case GameLevel.easy:
        return {
          'enemySpeed': 0.0015,
          'spawnInterval': 2500,
          'enemiesPerWave': 2,
          'name': 'Oson',
          'color': Colors.green,
        };
      case GameLevel.medium:
        return {
          'enemySpeed': 0.0025,
          'spawnInterval': 1800,
          'enemiesPerWave': 3,
          'name': 'O\'rtacha',
          'color': Colors.orange,
        };
      case GameLevel.hard:
        return {
          'enemySpeed': 0.004,
          'spawnInterval': 1200,
          'enemiesPerWave': 4,
          'name': 'Qiyin',
          'color': Colors.red,
        };
    }
  }

  static const int maxDailyGames = 20;
  static const int maxCoinsPerGame = 5;

  @override
  void initState() {
    super.initState();
    _loadDailyGames();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _gameLoop?.cancel();
    _spawnTimer?.cancel();
    _powerUpTimer?.cancel();
    _autoFireTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadDailyGames() async {
    if (_uid == null) return;
    setState(() => _isLoadingGames = true);
    try {
      final status = await _firestoreService.getDailyStatus(_uid!, isMiniPubg: true);
      final gamesPlayed = status['gamesPlayed'] ?? 0;
      if (mounted) {
        setState(() {
          _gamesPlayedToday = gamesPlayed;
          _isLoadingGames = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingGames = false);
    }
  }

  void _startGame() {
    if (_gamesPlayedToday >= maxDailyGames) {
      _showLimitReachedDialog();
      return;
    }

    HapticFeedback.mediumImpact();

    setState(() {
      _gameState = GameState.playing;
      _score = 0;
      _lives = 3;
      _maxLives = 3;
      _enemiesKilled = 0;
      _waveNumber = 1;
      _combo = 0;
      _maxCombo = 0;
      _comboTimer = 0;
      _bulletsFired = 0;
      _playerPosition = const Offset(0.5, 0.85);
      _enemies.clear();
      _bullets.clear();
      _explosions.clear();
      _powerUps.clear();
      _damageTexts.clear();
      _hasShield = false;
      _hasRapidFire = false;
      _hasDoublePoints = false;
      _shieldTimer = 0;
      _rapidFireTimer = 0;
      _doublePointsTimer = 0;
      _screenShake = Offset.zero;
      _shakeIntensity = 0;
      _autoFire = false;
    });

    // Game loop (60 FPS)
    _gameLoop = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_gameState == GameState.playing) {
        _updateGame();
      }
    });

    _spawnEnemies();
    _spawnPowerUps();

    if (_autoFire) {
      _startAutoFire();
    }
  }

  void _spawnEnemies() {
    _spawnTimer?.cancel();
    _spawnTimer = Timer.periodic(
      Duration(milliseconds: _difficulty['spawnInterval'] as int),
      (timer) {
        if (_gameState == GameState.playing && _enemies.length < 12) {
          final count = _difficulty['enemiesPerWave'] as int;
          for (int i = 0; i < count; i++) {
            final type = _random.nextInt(3);
            _enemies.add(Enemy(
              position: Offset(_random.nextDouble() * 0.8 + 0.1, -0.1),
              speed: (_difficulty['enemySpeed'] as double) *
                  (0.8 + _random.nextDouble() * 0.4),
              type: EnemyType.values[type],
              health: type == 2 ? 2 : 1,
            ));
          }
          _waveNumber = (_enemiesKilled ~/ 10) + 1;
        }
      },
    );
  }

  void _spawnPowerUps() {
    _powerUpTimer?.cancel();
    _powerUpTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (_gameState == GameState.playing && _powerUps.length < 2) {
        final type = PowerUpType.values[_random.nextInt(PowerUpType.values.length)];
        _powerUps.add(PowerUp(
          position: Offset(_random.nextDouble() * 0.8 + 0.1, -0.1),
          type: type,
        ));
      }
    });
  }

  void _startAutoFire() {
    _autoFireTimer?.cancel();
    final interval = _hasRapidFire ? 100 : 200;
    _autoFireTimer = Timer.periodic(Duration(milliseconds: interval), (timer) {
      if (_gameState == GameState.playing && _autoFire) {
        _shoot();
      }
    });
  }

  void _updateGame() {
    if (!mounted) return;

    setState(() {
      final dt = 0.016; // 16ms = 60fps

      // Update combo timer
      if (_combo > 0) {
        _comboTimer -= dt;
        if (_comboTimer <= 0) {
          _combo = 0;
        }
      }

      // Update power-up timers
      if (_hasShield) {
        _shieldTimer -= dt;
        if (_shieldTimer <= 0) _hasShield = false;
      }
      if (_hasRapidFire) {
        _rapidFireTimer -= dt;
        if (_rapidFireTimer <= 0) {
          _hasRapidFire = false;
          if (_autoFire) _startAutoFire();
        }
      }
      if (_hasDoublePoints) {
        _doublePointsTimer -= dt;
        if (_doublePointsTimer <= 0) _hasDoublePoints = false;
      }

      // Update screen shake
      if (_shakeIntensity > 0) {
        _screenShake = Offset(
          (_random.nextDouble() - 0.5) * _shakeIntensity,
          (_random.nextDouble() - 0.5) * _shakeIntensity,
        );
        _shakeIntensity *= 0.9;
        if (_shakeIntensity < 0.001) {
          _shakeIntensity = 0;
          _screenShake = Offset.zero;
        }
      }

      // Move enemies with patterns
      for (var enemy in _enemies) {
        double dx = 0;
        switch (enemy.type) {
          case EnemyType.normal:
            dx = sin(enemy.position.dy * 10) * 0.002;
            break;
          case EnemyType.fast:
            dx = cos(enemy.position.dy * 15) * 0.003;
            break;
          case EnemyType.tank:
            dx = sin(enemy.position.dy * 5) * 0.001;
            break;
        }
        enemy.position = Offset(
          (enemy.position.dx + dx).clamp(0.05, 0.95),
          enemy.position.dy + enemy.speed,
        );
      }

      // Move bullets
      for (var bullet in _bullets) {
        bullet.position = Offset(
          bullet.position.dx,
          bullet.position.dy - 0.015,
        );
      }

      // Move power-ups
      for (var powerUp in _powerUps) {
        powerUp.position = Offset(
          powerUp.position.dx + sin(powerUp.position.dy * 10) * 0.002,
          powerUp.position.dy + 0.002,
        );
      }

      // Update explosions
      for (var explosion in _explosions) {
        explosion.progress += 0.05;
      }
      _explosions.removeWhere((e) => e.progress >= 1.0);

      // Update damage texts
      for (var text in _damageTexts) {
        text.position = Offset(text.position.dx, text.position.dy - 0.01);
        text.opacity -= 0.02;
      }
      _damageTexts.removeWhere((t) => t.opacity <= 0);

      // Check collisions
      _checkCollisions();
      _checkPowerUpCollisions();

      // Remove off-screen objects
      _enemies.removeWhere((e) => e.position.dy > 1.1);
      _bullets.removeWhere((b) => b.position.dy < -0.1);
      _powerUps.removeWhere((p) => p.position.dy > 1.1);

      // Check if enemies reached bottom
      for (var enemy in _enemies.toList()) {
        if (enemy.position.dy > 0.9) {
          if (!_hasShield) {
            _lives--;
            _shakeIntensity = 0.02;
            HapticFeedback.heavyImpact();
          }
          _enemies.remove(enemy);
          _createExplosion(enemy.position, Colors.red);
          if (_lives <= 0) {
            _gameOver();
          }
        }
      }
    });
  }

  void _checkCollisions() {
    for (var bullet in _bullets.toList()) {
      for (var enemy in _enemies.toList()) {
        final distance = (bullet.position - enemy.position).distance;
        if (distance < 0.05) {
          _bullets.remove(bullet);
          enemy.health--;

          if (enemy.health <= 0) {
            _enemies.remove(enemy);
            _enemiesKilled++;

            // Combo system
            _combo++;
            _comboTimer = 2.0;
            if (_combo > _maxCombo) _maxCombo = _combo;

            // Calculate points
            int points = 10;
            if (enemy.type == EnemyType.fast) points = 15;
            if (enemy.type == EnemyType.tank) points = 25;
            if (_hasDoublePoints) points *= 2;
            points += (_combo ~/ 3) * 5; // Combo bonus

            _score += points;

            // Visual feedback
            _createExplosion(enemy.position, _getEnemyColor(enemy.type));
            _damageTexts.add(DamageText(
              position: enemy.position,
              text: '+$points',
              color: _combo >= 5 ? Colors.yellow : Colors.white,
            ));

            HapticFeedback.lightImpact();
          } else {
            // Enemy damaged but not killed
            _damageTexts.add(DamageText(
              position: enemy.position,
              text: 'HIT',
              color: Colors.orange,
            ));
          }
          break;
        }
      }
    }
  }

  void _checkPowerUpCollisions() {
    for (var powerUp in _powerUps.toList()) {
      final distance = (powerUp.position - _playerPosition).distance;
      if (distance < 0.08) {
        _powerUps.remove(powerUp);
        _applyPowerUp(powerUp.type);
        HapticFeedback.mediumImpact();
      }
    }
  }

  void _applyPowerUp(PowerUpType type) {
    switch (type) {
      case PowerUpType.shield:
        _hasShield = true;
        _shieldTimer = 5.0;
        _damageTexts.add(DamageText(
          position: _playerPosition,
          text: 'SHIELD!',
          color: Colors.cyan,
        ));
        break;
      case PowerUpType.rapidFire:
        _hasRapidFire = true;
        _rapidFireTimer = 5.0;
        if (_autoFire) _startAutoFire();
        _damageTexts.add(DamageText(
          position: _playerPosition,
          text: 'RAPID FIRE!',
          color: Colors.orange,
        ));
        break;
      case PowerUpType.doublePoints:
        _hasDoublePoints = true;
        _doublePointsTimer = 8.0;
        _damageTexts.add(DamageText(
          position: _playerPosition,
          text: '2X POINTS!',
          color: Colors.green,
        ));
        break;
      case PowerUpType.extraLife:
        if (_lives < _maxLives) {
          _lives++;
          _damageTexts.add(DamageText(
            position: _playerPosition,
            text: '+1 LIFE!',
            color: Colors.red,
          ));
        } else {
          _score += 50;
          _damageTexts.add(DamageText(
            position: _playerPosition,
            text: '+50 XP!',
            color: Colors.amber,
          ));
        }
        break;
    }
  }

  void _createExplosion(Offset position, Color color) {
    _explosions.add(Explosion(position: position, color: color));
  }

  Color _getEnemyColor(EnemyType type) {
    switch (type) {
      case EnemyType.normal:
        return Colors.red;
      case EnemyType.fast:
        return Colors.purple;
      case EnemyType.tank:
        return Colors.grey;
    }
  }

  void _shoot() {
    if (_gameState == GameState.playing) {
      setState(() {
        _bullets.add(Bullet(
          position: Offset(_playerPosition.dx, _playerPosition.dy - 0.05),
        ));
        _bulletsFired++;
      });
      HapticFeedback.selectionClick();
    }
  }

  void _gameOver() {
    _gameLoop?.cancel();
    _spawnTimer?.cancel();
    _powerUpTimer?.cancel();
    _autoFireTimer?.cancel();

    HapticFeedback.heavyImpact();

    setState(() {
      _gameState = GameState.gameOver;
    });

    _saveScore();
  }

  /// O'yin boshlanishidan oldin majburiy reklama ko'rsatish
  /// Reklama ko'rsatilmasa o'yin boshlanmaydi
  Future<void> _showAdThenStartGame() async {
    if (_gamesPlayedToday >= maxDailyGames) {
      _showLimitReachedDialog();
      return;
    }

    // Loading dialog ko'rsatish
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              SizedBox(height: 16),
              Text(
                'O\'yin tayyorlanmoqda...',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
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
          setState(() => _gameState = GameState.readyToStart);
        }
      } else {
        // Reklama tayyor emas - yuklanishini kutish
        AdMobService.loadInterstitialAd();
        await Future.delayed(const Duration(seconds: 3));

        if (!mounted) return;

        if (AdMobService.isInterstitialAdReady) {
          await AdMobService.showInterstitialAd();
          if (mounted) {
            Navigator.pop(context);
            setState(() => _gameState = GameState.readyToStart);
          }
        } else {
          // Reklama yuklanmadi
          Navigator.pop(context);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Reklama yuklanmadi. Qayta urinib ko\'ring.'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Reklama ko\'rsatishda xatolik: $e');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reklama yuklanmadi. Qayta urinib ko\'ring.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _saveScore() async {
    if (_uid == null) return;

    try {
      final int coins = _calculateCoins();

      // addCoinsForGameDirect - to'g'ridan-to'g'ri coin qo'shadi
      final success = await _firestoreService.addCoinsForGameDirect(_uid!, coins, isMiniPubg: true);
      if (success) {
        widget.onUpdate();
      }

      if (mounted) {
        setState(() {
          _gamesPlayedToday++;
        });
      }
    } catch (e) {
      debugPrint('Coin saqlashda xato: $e');
    }
  }

  int _calculateCoins() {
    // 10 ta dushman o'ldirmasa = 0 coin, 10+ = 1 coin
    if (_enemiesKilled >= 10) {
      return 1;
    }
    return 0;
  }

  void _showLimitReachedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.timer_off, color: Colors.orange, size: 28),
            ),
            const SizedBox(width: 12),
            const Text(
              'Kunlik limit',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Text(
          'Siz bugun $maxDailyGames ta o\'yin o\'ynadingiz.\nErtaga qayta urinib ko\'ring!',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _gameState == GameState.menu
            ? _buildMenu()
            : _gameState == GameState.readyToStart
                ? _buildReadyToStart()
                : _gameState == GameState.playing
                    ? _buildGame()
                    : _buildGameOver(),
      ),
    );
  }

  Widget _buildReadyToStart() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background,
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.background,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Daraja ko'rsatgich
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (_difficulty['color'] as Color).withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sports_esports,
                    color: _difficulty['color'] as Color,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _difficulty['name'] as String,
                    style: TextStyle(
                      color: _difficulty['color'] as Color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),

            // START tugmasi
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
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
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary,
                            AppColors.accent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 64,
                            ),
                            Text(
                              'START',
                              style: TextStyle(
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
            const SizedBox(height: 50),

            // Qisqa ma'lumot
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.favorite, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Jonlar:',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        '3',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Mukofot:',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        '10+ kill = 1 Coin',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.gamepad, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Qolgan:',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${maxDailyGames - _gamesPlayedToday} o\'yin',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu() {
    final remainingGames = maxDailyGames - _gamesPlayedToday;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.background,
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.background,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            // Header
            const SizedBox(height: 20),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.accent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.sports_esports,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
              ).createShader(bounds),
              child: const Text(
                'MINI PUBG',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dushmanlarni yo\'q qiling!',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 30),

            // Stats Card
            if (_isLoadingGames)
              const CircularProgressIndicator(color: AppColors.primary)
            else
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.surface,
                      AppColors.surface.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: remainingGames > 0
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : Colors.red.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          Icons.gamepad,
                          'O\'yinlar',
                          '$_gamesPlayedToday/$maxDailyGames',
                          remainingGames > 0 ? Colors.green : Colors.red,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.textSecondary.withValues(alpha: 0.3),
                        ),
                        _buildStatItem(
                          Icons.monetization_on,
                          'Mukofot',
                          '1-$maxCoinsPerGame coin',
                          Colors.amber,
                        ),
                      ],
                    ),
                    if (remainingGames <= 3 && remainingGames > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '⚠️ Faqat $remainingGames ta o\'yin qoldi!',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 30),

            // Auto-fire toggle
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: _autoFire
                      ? AppColors.accent.withValues(alpha: 0.5)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.flash_auto,
                        color: _autoFire ? AppColors.accent : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Avto-otish',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: _autoFire,
                    onChanged: (value) => setState(() => _autoFire = value),
                    activeColor: AppColors.accent,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Level selection
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Text(
                    'DARAJA TANLANG',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLevelCard(
                    GameLevel.easy,
                    'OSON',
                    'Sekin dushmanlar',
                    Icons.sentiment_satisfied,
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildLevelCard(
                    GameLevel.medium,
                    'O\'RTACHA',
                    'Tezroq harakat',
                    Icons.sentiment_neutral,
                    Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _buildLevelCard(
                    GameLevel.hard,
                    'QIYIN',
                    'Juda tez dushmanlar',
                    Icons.sentiment_very_dissatisfied,
                    Colors.red,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Back button
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios, size: 18),
              label: const Text('Orqaga'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelCard(
    GameLevel level,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final isSelected = _currentLevel == level;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _currentLevel = level);
        _showAdThenStartGame();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              color.withValues(alpha: isSelected ? 0.3 : 0.1),
              color.withValues(alpha: isSelected ? 0.1 : 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: isSelected ? 0.8 : 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.play_circle_fill,
              color: color,
              size: 40,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGame() {
    return Stack(
      children: [
        // Background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF0a0a0a),
                AppColors.background,
                const Color(0xFF1a0a0a),
              ],
            ),
          ),
        ),

        // Grid pattern
        CustomPaint(
          painter: GridPainter(),
          size: Size.infinite,
        ),

        // Game area with shake effect
        Transform.translate(
          offset: _screenShake * MediaQuery.of(context).size.width,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    final dx = details.delta.dx / constraints.maxWidth;
                    _playerPosition = Offset(
                      (_playerPosition.dx + dx).clamp(0.05, 0.95),
                      _playerPosition.dy,
                    );
                  });
                },
                onTapDown: (_) {
                  if (!_autoFire) _shoot();
                },
                child: Stack(
                  children: [
                    // Explosions (behind everything)
                    ..._explosions.map((explosion) => Positioned(
                          left: explosion.position.dx * constraints.maxWidth -
                              30 * explosion.progress,
                          top: explosion.position.dy * constraints.maxHeight -
                              30 * explosion.progress,
                          child: Opacity(
                            opacity: (1 - explosion.progress).clamp(0.0, 1.0),
                            child: Container(
                              width: 60 * explosion.progress,
                              height: 60 * explosion.progress,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    explosion.color,
                                    explosion.color.withValues(alpha: 0.5),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )),

                    // Power-ups
                    ..._powerUps.map((powerUp) => Positioned(
                          left: powerUp.position.dx * constraints.maxWidth - 18,
                          top: powerUp.position.dy * constraints.maxHeight - 18,
                          child: _buildPowerUpWidget(powerUp),
                        )),

                    // Enemies
                    ..._enemies.map((enemy) => Positioned(
                          left: enemy.position.dx * constraints.maxWidth - 20,
                          top: enemy.position.dy * constraints.maxHeight - 20,
                          child: _buildEnemyWidget(enemy),
                        )),

                    // Bullets
                    ..._bullets.map((bullet) => Positioned(
                          left: bullet.position.dx * constraints.maxWidth - 4,
                          top: bullet.position.dy * constraints.maxHeight - 10,
                          child: Container(
                            width: 8,
                            height: 20,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.yellow, Colors.orange],
                              ),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.yellow.withValues(alpha: 0.8),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        )),

                    // Player
                    Positioned(
                      left: _playerPosition.dx * constraints.maxWidth -
                          _playerSize * constraints.maxWidth / 2,
                      top: _playerPosition.dy * constraints.maxHeight -
                          _playerSize * constraints.maxWidth / 2,
                      child: _buildPlayerWidget(constraints),
                    ),

                    // Damage texts
                    ..._damageTexts.map((text) => Positioned(
                          left: text.position.dx * constraints.maxWidth - 30,
                          top: text.position.dy * constraints.maxHeight - 20,
                          child: Opacity(
                            opacity: text.opacity.clamp(0.0, 1.0),
                            child: Text(
                              text.text,
                              style: TextStyle(
                                color: text.color,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )),
                  ],
                ),
              );
            },
          ),
        ),

        // HUD
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Lives
              Row(
                children: List.generate(
                  _maxLives,
                  (index) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      index < _lives ? Icons.favorite : Icons.favorite_border,
                      color: index < _lives ? Colors.red : Colors.red.withValues(alpha: 0.3),
                      size: 28,
                    ),
                  ),
                ),
              ),
              // Score and combo
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildHUDItem(Icons.star, '$_score XP', Colors.amber),
                  if (_combo >= 3)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange, Colors.red],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '🔥 COMBO x$_combo',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Wave indicator
        Positioned(
          top: 60,
          left: 16,
          child: _buildHUDItem(Icons.waves, 'To\'lqin $_waveNumber', AppColors.primary),
        ),

        // Power-up indicators
        Positioned(
          top: 100,
          left: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_hasShield)
                _buildPowerUpIndicator('🛡️', _shieldTimer, Colors.cyan),
              if (_hasRapidFire)
                _buildPowerUpIndicator('⚡', _rapidFireTimer, Colors.orange),
              if (_hasDoublePoints)
                _buildPowerUpIndicator('2X', _doublePointsTimer, Colors.green),
            ],
          ),
        ),

        // Pause button
        Positioned(
          top: 16,
          right: 16,
          child: IconButton(
            onPressed: () => setState(() => _gameState = GameState.menu),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pause, color: Colors.white),
            ),
          ),
        ),

        // Controls hint
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _autoFire
                  ? '👆 Chapga-o\'ngga suring'
                  : '👆 Suring va bosing',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerWidget(BoxConstraints constraints) {
    final size = _playerSize * constraints.maxWidth;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Shield effect
        if (_hasShield)
          Container(
            width: size * 1.5,
            height: size * 1.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.cyan, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.withValues(alpha: 0.5),
                  blurRadius: 15,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
        // Player
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.accent],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.5),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 28,
          ),
        ),
      ],
    );
  }

  Widget _buildEnemyWidget(Enemy enemy) {
    Color color;
    IconData icon;
    double size;

    switch (enemy.type) {
      case EnemyType.normal:
        color = Colors.red;
        icon = Icons.android;
        size = 40;
        break;
      case EnemyType.fast:
        color = Colors.purple;
        icon = Icons.flash_on;
        size = 35;
        break;
      case EnemyType.tank:
        color = Colors.grey;
        icon = Icons.shield;
        size = 50;
        break;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow effect
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        // Enemy body
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color,
                color.withValues(alpha: 0.7),
              ],
            ),
            border: Border.all(color: Colors.white24, width: 2),
          ),
          child: Icon(icon, color: Colors.white, size: size * 0.5),
        ),
        // Health indicator for tanks
        if (enemy.type == EnemyType.tank && enemy.health > 1)
          Positioned(
            bottom: -5,
            child: Container(
              width: 20,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPowerUpWidget(PowerUp powerUp) {
    Color color;
    IconData icon;

    switch (powerUp.type) {
      case PowerUpType.shield:
        color = Colors.cyan;
        icon = Icons.shield;
        break;
      case PowerUpType.rapidFire:
        color = Colors.orange;
        icon = Icons.flash_on;
        break;
      case PowerUpType.doublePoints:
        color = Colors.green;
        icon = Icons.looks_two;
        break;
      case PowerUpType.extraLife:
        color = Colors.red;
        icon = Icons.favorite;
        break;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.7)],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.8),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildPowerUpIndicator(String emoji, double timer, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '${timer.toStringAsFixed(1)}s',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHUDItem(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOver() {
    final finalCoins = _calculateCoins();
    final accuracy = _bulletsFired > 0
        ? ((_enemiesKilled / _bulletsFired) * 100).toStringAsFixed(1)
        : '0';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background,
            Colors.red.withValues(alpha: 0.2),
            AppColors.background,
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Trophy icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.amber, Colors.orange],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'O\'YIN TUGADI!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 32),

              // Stats grid
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildResultStat(
                            'XP',
                            '$_score',
                            Icons.star,
                            Colors.amber,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 60,
                          color: AppColors.textSecondary.withValues(alpha: 0.2),
                        ),
                        Expanded(
                          child: _buildResultStat(
                            'Dushmanlar',
                            '$_enemiesKilled',
                            Icons.person_off,
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: _buildResultStat(
                            'Max Combo',
                            'x$_maxCombo',
                            Icons.local_fire_department,
                            Colors.orange,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 60,
                          color: AppColors.textSecondary.withValues(alpha: 0.2),
                        ),
                        Expanded(
                          child: _buildResultStat(
                            'Aniqlik',
                            '$accuracy%',
                            Icons.gps_fixed,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Coins earned
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withValues(alpha: 0.3),
                      Colors.green.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.green,
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'COIN OLINDI',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          '+$finalCoins',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          setState(() => _gameState = GameState.menu),
                      icon: const Icon(Icons.home),
                      label: const Text('MENYU'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.textSecondary),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _showAdThenStartGame,
                      icon: const Icon(Icons.refresh),
                      label: const Text('YANA O\'YNASH'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// Game classes
enum GameLevel { easy, medium, hard }

enum GameState { menu, readyToStart, playing, gameOver }

enum EnemyType { normal, fast, tank }

enum PowerUpType { shield, rapidFire, doublePoints, extraLife }

class Enemy {
  Offset position;
  final double speed;
  final EnemyType type;
  int health;

  Enemy({
    required this.position,
    required this.speed,
    required this.type,
    required this.health,
  });
}

class Bullet {
  Offset position;

  Bullet({required this.position});
}

class Explosion {
  final Offset position;
  final Color color;
  double progress = 0;

  Explosion({required this.position, required this.color});
}

class PowerUp {
  Offset position;
  final PowerUpType type;

  PowerUp({required this.position, required this.type});
}

class DamageText {
  Offset position;
  final String text;
  final Color color;
  double opacity = 1.0;

  DamageText({required this.position, required this.text, required this.color});
}

// Grid painter for background
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    const spacing = 40.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
