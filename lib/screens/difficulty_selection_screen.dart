import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/screens/training_screen.dart';
import 'package:flutter_application_1/widgets/ad_banner.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';
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

  String _getDifficultyName(AppLocalizations l, Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return l.diffEasy;
      case Difficulty.medium:
        return l.diffMedium;
      case Difficulty.hard:
        return l.diffHard;
      case Difficulty.expert:
        return l.diffExpert;
    }
  }

  String _getDifficultyDescription(AppLocalizations l, Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return l.diffEasyDesc;
      case Difficulty.medium:
        return l.diffMediumDesc;
      case Difficulty.hard:
        return l.diffHardDesc;
      case Difficulty.expert:
        return l.diffExpertDesc;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.difficultyTitle),
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
              child: Column(
                children: [
                  const Icon(Icons.military_tech, size: 60, color: AppColors.accent),
                  const SizedBox(height: 16),
                  Text(
                    l.selectDifficulty,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.difficultyInfo,
                    style: const TextStyle(
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
                    child: _buildDifficultyCard(l, difficulty, index),
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

  Widget _buildDifficultyCard(AppLocalizations l, Difficulty difficulty, int index) {
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
                            _getDifficultyName(l, difficulty),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getDifficultyDescription(l, difficulty),
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
                        l.targetTime,
                        '${difficulty.targetTimeout}s',
                      ),
                      _buildStatRow(
                        l.targetSize,
                        '${difficulty.targetSize.toInt()}px',
                      ),
                      _buildStatRow(
                        l.scoreMultiplier,
                        '${difficulty.scoreMultiplier}x',
                      ),
                      if (difficulty.hasMovingTargets)
                        _buildStatRow(l.movingTargets, l.yes),
                      if (difficulty.hasMultipleTargets)
                        _buildStatRow(l.multipleTargets, l.yes),
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

    // HomeScreen dan interstitial allaqachon ko'rsatilgan
    // Shuning uchun bu yerda to'g'ridan-to'g'ri o'yinga o'tish
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingScreen(difficulty: difficulty),
      ),
    );
  }
}
