import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final int coins;
  final int totalCoinsEarned;
  final int totalUCExchanged;
  final int dailyAds;
  final int dailyGames;
  final DateTime? lastResetDate;
  final int loginStreak;
  final DateTime? lastDailyBonusDate;
  final String referralCode;
  final String? referredBy;
  final int referralCount;
  final bool isAdmin;
  final int lastPromoVersion;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.coins = 0,
    this.totalCoinsEarned = 0,
    this.totalUCExchanged = 0,
    this.dailyAds = 0,
    this.dailyGames = 0,
    this.lastResetDate,
    this.loginStreak = 0,
    this.lastDailyBonusDate,
    required this.referralCode,
    this.referredBy,
    this.referralCount = 0,
    this.isAdmin = false,
    this.lastPromoVersion = 0,
    required this.createdAt,
    required this.lastLoginAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: data['uid'] ?? doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      coins: data['coins'] ?? 0,
      totalCoinsEarned: data['totalCoinsEarned'] ?? 0,
      totalUCExchanged: data['totalUCExchanged'] ?? 0,
      dailyAds: data['dailyAds'] ?? 0,
      dailyGames: data['dailyGames'] ?? 0,
      lastResetDate: (data['lastResetDate'] as Timestamp?)?.toDate(),
      loginStreak: data['loginStreak'] ?? 0,
      lastDailyBonusDate:
          (data['lastDailyBonusDate'] as Timestamp?)?.toDate(),
      referralCode: data['referralCode'] ?? '',
      referredBy: data['referredBy'],
      referralCount: data['referralCount'] ?? 0,
      isAdmin: data['isAdmin'] ?? false,
      lastPromoVersion: data['lastPromoVersion'] ?? 0,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt:
          (data['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'coins': coins,
      'totalCoinsEarned': totalCoinsEarned,
      'totalUCExchanged': totalUCExchanged,
      'dailyAds': dailyAds,
      'dailyGames': dailyGames,
      'lastResetDate':
          lastResetDate != null ? Timestamp.fromDate(lastResetDate!) : null,
      'loginStreak': loginStreak,
      'lastDailyBonusDate': lastDailyBonusDate != null
          ? Timestamp.fromDate(lastDailyBonusDate!)
          : null,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'referralCount': referralCount,
      'isAdmin': isAdmin,
      'lastPromoVersion': lastPromoVersion,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
    };
  }

  AppUser copyWith({
    int? coins,
    int? totalCoinsEarned,
    int? totalUCExchanged,
    int? dailyAds,
    int? dailyGames,
    DateTime? lastResetDate,
    int? loginStreak,
    DateTime? lastDailyBonusDate,
    int? referralCount,
    bool? isAdmin,
    int? lastPromoVersion,
    DateTime? lastLoginAt,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      coins: coins ?? this.coins,
      totalCoinsEarned: totalCoinsEarned ?? this.totalCoinsEarned,
      totalUCExchanged: totalUCExchanged ?? this.totalUCExchanged,
      dailyAds: dailyAds ?? this.dailyAds,
      dailyGames: dailyGames ?? this.dailyGames,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      loginStreak: loginStreak ?? this.loginStreak,
      lastDailyBonusDate: lastDailyBonusDate ?? this.lastDailyBonusDate,
      referralCode: referralCode,
      referredBy: referredBy,
      referralCount: referralCount ?? this.referralCount,
      isAdmin: isAdmin ?? this.isAdmin,
      lastPromoVersion: lastPromoVersion ?? this.lastPromoVersion,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  static String generateReferralCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }
}
