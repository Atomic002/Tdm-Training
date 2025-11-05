import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/training_screen.dart';
import 'package:flutter_application_1/screens/flappy_bird_screen.dart';
import 'package:flutter_application_1/models/difficulty.dart';
import 'package:flutter_application_1/services/coin_service.dart';
import '../utils/app_colors.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  final CoinService _coinService = CoinService();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _slideController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.background,
              AppColors.accent.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: Colors.amber,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      FutureBuilder<int>(
                        future: _coinService.getCurrentCoins(),
                        builder: (context, snapshot) {
                          return Text(
                            '${snapshot.data ?? 0} Coin',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Title
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Column(
                        children: [
                          Text(
                            'REACTION',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              foreground: Paint()
                                ..shader =
                                    LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.accent,
                                      ],
                                    ).createShader(
                                      const Rect.fromLTWH(0, 0, 200, 70),
                                    ),
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(2, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'MASTER',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 60),

                // Game Buttons
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        // Training Mode
                        _buildGameModeCard(
                          'MASHQ REJIMI',
                          'Qiyinlik darajasini tanlab reaction vaqtingizni yaxshilang',
                          Icons.fitness_center,
                          AppColors.primary,
                          () => _showDifficultyDialog(),
                        ),

                        const SizedBox(height: 20),

                        // Flappy Bird Mode
                        _buildGameModeCard(
                          'FLAPPY BIRD',
                          'Klassik flappy bird o\'yinini o\'ynab coin yutib oling',
                          Icons.flight_takeoff,
                          AppColors.accent,
                          () => _navigateToFlappyBird(),
                        ),

                        const SizedBox(height: 20),

                        // Stats Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.info.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppColors.info,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FutureBuilder<Map<String, dynamic>?>(
                                  future: _coinService.getDailyStatus(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData &&
                                        snapshot.data != null) {
                                      final status = snapshot.data!;
                                      final remaining =
                                          status['maxGames'] -
                                          status['gamesPlayed'];
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Kunlik o\'yinlar',
                                            style: TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Yana $remaining o\'yin qoldi',
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                    return const Text(
                                      'Ma\'lumot yuklanmoqda...',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameModeCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
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
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color.withOpacity(0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showDifficultyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.tune, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            const Text(
              'Qiyinlik Darajasi',
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
            _buildDifficultyOption(
              'OSON',
              '3s, katta nishon, sekin',
              Icons.sentiment_satisfied,
              AppColors.success,
              Difficulty.easy,
            ),
            const SizedBox(height: 12),
            _buildDifficultyOption(
              'O\'RTACHA',
              '2s, o\'rtacha nishon, tez',
              Icons.sentiment_neutral,
              AppColors.warning,
              Difficulty.medium,
            ),
            const SizedBox(height: 12),
            _buildDifficultyOption(
              'QIYIN',
              '1s, kichik nishon, juda tez',
              Icons.sentiment_dissatisfied,
              AppColors.danger,
              Difficulty.hard,
            ),
            const SizedBox(height: 12),
            _buildDifficultyOption(
              'EKSPERT',
              '1s, eng kichik, chaqmoq tez',
              Icons.whatshot,
              AppColors.accent,
              Difficulty.expert,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(
    String name,
    String description,
    IconData icon,
    Color color,
    Difficulty difficulty,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrainingScreen(difficulty: difficulty),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.play_arrow, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  void _navigateToFlappyBird() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FlappyBirdScreen()),
    );
  }
}
