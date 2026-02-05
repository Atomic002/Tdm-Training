import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import '../models/task_model.dart';
import '../models/exchange_model.dart';
import '../models/task_completion_model.dart';
import '../models/announcement_model.dart';
import '../models/uc_order_model.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Constants
  static const int coinsPerAd = 5;
  static const int maxDailyAds = 15;
  static const int maxDailyReactionGames = 30;
  static const int maxDailyMiniPubgGames = 20;
  static const int maxCoinsPerGame = 10;

  // Cache
  AppUser? _cachedUser;
  String? _cachedUserId;
  DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 3);
  bool? _cachedIsAdmin;
  String? _adminCacheUid;

  static const Map<int, int> ucExchangeRates = {
    8500: 60,      // 10 UC
    13000: 120,     // 20 UC
    18000: 325,    // 325 UC
    22000: 660,    // 660 UC    // 660 UC
    40000: 1200,   // 1200 UC
    60000: 2500,   // 2500 UC
    80000: 3000,   // 3000 UC
    160000: 5000,  // 5000 UC
  };

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  // ==================== USER OPERATIONS ====================

  Future<void> createOrUpdateUser(User firebaseUser) async {
    final docRef = _db.collection('users').doc(firebaseUser.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      // Yangi user — SharedPreferences dan migration
      int migratedCoins = 0;
      try {
        final prefs = await SharedPreferences.getInstance();
        migratedCoins = prefs.getInt('coins') ?? 0;
        if (migratedCoins > 0) {
          await prefs.remove('coins');
          await prefs.remove('last_reset_date');
          await prefs.remove('daily_ads');
          await prefs.remove('daily_games');
          await prefs.remove('exchange_history');
        }
      } catch (_) {}

      final newUser = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? '',
        photoUrl: firebaseUser.photoURL,
        coins: migratedCoins,
        totalCoinsEarned: migratedCoins,
        referralCode: AppUser.generateReferralCode(),
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      await docRef.set(newUser.toFirestore());
    } else {
      // Mavjud user — faqat login vaqtini yangilash
      await docRef.update({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'displayName': firebaseUser.displayName ?? '',
        'photoUrl': firebaseUser.photoURL,
        'email': firebaseUser.email ?? '',
      });
    }
  }

  Future<AppUser?> getUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  Stream<AppUser?> userStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Tranzaksiya ichida daily reset tekshiradi.
  /// [data] - hozirgi snapshot ma'lumotlari
  /// Qaytaradi: reset kerakmi yoki yo'q
  bool _needsDailyReset(Map<String, dynamic> data) {
    final lastReset = (data['lastResetDate'] as Timestamp?)?.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (lastReset == null) return true;
    return DateTime(lastReset.year, lastReset.month, lastReset.day)
        .isBefore(today);
  }

  /// Tranzaksiya ichida daily reset qiladi (agar kerak bo'lsa).
  /// Bu eski _checkAndResetDaily o'rniga ishlatiladi.
  Map<String, dynamic> _buildDailyResetFields() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return {
      'dailyAds': 0,
      'dailyReactionGames': 0,
      'dailyMiniPubgGames': 0,
      'lastResetDate': Timestamp.fromDate(today),
    };
  }

  // ==================== COIN OPERATIONS ====================

  Future<int> getCoins() async {
    if (_currentUid == null) return 0;
    try {
      // Keshdan olish (3 daqiqa ichida)
      if (_cachedUserId == _currentUid &&
          _cachedUser != null &&
          _cacheTime != null &&
          DateTime.now().difference(_cacheTime!) < _cacheDuration) {
        return _cachedUser!.coins;
      }
      final user = await getUser(_currentUid!);
      if (user != null) {
        _cachedUser = user;
        _cachedUserId = _currentUid;
        _cacheTime = DateTime.now();
      }
      return user?.coins ?? 0;
    } catch (e) {
      print('Error getting coins: $e');
      return 0;
    }
  }

  Future<void> addCoins(String uid, int amount) async {
    try {
      await _db.collection('users').doc(uid).update({
        'coins': FieldValue.increment(amount),
        'totalCoinsEarned': FieldValue.increment(amount),
      });
    } catch (e) {
      print('Error adding coins: $e');
    }
  }

  Future<bool> spendCoins(String uid, int amount) async {
    try {
      return await _db.runTransaction((transaction) async {
        final docRef = _db.collection('users').doc(uid);
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return false;

        final currentCoins = snapshot.data()?['coins'] ?? 0;
        if (currentCoins < amount) return false;

        transaction.update(docRef, {
          'coins': FieldValue.increment(-amount),
        });
        return true;
      });
    } catch (e) {
      print('Error spending coins: $e');
      return false;
    }
  }

  Future<bool> addCoinsForAd(String uid) async {
    try {
      return await _db.runTransaction((transaction) async {
        final docRef = _db.collection('users').doc(uid);
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return false;

        final data = snapshot.data()!;
        final Map<String, dynamic> updates = {};

        // Daily reset tranzaksiya ichida
        if (_needsDailyReset(data)) {
          updates.addAll(_buildDailyResetFields());
          // Reset bo'lganda dailyAds = 0 hisoblanadi
          updates['coins'] = FieldValue.increment(coinsPerAd);
          updates['totalCoinsEarned'] = FieldValue.increment(coinsPerAd);
          updates['dailyAds'] = 1; // 0 dan 1 ga
          transaction.update(docRef, updates);
          return true;
        }

        final dailyAds = data['dailyAds'] ?? 0;
        if (dailyAds >= maxDailyAds) return false;

        transaction.update(docRef, {
          'coins': FieldValue.increment(coinsPerAd),
          'totalCoinsEarned': FieldValue.increment(coinsPerAd),
          'dailyAds': FieldValue.increment(1),
        });
        return true;
      });
    } catch (e) {
      print('Error adding coins for ad: $e');
      return false;
    }
  }

  /// O'yin natijasiga qarab coin qo'shish (accuracy 0-100 foiz)
  Future<bool> addCoinsForGame(String uid, double accuracy, {bool isMiniPubg = false}) async {
    try {
      final coinsEarned =
          (accuracy / 10).round().clamp(0, maxCoinsPerGame);
      return await addCoinsForGameDirect(uid, coinsEarned, isMiniPubg: isMiniPubg);
    } catch (e) {
      print('Error adding coins for game: $e');
      return false;
    }
  }

  /// To'g'ridan-to'g'ri coin miqdorini qo'shish
  /// [isMiniPubg] = true bo'lsa Mini PUBG (20 limit), false bo'lsa Reaksiya (30 limit)
  Future<bool> addCoinsForGameDirect(String uid, int coins, {bool isMiniPubg = false}) async {
    try {
      final fieldName = isMiniPubg ? 'dailyMiniPubgGames' : 'dailyReactionGames';
      final maxGames = isMiniPubg ? maxDailyMiniPubgGames : maxDailyReactionGames;

      return await _db.runTransaction((transaction) async {
        final docRef = _db.collection('users').doc(uid);
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return false;

        final data = snapshot.data()!;
        final Map<String, dynamic> updates = {};

        // Daily reset tranzaksiya ichida
        if (_needsDailyReset(data)) {
          updates.addAll(_buildDailyResetFields());
          if (coins > 0) {
            updates['coins'] = FieldValue.increment(coins);
            updates['totalCoinsEarned'] = FieldValue.increment(coins);
          }
          updates[fieldName] = 1;
          transaction.update(docRef, updates);
          return true;
        }

        final dailyGames = data[fieldName] ?? 0;
        if (dailyGames >= maxGames) return false;

        final Map<String, dynamic> gameUpdates = {
          fieldName: FieldValue.increment(1),
        };
        if (coins > 0) {
          gameUpdates['coins'] = FieldValue.increment(coins);
          gameUpdates['totalCoinsEarned'] = FieldValue.increment(coins);
        }
        transaction.update(docRef, gameUpdates);
        return true;
      });
    } catch (e) {
      print('Error adding coins for game direct: $e');
      return false;
    }
  }

  /// Daily status olish - 1 ta read bilan
  /// [isMiniPubg] = true bo'lsa Mini PUBG statusi, false bo'lsa Reaksiya
  Future<Map<String, dynamic>> getDailyStatus(String uid, {bool isMiniPubg = false}) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return {};

      final data = doc.data()!;

      int dailyAds;
      int dailyReactionGames;
      int dailyMiniPubgGames;

      if (_needsDailyReset(data)) {
        dailyAds = 0;
        dailyReactionGames = 0;
        dailyMiniPubgGames = 0;
      } else {
        dailyAds = data['dailyAds'] ?? 0;
        dailyReactionGames = data['dailyReactionGames'] ?? 0;
        dailyMiniPubgGames = data['dailyMiniPubgGames'] ?? 0;
      }

      // Keshni yangilash
      _cachedUser = AppUser.fromFirestore(doc);
      _cachedUserId = uid;
      _cacheTime = DateTime.now();

      final gamesPlayed = isMiniPubg ? dailyMiniPubgGames : dailyReactionGames;
      final maxGames = isMiniPubg ? maxDailyMiniPubgGames : maxDailyReactionGames;

      return {
        'adsWatched': dailyAds,
        'maxAds': maxDailyAds,
        'canWatchAd': dailyAds < maxDailyAds,
        'gamesPlayed': gamesPlayed,
        'maxGames': maxGames,
        'canPlayGame': gamesPlayed < maxGames,
        'adsRemaining': maxDailyAds - dailyAds,
        'gamesRemaining': maxGames - gamesPlayed,
        // Har ikkala o'yin turi uchun
        'reactionGamesPlayed': dailyReactionGames,
        'miniPubgGamesPlayed': dailyMiniPubgGames,
        'maxReactionGames': maxDailyReactionGames,
        'maxMiniPubgGames': maxDailyMiniPubgGames,
      };
    } catch (e) {
      print('Error getting daily status: $e');
      return {};
    }
  }

  Future<bool> canWatchAd(String uid) async {
    final status = await getDailyStatus(uid);
    return status['canWatchAd'] ?? false;
  }

  /// [isMiniPubg] = true bo'lsa Mini PUBG, false bo'lsa Reaksiya
  Future<bool> canPlayGame(String uid, {bool isMiniPubg = false}) async {
    final status = await getDailyStatus(uid, isMiniPubg: isMiniPubg);
    return status['canPlayGame'] ?? false;
  }

  // ==================== EXCHANGE OPERATIONS ====================

  Future<bool> exchangeForUC(
    String uid,
    int coins,
    int ucAmount,
    String nickname,
    String pubgId,
  ) async {
    try {
      print('DEBUG [Exchange]: ========== UC ALMASHTIRISH BOSHLANDI ==========');
      print('DEBUG [Exchange]: User UID: $uid');
      print('DEBUG [Exchange]: Coins: $coins, UC: $ucAmount');
      print('DEBUG [Exchange]: Nickname: $nickname, PUBG ID: $pubgId');

      final spent = await spendCoins(uid, coins);
      if (!spent) {
        print('DEBUG [Exchange]: ❌ Coinlar sarflanmadi (yetarli emas yoki xato)');
        return false;
      }
      print('DEBUG [Exchange]: ✓ $coins coin sarflandi');

      final exchange = ExchangeModel(
        id: '',
        uid: uid,
        coins: coins,
        ucAmount: ucAmount,
        nickname: nickname,
        pubgId: pubgId,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      print('DEBUG [Exchange]: Firestore\'ga yozilmoqda: users/$uid/exchanges');
      final docRef = await _db
          .collection('users')
          .doc(uid)
          .collection('exchanges')
          .add(exchange.toFirestore());
      print('DEBUG [Exchange]: ✓ Exchange yaratildi, ID: ${docRef.id}');

      await _db.collection('users').doc(uid).update({
        'totalUCExchanged': FieldValue.increment(ucAmount),
      });
      print('DEBUG [Exchange]: ✓ totalUCExchanged yangilandi');
      print('DEBUG [Exchange]: ========== UC ALMASHTIRISH TUGADI (SUCCESS) ==========\n');

      return true;
    } catch (e, stackTrace) {
      print('DEBUG [Exchange]: ❌ UC ALMASHTIRISH XATOSI!');
      print('DEBUG [Exchange]: Xato: $e');
      print('DEBUG [Exchange]: Stack trace: $stackTrace');
      return false;
    }
  }

  Stream<List<ExchangeModel>> exchangeHistoryStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('exchanges')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExchangeModel.fromFirestore(doc))
            .toList());
  }

  Future<List<ExchangeModel>> getExchangeHistory(String uid) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('exchanges')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      return snapshot.docs
          .map((doc) => ExchangeModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting exchange history: $e');
      return [];
    }
  }

  // ==================== LEADERBOARD ====================

  Future<List<AppUser>> getLeaderboardByCoins({int limit = 50}) async {
    try {
      final snapshot = await _db
          .collection('users')
          .orderBy('coins', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting leaderboard by coins: $e');
      return [];
    }
  }

  Future<List<AppUser>> getLeaderboardByUC({int limit = 50}) async {
    try {
      final snapshot = await _db
          .collection('users')
          .orderBy('totalUCExchanged', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting leaderboard by UC: $e');
      return [];
    }
  }

  Future<int> getUserRank(String uid) async {
    try {
      final user = await getUser(uid);
      if (user == null) return 0;

      final snapshot = await _db
          .collection('users')
          .where('coins', isGreaterThan: user.coins)
          .count()
          .get();
      return (snapshot.count ?? 0) + 1;
    } catch (e) {
      print('Error getting user rank: $e');
      return 0;
    }
  }

  // ==================== TASK OPERATIONS ====================

  Stream<List<TaskModel>> activeTasks() {
    return _db
        .collection('tasks')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
  }

  Future<List<TaskModel>> getActiveTasks() async {
    try {
      print('DEBUG [FirestoreService]: tasks collection dan o\'qish boshlandi...');

      // Avval composite index bilan urinish (isActive + order)
      try {
        final snapshot = await _db
            .collection('tasks')
            .where('isActive', isEqualTo: true)
            .orderBy('order')
            .get();

        print('DEBUG [FirestoreService]: ${snapshot.docs.length} ta faol vazifa topildi (index bilan)');
        final tasks = snapshot.docs
            .map((doc) => TaskModel.fromFirestore(doc))
            .toList();

        return tasks;
      } catch (indexError) {
        // Agar composite index yo'q bo'lsa, faqat isActive filter ishlatamiz
        print('DEBUG [FirestoreService]: ⚠️ Composite index yo\'q, fallback query ishlatilmoqda...');
        print('DEBUG [FirestoreService]: Index xatosi: $indexError');

        final snapshot = await _db
            .collection('tasks')
            .where('isActive', isEqualTo: true)
            .get();

        print('DEBUG [FirestoreService]: ${snapshot.docs.length} ta faol vazifa topildi (fallback)');

        // In-memory sort qilamiz
        final tasks = snapshot.docs
            .map((doc) => TaskModel.fromFirestore(doc))
            .toList();

        tasks.sort((a, b) => a.order.compareTo(b.order));
        print('DEBUG [FirestoreService]: Vazifalar in-memory sort qilindi');

        return tasks;
      }
    } catch (e, stackTrace) {
      print('DEBUG [FirestoreService]: ❌ JIDDIY XATOLIK vazifalarni yuklashda!');
      print('DEBUG [FirestoreService]: Xato: $e');
      print('DEBUG [FirestoreService]: Stack trace: $stackTrace');

      // Oxirgi urinish - hech qanday filter yo'q
      try {
        print('DEBUG [FirestoreService]: Oxirgi urinish - barcha vazifalarni olish...');
        final snapshot = await _db.collection('tasks').get();
        print('DEBUG [FirestoreService]: Jami ${snapshot.docs.length} ta vazifa topildi (filter yo\'qsiz)');

        final tasks = snapshot.docs
            .map((doc) => TaskModel.fromFirestore(doc))
            .where((task) => task.isActive)
            .toList();

        tasks.sort((a, b) => a.order.compareTo(b.order));
        print('DEBUG [FirestoreService]: ${tasks.length} ta faol vazifa filtrlandi va sort qilindi');

        return tasks;
      } catch (finalError) {
        print('DEBUG [FirestoreService]: ❌ BARCHA URINISHLAR MUVAFFAQIYATSIZ!');
        print('DEBUG [FirestoreService]: Final xato: $finalError');
        return [];
      }
    }
  }

  Future<bool> completeTask(String uid, String taskId, int reward) async {
    try {
      final today =
          DateTime.now().toIso8601String().substring(0, 10);
      final completionId = '${uid}_${taskId}_$today';

      // Tekshirish — bugun bajarilganmi
      final existing =
          await _db.collection('task_completions').doc(completionId).get();
      if (existing.exists) return false;

      final completion = TaskCompletionModel(
        id: completionId,
        uid: uid,
        taskId: taskId,
        reward: reward,
        completedAt: DateTime.now(),
        date: today,
      );

      await _db
          .collection('task_completions')
          .doc(completionId)
          .set(completion.toFirestore());

      await addCoins(uid, reward);
      return true;
    } catch (e) {
      print('Error completing task: $e');
      return false;
    }
  }

  Future<bool> isTaskCompletedToday(String uid, String taskId) async {
    try {
      final today =
          DateTime.now().toIso8601String().substring(0, 10);
      final completionId = '${uid}_${taskId}_$today';
      final doc =
          await _db.collection('task_completions').doc(completionId).get();
      return doc.exists;
    } catch (e) {
      print('Error checking task completion: $e');
      return false;
    }
  }

  Future<Set<String>> getCompletedTaskIdsToday(String uid) async {
    try {
      final today =
          DateTime.now().toIso8601String().substring(0, 10);
      final snapshot = await _db
          .collection('task_completions')
          .where('uid', isEqualTo: uid)
          .where('date', isEqualTo: today)
          .get();
      return snapshot.docs.map((doc) => doc.data()['taskId'] as String).toSet();
    } catch (e) {
      print('Error getting completed tasks: $e');
      return {};
    }
  }

  // ==================== DAILY LOGIN ====================

  Future<int> processDailyLogin(String uid) async {
    try {
      final docRef = _db.collection('users').doc(uid);
      final doc = await docRef.get();
      if (!doc.exists) return 0;

      final data = doc.data()!;
      final lastBonus = (data['lastDailyBonusDate'] as Timestamp?)?.toDate();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (lastBonus != null) {
        final lastBonusDay =
            DateTime(lastBonus.year, lastBonus.month, lastBonus.day);
        if (!lastBonusDay.isBefore(today)) {
          // Bugun allaqachon bonus olgan
          return 0;
        }
      }

      // Login streak hisoblash
      int currentStreak = data['loginStreak'] ?? 0;
      if (lastBonus != null) {
        final yesterday = today.subtract(const Duration(days: 1));
        final lastBonusDay =
            DateTime(lastBonus.year, lastBonus.month, lastBonus.day);
        if (lastBonusDay.isAtSameMomentAs(yesterday)) {
          currentStreak++;
        } else {
          currentStreak = 1;
        }
      } else {
        currentStreak = 1;
      }

      // Streak bonusi — 7 kunlik tsikl
      final rewards = [10, 20, 30, 50, 75, 100, 150];
      final rewardIndex = (currentStreak - 1) % rewards.length;
      final reward = rewards[rewardIndex];

      await docRef.update({
        'loginStreak': currentStreak,
        'lastDailyBonusDate': Timestamp.fromDate(today),
        'coins': FieldValue.increment(reward),
        'totalCoinsEarned': FieldValue.increment(reward),
      });

      return reward;
    } catch (e) {
      print('Error processing daily login: $e');
      return 0;
    }
  }

  // ==================== REFERRAL SYSTEM ====================

  Future<bool> applyReferralCode(String uid, String code) async {
    try {
      final user = await getUser(uid);
      if (user == null || user.referredBy != null) return false;

      // Referral kodini topish
      final snapshot = await _db
          .collection('users')
          .where('referralCode', isEqualTo: code)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return false;

      final referrer = snapshot.docs.first;
      if (referrer.id == uid) return false; // O'ziga referral qilolmaydi

      // Referrer ga bonus
      await _db.collection('users').doc(referrer.id).update({
        'coins': FieldValue.increment(100),
        'totalCoinsEarned': FieldValue.increment(100),
        'referralCount': FieldValue.increment(1),
      });

      // Yangi user ga bonus
      await _db.collection('users').doc(uid).update({
        'coins': FieldValue.increment(50),
        'totalCoinsEarned': FieldValue.increment(50),
        'referredBy': referrer.id,
      });

      return true;
    } catch (e) {
      print('Error applying referral code: $e');
      return false;
    }
  }

  // ==================== ADMIN OPERATIONS ====================

  Future<bool> isAdmin(String uid) async {
    // Keshdan olish
    if (_adminCacheUid == uid && _cachedIsAdmin != null) {
      return _cachedIsAdmin!;
    }
    try {
      final user = await getUser(uid);
      _cachedIsAdmin = user?.isAdmin ?? false;
      _adminCacheUid = uid;
      return _cachedIsAdmin!;
    } catch (e) {
      return false;
    }
  }

  Future<List<AppUser>> getAllUsers({String? searchQuery}) async {
    try {
      Query query = _db.collection('users').orderBy('lastLoginAt', descending: true);

      final snapshot = await query.get();
      var users =
          snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        users = users
            .where((u) =>
                u.displayName.toLowerCase().contains(q) ||
                u.email.toLowerCase().contains(q))
            .toList();
      }

      return users;
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  Future<int> getTotalUsersCount() async {
    try {
      final snapshot = await _db.collection('users').count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting total users count: $e');
      return 0;
    }
  }

  Future<int> getActiveUsersToday() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final snapshot = await _db
          .collection('users')
          .where('lastLoginAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting active users: $e');
      return 0;
    }
  }

  Future<void> updateExchangeStatus(
    String uid,
    String exchangeId,
    String status,
    String adminUid,
  ) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('exchanges')
          .doc(exchangeId)
          .update({
        'status': status,
        'processedAt': FieldValue.serverTimestamp(),
        'processedBy': adminUid,
      });

      // Rad etilgan bo'lsa, coinlarni qaytarish
      if (status == 'rejected') {
        final exchangeDoc = await _db
            .collection('users')
            .doc(uid)
            .collection('exchanges')
            .doc(exchangeId)
            .get();
        if (exchangeDoc.exists) {
          final coins = exchangeDoc.data()?['coins'] ?? 0;
          final ucAmount = exchangeDoc.data()?['ucAmount'] ?? 0;
          await _db.collection('users').doc(uid).update({
            'coins': FieldValue.increment(coins),
            'totalUCExchanged': FieldValue.increment(-ucAmount),
          });
        }
      }
    } catch (e) {
      print('Error updating exchange status: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllPendingExchanges() async {
    try {
      print('DEBUG [Admin-Exchange]: ========== PENDING UC SO\'ROVLAR YUKLASH BOSHLANDI ==========');

      final usersSnapshot = await _db.collection('users').get();
      print('DEBUG [Admin-Exchange]: Jami ${usersSnapshot.docs.length} ta user topildi');

      final List<Map<String, dynamic>> allExchanges = [];
      int totalChecked = 0;
      int totalPending = 0;

      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final userName = userData['displayName'] ?? 'Unknown';

        try {
          final exchangesSnapshot = await userDoc.reference
              .collection('exchanges')
              .where('status', isEqualTo: 'pending')
              .orderBy('createdAt', descending: true)
              .get();

          totalChecked++;
          if (exchangesSnapshot.docs.isNotEmpty) {
            print('DEBUG [Admin-Exchange]: User $userName: ${exchangesSnapshot.docs.length} ta pending exchange');
            totalPending += exchangesSnapshot.docs.length;
          }

          for (final exchangeDoc in exchangesSnapshot.docs) {
            final exchangeData = exchangeDoc.data();
            print('DEBUG [Admin-Exchange]:   - ${exchangeData['coins']} coin -> ${exchangeData['ucAmount']} UC (${exchangeData['nickname']})');

            allExchanges.add({
              'exchange': ExchangeModel.fromFirestore(exchangeDoc),
              'userName': userData['displayName'] ?? '',
              'userEmail': userData['email'] ?? '',
            });
          }
        } catch (indexError) {
          print('DEBUG [Admin-Exchange]: ⚠️ User $userName uchun query xatosi (index yo\'q bo\'lishi mumkin)');
          print('DEBUG [Admin-Exchange]: Xato: $indexError');

          // Fallback - index yo'q bo'lsa, barcha exchanges'ni olamiz va filter qilamiz
          try {
            final allExchangesSnapshot = await userDoc.reference
                .collection('exchanges')
                .get();

            final pendingDocs = allExchangesSnapshot.docs
                .where((doc) => doc.data()['status'] == 'pending')
                .toList();

            if (pendingDocs.isNotEmpty) {
              print('DEBUG [Admin-Exchange]: Fallback: User $userName: ${pendingDocs.length} ta pending exchange (in-memory filter)');
              totalPending += pendingDocs.length;
            }

            for (final exchangeDoc in pendingDocs) {
              allExchanges.add({
                'exchange': ExchangeModel.fromFirestore(exchangeDoc),
                'userName': userData['displayName'] ?? '',
                'userEmail': userData['email'] ?? '',
              });
            }
          } catch (fallbackError) {
            print('DEBUG [Admin-Exchange]: ❌ Fallback ham muvaffaqiyatsiz: $fallbackError');
          }
        }
      }

      print('DEBUG [Admin-Exchange]: $totalChecked ta userdan jami $totalPending ta pending exchange topildi');

      allExchanges.sort((a, b) => (b['exchange'] as ExchangeModel)
          .createdAt
          .compareTo((a['exchange'] as ExchangeModel).createdAt));

      print('DEBUG [Admin-Exchange]: ${allExchanges.length} ta so\'rov qaytarilmoqda');
      print('DEBUG [Admin-Exchange]: ========== YUKLASH TUGADI ==========\n');

      return allExchanges;
    } catch (e, stackTrace) {
      print('DEBUG [Admin-Exchange]: ❌ JIDDIY XATOLIK!');
      print('DEBUG [Admin-Exchange]: Xato: $e');
      print('DEBUG [Admin-Exchange]: Stack trace: $stackTrace');
      return [];
    }
  }

  // ==================== TASK MANAGEMENT (ADMIN) ====================

  Future<List<TaskModel>> getAllTasks() async {
    try {
      final snapshot =
          await _db.collection('tasks').orderBy('order').get();
      return snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting all tasks: $e');
      return [];
    }
  }

  Future<void> createTask(TaskModel task) async {
    try {
      await _db.collection('tasks').add(task.toFirestore());
    } catch (e) {
      print('Error creating task: $e');
    }
  }

  Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _db.collection('tasks').doc(taskId).update(data);
    } catch (e) {
      print('Error updating task: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _db.collection('tasks').doc(taskId).delete();
    } catch (e) {
      print('Error deleting task: $e');
    }
  }

  // ==================== SETTINGS ====================

  Future<Map<String, dynamic>> getSettings() async {
    try {
      final doc = await _db.collection('settings').doc('app').get();
      return doc.data() ?? {};
    } catch (e) {
      print('Error getting settings: $e');
      return {};
    }
  }

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    try {
      settings['updatedAt'] = FieldValue.serverTimestamp();
      await _db.collection('settings').doc('app').set(
            settings,
            SetOptions(merge: true),
          );
    } catch (e) {
      print('Error updating settings: $e');
    }
  }

  // ==================== ADMIN: USER COIN MANAGEMENT ====================

  Future<void> setUserCoins(String uid, int coins) async {
    try {
      await _db.collection('users').doc(uid).update({'coins': coins});
    } catch (e) {
      print('Error setting user coins: $e');
    }
  }

  // ==================== ADMIN: TASK STATISTICS ====================

  /// Har bir vazifa uchun statistika - nechta user bajargan
  Future<Map<String, int>> getTaskCompletionCounts() async {
    try {
      final snapshot = await _db.collection('task_completions').get();
      final Map<String, int> counts = {};

      for (var doc in snapshot.docs) {
        final taskId = doc.data()['taskId'] as String?;
        if (taskId != null) {
          counts[taskId] = (counts[taskId] ?? 0) + 1;
        }
      }

      return counts;
    } catch (e) {
      print('Error getting task completion counts: $e');
      return {};
    }
  }

  /// Bir vazifa uchun barcha bajargan userlarni olish
  Future<List<Map<String, dynamic>>> getTaskCompletions(String taskId) async {
    try {
      final snapshot = await _db
          .collection('task_completions')
          .where('taskId', isEqualTo: taskId)
          .orderBy('completedAt', descending: true)
          .get();

      final List<Map<String, dynamic>> results = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final uid = data['uid'] as String?;

        if (uid != null) {
          final user = await getUser(uid);
          if (user != null) {
            results.add({
              'user': user,
              'completedAt': (data['completedAt'] as Timestamp).toDate(),
              'reward': data['reward'] ?? 0,
              'date': data['date'] ?? '',
            });
          }
        }
      }

      return results;
    } catch (e) {
      print('Error getting task completions: $e');
      return [];
    }
  }

  /// Vazifa uchun statistika - bugun, umumiy
  Future<Map<String, dynamic>> getTaskStats(String taskId) async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);

      // Barcha completions
      final allSnapshot = await _db
          .collection('task_completions')
          .where('taskId', isEqualTo: taskId)
          .get();

      // Bugungi completions
      final todaySnapshot = await _db
          .collection('task_completions')
          .where('taskId', isEqualTo: taskId)
          .where('date', isEqualTo: today)
          .get();

      // Unique users (hamma vaqt)
      final uniqueUsers = <String>{};
      for (var doc in allSnapshot.docs) {
        final uid = doc.data()['uid'] as String?;
        if (uid != null) uniqueUsers.add(uid);
      }

      // Unique users (bugun)
      final todayUniqueUsers = <String>{};
      for (var doc in todaySnapshot.docs) {
        final uid = doc.data()['uid'] as String?;
        if (uid != null) todayUniqueUsers.add(uid);
      }

      return {
        'totalCompletions': allSnapshot.docs.length,
        'uniqueUsers': uniqueUsers.length,
        'todayCompletions': todaySnapshot.docs.length,
        'todayUniqueUsers': todayUniqueUsers.length,
      };
    } catch (e) {
      print('Error getting task stats: $e');
      return {
        'totalCompletions': 0,
        'uniqueUsers': 0,
        'todayCompletions': 0,
        'todayUniqueUsers': 0,
      };
    }
  }

  // ==================== ANNOUNCEMENTS ====================

  /// Aktiv e'lonlarni olish (foydalanuvchilar uchun)
  Future<List<AnnouncementModel>> getActiveAnnouncements() async {
    try {
      final snapshot = await _db
          .collection('announcements')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => AnnouncementModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting active announcements: $e');
      return [];
    }
  }

  /// Barcha e'lonlarni olish (admin uchun)
  Future<List<AnnouncementModel>> getAllAnnouncements() async {
    try {
      final snapshot = await _db
          .collection('announcements')
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => AnnouncementModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting all announcements: $e');
      return [];
    }
  }

  /// E'lon yaratish
  Future<String?> createAnnouncement(AnnouncementModel announcement) async {
    try {
      final docRef = await _db
          .collection('announcements')
          .add(announcement.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error creating announcement: $e');
      return null;
    }
  }

  /// E'lonni yangilash
  Future<void> updateAnnouncement(
      String id, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.now();
      await _db.collection('announcements').doc(id).update(data);
    } catch (e) {
      print('Error updating announcement: $e');
    }
  }

  /// E'lonni o'chirish
  Future<void> deleteAnnouncement(String id) async {
    try {
      await _db.collection('announcements').doc(id).delete();
    } catch (e) {
      print('Error deleting announcement: $e');
    }
  }

  // ==================== UC ORDERS ====================

  /// UC buyurtma yaratish
  Future<String?> createUCOrder(UCOrderModel order) async {
    try {
      final docRef = await _db
          .collection('uc_orders')
          .add(order.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error creating UC order: $e');
      return null;
    }
  }

  /// Foydalanuvchining UC buyurtmalari
  Future<List<UCOrderModel>> getUserUCOrders(String uid) async {
    try {
      final snapshot = await _db
          .collection('uc_orders')
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => UCOrderModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting user UC orders: $e');
      return [];
    }
  }

  /// Barcha kutilayotgan UC buyurtmalar (admin)
  Future<List<UCOrderModel>> getAllUCOrders({String? statusFilter}) async {
    try {
      Query query = _db.collection('uc_orders');
      if (statusFilter != null && statusFilter != 'all') {
        query = query.where('status', isEqualTo: statusFilter);
      }
      final snapshot = await query
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => UCOrderModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e) {
      print('Error getting all UC orders: $e');
      return [];
    }
  }

  /// Chekni tasdiqlash (admin)
  Future<void> confirmReceipt(String orderId, String adminUid) async {
    try {
      await _db.collection('uc_orders').doc(orderId).update({
        'status': 'receipt_confirmed',
        'receiptConfirmedAt': Timestamp.now(),
        'receiptConfirmedBy': adminUid,
      });
    } catch (e) {
      print('Error confirming receipt: $e');
    }
  }

  /// Buyurtmani yakunlash (admin)
  Future<void> completeUCOrder(String orderId, String adminUid) async {
    try {
      await _db.collection('uc_orders').doc(orderId).update({
        'status': 'completed',
        'completedAt': Timestamp.now(),
        'completedBy': adminUid,
      });
    } catch (e) {
      print('Error completing UC order: $e');
    }
  }

  /// Buyurtmani rad etish (admin)
  Future<void> rejectUCOrder(
      String orderId, String adminUid, String note) async {
    try {
      await _db.collection('uc_orders').doc(orderId).update({
        'status': 'rejected',
        'adminNote': note,
        'completedAt': Timestamp.now(),
        'completedBy': adminUid,
      });
    } catch (e) {
      print('Error rejecting UC order: $e');
    }
  }

  // ==================== PROMO CODE ====================

  /// Promo kodni tekshirish va ishlatish
  /// Qaytaradi: {'success': bool, 'message': String, 'coins': int}
  Future<Map<String, dynamic>> redeemPromoCode(String uid, String code) async {
    try {
      final codeDoc = await _db.collection('promo_codes').doc(code).get();

      if (!codeDoc.exists) {
        return {'success': false, 'message': 'invalid', 'coins': 0};
      }

      final data = codeDoc.data() as Map<String, dynamic>;

      if (data['used'] == true) {
        return {'success': false, 'message': 'already_used', 'coins': 0};
      }

      final coins = (data['coins'] as num?)?.toInt() ?? 5;

      // Tranzaksiya bilan: kodni ishlatilgan deb belgilash + coin qo'shish
      await _db.runTransaction((transaction) async {
        final freshCodeDoc = await transaction.get(
          _db.collection('promo_codes').doc(code),
        );

        if (!freshCodeDoc.exists) throw Exception('Code not found');

        final freshData = freshCodeDoc.data() as Map<String, dynamic>;
        if (freshData['used'] == true) throw Exception('Already used');

        // Kodni ishlatilgan deb belgilash
        transaction.update(_db.collection('promo_codes').doc(code), {
          'used': true,
          'used_by': uid,
          'used_at': FieldValue.serverTimestamp(),
        });

        // Foydalanuvchiga coin qo'shish
        final userRef = _db.collection('users').doc(uid);
        transaction.update(userRef, {
          'coins': FieldValue.increment(coins),
        });
      });

      // Keshni tozalash
      _cachedUser = null;
      _cacheTime = null;

      return {'success': true, 'message': 'success', 'coins': coins};
    } catch (e) {
      print('Promo code redeem error: $e');
      if (e.toString().contains('Already used')) {
        return {'success': false, 'message': 'already_used', 'coins': 0};
      }
      return {'success': false, 'message': 'error', 'coins': 0};
    }
  }
}
