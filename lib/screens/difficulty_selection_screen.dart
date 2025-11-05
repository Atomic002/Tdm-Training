import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/screens/training_screen.dart';
import 'package:flutter_application_1/services/admob_service.dart';
import 'package:flutter_application_1/widgets/ad_banner.dart';
import '../utils/app_colors.dart';
import '../models/difficulty.dart';

class DifficultySelectionScreen extends StatefulWidget {
  const DifficultySelectionScreen({super.key});

  @override
  State<DifficultySelectionScreen> createState() =>
      _DifficultySelectionScreenState();
}

class _DifficultySelectionScreenState extends State<DifficultySelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideAnimations = List.generate(
      Difficulty.values.length,
      (index) => Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                index * 0.1,
                0.6 + (index * 0.1),
                curve: Curves.easeOutBack,
              ),
            ),
          ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qiyinlik Darajasi'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, Color(0xFF0F0F0F)],
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: const Column(
                children: [
                  Icon(Icons.military_tech, size: 60, color: AppColors.accent),
                  SizedBox(height: 16),
                  Text(
                    'Qiyinlik darajasini tanlang',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Har bir daraja o\'ziga xos qiyinchilikka ega',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Difficulty Cards
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: Difficulty.values.length,
                itemBuilder: (context, index) {
                  final difficulty = Difficulty.values[index];
                  return SlideTransition(
                    position: _slideAnimations[index],
                    child: _buildDifficultyCard(difficulty, index),
                  );
                },
              ),
            ),

            // Ad Banner
            AdBannerWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyCard(Difficulty difficulty, int index) {
    final colors = [
      [AppColors.success, AppColors.success.withOpacity(0.7)], // Easy
      [AppColors.info, AppColors.info.withOpacity(0.7)], // Medium
      [AppColors.warning, AppColors.warning.withOpacity(0.7)], // Hard
      [AppColors.danger, AppColors.danger.withOpacity(0.7)], // Expert
    ];

    final icons = [
      Icons.sentiment_satisfied_alt, // Easy
      Icons.sentiment_neutral, // Medium
      Icons.sentiment_dissatisfied, // Hard
      Icons.whatshot, // Expert
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors[index],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors[index][0].withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _selectDifficulty(difficulty),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icons[index], color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            difficulty.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            difficulty.description,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white.withOpacity(0.7),
                      size: 20,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Difficulty Stats
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildStatRow(
                        'Nishon vaqti:',
                        '${difficulty.targetTimeout}s',
                      ),
                      _buildStatRow(
                        'Nishon hajmi:',
                        '${difficulty.targetSize.toInt()}px',
                      ),
                      _buildStatRow(
                        'Ball ko\'paytiruvchi:',
                        '${difficulty.scoreMultiplier}x',
                      ),
                      if (difficulty.hasMovingTargets)
                        _buildStatRow('Harakat qiluvchi nishonlar:', 'Ha'),
                      if (difficulty.hasMultipleTargets)
                        _buildStatRow('Ko\'p nishonlar:', 'Ha'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _selectDifficulty(Difficulty difficulty) {
    HapticFeedback.mediumImpact();

    // Show selection animation
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

    // Show interstitial ad, then navigate
    Future.delayed(const Duration(milliseconds: 500), () {
      if (AdMobService.isInterstitialAdReady) {
        AdMobService.showInterstitialAd().then((_) {
          Navigator.pop(context); // Close loading dialog
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TrainingScreen(difficulty: difficulty),
            ),
          );
        });
      } else {
        // If ad not ready, just navigate after delay
        Future.delayed(const Duration(milliseconds: 1500), () {
          Navigator.pop(context); // Close loading dialog
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TrainingScreen(difficulty: difficulty),
            ),
          );
        });
      }
    });
  }
}
