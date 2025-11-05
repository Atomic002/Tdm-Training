import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/admob_service.dart';
import '../utils/app_colors.dart';

class AdBannerWidget extends StatefulWidget {
  final AdSize adSize;
  final EdgeInsets? margin;
  final bool showBorder;

  const AdBannerWidget({
    super.key,
    this.adSize = AdSize.banner,
    this.margin,
    this.showBorder = true,
  });

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  bool _isLoading = false;
  bool _hasError = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndLoadAd();
    });
  }

  @override
  void dispose() {
    _disposeBannerAd();
    super.dispose();
  }

  void _disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  Future<void> _initializeAndLoadAd() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // AdMobService initialization check
      if (!AdMobService.isInitialized) {
        debugPrint('AdBannerWidget: Initializing AdMobService...');
        await AdMobService.initialize();

        if (!mounted) return;

        // Wait a bit for initialization to complete
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (mounted && AdMobService.isInitialized) {
        _loadBannerAd();
      } else {
        _handleAdError('AdMobService initialization failed');
      }
    } catch (e) {
      debugPrint('AdBannerWidget: Error initializing AdMobService: $e');
      _handleAdError('Initialization error');
    }
  }

  void _loadBannerAd() {
    if (!mounted) return;

    if (_retryCount >= _maxRetries) {
      debugPrint('AdBannerWidget: Max retries reached. Stopping ad load.');
      _handleAdError('Max retries reached');
      return;
    }

    if (!AdMobService.isInitialized) {
      debugPrint('AdBannerWidget: AdMobService not initialized, retrying...');
      _scheduleRetry();
      return;
    }

    // Check if banner ad unit ID is available
    final bannerAdUnitId = AdMobService.bannerAdUnitId;
    if (bannerAdUnitId.isEmpty) {
      debugPrint('AdBannerWidget: Banner ad unit ID is empty');
      _handleAdError('Ad unit ID not available');
      return;
    }

    debugPrint(
      'AdBannerWidget: Loading banner ad (Attempt ${_retryCount + 1}/$_maxRetries)...',
    );

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    // Dispose existing ad
    _disposeBannerAd();

    // Create new banner ad
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: _onAdLoaded,
        onAdFailedToLoad: _onAdFailedToLoad,
        onAdOpened: (Ad ad) => debugPrint('AdBannerWidget: Banner ad opened'),
        onAdClosed: (Ad ad) => debugPrint('AdBannerWidget: Banner ad closed'),
        onAdImpression: (Ad ad) =>
            debugPrint('AdBannerWidget: Banner ad impression'),
        onAdWillDismissScreen: (Ad ad) =>
            debugPrint('AdBannerWidget: Banner ad will dismiss screen'),
      ),
    );

    _bannerAd!.load();
  }

  void _onAdLoaded(Ad ad) {
    debugPrint('AdBannerWidget: Banner ad loaded successfully');
    if (mounted) {
      setState(() {
        _isBannerAdReady = true;
        _isLoading = false;
        _hasError = false;
        _retryCount = 0; // Reset retry count on success
      });
    }
  }

  void _onAdFailedToLoad(Ad ad, LoadAdError error) {
    debugPrint(
      'AdBannerWidget: Banner ad failed to load: ${error.message} (Code: ${error.code})',
    );
    ad.dispose();

    if (mounted) {
      _retryCount++;

      if (_retryCount < _maxRetries) {
        debugPrint(
          'AdBannerWidget: Scheduling retry ${_retryCount + 1}/$_maxRetries',
        );
        _scheduleRetry();
      } else {
        debugPrint('AdBannerWidget: Max retry limit reached');
        _handleAdError('Failed to load after $_maxRetries attempts');
      }
    }
  }

  void _scheduleRetry() {
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _hasError = false;
    });

    // Exponential backoff
    final delay = Duration(
      seconds: _baseRetryDelay.inSeconds * (_retryCount + 1),
    );

    debugPrint('AdBannerWidget: Retrying in ${delay.inSeconds} seconds...');

    Future.delayed(delay, () {
      if (mounted) {
        _loadBannerAd();
      }
    });
  }

  void _handleAdError(String message) {
    if (!mounted) return;

    setState(() {
      _isBannerAdReady = false;
      _isLoading = false;
      _hasError = true;
    });

    debugPrint('AdBannerWidget: $message');
  }

  void refreshAd() {
    if (!mounted) return;

    debugPrint('AdBannerWidget: Manual refresh requested');
    _retryCount = 0;
    _initializeAndLoadAd();
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: widget.adSize.height.toDouble(),
      margin: widget.margin,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: widget.showBorder
            ? Border.all(color: AppColors.primary.withOpacity(0.1), width: 1)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reklama yuklanmoqda...',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      height: widget.adSize.height.toDouble(),
      margin: widget.margin,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: widget.showBorder
            ? Border.all(color: AppColors.primary.withOpacity(0.1), width: 1)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.textSecondary.withOpacity(0.4),
              size: 16,
            ),
            Text(
              'Reklama yuklanmadi',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.6),
                fontSize: 10,
              ),
            ),
            GestureDetector(
              onTap: refreshAd,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Qayta urinish',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdWidget() {
    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      margin: widget.margin,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: widget.showBorder
            ? Border.all(color: AppColors.primary.withOpacity(0.2), width: 1)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.showBorder ? 7 : 0),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while AdMobService is initializing
    if (!AdMobService.isInitialized && !_hasError) {
      return _buildLoadingWidget();
    }

    // Show loading while ad is loading
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    // Show ad if ready
    if (_isBannerAdReady && _bannerAd != null) {
      return _buildAdWidget();
    }

    // Show error state
    return _buildErrorWidget();
  }
}
