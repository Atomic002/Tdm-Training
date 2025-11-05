import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/coin_service.dart';
import '../services/admob_service.dart';
import '../utils/app_colors.dart';
import '../widgets/ad_banner.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';

// UCExchange model
class UCExchange {
  final int coins;
  final int ucAmount;
  final DateTime date;
  final String status;
  final String nickname;
  final String pubgId;

  UCExchange({
    required this.coins,
    required this.ucAmount,
    required this.date,
    this.status = 'completed',
    this.nickname = '',
    this.pubgId = '',
  });

  factory UCExchange.fromJson(Map<String, dynamic> json) {
    return UCExchange(
      coins: json['coins'] is int
          ? json['coins']
          : (int.tryParse(json['coins']?.toString() ?? '0') ?? 0),
      ucAmount: json['ucAmount'] is int
          ? json['ucAmount']
          : (int.tryParse(json['ucAmount']?.toString() ?? '0') ?? 0),
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      status: json['status']?.toString() ?? 'completed',
      nickname: json['nickname']?.toString() ?? '',
      pubgId: json['pubgId']?.toString() ?? '',
    );
  }

  String get formattedDate =>
      '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
}

class CoinScreen extends StatefulWidget {
  final VoidCallback onUpdate; // Callback to refresh HomeScreen

  const CoinScreen({super.key, required this.onUpdate});

  @override
  State<CoinScreen> createState() => _CoinScreenState();
}

class _CoinScreenState extends State<CoinScreen> with TickerProviderStateMixin {
  final CoinService _coinService = CoinService();
  int _currentCoins = 0;
  int _totalUC = 0;
  Map<String, dynamic> _dailyStatus = {};
  List<Map<String, dynamic>> _history = []; // Cache history
  bool _isLoading = true;
  bool _isWatchingAd = false;

  Timer? _adCooldownTimer;
  int _adCooldownSeconds = 0;
  bool _canWatchAd = true;

