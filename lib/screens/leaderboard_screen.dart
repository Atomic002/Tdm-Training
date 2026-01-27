import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'package:flutter_application_1/services/admob_service.dart';
import 'package:flutter_application_1/models/app_user.dart';
import 'package:flutter_application_1/widgets/ad_banner.dart';
import '../utils/app_colors.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  late TabController _tabController;

  List<AppUser> _coinLeaderboard = [];
  List<AppUser> _ucLeaderboard = [];
  int _userRank = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    AdMobService.loadInterstitialAd();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _showInterstitialAdOnExit();
    super.dispose();
  }

  void _showInterstitialAdOnExit() {
    try {
      if (AdMobService.isInterstitialAdReady) {
        AdMobService.showInterstitialAd();
      }
    } catch (e) {
      print('Reklama ko\'rsatishda xatolik: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final coinBoard = await _firestoreService.getLeaderboardByCoins();
      final ucBoard = await _firestoreService.getLeaderboardByUC();
      int rank = 0;
      if (_uid != null) {
        rank = await _firestoreService.getUserRank(_uid!);
      }

      if (mounted) {
        setState(() {
          _coinLeaderboard = coinBoard;
          _ucLeaderboard = ucBoard;
          _userRank = rank;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'REYTING',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Coinlar'),
            Tab(text: 'UC'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLeaderboardList(_coinLeaderboard, isCoin: true),
                      _buildLeaderboardList(_ucLeaderboard, isCoin: false),
                    ],
                  ),
          ),

          // User rank bar
          if (!_isLoading && _userRank > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Sizning o\'rningiz: #$_userRank',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

          const AdBannerWidget(),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(List<AppUser> users, {required bool isCoin}) {
    if (users.isEmpty) {
      return const Center(
        child: Text(
          'Hali ma\'lumot yo\'q',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final rank = index + 1;
          final isCurrentUser = user.uid == _uid;
          final value = isCoin ? user.coins : user.totalUCExchanged;
          final valueLabel = isCoin ? 'coin' : 'UC';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? AppColors.primary.withOpacity(0.15)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCurrentUser
                    ? AppColors.primary.withOpacity(0.5)
                    : rank <= 3
                        ? _getRankColor(rank).withOpacity(0.3)
                        : Colors.transparent,
                width: isCurrentUser ? 2 : 1,
              ),
            ),
            child: ListTile(
              leading: _buildRankWidget(rank),
              title: Text(
                user.displayName.isNotEmpty ? user.displayName : 'Foydalanuvchi',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: isCurrentUser
                  ? const Text('Siz',
                      style: TextStyle(color: AppColors.primary, fontSize: 12))
                  : null,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (isCoin ? Colors.amber : AppColors.accent).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$value $valueLabel',
                  style: TextStyle(
                    color: isCoin ? Colors.amber : AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRankWidget(int rank) {
    if (rank <= 3) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getRankColor(rank).withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            Icons.emoji_events,
            color: _getRankColor(rank),
            size: 24,
          ),
        ),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(
          '#$rank',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade400;
      default:
        return AppColors.textSecondary;
    }
  }
}
