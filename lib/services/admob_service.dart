import 'dart:ui';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  // ✅ ANDROID Production ad unit IDs - sizning haqiqiy ID laringiz
  static const String _androidBannerAdUnitId =
      'ca-app-pub-6629898898338853/3062672177';
  static const String _androidInterstitialAdUnitId =
      'ca-app-pub-6629898898338853/8238993146';
  static const String _androidRewardedAdUnitId =
      'ca-app-pub-6629898898338853/6856277647';

  // Test ad unit IDs for development
  static const String _testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  // ✅ PRODUCTION uchun false qiling, TEST uchun true
  static const bool _isTestMode = false;

  // Platform-specific ad unit IDs
  static String get bannerAdUnitId {
    if (_isTestMode) {
      return _testBannerAdUnitId;
    }
    // Android uchun sizning ID laringiz
    return _androidBannerAdUnitId;
  }

  static String get interstitialAdUnitId {
    if (_isTestMode) {
      return _testInterstitialAdUnitId;
    }
    return _androidInterstitialAdUnitId;
  }

  static String get rewardedAdUnitId {
    if (_isTestMode) {
      return _testRewardedAdUnitId;
    }
    return _androidRewardedAdUnitId;
  }

  static InterstitialAd? _interstitialAd;
  static RewardedAd? _rewardedAd;
  static bool _isInterstitialAdReady = false;
  static bool _isRewardedAdReady = false;
  static bool _isInitialized = false;

  // Ad loading states
  static bool _isLoadingInterstitial = false;
  static bool _isLoadingRewarded = false;

  // ✅ AdMob ni to'g'ri initialize qilish
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('AdMob initializing...');
      await MobileAds.instance.initialize();

      // Request configuration for better ad loading
      final RequestConfiguration requestConfiguration = RequestConfiguration(
        testDeviceIds: _isTestMode ? ['YOUR_TEST_DEVICE_ID'] : null,
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
      );
      MobileAds.instance.updateRequestConfiguration(requestConfiguration);

      _isInitialized = true;
      print('AdMob initialized successfully');

      // Load ads after initialization
      loadInterstitialAd();
      loadRewardedAd();
    } catch (e) {
      print('AdMob initialization failed: $e');
      _isInitialized = false;
    }
  }

  // ✅ Interstitial ad yuklash
  static void loadInterstitialAd() async {
    if (!_isInitialized) {
      print('AdMob not initialized yet');
      return;
    }

    if (_isLoadingInterstitial || _isInterstitialAdReady) {
      print('Interstitial ad already loading or ready');
      return;
    }

    _isLoadingInterstitial = true;
    print('Loading interstitial ad...');

    try {
      await InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            print('Interstitial ad loaded successfully');
            _interstitialAd?.dispose();
            _interstitialAd = ad;
            _isInterstitialAdReady = true;
            _isLoadingInterstitial = false;

            _interstitialAd!.setImmersiveMode(true);
            _interstitialAd!
                .fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (InterstitialAd ad) {
                print('Interstitial ad showed full screen');
              },
              onAdDismissedFullScreenContent: (InterstitialAd ad) {
                print('Interstitial ad dismissed');
                ad.dispose();
                _interstitialAd = null;
                _isInterstitialAdReady = false;
                // Load next ad with delay
                Future.delayed(const Duration(seconds: 2), () {
                  loadInterstitialAd();
                });
              },
              onAdFailedToShowFullScreenContent:
                  (InterstitialAd ad, AdError error) {
                    print('Interstitial ad failed to show: ${error.message}');
                    ad.dispose();
                    _interstitialAd = null;
                    _isInterstitialAdReady = false;
                    // Try to load again
                    Future.delayed(const Duration(seconds: 3), () {
                      loadInterstitialAd();
                    });
                  },
            );
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('Interstitial ad failed to load: ${error.message}');
            _isInterstitialAdReady = false;
            _isLoadingInterstitial = false;
            // Retry after delay
            Future.delayed(const Duration(seconds: 30), () {
              loadInterstitialAd();
            });
          },
        ),
      );
    } catch (e) {
      print('Error loading interstitial ad: $e');
      _isLoadingInterstitial = false;
      _isInterstitialAdReady = false;
    }
  }

  // ✅ Rewarded ad yuklash
  static void loadRewardedAd() async {
    if (!_isInitialized) {
      print('AdMob not initialized yet');
      return;
    }

    if (_isLoadingRewarded || _isRewardedAdReady) {
      print('Rewarded ad already loading or ready');
      return;
    }

    _isLoadingRewarded = true;
    print('Loading rewarded ad...');

    try {
      await RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            print('Rewarded ad loaded successfully');
            _rewardedAd?.dispose();
            _rewardedAd = ad;
            _isRewardedAdReady = true;
            _isLoadingRewarded = false;

            _rewardedAd!.setImmersiveMode(true);
            _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (RewardedAd ad) {
                print('Rewarded ad showed full screen');
              },
              onAdDismissedFullScreenContent: (RewardedAd ad) {
                print('Rewarded ad dismissed');
                ad.dispose();
                _rewardedAd = null;
                _isRewardedAdReady = false;
                // Load next ad with delay
                Future.delayed(const Duration(seconds: 2), () {
                  loadRewardedAd();
                });
              },
              onAdFailedToShowFullScreenContent:
                  (RewardedAd ad, AdError error) {
                    print('Rewarded ad failed to show: ${error.message}');
                    ad.dispose();
                    _rewardedAd = null;
                    _isRewardedAdReady = false;
                    // Try to load again
                    Future.delayed(const Duration(seconds: 3), () {
                      loadRewardedAd();
                    });
                  },
            );
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('Rewarded ad failed to load: ${error.message}');
            _isRewardedAdReady = false;
            _isLoadingRewarded = false;
            // Retry after delay
            Future.delayed(const Duration(seconds: 30), () {
              loadRewardedAd();
            });
          },
        ),
      );
    } catch (e) {
      print('Error loading rewarded ad: $e');
      _isLoadingRewarded = false;
      _isRewardedAdReady = false;
    }
  }

  // ✅ Interstitial ad ko'rsatish
  static Future<bool> showInterstitialAd() async {
    if (!_isInitialized) {
      print('AdMob not initialized');
      await initialize();
      return false;
    }

    if (_isInterstitialAdReady && _interstitialAd != null) {
      print('Showing interstitial ad');
      try {
        await _interstitialAd!.show();
        return true;
      } catch (e) {
        print('Error showing interstitial ad: $e');
        return false;
      }
    } else {
      print('Interstitial ad is not ready yet');
      if (!_isLoadingInterstitial) {
        loadInterstitialAd(); // Try to load if not ready
      }
      return false;
    }
  }

  // ✅ Rewarded ad ko'rsatish
  static Future<bool> showRewardedAd({
    required Function(RewardItem) onUserEarnedReward,
    required VoidCallback onRewardEarned,
    required VoidCallback onFailed,
  }) async {
    if (!_isInitialized) {
      print('AdMob not initialized');
      await initialize();
      onFailed();
      return false;
    }

    if (_isRewardedAdReady && _rewardedAd != null) {
      print('Showing rewarded ad');
      bool rewardGranted = false;

      try {
        await _rewardedAd!.show(
          onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
            print('User earned reward: ${reward.amount} ${reward.type}');
            rewardGranted = true;
            onUserEarnedReward(reward);
            onRewardEarned();
          },
        );

        // Wait a bit to ensure callback is processed
        await Future.delayed(const Duration(milliseconds: 500));

        if (!rewardGranted) {
          print('Reward was not granted');
          onFailed();
        }

        return rewardGranted;
      } catch (e) {
        print('Error showing rewarded ad: $e');
        onFailed();
        return false;
      }
    } else {
      print('Rewarded ad is not ready yet');
      if (!_isLoadingRewarded) {
        loadRewardedAd();
      }
      onFailed();
      return false;
    }
  }

  // ✅ Banner ad yaratish
  static BannerAd createBannerAd({
    AdSize adSize = AdSize.banner,
    required void Function(Ad, LoadAdError) onAdFailedToLoad,
    required void Function(Ad) onAdLoaded,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
        onAdOpened: (Ad ad) => print('Banner ad opened'),
        onAdClosed: (Ad ad) => print('Banner ad closed'),
      ),
    );
  }

  // ✅ Status getter methods
  static bool get isInterstitialAdReady =>
      _isInterstitialAdReady && _interstitialAd != null;
  static bool get isRewardedAdReady =>
      _isRewardedAdReady && _rewardedAd != null;
  static bool get isInitialized => _isInitialized;

  // ✅ Loading states
  static bool get isLoadingInterstitial => _isLoadingInterstitial;
  static bool get isLoadingRewarded => _isLoadingRewarded;

  // ✅ Debug ma'lumotlari
  static void printStatus() {
    print('=== AdMob Status ===');
    print('Initialized: $_isInitialized');
    print('Test Mode: $_isTestMode');
    print('Interstitial Ready: $isInterstitialAdReady');
    print('Interstitial Loading: $_isLoadingInterstitial');
    print('Rewarded Ready: $isRewardedAdReady');
    print('Rewarded Loading: $_isLoadingRewarded');
    print('Banner Ad Unit: $bannerAdUnitId');
    print('Interstitial Ad Unit: $interstitialAdUnitId');
    print('Rewarded Ad Unit: $rewardedAdUnitId');
    print('==================');
  }

  // ✅ Resources ni tozalash
  static void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _interstitialAd = null;
    _rewardedAd = null;
    _isInterstitialAdReady = false;
    _isRewardedAdReady = false;
    _isLoadingInterstitial = false;
    _isLoadingRewarded = false;
  }
}
