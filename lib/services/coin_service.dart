import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CoinService {
  static const int coinsPerAd = 5; // Changed from 10 to 5
  static const int maxDailyAds = 10;
  static const int maxDailyGames = 20;
  static const int maxCoinsPerGame = 10;

  // UC exchange rates
  static const Map<int, int> ucExchangeRates = {
    8000: 325, // 100 coins = 10 UC
    10000: 660, // 250 coins = 30 UC
    20000: 1200, // 500 coins = 60 UC
    30000: 2500, // 1000 coins = 120 UC
    40000: 3000, // 2000 coins = 250 UC
    100000: 5000,
  };

  static const String _coinsKey = 'coins';
  static const String _lastResetDateKey = 'last_reset_date';
  static const String _dailyAdsKey = 'daily_ads';
  static const String _dailyGamesKey = 'daily_games';
  static const String _exchangeHistoryKey = 'exchange_history';

  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  // Get current coins
  Future<int> getCoins() async {
    try {
      final prefs = await _prefs;
      return prefs.getInt(_coinsKey) ?? 0;
    } catch (e) {
      print('Error getting coins: $e');
      return 0;
    }
  }

  // getCurrentCoins method for compatibility
  Future<int> getCurrentCoins() async {
    return await getCoins();
  }

  // Add coins
  Future<void> addCoins(int amount) async {
    try {
      final prefs = await _prefs;
      final currentCoins = await getCoins();
      await prefs.setInt(_coinsKey, currentCoins + amount);
      print('Added $amount coins. Total: ${currentCoins + amount}');
    } catch (e) {
      print('Error adding coins: $e');
    }
  }

  // Spend coins
  Future<bool> spendCoins(int amount) async {
    try {
      final currentCoins = await getCoins();
      if (currentCoins >= amount) {
        final prefs = await _prefs;
        await prefs.setInt(_coinsKey, currentCoins - amount);
        print('Spent $amount coins. Remaining: ${currentCoins - amount}');
        return true;
      }
      print('Not enough coins. Current: $currentCoins, Required: $amount');
      return false;
    } catch (e) {
      print('Error spending coins: $e');
      return false;
    }
  }

  // Check if daily reset is needed
  Future<void> _checkDailyReset() async {
    try {
      final prefs = await _prefs;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final lastResetString = prefs.getString(_lastResetDateKey);
      DateTime? lastReset;

      if (lastResetString != null) {
        lastReset = DateTime.tryParse(lastResetString);
      }

      if (lastReset == null || lastReset.isBefore(today)) {
        // Reset daily counters
        await prefs.setInt(_dailyAdsKey, 0);
        await prefs.setInt(_dailyGamesKey, 0);
        await prefs.setString(_lastResetDateKey, today.toIso8601String());
        print('Daily counters reset for ${today.toIso8601String()}');
      }
    } catch (e) {
      print('Error checking daily reset: $e');
    }
  }

  // Get daily status
  Future<Map<String, dynamic>?> getDailyStatus() async {
    try {
      await _checkDailyReset();
      final prefs = await _prefs;

      final adsWatched = prefs.getInt(_dailyAdsKey) ?? 0;
      final gamesPlayed = prefs.getInt(_dailyGamesKey) ?? 0;

      return {
        'adsWatched': adsWatched,
        'maxAds': maxDailyAds,
        'canWatchAd': adsWatched < maxDailyAds,
        'gamesPlayed': gamesPlayed,
        'maxGames': maxDailyGames,
        'canPlayGame': gamesPlayed < maxDailyGames,
        'adsRemaining': maxDailyAds - adsWatched,
        'gamesRemaining': maxDailyGames - gamesPlayed,
      };
    } catch (e) {
      print('Error getting daily status: $e');
      return null;
    }
  }

  // Can watch ad?
  Future<bool> canWatchAd() async {
    try {
      final status = await getDailyStatus();
      return status?['canWatchAd'] ?? false;
    } catch (e) {
      print('Error checking if can watch ad: $e');
      return false;
    }
  }

  // Can play game?
  Future<bool> canPlayGame() async {
    try {
      final status = await getDailyStatus();
      return status?['canPlayGame'] ?? false;
    } catch (e) {
      print('Error checking if can play game: $e');
      return false;
    }
  }

  // Add coins for watching ad
  Future<bool> addCoinsForAd() async {
    try {
      await _checkDailyReset();
      final prefs = await _prefs;

      final adsWatched = prefs.getInt(_dailyAdsKey) ?? 0;
      if (adsWatched < maxDailyAds) {
        await addCoins(coinsPerAd);
        await prefs.setInt(_dailyAdsKey, adsWatched + 1);
        print(
          'Added $coinsPerAd coins for watching ad. Ads watched today: ${adsWatched + 1}',
        );
        return true;
      } else {
        print('Daily ad limit reached');
        return false;
      }
    } catch (e) {
      print('Error adding coins for ad: $e');
      return false;
    }
  }

  // Add coins for game result
  Future<bool> addCoinsForGameResult(double accuracy) async {
    try {
      await _checkDailyReset();
      final prefs = await _prefs;

      final gamesPlayed = prefs.getInt(_dailyGamesKey) ?? 0;
      if (gamesPlayed < maxDailyGames) {
        // Calculate coins based on accuracy (0-10 coins)
        final coinsEarned = (accuracy / 10).round().clamp(0, maxCoinsPerGame);
        await addCoins(coinsEarned);
        await prefs.setInt(_dailyGamesKey, gamesPlayed + 1);
        print(
          'Added $coinsEarned coins for game result. Accuracy: ${accuracy.toStringAsFixed(1)}%. Games played today: ${gamesPlayed + 1}',
        );
        return true;
      } else {
        print('Daily game limit reached');
        return false;
      }
    } catch (e) {
      print('Error adding coins for game result: $e');
      return false;
    }
  }

  // Exchange coins for UC
  Future<bool> exchangeForUC(
    int coins,
    int ucAmount,
    String nickname,
    String pubgId,
  ) async {
    try {
      final canAfford = await spendCoins(coins);
      if (canAfford) {
        // Save exchange history
        await _saveExchangeHistory(coins, ucAmount, nickname, pubgId);
        print(
          'Exchanged $coins coins for $ucAmount UC. Nickname: $nickname, PUBG ID: $pubgId',
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Error exchanging coins for UC: $e');
      return false;
    }
  }

  // Save exchange history
  Future<void> _saveExchangeHistory(
    int coins,
    int ucAmount,
    String nickname,
    String pubgId,
  ) async {
    try {
      final prefs = await _prefs;
      final historyJson = prefs.getString(_exchangeHistoryKey) ?? '[]';
      final List<dynamic> history = json.decode(historyJson);

      final exchange = {
        'coins': coins,
        'ucAmount': ucAmount,
        'nickname': nickname,
        'pubgId': pubgId,
        'date': DateTime.now().toIso8601String(),
        'status': 'pending', // pending, completed, failed
      };

      history.insert(0, exchange); // Add to beginning

      // Keep only last 20 exchanges
      if (history.length > 20) {
        history.removeRange(20, history.length);
      }

      await prefs.setString(_exchangeHistoryKey, json.encode(history));
      print('Exchange history saved');
    } catch (e) {
      print('Error saving exchange history: $e');
    }
  }

  // Get exchange history
  Future<List<Map<String, dynamic>>> getExchangeHistory() async {
    try {
      final prefs = await _prefs;
      final historyJson = prefs.getString(_exchangeHistoryKey) ?? '[]';
      final List<dynamic> history = json.decode(historyJson);

      return history.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Error getting exchange history: $e');
      return [];
    }
  }

  // Get today's statistics
  Future<Map<String, dynamic>> getTodayStats() async {
    try {
      await _checkDailyReset();
      final prefs = await _prefs;

      final adsWatched = prefs.getInt(_dailyAdsKey) ?? 0;
      final gamesPlayed = prefs.getInt(_dailyGamesKey) ?? 0;
      final currentCoins = await getCoins();

      // Calculate potential coins from remaining activities
      final remainingAds = maxDailyAds - adsWatched;
      final remainingGames = maxDailyGames - gamesPlayed;

      final maxPossibleCoinsFromAds = remainingAds * coinsPerAd;
      final maxPossibleCoinsFromGames = remainingGames * maxCoinsPerGame;

      return {
        'currentCoins': currentCoins,
        'adsWatched': adsWatched,
        'maxAds': maxDailyAds,
        'remainingAds': remainingAds,
        'gamesPlayed': gamesPlayed,
        'maxGames': maxDailyGames,
        'remainingGames': remainingGames,
        'maxPossibleCoinsFromAds': maxPossibleCoinsFromAds,
        'maxPossibleCoinsFromGames': maxPossibleCoinsFromGames,
        'totalMaxPossibleCoins':
            maxPossibleCoinsFromAds + maxPossibleCoinsFromGames,
      };
    } catch (e) {
      print('Error getting today stats: $e');
      return {};
    }
  }

  // Reset all data (for debugging)
  Future<void> resetAllData() async {
    try {
      final prefs = await _prefs;
      await prefs.remove(_coinsKey);
      await prefs.remove(_lastResetDateKey);
      await prefs.remove(_dailyAdsKey);
      await prefs.remove(_dailyGamesKey);
      await prefs.remove(_exchangeHistoryKey);
      print('All coin service data reset');
    } catch (e) {
      print('Error resetting data: $e');
    }
  }

  // Get detailed status for debugging
  Future<Map<String, dynamic>> getDebugInfo() async {
    try {
      final prefs = await _prefs;
      final now = DateTime.now();

      return {
        'currentTime': now.toIso8601String(),
        'coins': await getCoins(),
        'lastResetDate': prefs.getString(_lastResetDateKey),
        'dailyAds': prefs.getInt(_dailyAdsKey) ?? 0,
        'dailyGames': prefs.getInt(_dailyGamesKey) ?? 0,
        'exchangeHistoryCount': (await getExchangeHistory()).length,
        'canWatchAd': await canWatchAd(),
        'canPlayGame': await canPlayGame(),
      };
    } catch (e) {
      print('Error getting debug info: $e');
      return {'error': e.toString()};
    }
  }
}
