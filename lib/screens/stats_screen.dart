import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/ad_banner.dart';
import '../utils/app_colors.dart';
import '../models/difficulty.dart';
import '../services/score_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  final ScoreService _scoreService = ScoreService();
  late TabController _tabController;
  bool _isLoading = true;

  Map<String, dynamic> _stats = {};
  List<GameScore> _topScores = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final stats = await _scoreService.getStatistics();
      final topScores = await _scoreService.getTopScores(limit: 20);

      if (mounted) {
        setState(() {
          _stats = stats;
          _topScores = topScores;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading stats: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistika'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: 'Umumiy'),
            Tab(icon: Icon(Icons.list), text: 'Natijalar'),
            Tab(icon: Icon(Icons.military_tech), text: 'Darajalar'),
          ],
        ),
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
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(),
                        _buildScoresTab(),
                        _buildDifficultyTab(),
                      ],
                    ),
            ),
            const AdBannerWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final bestScore = _topScores.isNotEmpty ? _topScores.first : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Umumiy statistika',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Main Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Eng yuqori ball',
                  '${_stats['bestScore'] ?? 0}',
                  Icons.emoji_events,
                  AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'O\'rtacha ball',
                  '${(_stats['averageScore'] ?? 0.0).toStringAsFixed(0)}',
                  Icons.trending_up,
                  AppColors.info,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'O\'ynagan o\'yinlar',
                  '${_stats['totalGames'] ?? 0}',
                  Icons.games,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'O\'rtacha aniqlik',
                  '${(_stats['averageAccuracy'] ?? 0.0).toStringAsFixed(1)}%',
                  Icons.gps_fixed,
                  AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Detailed Stats
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Batafsil ma\'lumot',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  'Jami tushganlar:',
                  '${_stats['totalHits'] ?? 0}',
                  AppColors.success,
                ),
                _buildDetailRow(
                  'Jami o\'tkazilganlar:',
                  '${_stats['totalMisses'] ?? 0}',
                  AppColors.danger,
                ),
                _buildDetailRow(
                  'Jami o\'qlar:',
                  '${(_stats['totalHits'] ?? 0) + (_stats['totalMisses'] ?? 0)}',
                  AppColors.info,
                ),
                if (bestScore != null) ...[
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  const Text(
                    'Eng yaxshi natija:',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Ball:',
                    '${bestScore.score}',
                    AppColors.accent,
                  ),
                  _buildDetailRow(
                    'Aniqlik:',
                    '${bestScore.accuracy.toStringAsFixed(1)}%',
                    AppColors.success,
                  ),
                  _buildDetailRow(
                    'Sana:',
                    bestScore.formattedDate,
                    AppColors.textSecondary,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Clear Stats Button
          if ((_stats['totalGames'] ?? 0) > 0)
            Center(
              child: ElevatedButton.icon(
                onPressed: _showClearDialog,
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Statistikani tozalash'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScoresTab() {
    if (_topScores.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_esports,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              'Hali natijalar yo\'q',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'O\'yin o\'ynab natijalar yig\'ing!',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _topScores.length,
      itemBuilder: (context, index) {
        final score = _topScores[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: index < 3
                  ? AppColors.accent.withOpacity(0.5)
                  : AppColors.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Rank
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: index < 3
                      ? AppColors.accent.withOpacity(0.2)
                      : AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: index < 3 ? AppColors.accent : AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Score info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ball: ${score.score}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          score.formattedDate,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Aniqlik: ${score.accuracy.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Tushgan: ${score.hits}/${score.totalShots}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        if (score.difficulty != null) ...[
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getDifficultyColor(
                                score.difficulty!,
                              ).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              score.difficulty!.name.toUpperCase(),
                              style: TextStyle(
                                color: _getDifficultyColor(score.difficulty!),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Medal for top 3
              if (index < 3)
                Icon(
                  index == 0
                      ? Icons.looks_one
                      : index == 1
                      ? Icons.looks_two
                      : Icons.looks_3,
                  color: AppColors.accent,
                  size: 20,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDifficultyTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: Difficulty.values.length,
      itemBuilder: (context, index) {
        final difficulty = Difficulty.values[index];
        return FutureBuilder<List<GameScore>?>(
          future: _scoreService.getScoresByDifficulty(difficulty, limit: 5),
          builder: (context, snapshot) {
            final scores = snapshot.data ?? [];
            final bestScore = scores.isNotEmpty ? scores.first : null;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getDifficultyColor(difficulty).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(
                            difficulty,
                          ).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getDifficultyIcon(difficulty),
                          color: _getDifficultyColor(difficulty),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              difficulty.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${scores.length} o\'yin o\'ynalgan',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (bestScore != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${bestScore.score}',
                              style: TextStyle(
                                color: _getDifficultyColor(difficulty),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Eng yaxshi',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (scores.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(color: AppColors.textSecondary),
                    const SizedBox(height: 8),
                    ...scores
                        .take(3)
                        .map(
                          (score) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  score.formattedDate,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${score.score} (${score.accuracy.toStringAsFixed(0)}%)',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ] else ...[
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'Bu darajada hali o\'ynalmagan',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getDifficultyColor(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return AppColors.success;
      case Difficulty.medium:
        return AppColors.info;
      case Difficulty.hard:
        return AppColors.warning;
      case Difficulty.expert:
        return AppColors.danger;
    }
  }

  IconData _getDifficultyIcon(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return Icons.sentiment_satisfied_alt;
      case Difficulty.medium:
        return Icons.sentiment_neutral;
      case Difficulty.hard:
        return Icons.sentiment_dissatisfied;
      case Difficulty.expert:
        return Icons.whatshot;
    }
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Statistikani tozalash',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Barcha natijalar va statistikalar o\'chiriladi. Bu amalni qaytarib bo\'lmaydi.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Bekor qilish',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _scoreService.clearScores();
              Navigator.pop(context);
              await _loadData(); // Reload data
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Statistika tozalandi'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Tozalash'),
          ),
        ],
      ),
    );
  }
}