  late AnimationController _coinAnimationController;
  late Animation<double> _coinAnimation;
  late AnimationController _rotationController;
  late AnimationController _rewardAnimationController;
  late Animation<double> _rewardScaleAnimation;
  late Animation<Offset> _rewardSlideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAdMob();
    _initializeAnimations();
    _loadData();
  }

  Future<void> _initializeAdMob() async {
    try {
      await AdMobService.initialize();
      print('AdMob initialized in CoinScreen');
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('AdMob initialization failed: $e');
      }
    }
  }

  void _initializeAnimations() {
    try {
      _coinAnimationController = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
      _coinAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(
          parent: _coinAnimationController,
          curve: Curves.elasticOut,
        ),
      );

      _rotationController = AnimationController(
        duration: const Duration(seconds: 8),
        vsync: this,
      )..repeat();

      _rewardAnimationController = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      );

      _rewardScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _rewardAnimationController,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        ),
      );

      _rewardSlideAnimation =
          Tween<Offset>(
            begin: const Offset(0.0, 0.5),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: _rewardAnimationController,
              curve: const Interval(0.5, 1.0, curve: Curves.easeOutBack),
            ),
          );
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Animation initialization failed: $e');
      }
    }
  }

  void _startAdCooldown() {
    setState(() {
      _canWatchAd = false;
      _adCooldownSeconds = 20;
    });

    _adCooldownTimer?.cancel();
    _adCooldownTimer = Timer.periodic(const Duration(seconds: 1), (
      Timer timer,
    ) {
      if (mounted) {
        setState(() {
          _adCooldownSeconds--;
          if (_adCooldownSeconds <= 0) {
            _canWatchAd = true;
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _coinAnimationController.dispose();
    _rotationController.dispose();
    _rewardAnimationController.dispose();
    _adCooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final coins = await _coinService.getCoins();
      final status = await _coinService.getDailyStatus() ?? {};
      final history = await _coinService.getExchangeHistory();
      print('CoinScreen History: $history'); // Debug log

      final totalUC = (history ?? []).fold<int>(0, (sum, exchange) {
        try {
          if (exchange is Map<String, dynamic>) {
            final ucExchange = UCExchange.fromJson(exchange);
            return sum + ucExchange.ucAmount;
          }
          print('Invalid exchange item in CoinScreen: $exchange');
          return sum;
        } catch (e) {
          print(
            'Error processing exchange item in CoinScreen: $e, Item: $exchange',
          );
          return sum;
        }
      });

      if (mounted) {
        setState(() {
          _currentCoins = coins ?? 0;
          _totalUC = totalUC;
          _dailyStatus = status;
          _history = history ?? [];
          _isLoading = false;
        });
        widget.onUpdate(); // Notify HomeScreen to refresh
      }
    } catch (e, stackTrace) {
      print('Error loading data in CoinScreen: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _currentCoins = 0;
          _totalUC = 0;
          _dailyStatus = {};
          _history = [];
          _isLoading = false;
        });
        _showErrorSnackBar('Ma\'lumotlarni yuklashda xatolik yuz berdi: $e');
      }
    }
  }

  Future<void> _watchAdForCoins() async {
    if (!mounted ||
        _isWatchingAd ||
        !(_dailyStatus['canWatchAd'] ?? false) ||
        !_canWatchAd) {
      if (_isWatchingAd) {
        _showErrorSnackBar('Reklama allaqachon yuklanmoqda');
      } else if (!(_dailyStatus['canWatchAd'] ?? false)) {
        _showErrorSnackBar('Bugun reklamalar limitiga yetdingiz');
      } else if (!_canWatchAd) {
        _showErrorSnackBar('Iltimos $_adCooldownSeconds soniya kuting');
      }
      return;
    }

    setState(() => _isWatchingAd = true);
    _showLoadingDialog('Reklama yuklanmoqda...');

    try {
      final success = await AdMobService.showRewardedAd(
        onUserEarnedReward: (RewardItem reward) {},
        onRewardEarned: () async {
          if (mounted) {
            final added = await _coinService.addCoinsForAd();
            if (added) {
              setState(() {
                _currentCoins += 5;
              });
              _animateCoinGain();
              _animateReward();
              _showSuccessSnackBar('5 coin qo\'shildi!');
              _startAdCooldown();
              await _loadData();
            } else {
              _showErrorSnackBar('Coin qo\'shishda xatolik yuz berdi');
            }
          }
        },
        onFailed: () {
          if (mounted) {
            _showErrorSnackBar('Reklama ko\'rsatishda xatolik yuz berdi');
          }
        },
      );

      if (mounted) {
        Navigator.of(context).pop(); // Pop dialog only
        setState(() => _isWatchingAd = false);
        if (!success) {
          _showErrorSnackBar('Reklama ko\'rsatishda xatolik yuz berdi');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Pop dialog only
        setState(() => _isWatchingAd = false);
        _showErrorSnackBar('Reklama ko\'rsatishda xatolik: $e');
      }
    }
  }

  void _animateCoinGain() {
    if (!mounted) return;
    _coinAnimationController.forward().then((_) {
      if (mounted) {
        _coinAnimationController.reverse();
      }
    });
  }

  void _animateReward() {
    if (!mounted) return;
    _rewardAnimationController.forward().then((_) {
      if (mounted) {
        _rewardAnimationController.reset();
      }
    });
  }

  void _showLoadingDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
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
                message,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUCExchangeDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => UCExchangeDialog(
        currentCoins: _currentCoins,
        coinService: _coinService,
        onExchangeSuccess: _loadData,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
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
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        widget.onUpdate(); // Refresh HomeScreen before popping
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Coinlar'),
          backgroundColor: AppColors.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              widget.onUpdate(); // Refresh HomeScreen on back press
              Navigator.pop(context);
            },
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
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: AppColors.primary,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildCoinDisplay(),
                              const SizedBox(height: 24),
                              _buildDailyStatus(),
                              const SizedBox(height: 24),
                              _buildEarnCoinsSection(),
                              const SizedBox(height: 24),
                              _buildUCExchangeSection(),
                              const SizedBox(height: 24),
                              _buildExchangeHistory(),
                            ],
                          ),
                        ),
                      ),
              ),
              const AdBannerWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoinDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.2),
            AppColors.accent.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([
              _coinAnimationController,
              _rotationController,
            ]),
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * 3.14159,
                child: AnimatedBuilder(
                  animation: _coinAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _coinAnimation.value,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.shade400,
                              Colors.orange.shade600,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber,
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.monetization_on,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _rewardAnimationController,
            builder: (context, child) {
              return SlideTransition(
                position: _rewardSlideAnimation,
                child: ScaleTransition(
                  scale: _rewardScaleAnimation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_currentCoins',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '$_totalUC UC',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const Text(
            'Coinlaringiz va UC',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kunlik Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatusItem(
                  'O\'yinlar',
                  '${_dailyStatus['gamesPlayed'] ?? 0}/${_dailyStatus['maxGames'] ?? 0}',
                  Icons.gamepad,
                  AppColors.info,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusItem(
                  'Reklamalar',
                  '${_dailyStatus['adsWatched'] ?? 0}/${_dailyStatus['maxAds'] ?? 0}',
                  Icons.ads_click,
                  AppColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEarnCoinsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Coin Topish',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildEarnButton(
            title: 'Reklama Ko\'rish',
            subtitle: 'Har bir reklama uchun 5 coin',
            icon: Icons.play_circle_fill,
            onPressed:
                (_dailyStatus['canWatchAd'] ?? false) &&
                    !_isWatchingAd &&
                    _canWatchAd
                ? _watchAdForCoins
                : null,
            buttonText: !_canWatchAd
                ? '$_adCooldownSeconds soniya'
                : (_dailyStatus['canWatchAd'] ?? false)
                ? 'Reklama Ko\'rish'
                : 'Limit tugadi',
            color: AppColors.success,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.info, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'O\'yin o\'ynab ham coin olishingiz mumkin! Aniqligingizga qarab 0-10 coin olasiz.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarnButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback? onPressed,
    required String buttonText,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: onPressed != null ? color : Colors.grey,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  Widget _buildUCExchangeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.currency_exchange, color: AppColors.accent, size: 24),
              const SizedBox(width: 8),
              const Text(
                'UC Almashtirish',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...CoinService.ucExchangeRates.entries.map((entry) {
            final coins = entry.key;
            final uc = entry.value;
            final canAfford = _currentCoins >= coins;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: canAfford
                    ? AppColors.accent.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: canAfford
                      ? AppColors.accent.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$coins Coin',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.arrow_forward,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$uc UC',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (!canAfford)
                    Text(
                      'Yetarli emas',
                      style: TextStyle(fontSize: 12, color: AppColors.danger),
                    ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _showUCExchangeDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'UC Almashish',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeHistory() {
    if (_history.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.history, color: AppColors.textSecondary, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Almashtirish tarixi bo\'sh',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final history = _history
        .take(5)
        .map((e) => UCExchange.fromJson(e))
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'So\'nggi Almashtirish',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...history.map(
            (exchange) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.swap_horiz, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${exchange.coins} Coin → ${exchange.ucAmount} UC',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Nickname: ${exchange.nickname}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'ID: ${exchange.pubgId}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          exchange.formattedDate,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: exchange.status == 'pending'
                          ? AppColors.info.withOpacity(0.2)
                          : AppColors.success.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      exchange.status == 'pending'
                          ? 'Kutilmoqda'
                          : 'Tugallandi',
                      style: TextStyle(
                        fontSize: 10,
                        color: exchange.status == 'pending'
                            ? AppColors.info
                            : AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UCExchangeDialog extends StatefulWidget {
  final int currentCoins;
  final CoinService coinService;
  final VoidCallback onExchangeSuccess;

  const UCExchangeDialog({
    super.key,
    required this.currentCoins,
    required this.coinService,
    required this.onExchangeSuccess,
  });

  @override
  State<UCExchangeDialog> createState() => _UCExchangeDialogState();
}

class _UCExchangeDialogState extends State<UCExchangeDialog> {
  final _nicknameController = TextEditingController();
  final _pubgIdController = TextEditingController();
  int? _selectedCoins;
  int? _selectedUC;

  @override
  void dispose() {
    _nicknameController.dispose();
    _pubgIdController.dispose();
    super.dispose();
  }

  void _selectExchange(int coins, int uc) {
    if (mounted) {
      setState(() {
        _selectedCoins = coins;
        _selectedUC = uc;
      });
    }
  }

  Future<void> _confirmExchange() async {
    if (!mounted) return;
    if (_selectedCoins == null || _selectedUC == null) {
      _showErrorSnackBar('Iltimos, almashtirish miqdorini tanlang');
      return;
    }

    if (_nicknameController.text.trim().isEmpty) {
      _showErrorSnackBar('Iltimos, nickname kiriting');
      return;
    }

    if (_pubgIdController.text.trim().isEmpty) {
      _showErrorSnackBar('Iltimos, PUBG ID kiriting');
      return;
    }

    if (widget.currentCoins < _selectedCoins!) {
      _showErrorSnackBar('Yetarli coin yo\'q');
      return;
    }

    try {
      final success = await widget.coinService.exchangeForUC(
        _selectedCoins!,
        _selectedUC!,
        _nicknameController.text.trim(),
        _pubgIdController.text.trim(),
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          _showSuccessDialog();
          widget.onExchangeSuccess();
        } else {
          _showErrorSnackBar('Almashtirish muvaffaqiyatsiz');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Xatolik yuz berdi: $e');
      }
    }
  }

  void _showSuccessDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 28),
            const SizedBox(width: 12),
            const Text(
              'Muvaffaqiyatli!',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'UC almashtirish so\'rovi qabul qilindi!',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ma\'lumotlar:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nickname: ${_nicknameController.text}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  Text(
                    'PUBG ID: ${_pubgIdController.text}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  Text(
                    'Miqdor: $_selectedCoins Coin → $_selectedUC UC',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'UC lar 24-48 soat ichida hisobingizga o\'tkaziladi.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'UC Almashtirish',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Mavjud: ${widget.currentCoins} coin',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Almashtirish miqdorini tanlang:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...CoinService.ucExchangeRates.entries.map((entry) {
              final coins = entry.key;
              final uc = entry.value;
              final canAfford = widget.currentCoins >= coins;
              final isSelected = _selectedCoins == coins;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: canAfford ? () => _selectExchange(coins, uc) : null,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent.withOpacity(0.2)
                            : canAfford
                            ? AppColors.surface.withOpacity(0.5)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accent
                              : canAfford
                              ? AppColors.primary.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: AppColors.accent,
                              size: 20,
                            )
                          else
                            Icon(
                              Icons.radio_button_unchecked,
                              color: canAfford
                                  ? AppColors.textSecondary
                                  : Colors.grey,
                              size: 20,
                            ),
                          const SizedBox(width: 12),
                          Text(
                            '$coins Coin',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: canAfford
                                  ? Colors.amber.shade700
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.arrow_forward,
                            color: AppColors.textSecondary,
                            size: 16,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '$uc UC',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: canAfford ? AppColors.accent : Colors.grey,
                            ),
                          ),
                          const Spacer(),
                          if (!canAfford)
                            Text(
                              'Yetarli emas',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            const Text(
              'Ma\'lumotlaringizni kiriting:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nicknameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Nickname',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pubgIdController,
              style: const TextStyle(color: AppColors.textPrimary),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'PUBG ID',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
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
          onPressed: _confirmExchange,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
          child: const Text('Almashish'),
        ),
      ],
    );
  }
}
