import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/admob_service.dart';
import '../models/exchange_model.dart';
import '../utils/app_colors.dart';
import '../widgets/ad_banner.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';
import 'dart:async';

class CoinScreen extends StatefulWidget {
  final VoidCallback onUpdate; // Callback to refresh HomeScreen

  const CoinScreen({super.key, required this.onUpdate});

  @override
  State<CoinScreen> createState() => _CoinScreenState();
}

class _CoinScreenState extends State<CoinScreen> with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  int _currentCoins = 0;
  int _totalUC = 0;
  Map<String, dynamic> _dailyStatus = {};
  List<ExchangeModel> _history = [];
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
    _initializeAnimations();
    _loadData();
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
      _adCooldownSeconds = 180;
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
    if (!mounted || _uid == null) return;
    setState(() => _isLoading = true);

    try {
      final coins = await _firestoreService.getCoins();
      final status = await _firestoreService.getDailyStatus(_uid!);
      final history = await _firestoreService.getExchangeHistory(_uid!);

      final totalUC = history.fold<int>(0, (sum, exchange) {
        return sum + exchange.ucAmount;
      });

      if (mounted) {
        setState(() {
          _currentCoins = coins;
          _totalUC = totalUC;
          _dailyStatus = status;
          _history = history;
          _isLoading = false;
        });
        widget.onUpdate();
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
        final l = AppLocalizations.of(context);
        _showErrorSnackBar(l?.dataLoadError ?? 'Error loading data');
      }
    }
  }

  Future<void> _watchAdForCoins() async {
    final l = AppLocalizations.of(context)!;
    if (!mounted ||
        _uid == null ||
        _isWatchingAd ||
        !(_dailyStatus['canWatchAd'] ?? false) ||
        !_canWatchAd) {
      if (_isWatchingAd) {
        _showErrorSnackBar(l.adAlreadyLoading);
      } else if (!(_dailyStatus['canWatchAd'] ?? false)) {
        _showErrorSnackBar(l.adLimitReachedToday);
      } else if (!_canWatchAd) {
        _showErrorSnackBar(l.pleaseWait('${_adCooldownSeconds ~/ 60}:${(_adCooldownSeconds % 60).toString().padLeft(2, '0')}'));
      }
      return;
    }

    setState(() => _isWatchingAd = true);
    _showLoadingDialog(l.adLoading);

    try {
      final success = await AdMobService.showRewardedAd(
        onUserEarnedReward: (RewardItem reward) {},
        onRewardEarned: () async {
          if (mounted && _uid != null) {
            final added = await _firestoreService.addCoinsForAd(_uid!);
            if (added) {
              _animateCoinGain();
              _animateReward();
              final l2 = AppLocalizations.of(context)!;
              _showSuccessSnackBar(l2.coinsAdded(FirestoreService.coinsPerAd));
              _startAdCooldown();
              await _loadData();
            } else {
              final l2 = AppLocalizations.of(context)!;
              _showErrorSnackBar(l2.coinAddError);
            }
          }
        },
        onFailed: () {
          if (mounted) {
            final l2 = AppLocalizations.of(context)!;
            _showErrorSnackBar(l2.adShowError);
          }
        },
      );

      if (mounted) {
        Navigator.of(context).pop(); // Pop dialog only
        setState(() => _isWatchingAd = false);
        if (!success) {
          _showErrorSnackBar(l.adShowError);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Pop dialog only
        setState(() => _isWatchingAd = false);
        _showErrorSnackBar(l.adShowErrorWithDetails(e.toString()));
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
    if (!mounted || _uid == null) return;
    showDialog(
      context: context,
      builder: (context) => UCExchangeDialog(
        currentCoins: _currentCoins,
        firestoreService: _firestoreService,
        uid: _uid!,
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
    final l = AppLocalizations.of(context)!;
    return WillPopScope(
      onWillPop: () async {
        widget.onUpdate();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.coins),
          backgroundColor: AppColors.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              widget.onUpdate();
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
                              _buildCoinDisplay(l),
                              const SizedBox(height: 24),
                              _buildDailyStatus(l),
                              const SizedBox(height: 24),
                              _buildEarnCoinsSection(l),
                              const SizedBox(height: 24),
                              _buildUCExchangeSection(l),
                              const SizedBox(height: 24),
                              _buildExchangeHistory(l),
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

  Widget _buildCoinDisplay(AppLocalizations l) {
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
          Text(
            l.coinsAndUC,
            style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyStatus(AppLocalizations l) {
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
          Text(
            l.dailyStatus,
            style: const TextStyle(
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
                  l.games,
                  '${_dailyStatus['gamesPlayed'] ?? 0}/${_dailyStatus['maxGames'] ?? 0}',
                  Icons.gamepad,
                  AppColors.info,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusItem(
                  l.ads,
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

  Widget _buildEarnCoinsSection(AppLocalizations l) {
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
          Text(
            l.earnCoins,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildEarnButton(
            title: l.watchAd,
            subtitle: l.adRewardInfo(FirestoreService.coinsPerAd),
            icon: Icons.play_circle_fill,
            onPressed:
                (_dailyStatus['canWatchAd'] ?? false) &&
                    !_isWatchingAd &&
                    _canWatchAd
                ? _watchAdForCoins
                : null,
            buttonText: !_canWatchAd
                ? '${_adCooldownSeconds ~/ 60}:${(_adCooldownSeconds % 60).toString().padLeft(2, '0')}'
                : (_dailyStatus['canWatchAd'] ?? false)
                ? l.watchAd
                : l.adLimitReached,
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
                    l.gameEarnInfo,
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

  Widget _buildUCExchangeSection(AppLocalizations l) {
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
              Text(
                l.ucExchange,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...FirestoreService.ucExchangeRates.entries.map((entry) {
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
                      l.notEnough,
                      style: TextStyle(fontSize: 12, color: AppColors.danger),
                    ),
                ],
              ),
            );
          }),
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
              child: Text(
                l.exchangeUC,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeHistory(AppLocalizations l) {
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
            Text(
              l.exchangeHistoryEmpty,
              style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final history = _history.take(5).toList();

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
          Text(
            l.recentExchanges,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...history.map(
            (exchange) {
              final formattedDate =
                  '${exchange.createdAt.day}/${exchange.createdAt.month}/${exchange.createdAt.year} ${exchange.createdAt.hour}:${exchange.createdAt.minute.toString().padLeft(2, '0')}';

              return Container(
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
                            formattedDate,
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
                            : exchange.status == 'approved'
                                ? AppColors.success.withOpacity(0.2)
                                : AppColors.danger.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        exchange.status == 'pending'
                            ? l.statusPending
                            : exchange.status == 'approved'
                                ? l.statusApproved
                                : exchange.status == 'rejected'
                                    ? l.statusRejected
                                    : l.statusCompleted,
                        style: TextStyle(
                          fontSize: 10,
                          color: exchange.status == 'pending'
                              ? AppColors.info
                              : exchange.status == 'approved'
                                  ? AppColors.success
                                  : exchange.status == 'rejected'
                                      ? AppColors.danger
                                      : AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class UCExchangeDialog extends StatefulWidget {
  final int currentCoins;
  final FirestoreService firestoreService;
  final String uid;
  final VoidCallback onExchangeSuccess;

  const UCExchangeDialog({
    super.key,
    required this.currentCoins,
    required this.firestoreService,
    required this.uid,
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
    final l = AppLocalizations.of(context)!;
    if (_selectedCoins == null || _selectedUC == null) {
      _showErrorSnackBar(l.selectExchangeAmountError);
      return;
    }

    if (_nicknameController.text.trim().isEmpty) {
      _showErrorSnackBar(l.enterNickname);
      return;
    }

    if (_pubgIdController.text.trim().isEmpty) {
      _showErrorSnackBar(l.enterPubgId);
      return;
    }

    if (widget.currentCoins < _selectedCoins!) {
      _showErrorSnackBar(l.notEnoughCoins);
      return;
    }

    try {
      final success = await widget.firestoreService.exchangeForUC(
        widget.uid,
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
          _showErrorSnackBar(l.exchangeFailed);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(l.errorOccurred(e.toString()));
      }
    }
  }

  void _showSuccessDialog() {
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
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
            Text(
              l.success,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.ucExchangeRequestAccepted,
              style: const TextStyle(color: AppColors.textPrimary),
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
                    l.info,
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
                    l.amount(_selectedCoins!, _selectedUC!),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.adminReviewNote,
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
            child: Text(l.ok),
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
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        l.ucExchange,
        style: const TextStyle(color: AppColors.textPrimary),
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
                    l.available(widget.currentCoins),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.selectExchangeAmount,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...FirestoreService.ucExchangeRates.entries.map((entry) {
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
                              l.notEnough,
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
            Text(
              l.enterYourInfo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nicknameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: l.nickname,
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
                labelText: l.pubgId,
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
          child: Text(
            l.cancel,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _confirmExchange,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
          child: Text(l.exchange),
        ),
      ],
    );
  }
}
