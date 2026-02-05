import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('uz'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In uz, this message translates to:
  /// **'PUBG TDM Training'**
  String get appTitle;

  /// No description provided for @loading.
  ///
  /// In uz, this message translates to:
  /// **'Yuklanmoqda...'**
  String get loading;

  /// No description provided for @pubgTdm.
  ///
  /// In uz, this message translates to:
  /// **'PUBG TDM'**
  String get pubgTdm;

  /// No description provided for @training.
  ///
  /// In uz, this message translates to:
  /// **'TRAINING'**
  String get training;

  /// No description provided for @reaction.
  ///
  /// In uz, this message translates to:
  /// **'REACTION'**
  String get reaction;

  /// No description provided for @improveReaction.
  ///
  /// In uz, this message translates to:
  /// **'Reaction tezligingizni oshiring'**
  String get improveReaction;

  /// No description provided for @testAccount.
  ///
  /// In uz, this message translates to:
  /// **'Test akkaunt'**
  String get testAccount;

  /// No description provided for @testAccountWarning.
  ///
  /// In uz, this message translates to:
  /// **'test accountga uc berilmaydi va doimiy bu accountdan foydalanib bulmidi'**
  String get testAccountWarning;

  /// No description provided for @testAccountCredentials.
  ///
  /// In uz, this message translates to:
  /// **'Email: testaccount@test.com\nParol: 12345678'**
  String get testAccountCredentials;

  /// No description provided for @email.
  ///
  /// In uz, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In uz, this message translates to:
  /// **'Parol'**
  String get password;

  /// No description provided for @name.
  ///
  /// In uz, this message translates to:
  /// **'Ism'**
  String get name;

  /// No description provided for @confirmPassword.
  ///
  /// In uz, this message translates to:
  /// **'Parolni tasdiqlang'**
  String get confirmPassword;

  /// No description provided for @nickname.
  ///
  /// In uz, this message translates to:
  /// **'Nickname'**
  String get nickname;

  /// No description provided for @pubgId.
  ///
  /// In uz, this message translates to:
  /// **'PUBG ID'**
  String get pubgId;

  /// No description provided for @enterEmail.
  ///
  /// In uz, this message translates to:
  /// **'Email kiriting'**
  String get enterEmail;

  /// No description provided for @enterValidEmail.
  ///
  /// In uz, this message translates to:
  /// **'To\'g\'ri email kiriting'**
  String get enterValidEmail;

  /// No description provided for @enterPassword.
  ///
  /// In uz, this message translates to:
  /// **'Parol kiriting'**
  String get enterPassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In uz, this message translates to:
  /// **'Parol kamida 6 ta belgidan iborat bo\'lishi kerak'**
  String get passwordMinLength;

  /// No description provided for @enterName.
  ///
  /// In uz, this message translates to:
  /// **'Ism kiriting'**
  String get enterName;

  /// No description provided for @nameMinLength.
  ///
  /// In uz, this message translates to:
  /// **'Ism kamida 2 ta belgidan iborat bo\'lishi kerak'**
  String get nameMinLength;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In uz, this message translates to:
  /// **'Parolni tasdiqlang'**
  String get confirmPasswordHint;

  /// No description provided for @passwordsNotMatch.
  ///
  /// In uz, this message translates to:
  /// **'Parollar mos kelmayapti'**
  String get passwordsNotMatch;

  /// No description provided for @login.
  ///
  /// In uz, this message translates to:
  /// **'Kirish'**
  String get login;

  /// No description provided for @or.
  ///
  /// In uz, this message translates to:
  /// **'yoki'**
  String get or;

  /// No description provided for @signInWithGoogle.
  ///
  /// In uz, this message translates to:
  /// **'Google bilan kirish'**
  String get signInWithGoogle;

  /// No description provided for @noAccount.
  ///
  /// In uz, this message translates to:
  /// **'Akkauntingiz yo\'qmi? '**
  String get noAccount;

  /// No description provided for @register.
  ///
  /// In uz, this message translates to:
  /// **'Ro\'yxatdan o\'tish'**
  String get register;

  /// No description provided for @createNewAccount.
  ///
  /// In uz, this message translates to:
  /// **'Yangi akkaunt yarating'**
  String get createNewAccount;

  /// No description provided for @haveAccount.
  ///
  /// In uz, this message translates to:
  /// **'Akkauntingiz bormi? '**
  String get haveAccount;

  /// No description provided for @termsAgreement.
  ///
  /// In uz, this message translates to:
  /// **'Davom etish orqali foydalanish shartlariga\nrozilik bildirasiz'**
  String get termsAgreement;

  /// No description provided for @loginError.
  ///
  /// In uz, this message translates to:
  /// **'Kirish xatoligi'**
  String get loginError;

  /// No description provided for @userNotFound.
  ///
  /// In uz, this message translates to:
  /// **'Foydalanuvchi topilmadi'**
  String get userNotFound;

  /// No description provided for @wrongPassword.
  ///
  /// In uz, this message translates to:
  /// **'Parol noto\'g\'ri'**
  String get wrongPassword;

  /// No description provided for @invalidEmail.
  ///
  /// In uz, this message translates to:
  /// **'Email formati noto\'g\'ri'**
  String get invalidEmail;

  /// No description provided for @invalidCredential.
  ///
  /// In uz, this message translates to:
  /// **'Email yoki parol noto\'g\'ri'**
  String get invalidCredential;

  /// No description provided for @registerError.
  ///
  /// In uz, this message translates to:
  /// **'Ro\'yxatdan o\'tishda xatolik yuz berdi'**
  String get registerError;

  /// No description provided for @emailAlreadyInUse.
  ///
  /// In uz, this message translates to:
  /// **'Bu email allaqachon ro\'yxatdan o\'tgan'**
  String get emailAlreadyInUse;

  /// No description provided for @weakPassword.
  ///
  /// In uz, this message translates to:
  /// **'Parol juda zaif'**
  String get weakPassword;

  /// No description provided for @loginErrorWithDetails.
  ///
  /// In uz, this message translates to:
  /// **'Kirish xatoligi: {error}'**
  String loginErrorWithDetails(String error);

  /// No description provided for @noInternet.
  ///
  /// In uz, this message translates to:
  /// **'Internetga ulanmagansiz!'**
  String get noInternet;

  /// No description provided for @noInternetDesc.
  ///
  /// In uz, this message translates to:
  /// **'Iltimos, internetga ulanib qayta urinib ko\'ring.'**
  String get noInternetDesc;

  /// No description provided for @retry.
  ///
  /// In uz, this message translates to:
  /// **'Qayta urinish'**
  String get retry;

  /// No description provided for @coins.
  ///
  /// In uz, this message translates to:
  /// **'Coinlar'**
  String get coins;

  /// No description provided for @totalUC.
  ///
  /// In uz, this message translates to:
  /// **'Jami UC'**
  String get totalUC;

  /// No description provided for @start.
  ///
  /// In uz, this message translates to:
  /// **'BOSHLASH'**
  String get start;

  /// No description provided for @startSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Reaction training o\'ynash'**
  String get startSubtitle;

  /// No description provided for @coinsMenu.
  ///
  /// In uz, this message translates to:
  /// **'COINLAR'**
  String get coinsMenu;

  /// No description provided for @coinsMenuSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Coin yig\'ish va UC almashish'**
  String get coinsMenuSubtitle;

  /// No description provided for @ucShop.
  ///
  /// In uz, this message translates to:
  /// **'UC DO\'KONI'**
  String get ucShop;

  /// No description provided for @ucShopSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'UC sotib olish (so\'m bilan)'**
  String get ucShopSubtitle;

  /// No description provided for @tasks.
  ///
  /// In uz, this message translates to:
  /// **'VAZIFALAR'**
  String get tasks;

  /// No description provided for @tasksSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Vazifa bajaring — coin oling'**
  String get tasksSubtitle;

  /// No description provided for @miniPubg.
  ///
  /// In uz, this message translates to:
  /// **'MINI PUBG'**
  String get miniPubg;

  /// No description provided for @miniPubgSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Dushmanlarni yo\'q qiling va coin oling'**
  String get miniPubgSubtitle;

  /// No description provided for @leaderboard.
  ///
  /// In uz, this message translates to:
  /// **'REYTING'**
  String get leaderboard;

  /// No description provided for @leaderboardSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Top o\'yinchilar reytingi'**
  String get leaderboardSubtitle;

  /// No description provided for @statistics.
  ///
  /// In uz, this message translates to:
  /// **'STATISTIKA'**
  String get statistics;

  /// No description provided for @statisticsSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Natijalaringizni ko\'ring'**
  String get statisticsSubtitle;

  /// No description provided for @settings.
  ///
  /// In uz, this message translates to:
  /// **'SOZLAMALAR'**
  String get settings;

  /// No description provided for @settingsSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'O\'yin sozlamalari'**
  String get settingsSubtitle;

  /// No description provided for @adminPanel.
  ///
  /// In uz, this message translates to:
  /// **'ADMIN PANEL'**
  String get adminPanel;

  /// No description provided for @adminPanelSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Foydalanuvchilar va sozlamalar'**
  String get adminPanelSubtitle;

  /// No description provided for @news.
  ///
  /// In uz, this message translates to:
  /// **'YANGILIKLAR'**
  String get news;

  /// No description provided for @close.
  ///
  /// In uz, this message translates to:
  /// **'Yopish'**
  String get close;

  /// No description provided for @dataLoadError.
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumotlarni yuklashda xatolik yuz berdi'**
  String get dataLoadError;

  /// No description provided for @settingsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Sozlamalar'**
  String get settingsTitle;

  /// No description provided for @statsLabel.
  ///
  /// In uz, this message translates to:
  /// **'Statistika'**
  String get statsLabel;

  /// No description provided for @streak.
  ///
  /// In uz, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @streakDays.
  ///
  /// In uz, this message translates to:
  /// **'{count} kun'**
  String streakDays(int count);

  /// No description provided for @total.
  ///
  /// In uz, this message translates to:
  /// **'Jami'**
  String get total;

  /// No description provided for @referralCode.
  ///
  /// In uz, this message translates to:
  /// **'Taklif Kodi'**
  String get referralCode;

  /// No description provided for @yourCode.
  ///
  /// In uz, this message translates to:
  /// **'Sizning kodingiz:'**
  String get yourCode;

  /// No description provided for @referralCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta taklif'**
  String referralCount(int count);

  /// No description provided for @codeCopied.
  ///
  /// In uz, this message translates to:
  /// **'Kod nusxalandi!'**
  String get codeCopied;

  /// No description provided for @appName.
  ///
  /// In uz, this message translates to:
  /// **'TDM Training'**
  String get appName;

  /// No description provided for @version.
  ///
  /// In uz, this message translates to:
  /// **'Versiya 2.0.0'**
  String get version;

  /// No description provided for @copyright.
  ///
  /// In uz, this message translates to:
  /// **'© 2025 TDM Training. Barcha huquqlar himoyalangan.'**
  String get copyright;

  /// No description provided for @logout.
  ///
  /// In uz, this message translates to:
  /// **'Chiqish'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In uz, this message translates to:
  /// **'Hisobdan chiqishni xohlaysizmi?'**
  String get logoutConfirm;

  /// No description provided for @cancel.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilish'**
  String get cancel;

  /// No description provided for @adLoading.
  ///
  /// In uz, this message translates to:
  /// **'Reklama yuklanmoqda...'**
  String get adLoading;

  /// No description provided for @skipAd.
  ///
  /// In uz, this message translates to:
  /// **'O\'tkazib yuborish'**
  String get skipAd;

  /// No description provided for @user.
  ///
  /// In uz, this message translates to:
  /// **'Foydalanuvchi'**
  String get user;

  /// No description provided for @difficultyTitle.
  ///
  /// In uz, this message translates to:
  /// **'Qiyinlik Darajasi'**
  String get difficultyTitle;

  /// No description provided for @selectDifficulty.
  ///
  /// In uz, this message translates to:
  /// **'Qiyinlik darajasini tanlang'**
  String get selectDifficulty;

  /// No description provided for @difficultyInfo.
  ///
  /// In uz, this message translates to:
  /// **'Har bir daraja o\'ziga xos qiyinchilikka ega'**
  String get difficultyInfo;

  /// No description provided for @targetTime.
  ///
  /// In uz, this message translates to:
  /// **'Nishon vaqti:'**
  String get targetTime;

  /// No description provided for @targetSize.
  ///
  /// In uz, this message translates to:
  /// **'Nishon hajmi:'**
  String get targetSize;

  /// No description provided for @scoreMultiplier.
  ///
  /// In uz, this message translates to:
  /// **'Ball ko\'paytiruvchi:'**
  String get scoreMultiplier;

  /// No description provided for @movingTargets.
  ///
  /// In uz, this message translates to:
  /// **'Harakat qiluvchi nishonlar:'**
  String get movingTargets;

  /// No description provided for @multipleTargets.
  ///
  /// In uz, this message translates to:
  /// **'Ko\'p nishonlar:'**
  String get multipleTargets;

  /// No description provided for @yes.
  ///
  /// In uz, this message translates to:
  /// **'Ha'**
  String get yes;

  /// No description provided for @diffEasy.
  ///
  /// In uz, this message translates to:
  /// **'OSON'**
  String get diffEasy;

  /// No description provided for @diffMedium.
  ///
  /// In uz, this message translates to:
  /// **'O\'RTA'**
  String get diffMedium;

  /// No description provided for @diffHard.
  ///
  /// In uz, this message translates to:
  /// **'QIYIN'**
  String get diffHard;

  /// No description provided for @diffExpert.
  ///
  /// In uz, this message translates to:
  /// **'EKSPERT'**
  String get diffExpert;

  /// No description provided for @diffEasyDesc.
  ///
  /// In uz, this message translates to:
  /// **'Yangi boshlovchilar uchun'**
  String get diffEasyDesc;

  /// No description provided for @diffMediumDesc.
  ///
  /// In uz, this message translates to:
  /// **'O\'rta daraja o\'yinchilar uchun'**
  String get diffMediumDesc;

  /// No description provided for @diffHardDesc.
  ///
  /// In uz, this message translates to:
  /// **'Tajribali o\'yinchilar uchun'**
  String get diffHardDesc;

  /// No description provided for @diffExpertDesc.
  ///
  /// In uz, this message translates to:
  /// **'Professional o\'yinchilar uchun'**
  String get diffExpertDesc;

  /// No description provided for @coinsAndUC.
  ///
  /// In uz, this message translates to:
  /// **'Coinlaringiz va UC'**
  String get coinsAndUC;

  /// No description provided for @dailyStatus.
  ///
  /// In uz, this message translates to:
  /// **'Kunlik Status'**
  String get dailyStatus;

  /// No description provided for @games.
  ///
  /// In uz, this message translates to:
  /// **'O\'yinlar'**
  String get games;

  /// No description provided for @ads.
  ///
  /// In uz, this message translates to:
  /// **'Reklamalar'**
  String get ads;

  /// No description provided for @earnCoins.
  ///
  /// In uz, this message translates to:
  /// **'Coin Topish'**
  String get earnCoins;

  /// No description provided for @watchAd.
  ///
  /// In uz, this message translates to:
  /// **'Reklama Ko\'rish'**
  String get watchAd;

  /// No description provided for @adRewardInfo.
  ///
  /// In uz, this message translates to:
  /// **'Har bir reklama uchun {coins} coin'**
  String adRewardInfo(int coins);

  /// No description provided for @adLimitReached.
  ///
  /// In uz, this message translates to:
  /// **'Limit tugadi'**
  String get adLimitReached;

  /// No description provided for @gameEarnInfo.
  ///
  /// In uz, this message translates to:
  /// **'O\'yin o\'ynab ham coin olishingiz mumkin! Aniqligingizga qarab 0-10 coin olasiz.'**
  String get gameEarnInfo;

  /// No description provided for @ucExchange.
  ///
  /// In uz, this message translates to:
  /// **'UC Almashtirish'**
  String get ucExchange;

  /// No description provided for @exchangeUC.
  ///
  /// In uz, this message translates to:
  /// **'UC Almashish'**
  String get exchangeUC;

  /// No description provided for @notEnough.
  ///
  /// In uz, this message translates to:
  /// **'Yetarli emas'**
  String get notEnough;

  /// No description provided for @recentExchanges.
  ///
  /// In uz, this message translates to:
  /// **'So\'nggi Almashtirish'**
  String get recentExchanges;

  /// No description provided for @exchangeHistoryEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Almashtirish tarixi bo\'sh'**
  String get exchangeHistoryEmpty;

  /// No description provided for @statusPending.
  ///
  /// In uz, this message translates to:
  /// **'Kutilmoqda'**
  String get statusPending;

  /// No description provided for @statusApproved.
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlangan'**
  String get statusApproved;

  /// No description provided for @statusRejected.
  ///
  /// In uz, this message translates to:
  /// **'Rad etilgan'**
  String get statusRejected;

  /// No description provided for @statusCompleted.
  ///
  /// In uz, this message translates to:
  /// **'Tugallandi'**
  String get statusCompleted;

  /// No description provided for @available.
  ///
  /// In uz, this message translates to:
  /// **'Mavjud: {coins} coin'**
  String available(int coins);

  /// No description provided for @selectExchangeAmount.
  ///
  /// In uz, this message translates to:
  /// **'Almashtirish miqdorini tanlang:'**
  String get selectExchangeAmount;

  /// No description provided for @enterYourInfo.
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumotlaringizni kiriting:'**
  String get enterYourInfo;

  /// No description provided for @exchange.
  ///
  /// In uz, this message translates to:
  /// **'Almashish'**
  String get exchange;

  /// No description provided for @selectExchangeAmountError.
  ///
  /// In uz, this message translates to:
  /// **'Iltimos, almashtirish miqdorini tanlang'**
  String get selectExchangeAmountError;

  /// No description provided for @enterNickname.
  ///
  /// In uz, this message translates to:
  /// **'Iltimos, nickname kiriting'**
  String get enterNickname;

  /// No description provided for @enterPubgId.
  ///
  /// In uz, this message translates to:
  /// **'Iltimos, PUBG ID kiriting'**
  String get enterPubgId;

  /// No description provided for @notEnoughCoins.
  ///
  /// In uz, this message translates to:
  /// **'Yetarli coin yo\'q'**
  String get notEnoughCoins;

  /// No description provided for @exchangeFailed.
  ///
  /// In uz, this message translates to:
  /// **'Almashtirish muvaffaqiyatsiz'**
  String get exchangeFailed;

  /// No description provided for @errorOccurred.
  ///
  /// In uz, this message translates to:
  /// **'Xatolik yuz berdi: {error}'**
  String errorOccurred(String error);

  /// No description provided for @success.
  ///
  /// In uz, this message translates to:
  /// **'Muvaffaqiyatli!'**
  String get success;

  /// No description provided for @ucExchangeRequestAccepted.
  ///
  /// In uz, this message translates to:
  /// **'UC almashtirish so\'rovi qabul qilindi!'**
  String get ucExchangeRequestAccepted;

  /// No description provided for @info.
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumotlar:'**
  String get info;

  /// No description provided for @amount.
  ///
  /// In uz, this message translates to:
  /// **'Miqdor: {coins} Coin → {uc} UC'**
  String amount(int coins, int uc);

  /// No description provided for @adminReviewNote.
  ///
  /// In uz, this message translates to:
  /// **'So\'rov admin tomonidan ko\'rib chiqiladi. UC lar tasdiqlangandan so\'ng hisobingizga o\'tkaziladi.'**
  String get adminReviewNote;

  /// No description provided for @ok.
  ///
  /// In uz, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @adAlreadyLoading.
  ///
  /// In uz, this message translates to:
  /// **'Reklama allaqachon yuklanmoqda'**
  String get adAlreadyLoading;

  /// No description provided for @adLimitReachedToday.
  ///
  /// In uz, this message translates to:
  /// **'Bugun reklamalar limitiga yetdingiz'**
  String get adLimitReachedToday;

  /// No description provided for @pleaseWait.
  ///
  /// In uz, this message translates to:
  /// **'Iltimos {time} kuting'**
  String pleaseWait(String time);

  /// No description provided for @coinsAdded.
  ///
  /// In uz, this message translates to:
  /// **'{coins} coin qo\'shildi!'**
  String coinsAdded(int coins);

  /// No description provided for @coinAddError.
  ///
  /// In uz, this message translates to:
  /// **'Coin qo\'shishda xatolik yuz berdi'**
  String get coinAddError;

  /// No description provided for @adShowError.
  ///
  /// In uz, this message translates to:
  /// **'Reklama ko\'rsatishda xatolik yuz berdi'**
  String get adShowError;

  /// No description provided for @adShowErrorWithDetails.
  ///
  /// In uz, this message translates to:
  /// **'Reklama ko\'rsatishda xatolik: {error}'**
  String adShowErrorWithDetails(String error);

  /// No description provided for @yourRank.
  ///
  /// In uz, this message translates to:
  /// **'Sizning o\'rningiz: #{rank}'**
  String yourRank(int rank);

  /// No description provided for @noDataYet.
  ///
  /// In uz, this message translates to:
  /// **'Hali ma\'lumot yo\'q'**
  String get noDataYet;

  /// No description provided for @you.
  ///
  /// In uz, this message translates to:
  /// **'Siz'**
  String get you;

  /// No description provided for @overallStats.
  ///
  /// In uz, this message translates to:
  /// **'Umumiy statistika'**
  String get overallStats;

  /// No description provided for @overall.
  ///
  /// In uz, this message translates to:
  /// **'Umumiy'**
  String get overall;

  /// No description provided for @results.
  ///
  /// In uz, this message translates to:
  /// **'Natijalar'**
  String get results;

  /// No description provided for @levels.
  ///
  /// In uz, this message translates to:
  /// **'Darajalar'**
  String get levels;

  /// No description provided for @bestScore.
  ///
  /// In uz, this message translates to:
  /// **'Eng yuqori ball'**
  String get bestScore;

  /// No description provided for @averageScore.
  ///
  /// In uz, this message translates to:
  /// **'O\'rtacha ball'**
  String get averageScore;

  /// No description provided for @gamesPlayed.
  ///
  /// In uz, this message translates to:
  /// **'O\'ynagan o\'yinlar'**
  String get gamesPlayed;

  /// No description provided for @averageAccuracy.
  ///
  /// In uz, this message translates to:
  /// **'O\'rtacha aniqlik'**
  String get averageAccuracy;

  /// No description provided for @detailedInfo.
  ///
  /// In uz, this message translates to:
  /// **'Batafsil ma\'lumot'**
  String get detailedInfo;

  /// No description provided for @totalHits.
  ///
  /// In uz, this message translates to:
  /// **'Jami tushganlar:'**
  String get totalHits;

  /// No description provided for @totalMisses.
  ///
  /// In uz, this message translates to:
  /// **'Jami o\'tkazilganlar:'**
  String get totalMisses;

  /// No description provided for @totalShots.
  ///
  /// In uz, this message translates to:
  /// **'Jami o\'qlar:'**
  String get totalShots;

  /// No description provided for @bestResult.
  ///
  /// In uz, this message translates to:
  /// **'Eng yaxshi natija:'**
  String get bestResult;

  /// No description provided for @score.
  ///
  /// In uz, this message translates to:
  /// **'Ball:'**
  String get score;

  /// No description provided for @accuracy.
  ///
  /// In uz, this message translates to:
  /// **'Aniqlik:'**
  String get accuracy;

  /// No description provided for @date.
  ///
  /// In uz, this message translates to:
  /// **'Sana:'**
  String get date;

  /// No description provided for @clearStats.
  ///
  /// In uz, this message translates to:
  /// **'Statistikani tozalash'**
  String get clearStats;

  /// No description provided for @statsCleared.
  ///
  /// In uz, this message translates to:
  /// **'Statistika tozalandi'**
  String get statsCleared;

  /// No description provided for @noResultsYet.
  ///
  /// In uz, this message translates to:
  /// **'Hali natijalar yo\'q'**
  String get noResultsYet;

  /// No description provided for @playToCollect.
  ///
  /// In uz, this message translates to:
  /// **'O\'yin o\'ynab natijalar yig\'ing!'**
  String get playToCollect;

  /// No description provided for @hits.
  ///
  /// In uz, this message translates to:
  /// **'Tushgan: {hits}/{total}'**
  String hits(int hits, int total);

  /// No description provided for @gamesPlayedCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} o\'yin o\'ynalgan'**
  String gamesPlayedCount(int count);

  /// No description provided for @best.
  ///
  /// In uz, this message translates to:
  /// **'Eng yaxshi'**
  String get best;

  /// No description provided for @notPlayedYet.
  ///
  /// In uz, this message translates to:
  /// **'Bu darajada hali o\'ynalmagan'**
  String get notPlayedYet;

  /// No description provided for @clearStatsConfirm.
  ///
  /// In uz, this message translates to:
  /// **'Barcha natijalar va statistikalar o\'chiriladi. Bu amalni qaytarib bo\'lmaydi.'**
  String get clearStatsConfirm;

  /// No description provided for @clear.
  ///
  /// In uz, this message translates to:
  /// **'Tozalash'**
  String get clear;

  /// No description provided for @adLoadingText.
  ///
  /// In uz, this message translates to:
  /// **'Reklama yuklanmoqda...'**
  String get adLoadingText;

  /// No description provided for @adLoadFailed.
  ///
  /// In uz, this message translates to:
  /// **'Reklama yuklanmadi'**
  String get adLoadFailed;

  /// No description provided for @startGame.
  ///
  /// In uz, this message translates to:
  /// **'START'**
  String get startGame;

  /// No description provided for @readyToPlay.
  ///
  /// In uz, this message translates to:
  /// **'O\'yinga tayyor'**
  String get readyToPlay;

  /// No description provided for @matchNumber.
  ///
  /// In uz, this message translates to:
  /// **'Match #{number}'**
  String matchNumber(int number);

  /// No description provided for @gameDuration.
  ///
  /// In uz, this message translates to:
  /// **'O\'yin davomiyligi'**
  String get gameDuration;

  /// No description provided for @targetSizeLabel.
  ///
  /// In uz, this message translates to:
  /// **'Nishon hajmi'**
  String get targetSizeLabel;

  /// No description provided for @rewardLabel.
  ///
  /// In uz, this message translates to:
  /// **'Mukofot'**
  String get rewardLabel;

  /// No description provided for @upToCoins.
  ///
  /// In uz, this message translates to:
  /// **'{coins} gacha coin'**
  String upToCoins(int coins);

  /// No description provided for @level.
  ///
  /// In uz, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @lives.
  ///
  /// In uz, this message translates to:
  /// **'Jonlar'**
  String get lives;

  /// No description provided for @reward.
  ///
  /// In uz, this message translates to:
  /// **'Mukofot'**
  String get reward;

  /// No description provided for @remainingGames.
  ///
  /// In uz, this message translates to:
  /// **'Qolgan o\'yinlar'**
  String get remainingGames;

  /// No description provided for @language.
  ///
  /// In uz, this message translates to:
  /// **'Til'**
  String get language;

  /// No description provided for @uzbek.
  ///
  /// In uz, this message translates to:
  /// **'O\'zbekcha'**
  String get uzbek;

  /// No description provided for @russian.
  ///
  /// In uz, this message translates to:
  /// **'Русский'**
  String get russian;

  /// No description provided for @english.
  ///
  /// In uz, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @selectLanguage.
  ///
  /// In uz, this message translates to:
  /// **'Tilni tanlang'**
  String get selectLanguage;

  /// No description provided for @totalUsers.
  ///
  /// In uz, this message translates to:
  /// **'Jami userlar'**
  String get totalUsers;

  /// No description provided for @activeToday.
  ///
  /// In uz, this message translates to:
  /// **'Bugun faol'**
  String get activeToday;

  /// No description provided for @pending.
  ///
  /// In uz, this message translates to:
  /// **'Kutilmoqda'**
  String get pending;

  /// No description provided for @users.
  ///
  /// In uz, this message translates to:
  /// **'Foydalanuvchilar'**
  String get users;

  /// No description provided for @usersSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Barcha userlarni ko\'rish va boshqarish'**
  String get usersSubtitle;

  /// No description provided for @tasksAdmin.
  ///
  /// In uz, this message translates to:
  /// **'Vazifalar'**
  String get tasksAdmin;

  /// No description provided for @tasksAdminSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Vazifalarni qo\'shish va boshqarish'**
  String get tasksAdminSubtitle;

  /// No description provided for @ucRequests.
  ///
  /// In uz, this message translates to:
  /// **'UC so\'rovlar'**
  String get ucRequests;

  /// No description provided for @ucRequestsSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta kutilayotgan so\'rov'**
  String ucRequestsSubtitle(int count);

  /// No description provided for @announcements.
  ///
  /// In uz, this message translates to:
  /// **'E\'lonlar'**
  String get announcements;

  /// No description provided for @announcementsSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Yangiliklar va e\'lonlarni boshqarish'**
  String get announcementsSubtitle;

  /// No description provided for @ucOrders.
  ///
  /// In uz, this message translates to:
  /// **'UC Buyurtmalar'**
  String get ucOrders;

  /// No description provided for @ucOrdersSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'UC sotib olish buyurtmalari'**
  String get ucOrdersSubtitle;

  /// No description provided for @settingsAdmin.
  ///
  /// In uz, this message translates to:
  /// **'Sozlamalar'**
  String get settingsAdmin;

  /// No description provided for @settingsAdminSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Telegram, Instagram, limitlar'**
  String get settingsAdminSubtitle;

  /// No description provided for @notLoggedIn.
  ///
  /// In uz, this message translates to:
  /// **'Login qilmagan! Iltimos qaytadan kiriting'**
  String get notLoggedIn;

  /// No description provided for @taskWarning.
  ///
  /// In uz, this message translates to:
  /// **'Ogohlantirish: Sizning obunangiz (yoki bajarilgan vazifa) adminlar tomonidan tekshiriladi.\nAgar \'bajardim/obuna bo\'ldim\' deb aldasangiz, hisobingizdan 2 baravar coin yechib olinadi.'**
  String get taskWarning;

  /// No description provided for @telegramIdTitle.
  ///
  /// In uz, this message translates to:
  /// **'Telegram ID'**
  String get telegramIdTitle;

  /// No description provided for @verificationCode.
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlash Kodi'**
  String get verificationCode;

  /// No description provided for @step1TelegramId.
  ///
  /// In uz, this message translates to:
  /// **'1-qadam: Telegram ID kiriting'**
  String get step1TelegramId;

  /// No description provided for @howToGetTelegramId.
  ///
  /// In uz, this message translates to:
  /// **'Telegram ID qanday olish?'**
  String get howToGetTelegramId;

  /// No description provided for @telegramIdInstructions.
  ///
  /// In uz, this message translates to:
  /// **'1. Botga o\'ting: @your_bot_name\n2. /myid buyrug\'ini yuboring\n3. ID ni nusxalang'**
  String get telegramIdInstructions;

  /// No description provided for @openBot.
  ///
  /// In uz, this message translates to:
  /// **'Botni ochish →'**
  String get openBot;

  /// No description provided for @telegramIdConfirmed.
  ///
  /// In uz, this message translates to:
  /// **'Telegram ID tasdiqlandi!'**
  String get telegramIdConfirmed;

  /// No description provided for @step2EnterCode.
  ///
  /// In uz, this message translates to:
  /// **'2-qadam: Botdan kelgan kodni kiriting'**
  String get step2EnterCode;

  /// No description provided for @whereToGetCode.
  ///
  /// In uz, this message translates to:
  /// **'Kodni qayerdan olish?'**
  String get whereToGetCode;

  /// No description provided for @codeInstructions.
  ///
  /// In uz, this message translates to:
  /// **'1. Botga /code buyrug\'ini yuboring\n2. Bot sizga 4 xonali kod yuboradi\n3. Kodni bu yerga kiriting'**
  String get codeInstructions;

  /// No description provided for @coinReward.
  ///
  /// In uz, this message translates to:
  /// **'+{reward} coin olasiz'**
  String coinReward(int reward);

  /// No description provided for @next.
  ///
  /// In uz, this message translates to:
  /// **'Keyingi'**
  String get next;

  /// No description provided for @verify.
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlash'**
  String get verify;

  /// No description provided for @coinEarned.
  ///
  /// In uz, this message translates to:
  /// **'+{reward} coin oldiniz!'**
  String coinEarned(int reward);

  /// No description provided for @taskAlreadyCompleted.
  ///
  /// In uz, this message translates to:
  /// **'Bu vazifa bugun allaqachon bajarilgan'**
  String get taskAlreadyCompleted;

  /// No description provided for @telegramVerify.
  ///
  /// In uz, this message translates to:
  /// **'Telegram Tekshirish'**
  String get telegramVerify;

  /// No description provided for @enterTelegramIdLabel.
  ///
  /// In uz, this message translates to:
  /// **'Telegram ID kiriting:'**
  String get enterTelegramIdLabel;

  /// No description provided for @telegramIdInstructions2.
  ///
  /// In uz, this message translates to:
  /// **'1. Telegram\'da @userinfobot ga yozing\n2. /start bosing\n3. \"Id:\" qatoridagi raqamni nusxalang'**
  String get telegramIdInstructions2;

  /// No description provided for @openUserInfoBot.
  ///
  /// In uz, this message translates to:
  /// **'@userinfobot ochish →'**
  String get openUserInfoBot;

  /// No description provided for @check.
  ///
  /// In uz, this message translates to:
  /// **'Tekshirish'**
  String get check;

  /// No description provided for @subscriptionNotFound.
  ///
  /// In uz, this message translates to:
  /// **'Obuna topilmadi! Kanalga obuna bo\'ling va qaytadan urinib ko\'ring.'**
  String get subscriptionNotFound;

  /// No description provided for @telegramChannel.
  ///
  /// In uz, this message translates to:
  /// **'Telegram Kanal'**
  String get telegramChannel;

  /// No description provided for @subscribedToChannel.
  ///
  /// In uz, this message translates to:
  /// **'Telegram kanalga obuna bo\'ldingizmi?'**
  String get subscribedToChannel;

  /// No description provided for @no.
  ///
  /// In uz, this message translates to:
  /// **'Yo\'q'**
  String get no;

  /// No description provided for @yesSubscribed.
  ///
  /// In uz, this message translates to:
  /// **'Ha, obuna bo\'ldim'**
  String get yesSubscribed;

  /// No description provided for @subscribedToInstagram.
  ///
  /// In uz, this message translates to:
  /// **'Instagram sahifaga obuna bo\'ldingizmi?'**
  String get subscribedToInstagram;

  /// No description provided for @taskCompletedQuestion.
  ///
  /// In uz, this message translates to:
  /// **'Vazifani bajardingizmi?'**
  String get taskCompletedQuestion;

  /// No description provided for @shareAppText.
  ///
  /// In uz, this message translates to:
  /// **'TDM Training - UC topishning eng oson yo\'li! Bu ilovani yuklab oling va coin to\'plang!'**
  String get shareAppText;

  /// No description provided for @share.
  ///
  /// In uz, this message translates to:
  /// **'Ulashish'**
  String get share;

  /// No description provided for @sharedApp.
  ///
  /// In uz, this message translates to:
  /// **'Ilovani ulashdingizmi?'**
  String get sharedApp;

  /// No description provided for @adNotLoaded.
  ///
  /// In uz, this message translates to:
  /// **'Reklama yuklanmadi'**
  String get adNotLoaded;

  /// No description provided for @taskTypeDailyBonus.
  ///
  /// In uz, this message translates to:
  /// **'Kunlik bonus'**
  String get taskTypeDailyBonus;

  /// No description provided for @taskTypeInviteFriend.
  ///
  /// In uz, this message translates to:
  /// **'Do\'st taklif'**
  String get taskTypeInviteFriend;

  /// No description provided for @taskTypeAd.
  ///
  /// In uz, this message translates to:
  /// **'Reklama'**
  String get taskTypeAd;

  /// No description provided for @taskTypeGame.
  ///
  /// In uz, this message translates to:
  /// **'O\'yin'**
  String get taskTypeGame;

  /// No description provided for @taskTypeApp.
  ///
  /// In uz, this message translates to:
  /// **'Ilova'**
  String get taskTypeApp;

  /// No description provided for @taskTypeShare.
  ///
  /// In uz, this message translates to:
  /// **'Ulashish'**
  String get taskTypeShare;

  /// No description provided for @taskTypeRate.
  ///
  /// In uz, this message translates to:
  /// **'Baholash'**
  String get taskTypeRate;

  /// No description provided for @todayProgress.
  ///
  /// In uz, this message translates to:
  /// **'Bugungi progress'**
  String get todayProgress;

  /// No description provided for @noTasksYet.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha vazifalar yo\'q'**
  String get noTasksYet;

  /// No description provided for @newTasksComingSoon.
  ///
  /// In uz, this message translates to:
  /// **'Tez orada yangi vazifalar qo\'shiladi'**
  String get newTasksComingSoon;

  /// No description provided for @yourReferralCode.
  ///
  /// In uz, this message translates to:
  /// **'Taklif kodingiz'**
  String get yourReferralCode;

  /// No description provided for @copy.
  ///
  /// In uz, this message translates to:
  /// **'Nusxalash'**
  String get copy;

  /// No description provided for @referralEarnInfo.
  ///
  /// In uz, this message translates to:
  /// **'Har bir taklif uchun +100 coin oling!'**
  String get referralEarnInfo;

  /// No description provided for @haveReferralCode.
  ///
  /// In uz, this message translates to:
  /// **'Taklif kodi bor?'**
  String get haveReferralCode;

  /// No description provided for @confirm.
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlash'**
  String get confirm;

  /// No description provided for @referralEarnHint.
  ///
  /// In uz, this message translates to:
  /// **'Taklif kodi kiritib +50 coin oling!'**
  String get referralEarnHint;

  /// No description provided for @enter6DigitCode.
  ///
  /// In uz, this message translates to:
  /// **'6 belgili kod kiriting'**
  String get enter6DigitCode;

  /// No description provided for @referralSuccess.
  ///
  /// In uz, this message translates to:
  /// **'+50 coin oldingiz! Taklif qiluvchi ham +100 coin oldi.'**
  String get referralSuccess;

  /// No description provided for @referralCodeNotFound.
  ///
  /// In uz, this message translates to:
  /// **'Kod topilmadi yoki allaqachon ishlatilgan'**
  String get referralCodeNotFound;

  /// No description provided for @taskCompleted.
  ///
  /// In uz, this message translates to:
  /// **'Bajarildi'**
  String get taskCompleted;

  /// No description provided for @enterTelegramIdError.
  ///
  /// In uz, this message translates to:
  /// **'Telegram ID kiriting'**
  String get enterTelegramIdError;

  /// No description provided for @invalidIdFormat.
  ///
  /// In uz, this message translates to:
  /// **'Noto\'g\'ri ID format'**
  String get invalidIdFormat;

  /// No description provided for @subscribeFirst.
  ///
  /// In uz, this message translates to:
  /// **'Avval botga obuna bo\'ling va /code buyrug\'ini yuboring'**
  String get subscribeFirst;

  /// No description provided for @serverError.
  ///
  /// In uz, this message translates to:
  /// **'Server bilan bog\'lanishda xatolik'**
  String get serverError;

  /// No description provided for @checkInternet.
  ///
  /// In uz, this message translates to:
  /// **'Internet ulanishini tekshiring'**
  String get checkInternet;

  /// No description provided for @enter4DigitCode.
  ///
  /// In uz, this message translates to:
  /// **'4 xonali kod kiriting'**
  String get enter4DigitCode;

  /// No description provided for @wrongCode.
  ///
  /// In uz, this message translates to:
  /// **'Noto\'g\'ri kod'**
  String get wrongCode;

  /// No description provided for @yesCompleted.
  ///
  /// In uz, this message translates to:
  /// **'Ha, bajardim'**
  String get yesCompleted;

  /// No description provided for @referralShareText.
  ///
  /// In uz, this message translates to:
  /// **'TDM Training ilovasini yuklab, mening taklif kodimni kiriting: {code}\nDo\'stingiz uchun +50 coin, siz uchun +100 coin!'**
  String referralShareText(String code);

  /// No description provided for @sendCodeToBot.
  ///
  /// In uz, this message translates to:
  /// **'Botga /code buyrug\'ini yuboring'**
  String get sendCodeToBot;

  /// No description provided for @ucShopBuyViaId.
  ///
  /// In uz, this message translates to:
  /// **'ID orqali UC sotib oling'**
  String get ucShopBuyViaId;

  /// No description provided for @ucShopDesc.
  ///
  /// In uz, this message translates to:
  /// **'To\'lovni amalga oshiring, chekni yuklang, admin tasdiqlagandan so\'ng UC yuboriladi'**
  String get ucShopDesc;

  /// No description provided for @ucPricesList.
  ///
  /// In uz, this message translates to:
  /// **'UC NARXLARI'**
  String get ucPricesList;

  /// No description provided for @orderHistory.
  ///
  /// In uz, this message translates to:
  /// **'BUYURTMALAR TARIXI'**
  String get orderHistory;

  /// No description provided for @noOrdersYet.
  ///
  /// In uz, this message translates to:
  /// **'Hali buyurtma yo\'q'**
  String get noOrdersYet;

  /// No description provided for @enterYourPubgId.
  ///
  /// In uz, this message translates to:
  /// **'ID raqamingizni kiriting'**
  String get enterYourPubgId;

  /// No description provided for @selectImage.
  ///
  /// In uz, this message translates to:
  /// **'Rasm tanlash'**
  String get selectImage;

  /// No description provided for @camera.
  ///
  /// In uz, this message translates to:
  /// **'Kamera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In uz, this message translates to:
  /// **'Galereya'**
  String get gallery;

  /// No description provided for @receiptSelected.
  ///
  /// In uz, this message translates to:
  /// **'Chek tanlandi'**
  String get receiptSelected;

  /// No description provided for @uploadReceipt.
  ///
  /// In uz, this message translates to:
  /// **'Chek rasmini yuklang'**
  String get uploadReceipt;

  /// No description provided for @paymentNote.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov chekini yuklang. Admin tekshirib tasdiqlagandan so\'ng UC yuboriladi.'**
  String get paymentNote;

  /// No description provided for @imageUploadFailed.
  ///
  /// In uz, this message translates to:
  /// **'Rasm yuklanmadi. Qayta urinib ko\'ring.'**
  String get imageUploadFailed;

  /// No description provided for @orderAccepted.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma qabul qilindi! Admin tekshiradi.'**
  String get orderAccepted;

  /// No description provided for @submitting.
  ///
  /// In uz, this message translates to:
  /// **'Yuborilmoqda...'**
  String get submitting;

  /// No description provided for @placeOrder.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma berish'**
  String get placeOrder;

  /// No description provided for @ucStatusPending.
  ///
  /// In uz, this message translates to:
  /// **'Chek kutilmoqda'**
  String get ucStatusPending;

  /// No description provided for @ucStatusConfirmed.
  ///
  /// In uz, this message translates to:
  /// **'Chek tasdiqlandi'**
  String get ucStatusConfirmed;

  /// No description provided for @ucStatusCompleted.
  ///
  /// In uz, this message translates to:
  /// **'Bajarildi'**
  String get ucStatusCompleted;

  /// No description provided for @ucStatusRejected.
  ///
  /// In uz, this message translates to:
  /// **'Rad etildi'**
  String get ucStatusRejected;

  /// No description provided for @ucStatusUnknown.
  ///
  /// In uz, this message translates to:
  /// **'Noma\'lum'**
  String get ucStatusUnknown;

  /// No description provided for @som.
  ///
  /// In uz, this message translates to:
  /// **'so\'m'**
  String get som;

  /// No description provided for @priceSom.
  ///
  /// In uz, this message translates to:
  /// **'{price} so\'m'**
  String priceSom(String price);

  /// No description provided for @dailyLimit.
  ///
  /// In uz, this message translates to:
  /// **'Kunlik Limit'**
  String get dailyLimit;

  /// No description provided for @dailyLimitReached.
  ///
  /// In uz, this message translates to:
  /// **'Bugun maksimal o\'yin soniga yetdingiz!'**
  String get dailyLimitReached;

  /// No description provided for @dailyGameLimitInfo.
  ///
  /// In uz, this message translates to:
  /// **'Kuniga {count} marta o\'ynash mumkin'**
  String dailyGameLimitInfo(int count);

  /// No description provided for @tryAgainTomorrow.
  ///
  /// In uz, this message translates to:
  /// **'Ertaga qayta urinib ko\'ring!'**
  String get tryAgainTomorrow;

  /// No description provided for @gamePreparingLoading.
  ///
  /// In uz, this message translates to:
  /// **'O\'yin tayyorlanmoqda...'**
  String get gamePreparingLoading;

  /// No description provided for @adFailedRetry.
  ///
  /// In uz, this message translates to:
  /// **'Reklama yuklanmadi. Qayta urinib ko\'ring.'**
  String get adFailedRetry;

  /// No description provided for @matchFinishedTitle.
  ///
  /// In uz, this message translates to:
  /// **'Match {number} Tugadi!'**
  String matchFinishedTitle(int number);

  /// No description provided for @coinEarnedGame.
  ///
  /// In uz, this message translates to:
  /// **'+1 Coin oldingiz!'**
  String get coinEarnedGame;

  /// No description provided for @averageTimeLabel.
  ///
  /// In uz, this message translates to:
  /// **'O\'rtacha vaqt:'**
  String get averageTimeLabel;

  /// No description provided for @hitsLabel.
  ///
  /// In uz, this message translates to:
  /// **'Tegganlar:'**
  String get hitsLabel;

  /// No description provided for @missesLabel.
  ///
  /// In uz, this message translates to:
  /// **'O\'tkaziganlar:'**
  String get missesLabel;

  /// No description provided for @passedLabel.
  ///
  /// In uz, this message translates to:
  /// **'O\'tganlar:'**
  String get passedLabel;

  /// No description provided for @crashedLabel.
  ///
  /// In uz, this message translates to:
  /// **'Urilganlar:'**
  String get crashedLabel;

  /// No description provided for @remainingMatchesInfo.
  ///
  /// In uz, this message translates to:
  /// **'Bugun yana {count} match o\'ynash mumkin'**
  String remainingMatchesInfo(int count);

  /// No description provided for @nextMatch.
  ///
  /// In uz, this message translates to:
  /// **'Keyingi Match'**
  String get nextMatch;

  /// No description provided for @tapToJump.
  ///
  /// In uz, this message translates to:
  /// **'Tap to Jump!'**
  String get tapToJump;

  /// No description provided for @passThroughPipes.
  ///
  /// In uz, this message translates to:
  /// **'Pipe\'lardan o\'tib boring'**
  String get passThroughPipes;

  /// No description provided for @timeLabel.
  ///
  /// In uz, this message translates to:
  /// **'Vaqt:'**
  String get timeLabel;

  /// No description provided for @targetsLabel.
  ///
  /// In uz, this message translates to:
  /// **'Nishonlar:'**
  String get targetsLabel;

  /// No description provided for @targetSmall.
  ///
  /// In uz, this message translates to:
  /// **'Kichik'**
  String get targetSmall;

  /// No description provided for @targetLarge.
  ///
  /// In uz, this message translates to:
  /// **'Katta'**
  String get targetLarge;

  /// No description provided for @matchLabel.
  ///
  /// In uz, this message translates to:
  /// **'Match {number}'**
  String matchLabel(int number);

  /// No description provided for @flappyModeMatch.
  ///
  /// In uz, this message translates to:
  /// **'Flappy Mode - Match {number}'**
  String flappyModeMatch(int number);

  /// No description provided for @rewardCoins.
  ///
  /// In uz, this message translates to:
  /// **'+{coins} Coin'**
  String rewardCoins(int coins);

  /// No description provided for @backToLevels.
  ///
  /// In uz, this message translates to:
  /// **'Darajalar'**
  String get backToLevels;

  /// No description provided for @miniPubgDestroyEnemies.
  ///
  /// In uz, this message translates to:
  /// **'Dushmanlarni yo\'q qiling!'**
  String get miniPubgDestroyEnemies;

  /// No description provided for @gamesLeftWarning.
  ///
  /// In uz, this message translates to:
  /// **'Faqat {count} ta o\'yin qoldi!'**
  String gamesLeftWarning(int count);

  /// No description provided for @autoFire.
  ///
  /// In uz, this message translates to:
  /// **'Avto-otish'**
  String get autoFire;

  /// No description provided for @selectLevel.
  ///
  /// In uz, this message translates to:
  /// **'DARAJA TANLANG'**
  String get selectLevel;

  /// No description provided for @miniPubgEasyDesc.
  ///
  /// In uz, this message translates to:
  /// **'Sekin dushmanlar'**
  String get miniPubgEasyDesc;

  /// No description provided for @miniPubgMediumDesc.
  ///
  /// In uz, this message translates to:
  /// **'Tezroq harakat'**
  String get miniPubgMediumDesc;

  /// No description provided for @miniPubgHardDesc.
  ///
  /// In uz, this message translates to:
  /// **'Juda tez dushmanlar'**
  String get miniPubgHardDesc;

  /// No description provided for @back.
  ///
  /// In uz, this message translates to:
  /// **'Orqaga'**
  String get back;

  /// No description provided for @killRewardInfo.
  ///
  /// In uz, this message translates to:
  /// **'10+ kill = 1 Coin'**
  String get killRewardInfo;

  /// No description provided for @remaining.
  ///
  /// In uz, this message translates to:
  /// **'Qolgan'**
  String get remaining;

  /// No description provided for @gamesCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} o\'yin'**
  String gamesCount(int count);

  /// No description provided for @waveNumber.
  ///
  /// In uz, this message translates to:
  /// **'To\'lqin {number}'**
  String waveNumber(int number);

  /// No description provided for @controlHintAutoFire.
  ///
  /// In uz, this message translates to:
  /// **'Chapga-o\'ngga suring'**
  String get controlHintAutoFire;

  /// No description provided for @controlHintManual.
  ///
  /// In uz, this message translates to:
  /// **'Suring va bosing'**
  String get controlHintManual;

  /// No description provided for @gameOverTitle.
  ///
  /// In uz, this message translates to:
  /// **'O\'YIN TUGADI!'**
  String get gameOverTitle;

  /// No description provided for @enemies.
  ///
  /// In uz, this message translates to:
  /// **'Dushmanlar'**
  String get enemies;

  /// No description provided for @maxComboLabel.
  ///
  /// In uz, this message translates to:
  /// **'Max Combo'**
  String get maxComboLabel;

  /// No description provided for @accuracyShort.
  ///
  /// In uz, this message translates to:
  /// **'Aniqlik'**
  String get accuracyShort;

  /// No description provided for @coinsEarnedLabel.
  ///
  /// In uz, this message translates to:
  /// **'COIN OLINDI'**
  String get coinsEarnedLabel;

  /// No description provided for @menuButton.
  ///
  /// In uz, this message translates to:
  /// **'MENYU'**
  String get menuButton;

  /// No description provided for @playAgain.
  ///
  /// In uz, this message translates to:
  /// **'YANA O\'YNASH'**
  String get playAgain;

  /// No description provided for @promoCodeTitle.
  ///
  /// In uz, this message translates to:
  /// **'Telegram Bot Vazifa'**
  String get promoCodeTitle;

  /// No description provided for @promoCodeDesc.
  ///
  /// In uz, this message translates to:
  /// **'Telegram botimizda vazifalarni bajaring va promo kod oling!'**
  String get promoCodeDesc;

  /// No description provided for @openTelegramBot.
  ///
  /// In uz, this message translates to:
  /// **'Telegram Botni ochish'**
  String get openTelegramBot;

  /// No description provided for @enterPromoCode.
  ///
  /// In uz, this message translates to:
  /// **'Promo kodni kiriting'**
  String get enterPromoCode;

  /// No description provided for @redeemCode.
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlash'**
  String get redeemCode;

  /// No description provided for @promoCodeSuccess.
  ///
  /// In uz, this message translates to:
  /// **'Tabriklaymiz! +{coins} coin qo\'shildi!'**
  String promoCodeSuccess(int coins);

  /// No description provided for @promoCodeInvalid.
  ///
  /// In uz, this message translates to:
  /// **'Promo kod topilmadi'**
  String get promoCodeInvalid;

  /// No description provided for @promoCodeUsed.
  ///
  /// In uz, this message translates to:
  /// **'Bu promo kod allaqachon ishlatilgan'**
  String get promoCodeUsed;

  /// No description provided for @promoCodeError.
  ///
  /// In uz, this message translates to:
  /// **'Xatolik yuz berdi. Qayta urinib ko\'ring'**
  String get promoCodeError;

  /// No description provided for @ucServiceBadge.
  ///
  /// In uz, this message translates to:
  /// **'100% HALOL VA HAQIQIY'**
  String get ucServiceBadge;

  /// No description provided for @ucServiceDesc2.
  ///
  /// In uz, this message translates to:
  /// **'Eng yaxshi UC servis xizmati! Tez, ishonchli va arzon narxlarda PUBG Mobile UC xarid qiling. Barcha tranzaksiyalar kafolatlanadi.'**
  String get ucServiceDesc2;

  /// No description provided for @ucOrderViaTelegram.
  ///
  /// In uz, this message translates to:
  /// **'Telegram orqali buyurtma berish'**
  String get ucOrderViaTelegram;

  /// No description provided for @ucServiceFeature1.
  ///
  /// In uz, this message translates to:
  /// **'Tez yetkazib berish (5-30 daqiqa)'**
  String get ucServiceFeature1;

  /// No description provided for @ucServiceFeature2.
  ///
  /// In uz, this message translates to:
  /// **'Eng arzon narxlar'**
  String get ucServiceFeature2;

  /// No description provided for @ucServiceFeature3.
  ///
  /// In uz, this message translates to:
  /// **'24/7 qo\'llab-quvvatlash'**
  String get ucServiceFeature3;

  /// No description provided for @ucServiceFeature4.
  ///
  /// In uz, this message translates to:
  /// **'100% xavfsiz tranzaksiya'**
  String get ucServiceFeature4;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
