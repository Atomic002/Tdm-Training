import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../utils/app_colors.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MiniPubgGameScreen extends StatefulWidget {
  final VoidCallback onUpdate;

  const MiniPubgGameScreen({super.key, required this.onUpdate});

  @override
  State<MiniPubgGameScreen> createState() => _MiniPubgGameScreenState();
}

class _MiniPubgGameScreenState extends State<MiniPubgGameScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // Game state
  GameLevel _currentLevel = GameLevel.easy;
  GameState _gameState = GameState.menu;
  int _score = 0;
  int _lives = 3;
  int _enemiesKilled = 0;
  int _waveNumber = 1;

  // Player
  Offset _playerPosition = const Offset(0.5, 0.8);

  // Enemies
  final List<Enemy> _enemies = [];
  final List<Bullet> _bullets = [];
  Timer? _gameLoop;
  Timer? _spawnTimer;
  final Random _random = Random();

  // Difficulty settings
  Map<String, dynamic> get _difficulty {
    switch (_currentLevel) {
      case GameLevel.easy:
        return {
          'enemySpeed': 0.002,
          'spawnInterval': 2000,
          'enemiesPerWave': 3,
          'coinsReward': 5,
          'name': 'Oson',
        };
      case GameLevel.medium:
        return {
          'enemySpeed': 0.004,
          'spawnInterval': 1500,
          'enemiesPerWave': 5,
          'coinsReward': 10,
          'name': 'O\'rtacha',
        };
      case GameLevel.hard:
        return {
          'enemySpeed': 0.006,
          'spawnInterval': 1000,
          'enemiesPerWave': 7,
          'coinsReward': 20,
          'name': 'Qiyin',
        };
    }
  }

  @override
  void dispose() {
    _gameLoop?.cancel();
    _spawnTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _gameState = GameState.playing;
      _score = 0;
      _lives = 3;
      _enemiesKilled = 0;
      _waveNumber = 1;
      _playerPosition = const Offset(0.5, 0.8);
      _enemies.clear();
      _bullets.clear();
    });

    // Game loop (60 FPS)
    _gameLoop = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_gameState == GameState.playing) {
        _updateGame();
      }
    });

    // Enemy spawn timer
    _spawnEnemies();
  }

  void _spawnEnemies() {
    _spawnTimer?.cancel();
    _spawnTimer = Timer.periodic(
      Duration(milliseconds: _difficulty['spawnInterval'] as int),
      (timer) {
        if (_gameState == GameState.playing && _enemies.length < 10) {
          for (int i = 0; i < _difficulty['enemiesPerWave']; i++) {
            _enemies.add(Enemy(
              position: Offset(_random.nextDouble(), -0.1),
              speed: _difficulty['enemySpeed'] as double,
            ));
          }
        }
      },
    );
  }

  void _updateGame() {
    if (!mounted) return;

    setState(() {
      // Move enemies
      for (var enemy in _enemies) {
        enemy.position = Offset(
          enemy.position.dx,
          enemy.position.dy + enemy.speed,
        );
      }

      // Move bullets
      for (var bullet in _bullets) {
        bullet.position = Offset(
          bullet.position.dx,
          bullet.position.dy - 0.01,
        );
      }

      // Check collisions
      _checkCollisions();

      // Remove off-screen objects
      _enemies.removeWhere((e) => e.position.dy > 1.1);
      _bullets.removeWhere((b) => b.position.dy < -0.1);

      // Check if enemies reached player
      for (var enemy in _enemies.toList()) {
        if (enemy.position.dy > 0.9) {
          _lives--;
          _enemies.remove(enemy);
          if (_lives <= 0) {
            _gameOver();
          }
        }
      }

      // Update score
      if (_enemiesKilled > 0 && _enemiesKilled % 10 == 0) {
        _waveNumber = (_enemiesKilled ~/ 10) + 1;
      }
    });
  }

  void _checkCollisions() {
    for (var bullet in _bullets.toList()) {
      for (var enemy in _enemies.toList()) {
        final distance = (bullet.position - enemy.position).distance;
        if (distance < 0.05) {
          _bullets.remove(bullet);
          _enemies.remove(enemy);
          _enemiesKilled++;
          _score += 10;
          break;
        }
      }
    }
  }

  void _shoot() {
    if (_gameState == GameState.playing) {
      setState(() {
        _bullets.add(Bullet(
          position: Offset(_playerPosition.dx, _playerPosition.dy - 0.05),
        ));
      });
    }
  }

  void _gameOver() {
    _gameLoop?.cancel();
    _spawnTimer?.cancel();

    setState(() {
      _gameState = GameState.gameOver;
    });

    _saveScore();
  }

  Future<void> _saveScore() async {
    if (_uid == null) return;

    try {
      final coins = (_score / 10).floor(); // 10 xp = 1 coin
      final maxCoins = _difficulty['coinsReward'] as int;
      final finalCoins = coins > maxCoins ? maxCoins : coins;

      if (finalCoins > 0) {
        await _firestoreService.addCoinsForGame(_uid!, finalCoins.toDouble());
        widget.onUpdate();
      }
    } catch (e) {
      print('Coin saqlashda xato: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _gameState == GameState.menu
            ? _buildMenu()
            : _gameState == GameState.playing
                ? _buildGame()
                : _buildGameOver(),
      ),
    );
  }

  Widget _buildMenu() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background,
            AppColors.primary.withOpacity(0.3),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title
            const Icon(Icons.military_tech, size: 80, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Mini PUBG Mobile',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dushmanlarni yo\'q qiling va coin yig\'ing!',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 48),

            // Level selection
            const Text(
              'Daraja tanlang:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            _buildLevelButton(GameLevel.easy, Icons.star_border, Colors.green),
            const SizedBox(height: 16),
            _buildLevelButton(GameLevel.medium, Icons.star_half, Colors.orange),
            const SizedBox(height: 16),
            _buildLevelButton(GameLevel.hard, Icons.star, Colors.red),

            const SizedBox(height: 48),

            // Back button
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
              label: const Text(
                'Orqaga',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelButton(GameLevel level, IconData icon, Color color) {
    final Map<String, dynamic> difficulty = level == GameLevel.easy
        ? {
            'enemySpeed': 0.002,
            'spawnInterval': 2000,
            'enemiesPerWave': 3,
            'coinsReward': 5,
            'name': 'Oson',
          }
        : level == GameLevel.medium
            ? {
                'enemySpeed': 0.004,
                'spawnInterval': 1500,
                'enemiesPerWave': 5,
                'coinsReward': 10,
                'name': 'O\'rtacha',
              }
            : {
                'enemySpeed': 0.006,
                'spawnInterval': 1000,
                'enemiesPerWave': 7,
                'coinsReward': 20,
                'name': 'Qiyin',
              };

    return Container(
      width: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() => _currentLevel = level);
            _startGame();
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, size: 40, color: color),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        difficulty['name'] as String,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        'Max: ${difficulty['coinsReward']} coin',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.play_arrow, size: 32, color: color),
              ],
            ),
          ),
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
                Colors.blue.shade900,
                Colors.green.shade900,
              ],
            ),
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
              _buildHUDItem(Icons.star, '$_score', Colors.amber),
              _buildHUDItem(Icons.favorite, '$_lives', Colors.red),
              _buildHUDItem(Icons.waves, 'Wave $_waveNumber', AppColors.primary),
            ],
          ),
        ),

        // Game area
        GestureDetector(
          onPanUpdate: (details) {
            if (_gameState == GameState.playing) {
              setState(() {
                final renderBox = context.findRenderObject() as RenderBox;
                final localPosition = renderBox.globalToLocal(details.globalPosition);
                final size = renderBox.size;
                _playerPosition = Offset(
                  (localPosition.dx / size.width).clamp(0.05, 0.95),
                  (localPosition.dy / size.height).clamp(0.7, 0.9),
                );
              });
            }
          },
          onTap: _shoot,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // Player
                  Positioned(
                    left: _playerPosition.dx * constraints.maxWidth - 20,
                    top: _playerPosition.dy * constraints.maxHeight - 20,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                        ),
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 24),
                    ),
                  ),

                  // Enemies
                  ..._enemies.map((enemy) => Positioned(
                        left: enemy.position.dx * constraints.maxWidth - 15,
                        top: enemy.position.dy * constraints.maxHeight - 15,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Colors.red, Colors.orange],
                            ),
                          ),
                          child: const Icon(Icons.person, color: Colors.white, size: 18),
                        ),
                      )),

                  // Bullets
                  ..._bullets.map((bullet) => Positioned(
                        left: bullet.position.dx * constraints.maxWidth - 3,
                        top: bullet.position.dy * constraints.maxHeight - 6,
                        child: Container(
                          width: 6,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.yellow,
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.yellow.withOpacity(0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
              );
            },
          ),
        ),

        // Controls hint
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Ekranni bosib o\'qni boshqaring va otish uchun bosing',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHUDItem(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOver() {
    final coins = (_score / 10).floor();
    final maxCoins = _difficulty['coinsReward'] as int;
    final finalCoins = coins > maxCoins ? maxCoins : coins;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background,
            Colors.red.withOpacity(0.3),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.celebration, size: 80, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'O\'yin Tugadi!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 32),

            _buildStatCard('Xp', '$_score', Icons.star, Colors.amber),
            const SizedBox(height: 12),
            _buildStatCard('Dushmanlar', '$_enemiesKilled', Icons.person, Colors.red),
            const SizedBox(height: 12),
            _buildStatCard('To\'lqinlar', '$_waveNumber', Icons.waves, AppColors.primary),
            const SizedBox(height: 12),
            _buildStatCard(
              'Coin olindi',
              '$finalCoins',
              Icons.monetization_on,
              Colors.green,
            ),

            const SizedBox(height: 48),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => setState(() => _gameState = GameState.menu),
                  icon: const Icon(Icons.home),
                  label: const Text('Menyu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _startGame,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Yana o\'ynash'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

enum GameLevel { easy, medium, hard }

enum GameState { menu, playing, gameOver }

class Enemy {
  Offset position;
  final double speed;

  Enemy({required this.position, required this.speed});
}

class Bullet {
  Offset position;

  Bullet({required this.position});
}
