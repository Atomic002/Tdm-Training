import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import '../models/task_model.dart';
import '../models/exchange_model.dart';
import '../models/task_completion_model.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Constants
  static const int coinsPerAd = 5;
  static const int maxDailyAds = 10;
  static const int maxDailyGames = 20;
  static const int maxCoinsPerGame = 10;

  static const Map<int, int> ucExchangeRates = {
    8000: 325,
    10000: 660,
    20000: 1200,
    30000: 2500,
    40000: 3000,
    100000: 5000,
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

  Future<void> _checkAndResetDaily(String uid) async {
    final docRef = _db.collection('users').doc(uid);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final lastReset = (data['lastResetDate'] as Timestamp?)?.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastReset == null ||
        DateTime(lastReset.year, lastReset.month, lastReset.day)
            .isBefore(today)) {
      await docRef.update({
        'dailyAds': 0,
        'dailyGames': 0,
        'lastResetDate': Timestamp.fromDate(today),
      });
    }
  }

  // ==================== COIN OPERATIONS ====================

  Future<int> getCoins() async {
    if (_currentUid == null) return 0;
    try {
      final user = await getUser(_currentUid!);
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
      await _checkAndResetDaily(uid);

      return await _db.runTransaction((transaction) async {
        final docRef = _db.collection('users').doc(uid);
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return false;

        final dailyAds = snapshot.data()?['dailyAds'] ?? 0;
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

  Future<bool> addCoinsForGame(String uid, double accuracy) async {
    try {
      await _checkAndResetDaily(uid);

      final coinsEarned =
          (accuracy / 10).round().clamp(0, maxCoinsPerGame);

      return await _db.runTransaction((transaction) async {
        final docRef = _db.collection('users').doc(uid);
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return false;

        final dailyGames = snapshot.data()?['dailyGames'] ?? 0;
        if (dailyGames >= maxDailyGames) return false;

        transaction.update(docRef, {
          'coins': FieldValue.increment(coinsEarned),
          'totalCoinsEarned': FieldValue.increment(coinsEarned),
          'dailyGames': FieldValue.increment(1),
        });
        return true;
      });
    } catch (e) {
      print('Error adding coins for game: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getDailyStatus(String uid) async {
    try {
      await _checkAndResetDaily(uid);
      final user = await getUser(uid);
      if (user == null) return {};

      return {
        'adsWatched': user.dailyAds,
        'maxAds': maxDailyAds,
        'canWatchAd': user.dailyAds < maxDailyAds,
        'gamesPlayed': user.dailyGames,
        'maxGames': maxDailyGames,
        'canPlayGame': user.dailyGames < maxDailyGames,
        'adsRemaining': maxDailyAds - user.dailyAds,
        'gamesRemaining': maxDailyGames - user.dailyGames,
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

  Future<bool> canPlayGame(String uid) async {
    final status = await getDailyStatus(uid);
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
      final spent = await spendCoins(uid, coins);
      if (!spent) return false;

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

      await _db
          .collection('users')
          .doc(uid)
          .collection('exchanges')
          .add(exchange.toFirestore());

      await _db.collection('users').doc(uid).update({
        'totalUCExchanged': FieldValue.increment(ucAmount),
      });

      return true;
    } catch (e) {
      print('Error exchanging for UC: $e');
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
    try {
      final user = await getUser(uid);
      return user?.isAdmin ?? false;
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
      final usersSnapshot = await _db.collection('users').get();
      final List<Map<String, dynamic>> allExchanges = [];

      for (final userDoc in usersSnapshot.docs) {
        final exchangesSnapshot = await userDoc.reference
            .collection('exchanges')
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .get();

        for (final exchangeDoc in exchangesSnapshot.docs) {
          allExchanges.add({
            'exchange': ExchangeModel.fromFirestore(exchangeDoc),
            'userName': userDoc.data()['displayName'] ?? '',
            'userEmail': userDoc.data()['email'] ?? '',
          });
        }
      }

      allExchanges.sort((a, b) => (b['exchange'] as ExchangeModel)
          .createdAt
          .compareTo((a['exchange'] as ExchangeModel).createdAt));

      return allExchanges;
    } catch (e) {
      print('Error getting pending exchanges: $e');
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
}
