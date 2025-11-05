import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/services/admob_service.dart';
import 'package:flutter_application_1/services/coin_service.dart';
import 'package:flutter_application_1/widgets/ad_banner.dart';
import 'package:flutter_application_1/screens/difficulty_selection_screen.dart';
import 'package:flutter_application_1/screens/stats_screen.dart';
import 'package:flutter_application_1/screens/coin_screen.dart';
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
  final CoinService _coinService = CoinService();
  int _currentCoins = 0;
  int _totalUC = 0;
  bool _isLoading = true;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
    _preloadAds();
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

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final coins = await _coinService.getCoins();
      final history = await _coinService.getExchangeHistory();
      print('HomeScreen History: $history'); // Debug log

      final totalUC = (history ?? []).fold<int>(0, (sum, exchange) {
        try {
          if (exchange is Map<String, dynamic> &&
              exchange.containsKey('ucAmount')) {
            final ucAmount = exchange['ucAmount'];
            if (ucAmount is int) {
              return sum + ucAmount;
            } else if (ucAmount is double) {
              return sum + ucAmount.toInt();
            } else if (ucAmount is String) {
              return sum + (int.tryParse(ucAmount) ?? 0);
            }
          }
          print('Invalid exchange item in HomeScreen: $exchange');
          return sum;
        } catch (e) {
          print(
            'Error processing exchange item in HomeScreen: $e, Item: $exchange',
          );
          return sum;
        }
      });

      if (mounted) {
        setState(() {
          _currentCoins = coins ?? 0;
          _totalUC = totalUC;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Error loading data in HomeScreen: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _currentCoins = 0;
          _totalUC = 0;
          _isLoading = false;
        });
        _showErrorSnackBar('Ma\'lumotlarni yuklashda xatolik yuz berdi: $e');
      }
    }
  }

  Future<void> _preloadAds() async {
    try {
      AdMobService.loadInterstitialAd();
      print('Interstitial ad preloaded in HomeScreen');
    } catch (e) {
      print('Error preloading ads in HomeScreen: $e');
      if (mounted) {
        _showErrorSnackBar('Reklama yuklashda xatolik: $e');
      }
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
                                  onUpdate:
                                      _loadData, // Pass callback to refresh data
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
                                    ? SizedBox(
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
                                  ? SizedBox(
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
                                    // Animated logo
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

  void _navigateToStats() {
    _showInterstitialAndNavigate(() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const StatsScreen()),
      );
    });
  }

  void _showInterstitialAndNavigate(VoidCallback navigation) {
    if (!AdMobService.isInterstitialAdReady) {
      print('Reklama tayyor emas, darhol o\'tish');
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
        if (mounted) {
          Navigator.pop(context);
          navigation();
        }
      } catch (e) {
        print('Reklama xatoligi: $e');
        if (mounted) {
          Navigator.pop(context);
          navigation();
        }
      }
    });
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.settings, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Sozlamalar', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sozlamalar bo\'limi tez orada qo\'shiladi!',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kelgusi versiyalarda:',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Tovush sozlamalari\n• Qiyinchilik moslashlari\n• Tema tanlamlari\n• Statistika eksporti\n• Coin tarixi\n• UC almashtirish tarixi',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
