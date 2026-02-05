import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/services/admob_service.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'package:flutter_application_1/models/app_user.dart';
import 'package:flutter_application_1/widgets/ad_banner.dart';
import 'package:flutter_application_1/screens/difficulty_selection_screen.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/screens/stats_screen.dart';
import 'package:flutter_application_1/screens/coin_screen.dart';
import 'package:flutter_application_1/screens/tasks_screen.dart';
import 'package:flutter_application_1/screens/leaderboard_screen.dart';
import 'package:flutter_application_1/screens/mini_pubg_game_screen.dart';
import 'package:flutter_application_1/screens/admin/admin_dashboard_screen.dart';
import 'package:flutter_application_1/screens/uc_shop_screen.dart';
import 'package:flutter_application_1/models/announcement_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';
import 'package:flutter_application_1/main.dart';
import '../utils/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final FirestoreService _firestoreService = FirestoreService();
  final User? _user = FirebaseAuth.instance.currentUser;
  int _currentCoins = 0;
  int _totalUC = 0;
  bool _isLoading = true;
  bool _isAdmin = false;
  AppUser? _appUser;
  List<AnnouncementModel> _announcements = [];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
    _preloadAds();
    _checkAdmin();
  }

  void _initializeAnimations() {
    try {
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );

      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutQuart,
        ),
      );

      _slideAnimation =
          Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOutCubic,
            ),
          );

      _animationController.forward();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Animation initialization failed: $e');
      }
    }
  }

  Future<void> _checkAdmin() async {
    if (_user == null) return;
    final admin = await _firestoreService.isAdmin(_user!.uid);
    if (mounted) {
      setState(() => _isAdmin = admin);
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      if (_user == null) return;
      final results = await Future.wait([
        _firestoreService.getUser(_user!.uid),
        _firestoreService.getActiveAnnouncements(),
      ]);

      final appUser = results[0] as AppUser?;
      final announcements = results[1] as List<AnnouncementModel>;

      if (mounted) {
        setState(() {
          _appUser = appUser;
          _currentCoins = appUser?.coins ?? 0;
          _totalUC = appUser?.totalUCExchanged ?? 0;
          _announcements = announcements;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data in HomeScreen: $e');
      if (mounted) {
        setState(() {
          _currentCoins = 0;
          _totalUC = 0;
          _isLoading = false;
        });
        final l = AppLocalizations.of(context);
        _showErrorSnackBar(l?.dataLoadError ?? 'Ma\'lumotlarni yuklashda xatolik yuz berdi');
      }
    }
  }

  Future<void> _preloadAds() async {
    try {
      AdMobService.loadInterstitialAd();
    } catch (e) {
      print('Error preloading ads in HomeScreen: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, Color(0xFF0F0F0F)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top coin/UC bar - Fixed
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // App title with logo
                    Row(
                      children: [
                        Container(
                          width: isSmallScreen ? 35 : 40,
                          height: isSmallScreen ? 35 : 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                Colors.orange.shade700,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.gps_fixed,
                            color: Colors.white,
                            size: isSmallScreen ? 20 : 24,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.pubgTdm,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              l.training,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 10 : 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Coin va UC display
                    Row(
                      children: [
                        // Coin display
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CoinScreen(
                                  onUpdate: _loadData,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.03,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.amber.shade400,
                                  Colors.orange.shade600,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.monetization_on,
                                  color: Colors.white,
                                  size: isSmallScreen ? 16 : 18,
                                ),
                                const SizedBox(width: 4),
                                _isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        '$_currentCoins',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: isSmallScreen ? 13 : 14,
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // UC display
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.03,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.accent,
                                AppColors.accent.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.diamond,
                                color: Colors.white,
                                size: isSmallScreen ? 16 : 18,
                              ),
                              const SizedBox(width: 4),
                              _isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      '$_totalUC UC',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: isSmallScreen ? 13 : 14,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.05,
                            vertical: isSmallScreen ? 20 : 30,
                          ),
                          child: Column(
                            children: [
                              // Logo/Title section
                              Container(
                                margin: EdgeInsets.only(
                                  bottom: isSmallScreen ? 30 : 40,
                                ),
                                child: Column(
                                  children: [
                                    TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      duration: const Duration(
                                        milliseconds: 1200,
                                      ),
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: 0.3 + (0.7 * value),
                                          child: Transform.rotate(
                                            angle: (1.0 - value) * 2.0,
                                            child: Container(
                                              width: isSmallScreen ? 80 : 100,
                                              height: isSmallScreen ? 80 : 100,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    AppColors.primary,
                                                    Colors.orange.shade700,
                                                    Colors.red.shade600,
                                                  ],
                                                ),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.primary
                                                        .withOpacity(0.5),
                                                    blurRadius: 20,
                                                    spreadRadius: 5,
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                Icons.gps_fixed,
                                                size: isSmallScreen ? 40 : 50,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    SizedBox(height: isSmallScreen ? 12 : 16),
                                    Text(
                                      l.reaction,
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 24 : 28,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    Text(
                                      l.training,
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 14 : 16,
                                        fontWeight: FontWeight.w300,
                                        color: AppColors.accent,
                                        letterSpacing: 4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Stats cards
                              if (!_isLoading) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        l.coins,
                                        '$_currentCoins',
                                        Icons.monetization_on,
                                        Colors.amber.shade600,
                                        isSmallScreen,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        l.totalUC,
                                        '$_totalUC',
                                        Icons.diamond,
                                        AppColors.accent,
                                        isSmallScreen,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: isSmallScreen ? 20 : 30),
                              ],

                              // Announcements Section
                              if (_announcements.isNotEmpty) ...[
                                _buildAnnouncementsSection(isSmallScreen, l),
                                SizedBox(height: isSmallScreen ? 20 : 30),
                              ],

                              // Menu Buttons
                              Column(
                                children: [
                                  _buildMenuButton(
                                    title: l.start,
                                    subtitle: l.startSubtitle,
                                    icon: Icons.play_arrow,
                                    onTap: () => _navigateToTraining(),
                                    color: AppColors.primary,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  _buildMenuButton(
                                    title: l.coinsMenu,
                                    subtitle: l.coinsMenuSubtitle,
                                    icon: Icons.monetization_on,
                                    onTap: () => _navigateToCoins(),
                                    color: Colors.amber.shade600,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  _buildMenuButton(
                                    title: l.ucShop,
                                    subtitle: l.ucShopSubtitle,
                                    icon: Icons.shopping_cart,
                                    onTap: () => _navigateToUCShop(),
                                    color: Colors.teal,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  _buildMenuButton(
                                    title: l.tasks,
                                    subtitle: l.tasksSubtitle,
                                    icon: Icons.assignment_turned_in,
                                    onTap: () => _navigateToTasks(),
                                    color: Colors.green.shade600,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  _buildMenuButton(
                                    title: l.miniPubg,
                                    subtitle: l.miniPubgSubtitle,
                                    icon: Icons.military_tech,
                                    onTap: () => _navigateToMiniPubg(),
                                    color: Colors.red.shade700,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  _buildMenuButton(
                                    title: l.leaderboard,
                                    subtitle: l.leaderboardSubtitle,
                                    icon: Icons.leaderboard,
                                    onTap: () => _navigateToLeaderboard(),
                                    color: Colors.purple.shade600,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  _buildMenuButton(
                                    title: l.statistics,
                                    subtitle: l.statisticsSubtitle,
                                    icon: Icons.bar_chart,
                                    onTap: () => _navigateToStats(),
                                    color: AppColors.info,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  _buildMenuButton(
                                    title: l.settings,
                                    subtitle: l.settingsSubtitle,
                                    icon: Icons.settings,
                                    onTap: () => _showSettings(),
                                    color: AppColors.textSecondary,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  if (_isAdmin) ...[
                                    SizedBox(height: isSmallScreen ? 12 : 16),
                                    _buildMenuButton(
                                      title: l.adminPanel,
                                      subtitle: l.adminPanelSubtitle,
                                      icon: Icons.admin_panel_settings,
                                      onTap: () => _navigateToAdmin(),
                                      color: Colors.red.shade600,
                                      isSmallScreen: isSmallScreen,
                                    ),
                                  ],
                                ],
                              ),

                              // Bottom spacing for ad
                              SizedBox(height: isSmallScreen ? 20 : 30),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Ad Banner - Fixed at bottom
              const AdBannerWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isSmallScreen,
  ) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isSmallScreen ? 20 : 24),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required bool isSmallScreen,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surface, AppColors.surface.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textSecondary,
                  size: isSmallScreen ? 14 : 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToTraining() {
    _showInterstitialAndNavigate(() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const DifficultySelectionScreen(),
        ),
      );
    });
  }

  void _navigateToCoins() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CoinScreen(onUpdate: _loadData)),
    );
  }

  void _navigateToTasks() {
    _showInterstitialAndNavigate(() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TasksScreen(onUpdate: _loadData),
        ),
      );
    });
  }

  void _navigateToLeaderboard() {
    _showInterstitialAndNavigate(() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
      );
    });
  }

  void _navigateToMiniPubg() {
    _showInterstitialAndNavigate(() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MiniPubgGameScreen(onUpdate: _loadData),
        ),
      );
    });
  }

  void _navigateToStats() {
    _showInterstitialAndNavigate(() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const StatsScreen()),
      );
    });
  }

  void _navigateToUCShop() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UCShopScreen()),
    ).then((_) => _loadData());
  }

  void _navigateToAdmin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
    );
  }

  void _showInterstitialAndNavigate(VoidCallback navigation) {
    if (!AdMobService.isInterstitialAdReady) {
      navigation();
      return;
    }

    final l = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
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
                l.adLoading,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  navigation();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(l.skipAd),
              ),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () async {
      try {
        await AdMobService.showInterstitialAd();
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context, rootNavigator: true).pop();
          navigation();
        }
      } catch (e) {
        print('Reklama xatoligi: $e');
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context, rootNavigator: true).pop();
          navigation();
        }
      }
    });
  }

  Widget _buildAnnouncementsSection(bool isSmallScreen, AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l.news,
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: 1,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_announcements.length}',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: isSmallScreen ? 11 : 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 10 : 12),
        SizedBox(
          height: isSmallScreen ? 160 : 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _announcements.length,
            itemBuilder: (context, index) {
              return _buildAnnouncementCard(
                _announcements[index],
                isSmallScreen,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementCard(AnnouncementModel announcement, bool isSmallScreen) {
    final cardWidth = MediaQuery.of(context).size.width * 0.75;

    Color cardColor;
    IconData cardIcon;
    switch (announcement.type) {
      case 'youtube':
        cardColor = Colors.red;
        cardIcon = Icons.play_circle_fill;
        break;
      case 'promo':
        cardColor = Colors.purple;
        cardIcon = Icons.local_offer;
        break;
      case 'update':
        cardColor = Colors.blue;
        cardIcon = Icons.system_update;
        break;
      case 'image':
        cardColor = Colors.orange;
        cardIcon = Icons.image;
        break;
      case 'ucShop':
        cardColor = Colors.teal;
        cardIcon = Icons.shopping_cart;
        break;
      default: // news
        cardColor = AppColors.primary;
        cardIcon = Icons.newspaper;
    }

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cardColor.withOpacity(0.15),
            cardColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onAnnouncementTap(announcement),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(cardIcon, color: cardColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        announcement.title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (announcement.description != null &&
                    announcement.description!.isNotEmpty) ...[
                  SizedBox(height: isSmallScreen ? 8 : 10),
                  Expanded(
                    child: Text(
                      announcement.description!,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: isSmallScreen ? 12 : 13,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (announcement.imageUrl != null &&
                    announcement.imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        announcement.imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
                if (announcement.actionText != null &&
                    announcement.actionText!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      announcement.actionText!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onAnnouncementTap(AnnouncementModel announcement) {
    if (announcement.type == 'ucShop') {
      _navigateToUCShop();
      return;
    }

    if (announcement.type == 'youtube' && announcement.videoUrl != null) {
      _launchUrl(announcement.videoUrl!);
      return;
    }

    if (announcement.actionUrl != null && announcement.actionUrl!.isNotEmpty) {
      _launchUrl(announcement.actionUrl!);
      return;
    }

    // Show detail dialog for news/promo/image types
    if (announcement.description != null || announcement.imageUrl != null) {
      final l = AppLocalizations.of(context)!;
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  announcement.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                if (announcement.imageUrl != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      announcement.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ],
                if (announcement.description != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    announcement.description!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      l.close,
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _signOut() async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.logout, color: AppColors.danger),
            const SizedBox(width: 8),
            Text(l.logout, style: const TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Text(
          l.logoutConfirm,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.cancel,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.logout,
                style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showSettings() {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 700),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.8),
                      AppColors.accent.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.settings, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l.settingsTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Profile
                      if (_user != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.accent.withOpacity(0.1),
                                AppColors.primary.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 28,
                                  backgroundImage: _user!.photoURL != null
                                      ? NetworkImage(_user!.photoURL!)
                                      : null,
                                  backgroundColor: AppColors.primary,
                                  child: _user!.photoURL == null
                                      ? const Icon(Icons.person, color: Colors.white, size: 32)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _user!.displayName ?? l.user,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _user!.email ?? '',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Language Selector
                      Text(
                        l.language,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            _buildLanguageOption(
                              dialogContext,
                              'uz',
                              l.uzbek,
                            ),
                            const SizedBox(width: 8),
                            _buildLanguageOption(
                              dialogContext,
                              'ru',
                              l.russian,
                            ),
                            const SizedBox(width: 8),
                            _buildLanguageOption(
                              dialogContext,
                              'en',
                              l.english,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Statistics
                      if (_appUser != null) ...[
                        Text(
                          l.statsLabel,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Stats Grid
                        Row(
                          children: [
                            Expanded(
                              child: _buildSettingStat(
                                icon: Icons.monetization_on,
                                label: l.coins,
                                value: '$_currentCoins',
                                color: Colors.amber,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSettingStat(
                                icon: Icons.diamond,
                                label: 'UC',
                                value: '$_totalUC',
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSettingStat(
                                icon: Icons.local_fire_department,
                                label: l.streak,
                                value: l.streakDays(_appUser!.loginStreak),
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSettingStat(
                                icon: Icons.emoji_events,
                                label: l.total,
                                value: '${_appUser!.totalCoinsEarned}',
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Referral Code
                        Text(
                          l.referralCode,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.withOpacity(0.1),
                                Colors.teal.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    l.yourCode,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      l.referralCount(_appUser!.referralCount),
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _appUser!.referralCode,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 24,
                                          letterSpacing: 4,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Material(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(8),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () {
                                        Clipboard.setData(
                                          ClipboardData(text: _appUser!.referralCode),
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(l.codeCopied),
                                            duration: const Duration(seconds: 2),
                                            backgroundColor: Colors.green,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Icon(
                                          Icons.copy,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ] else
                        const Center(child: CircularProgressIndicator()),

                      // App Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.textSecondary.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.info_outline,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l.appName,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        l.version,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l.copyright,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border(
                    top: BorderSide(color: AppColors.textSecondary.withOpacity(0.2)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _signOut();
                        },
                        icon: const Icon(Icons.logout, size: 18),
                        label: Text(l.logout),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: BorderSide(color: AppColors.danger.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext dialogContext,
    String langCode,
    String label,
  ) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    final isSelected = currentLocale == langCode;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            MyApp.setLocale(context, Locale(langCode));
            Navigator.pop(dialogContext);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

}
