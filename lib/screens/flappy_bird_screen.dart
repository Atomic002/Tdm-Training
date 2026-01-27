import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'package:flutter_application_1/services/admob_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:math';
import '../utils/app_colors.dart';

class FlappyBirdScreen extends StatefulWidget {
  const FlappyBirdScreen({super.key});

  @override
  State<FlappyBirdScreen> createState() => _FlappyBirdScreenState();
}

class _FlappyBirdScreenState extends State<FlappyBirdScreen>
    with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // O'yin holati
  bool _gameStarted = false;
  bool _gameOver = false;
  bool _canPlayGame = true;
  bool _isShowingAd = false;

  // Qush parametrlari
  double _birdY = 0;
  double _birdVelocity = 0;
  final double _gravity = 0.8;
  final double _jumpStrength = -12;

  // Quvur parametrlari
  final List<Map<String, double>> _pipes = [];
  final double _pipeWidth = 80;
  final double _pipeGap = 200;
  double _pipeSpeed = 2;

  // O'yin ma'lumotlari
  int _score = 0;
  int _bestScore = 0;

  // Animatsiya
  late AnimationController _birdAnimationController;
  late Animation<double> _birdAnimation;
  late AnimationController _coinAnimationController;
  late Animation<double> _coinScaleAnimation;
  late Animation<Offset> _coinSlideAnimation;

  Timer? _gameTimer;

  @override
  void initState() {
    super.initState();
    _initializeAdMob();
    _initializeAnimations();
    _checkGamePermission();
    _loadBestScore();
  }

  Future<void> _initializeAdMob() async {
    try {
      await AdMobService.initialize();
      AdMobService.loadInterstitialAd();
    } catch (e) {
      print('AdMob initialization failed: $e');
    }
  }

  void _initializeAnimations() {
    _birdAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _birdAnimation = Tween<double>(begin: 0, end: 0.3).animate(
      CurvedAnimation(parent: _birdAnimationController, curve: Curves.easeOut),
    );

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
  }

  void _loadBestScore() async {
    // SharedPreferences dan eng yaxshi natijani yuklash
    // Bu yerda ScoreService ishlatilishi mumkin
  }

  Future<void> _checkGamePermission() async {
    final canPlay = _uid != null ? await _firestoreService.canPlayGame(_uid!) : false;
    setState(() {
      _canPlayGame = canPlay;
    });

    if (!canPlay) {
      _showGameLimitDialog();
    }
  }

  void _showGameLimitDialog() {
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
            const Text(
              'Kunlik Limit',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        content: const Text(
          'Bugun maksimal o\'yin soniga yetdingiz!\nErtaga qayta urinib ko\'ring!',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _startGame() {
    if (!_canPlayGame) return;

    setState(() {
      _gameStarted = true;
      _gameOver = false;
      _birdY = 0;
      _birdVelocity = 0;
      _pipes.clear();
      _score = 0;
      _pipeSpeed = 2;
    });

    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _updateGame();
    });

    // Birinchi quvurni qo'shish
    Future.delayed(const Duration(seconds: 2), () {
      _addPipe();
    });
  }

  void _updateGame() {
    if (!_gameStarted || _gameOver) return;

    setState(() {
      // Qushni yangilash
      _birdVelocity += _gravity;
      _birdY += _birdVelocity;

      // Quvurlarni yangilash
      for (int i = 0; i < _pipes.length; i++) {
        _pipes[i]['x'] = _pipes[i]['x']! - _pipeSpeed;

        // Ball qo'shish
        if (_pipes[i]['x']! < -50 && !_pipes[i].containsKey('scored')) {
          _score++;
          _pipes[i]['scored'] = 1;

          // Qiyinlikni oshirish
          if (_score % 5 == 0) {
            _pipeSpeed += 0.5;
          }
        }
      }

      // Ekrandan chiqib ketgan quvurlarni o'chirish
      _pipes.removeWhere((pipe) => pipe['x']! < -_pipeWidth);

      // Yangi quvur qo'shish
      if (_pipes.isEmpty ||
          _pipes.last['x']! < MediaQuery.of(context).size.width - 300) {
        _addPipe();
      }

      // Collision detection
      _checkCollisions();
    });
  }

  void _addPipe() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final random = Random();

    final pipeHeight =
        random.nextDouble() * (screenHeight * 0.4) + (screenHeight * 0.1);

    _pipes.add({
      'x': screenWidth.toDouble(),
      'topHeight': pipeHeight,
      'bottomY': pipeHeight + _pipeGap,
    });
  }

  void _checkCollisions() {
    final screenHeight = MediaQuery.of(context).size.height;
    final birdSize = 40.0;
    final birdCenterY = screenHeight / 2 + _birdY;

    // Yer va osmon bilan to'qnashuv
    if (birdCenterY <= 0 || birdCenterY >= screenHeight - 100) {
      _endGame();
      return;
    }

    // Quvurlar bilan to'qnashuv
    for (final pipe in _pipes) {
      final pipeX = pipe['x']!;
      final topHeight = pipe['topHeight']!;
      final bottomY = pipe['bottomY']!;

      // Qush quvur oralig'ida ekanligini tekshirish
      if (pipeX < 100 + birdSize && pipeX + _pipeWidth > 100) {
        if (birdCenterY < topHeight || birdCenterY + birdSize > bottomY) {
          _endGame();
          return;
        }
      }
    }
  }

  void _jump() {
    if (!_gameStarted) {
      _startGame();
      return;
    }

    if (_gameOver) return;

    setState(() {
      _birdVelocity = _jumpStrength;
    });

    HapticFeedback.lightImpact();
    _birdAnimationController.forward().then((_) {
      _birdAnimationController.reverse();
    });
  }

  void _endGame() {
    setState(() {
      _gameOver = true;
    });

    _gameTimer?.cancel();

    // Eng yaxshi natijani yangilash
    if (_score > _bestScore) {
      _bestScore = _score;
      // Bu yerda SharedPreferences ga saqlash kerak
    }

    // Coin berish
    if (_uid != null) _firestoreService.addCoins(_uid!, 1);
    _coinAnimationController.forward();

    // Reklama ko'rsatish
    _showAdAndGameOverDialog();
  }

  Future<void> _showAdAndGameOverDialog() async {
    await _showInterstitialAd();
    if (mounted) {
      _showGameOverDialog();
    }
  }

  Future<void> _showInterstitialAd() async {
    if (_isShowingAd) return;

    setState(() {
      _isShowingAd = true;
    });

    try {
      if (AdMobService.isInterstitialAdReady) {
        await AdMobService.showInterstitialAd();
      }
    } catch (e) {
      print('Error showing ad: $e');
    } finally {
      AdMobService.loadInterstitialAd();
      if (mounted) {
        setState(() {
          _isShowingAd = false;
        });
      }
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.emoji_events, color: AppColors.accent, size: 28),
            const SizedBox(width: 12),
            const Text(
              'O\'yin Tugadi!',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Coin earned
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade400, Colors.orange.shade600],
                ),
                borderRadius: BorderRadius.circular(12),
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
                  const Text(
                    '+1 Coin oldingiez!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Score
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ball:',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        '$_score',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Eng yaxshi:',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        '$_bestScore',
                        style: const TextStyle(
                          color: AppColors.success,
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
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'Bosh sahifa',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final canPlay = _uid != null ? await _firestoreService.canPlayGame(_uid!) : false;
              if (canPlay) {
                _coinAnimationController.reset();
                _startGame();
              } else {
                _showGameLimitDialog();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text(
              'Qayta o\'ynash',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _birdAnimationController.dispose();
    _coinAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final birdSize = 40.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'FLAPPY BIRD',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
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
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: _jump,
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withOpacity(0.3),
                    AppColors.background,
                  ],
                ),
              ),
            ),

            // Pipes (quvurlar)
            ...(_pipes.map((pipe) => _buildPipe(pipe, size))),

            // Bird (qush)
            if (_canPlayGame)
              AnimatedBuilder(
                animation: _birdAnimation,
                builder: (context, child) {
                  return Positioned(
                    left: 100,
                    top: size.height / 2 + _birdY - birdSize / 2,
                    child: Transform.rotate(
                      angle: _birdVelocity * 0.1 + _birdAnimation.value,
                      child: Container(
                        width: birdSize,
                        height: birdSize,
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
                        child: const Center(
                          child: Icon(
                            Icons.flight,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

            // Score
            if (_gameStarted)
              Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '$_score',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Start instruction
            if (!_gameStarted && !_gameOver && _canPlayGame)
              Positioned(
                top: size.height / 2 + 100,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.touch_app,
                            color: AppColors.primary,
                            size: 32,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Qushni uchirish uchun\nekranga bosing!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Eng yaxshi natija: $_bestScore',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Coin animation
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

            // Ad loading indicator
            if (_isShowingAd)
              Positioned(
                bottom: 120,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.info,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Reklama...',
                        style: TextStyle(color: AppColors.info, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPipe(Map<String, double> pipe, Size size) {
    final pipeX = pipe['x']!;
    final topHeight = pipe['topHeight']!;
    final bottomY = pipe['bottomY']!;

    return Stack(
      children: [
        // Top pipe
        Positioned(
          left: pipeX,
          top: 0,
          child: Container(
            width: _pipeWidth,
            height: topHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.success, AppColors.success.withOpacity(0.7)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
          ),
        ),
        // Bottom pipe
        Positioned(
          left: pipeX,
          top: bottomY,
          child: Container(
            width: _pipeWidth,
            height: size.height - bottomY,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.success, AppColors.success.withOpacity(0.7)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
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
