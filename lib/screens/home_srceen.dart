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
import 'package:flutter_application_1/screens/admin/admin_dashboard_screen.dart';
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
      final appUser = await _firestoreService.getUser(_user!.uid);

      if (mounted) {
        setState(() {
          _currentCoins = appUser?.coins ?? 0;
          _totalUC = appUser?.totalUCExchanged ?? 0;
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
        _showErrorSnackBar('Ma\'lumotlarni yuklashda xatolik yuz berdi');
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
                              'PUBG TDM',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'TRAINING',
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
                                      'REACTION',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 24 : 28,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    Text(
                                      'TRAINING',
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
                                        'Coinlar',
                                        '$_currentCoins',
                                        Icons.monetization_on,
                                        Colors.amber.shade600,
                                        isSmallScreen,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        'Jami UC',
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

                              // Menu Buttons
                              Column(
                                children: [
                                  _buildMenuButton(
                                    title: 'BOSHLASH',
                                    subtitle: 'Reaction training o\'ynash',
                                    icon: Icons.play_arrow,
                                    onTap: () => _navigateToTraining(),
                                    color: AppColors.primary,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  _buildMenuButton(
                                    title: 'COINLAR',
                                    subtitle: 'Coin yig\'ish va UC almashish',
                                    icon: Icons.monetization_on,
                                    onTap: () => _navigateToCoins(),
                                    color: Colors.amber.shade600,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  _buildMenuButton(
                                    title: 'VAZIFALAR',
                                    subtitle: 'Vazifa bajaring — coin oling',
                                    icon: Icons.assignment_turned_in,
                                    onTap: () => _navigateToTasks(),
                                    color: Colors.green.shade600,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  _buildMenuButton(
                                    title: 'REYTING',
                                    subtitle: 'Top o\'yinchilar reytingi',
                                    icon: Icons.leaderboard,
                                    onTap: () => _navigateToLeaderboard(),
                                    color: Colors.purple.shade600,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  _buildMenuButton(
                                    title: 'STATISTIKA',
                                    subtitle: 'Natijalaringizni ko\'ring',
                                    icon: Icons.bar_chart,
                                    onTap: () => _navigateToStats(),
                                    color: AppColors.info,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  _buildMenuButton(
                                    title: 'SOZLAMALAR',
                                    subtitle: 'O\'yin sozlamalari',
                                    icon: Icons.settings,
                                    onTap: () => _showSettings(),
                                    color: AppColors.textSecondary,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  if (_isAdmin) ...[
                                    SizedBox(height: isSmallScreen ? 12 : 16),
                                    _buildMenuButton(
                                      title: 'ADMIN PANEL',
                                      subtitle: 'Foydalanuvchilar va sozlamalar',
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
      ).then((_) => _loadData());
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
      ).then((_) => _loadData());
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

  void _navigateToStats() {
    _showInterstitialAndNavigate(() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const StatsScreen()),
      );
    });
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
              const Text(
                'Reklama yuklanmoqda...',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
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
                child: const Text('O\'tkazib yuborish'),
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

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppColors.danger),
            SizedBox(width: 8),
            Text('Chiqish', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: const Text(
          'Hisobdan chiqishni xohlaysizmi?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Bekor qilish',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Chiqish',
                style: TextStyle(color: AppColors.danger)),
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
                    const Expanded(
                      child: Text(
                        'Sozlamalar',
                        style: TextStyle(
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
                                      _user!.displayName ?? 'Foydalanuvchi',
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

                      // Statistics
                      FutureBuilder<AppUser?>(
                        future: _user != null
                            ? _firestoreService.getUser(_user!.uid)
                            : Future.value(null),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData || userSnapshot.data == null) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final appUser = userSnapshot.data!;

                          return FutureBuilder<Map<String, dynamic>>(
                            future: _firestoreService.getDailyStatus(_user!.uid),
                            builder: (context, statusSnapshot) {
                              final dailyStatus = statusSnapshot.data ?? {};

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Statistics Header
                                  const Text(
                                    'Statistika',
                                    style: TextStyle(
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
                                          label: 'Coinlar',
                                          value: '${appUser.coins}',
                                          color: Colors.amber,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildSettingStat(
                                          icon: Icons.diamond,
                                          label: 'UC',
                                          value: '${appUser.totalUCExchanged}',
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
                                          label: 'Streak',
                                          value: '${appUser.loginStreak} kun',
                                          color: Colors.orange,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildSettingStat(
                                          icon: Icons.emoji_events,
                                          label: 'Jami',
                                          value: '${appUser.totalCoinsEarned}',
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Daily Activity
                                  const Text(
                                    'Bugungi Aktivlik',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                                    ),
                                    child: Column(
                                      children: [
                                        _buildProgressItem(
                                          'Reklamalar',
                                          dailyStatus['adsWatched'] ?? 0,
                                          dailyStatus['maxAds'] ?? 10,
                                          Colors.blue,
                                        ),
                                        const SizedBox(height: 12),
                                        _buildProgressItem(
                                          'O\'yinlar',
                                          dailyStatus['gamesPlayed'] ?? 0,
                                          dailyStatus['maxGames'] ?? 20,
                                          Colors.green,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Referral Code
                                  const Text(
                                    'Taklif Kodi',
                                    style: TextStyle(
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
                                            const Text(
                                              'Sizning kodingiz:',
                                              style: TextStyle(
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
                                                '${appUser.referralCount} ta taklif',
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
                                                  appUser.referralCode,
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
                                                    ClipboardData(text: appUser.referralCode),
                                                  );
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: const Text('Kod nusxalandi!'),
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
                                            const Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'TDM Training',
                                                    style: TextStyle(
                                                      color: AppColors.textPrimary,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Versiya 2.0.0',
                                                    style: TextStyle(
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
                                        const Text(
                                          '© 2025 TDM Training. Barcha huquqlar himoyalangan.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
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
                        label: const Text('Chiqish'),
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

  Widget _buildProgressItem(String label, int current, int max, Color color) {
    final progress = max > 0 ? current / max : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            Text(
              '$current/$max',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
