// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PUBG TDM Training';

  @override
  String get loading => 'Loading...';

  @override
  String get pubgTdm => 'PUBG TDM';

  @override
  String get training => 'TRAINING';

  @override
  String get reaction => 'REACTION';

  @override
  String get improveReaction => 'Improve your reaction speed';

  @override
  String get testAccount => 'Test account';

  @override
  String get testAccountWarning =>
      'UC will not be given to test account and you cannot use it permanently';

  @override
  String get testAccountCredentials =>
      'Email: testaccount@test.com\nPassword: 12345678';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get name => 'Name';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get nickname => 'Nickname';

  @override
  String get pubgId => 'PUBG ID';

  @override
  String get enterEmail => 'Enter email';

  @override
  String get enterValidEmail => 'Enter a valid email';

  @override
  String get enterPassword => 'Enter password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get enterName => 'Enter name';

  @override
  String get nameMinLength => 'Name must be at least 2 characters';

  @override
  String get confirmPasswordHint => 'Confirm password';

  @override
  String get passwordsNotMatch => 'Passwords do not match';

  @override
  String get login => 'Sign In';

  @override
  String get or => 'or';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get noAccount => 'Don\'t have an account? ';

  @override
  String get register => 'Register';

  @override
  String get createNewAccount => 'Create a new account';

  @override
  String get haveAccount => 'Already have an account? ';

  @override
  String get termsAgreement => 'By continuing, you agree to\nthe terms of use';

  @override
  String get loginError => 'Login error';

  @override
  String get userNotFound => 'User not found';

  @override
  String get wrongPassword => 'Wrong password';

  @override
  String get invalidEmail => 'Invalid email format';

  @override
  String get invalidCredential => 'Invalid email or password';

  @override
  String get registerError => 'Registration error';

  @override
  String get emailAlreadyInUse => 'This email is already registered';

  @override
  String get weakPassword => 'Password is too weak';

  @override
  String loginErrorWithDetails(String error) {
    return 'Login error: $error';
  }

  @override
  String get noInternet => 'No internet connection!';

  @override
  String get noInternetDesc => 'Please connect to the internet and try again.';

  @override
  String get retry => 'Retry';

  @override
  String get coins => 'Coins';

  @override
  String get totalUC => 'Total UC';

  @override
  String get start => 'START';

  @override
  String get startSubtitle => 'Play Reaction Training';

  @override
  String get coinsMenu => 'COINS';

  @override
  String get coinsMenuSubtitle => 'Collect coins and exchange for UC';

  @override
  String get ucShop => 'UC SHOP';

  @override
  String get ucShopSubtitle => 'Buy UC (with real money)';

  @override
  String get tasks => 'TASKS';

  @override
  String get tasksSubtitle => 'Complete tasks — earn coins';

  @override
  String get miniPubg => 'MINI PUBG';

  @override
  String get miniPubgSubtitle => 'Destroy enemies and earn coins';

  @override
  String get leaderboard => 'LEADERBOARD';

  @override
  String get leaderboardSubtitle => 'Top players ranking';

  @override
  String get statistics => 'STATISTICS';

  @override
  String get statisticsSubtitle => 'View your results';

  @override
  String get settings => 'SETTINGS';

  @override
  String get settingsSubtitle => 'Game settings';

  @override
  String get adminPanel => 'ADMIN PANEL';

  @override
  String get adminPanelSubtitle => 'Users and settings';

  @override
  String get news => 'NEWS';

  @override
  String get close => 'Close';

  @override
  String get dataLoadError => 'Error loading data';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get statsLabel => 'Statistics';

  @override
  String get streak => 'Streak';

  @override
  String streakDays(int count) {
    return '$count days';
  }

  @override
  String get total => 'Total';

  @override
  String get referralCode => 'Referral Code';

  @override
  String get yourCode => 'Your code:';

  @override
  String referralCount(int count) {
    return '$count referrals';
  }

  @override
  String get codeCopied => 'Code copied!';

  @override
  String get appName => 'TDM Training';

  @override
  String get version => 'Version 2.0.0';

  @override
  String get copyright => '© 2025 TDM Training. All rights reserved.';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirm => 'Do you want to log out?';

  @override
  String get cancel => 'Cancel';

  @override
  String get adLoading => 'Loading ad...';

  @override
  String get skipAd => 'Skip';

  @override
  String get user => 'User';

  @override
  String get difficultyTitle => 'Difficulty Level';

  @override
  String get selectDifficulty => 'Select difficulty level';

  @override
  String get difficultyInfo => 'Each level has its own difficulty';

  @override
  String get targetTime => 'Target time:';

  @override
  String get targetSize => 'Target size:';

  @override
  String get scoreMultiplier => 'Score multiplier:';

  @override
  String get movingTargets => 'Moving targets:';

  @override
  String get multipleTargets => 'Multiple targets:';

  @override
  String get yes => 'Yes';

  @override
  String get diffEasy => 'EASY';

  @override
  String get diffMedium => 'MEDIUM';

  @override
  String get diffHard => 'HARD';

  @override
  String get diffExpert => 'EXPERT';

  @override
  String get diffEasyDesc => 'For beginners';

  @override
  String get diffMediumDesc => 'For intermediate players';

  @override
  String get diffHardDesc => 'For experienced players';

  @override
  String get diffExpertDesc => 'For professional players';

  @override
  String get coinsAndUC => 'Your Coins and UC';

  @override
  String get dailyStatus => 'Daily Status';

  @override
  String get games => 'Games';

  @override
  String get ads => 'Ads';

  @override
  String get earnCoins => 'Earn Coins';

  @override
  String get watchAd => 'Watch Ad';

  @override
  String adRewardInfo(int coins) {
    return '$coins coins per ad';
  }

  @override
  String get adLimitReached => 'Limit reached';

  @override
  String get gameEarnInfo =>
      'You can also earn coins by playing! You\'ll get 0-10 coins based on your accuracy.';

  @override
  String get ucExchange => 'UC Exchange';

  @override
  String get exchangeUC => 'Exchange UC';

  @override
  String get notEnough => 'Not enough';

  @override
  String get recentExchanges => 'Recent Exchanges';

  @override
  String get exchangeHistoryEmpty => 'Exchange history is empty';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusCompleted => 'Completed';

  @override
  String available(int coins) {
    return 'Available: $coins coins';
  }

  @override
  String get selectExchangeAmount => 'Select exchange amount:';

  @override
  String get enterYourInfo => 'Enter your information:';

  @override
  String get exchange => 'Exchange';

  @override
  String get selectExchangeAmountError => 'Please select an exchange amount';

  @override
  String get enterNickname => 'Please enter nickname';

  @override
  String get enterPubgId => 'Please enter PUBG ID';

  @override
  String get notEnoughCoins => 'Not enough coins';

  @override
  String get exchangeFailed => 'Exchange failed';

  @override
  String errorOccurred(String error) {
    return 'An error occurred: $error';
  }

  @override
  String get success => 'Success!';

  @override
  String get ucExchangeRequestAccepted => 'UC exchange request accepted!';

  @override
  String get info => 'Information:';

  @override
  String amount(int coins, int uc) {
    return 'Amount: $coins Coins → $uc UC';
  }

  @override
  String get adminReviewNote =>
      'The request will be reviewed by admin. UC will be credited after confirmation.';

  @override
  String get ok => 'OK';

  @override
  String get adAlreadyLoading => 'Ad is already loading';

  @override
  String get adLimitReachedToday => 'You\'ve reached today\'s ad limit';

  @override
  String pleaseWait(String time) {
    return 'Please wait $time';
  }

  @override
  String coinsAdded(int coins) {
    return '$coins coins added!';
  }

  @override
  String get coinAddError => 'Error adding coins';

  @override
  String get adShowError => 'Error showing ad';

  @override
  String adShowErrorWithDetails(String error) {
    return 'Ad error: $error';
  }

  @override
  String yourRank(int rank) {
    return 'Your rank: #$rank';
  }

  @override
  String get noDataYet => 'No data yet';

  @override
  String get you => 'You';

  @override
  String get overallStats => 'Overall Statistics';

  @override
  String get overall => 'Overall';

  @override
  String get results => 'Results';

  @override
  String get levels => 'Levels';

  @override
  String get bestScore => 'Best Score';

  @override
  String get averageScore => 'Average Score';

  @override
  String get gamesPlayed => 'Games Played';

  @override
  String get averageAccuracy => 'Average Accuracy';

  @override
  String get detailedInfo => 'Detailed Information';

  @override
  String get totalHits => 'Total hits:';

  @override
  String get totalMisses => 'Total misses:';

  @override
  String get totalShots => 'Total shots:';

  @override
  String get bestResult => 'Best result:';

  @override
  String get score => 'Score:';

  @override
  String get accuracy => 'Accuracy:';

  @override
  String get date => 'Date:';

  @override
  String get clearStats => 'Clear Statistics';

  @override
  String get statsCleared => 'Statistics cleared';

  @override
  String get noResultsYet => 'No results yet';

  @override
  String get playToCollect => 'Play games to collect results!';

  @override
  String hits(int hits, int total) {
    return 'Hits: $hits/$total';
  }

  @override
  String gamesPlayedCount(int count) {
    return '$count games played';
  }

  @override
  String get best => 'Best';

  @override
  String get notPlayedYet => 'Not played at this level yet';

  @override
  String get clearStatsConfirm =>
      'All results and statistics will be deleted. This action cannot be undone.';

  @override
  String get clear => 'Clear';

  @override
  String get adLoadingText => 'Loading ad...';

  @override
  String get adLoadFailed => 'Ad failed to load';

  @override
  String get startGame => 'START';

  @override
  String get readyToPlay => 'Ready to play';

  @override
  String matchNumber(int number) {
    return 'Match #$number';
  }

  @override
  String get gameDuration => 'Game duration';

  @override
  String get targetSizeLabel => 'Target size';

  @override
  String get rewardLabel => 'Reward';

  @override
  String upToCoins(int coins) {
    return 'up to $coins coins';
  }

  @override
  String get level => 'Level';

  @override
  String get lives => 'Lives';

  @override
  String get reward => 'Reward';

  @override
  String get remainingGames => 'Games left';

  @override
  String get language => 'Language';

  @override
  String get uzbek => 'O\'zbekcha';

  @override
  String get russian => 'Русский';

  @override
  String get english => 'English';

  @override
  String get selectLanguage => 'Select language';

  @override
  String get totalUsers => 'Total users';

  @override
  String get activeToday => 'Active today';

  @override
  String get pending => 'Pending';

  @override
  String get users => 'Users';

  @override
  String get usersSubtitle => 'View and manage all users';

  @override
  String get tasksAdmin => 'Tasks';

  @override
  String get tasksAdminSubtitle => 'Add and manage tasks';

  @override
  String get ucRequests => 'UC Requests';

  @override
  String ucRequestsSubtitle(int count) {
    return '$count pending requests';
  }

  @override
  String get announcements => 'Announcements';

  @override
  String get announcementsSubtitle => 'Manage news and announcements';

  @override
  String get ucOrders => 'UC Orders';

  @override
  String get ucOrdersSubtitle => 'UC purchase orders';

  @override
  String get settingsAdmin => 'Settings';

  @override
  String get settingsAdminSubtitle => 'Telegram, Instagram, limits';

  @override
  String get notLoggedIn => 'Not logged in! Please sign in again';

  @override
  String get taskWarning =>
      'Warning: Your subscription (or completed task) is verified by administrators.\nIf you cheat, 2x coins will be deducted from your account.';

  @override
  String get telegramIdTitle => 'Telegram ID';

  @override
  String get verificationCode => 'Verification Code';

  @override
  String get step1TelegramId => 'Step 1: Enter Telegram ID';

  @override
  String get howToGetTelegramId => 'How to get Telegram ID?';

  @override
  String get telegramIdInstructions =>
      '1. Go to bot: @your_bot_name\n2. Send /myid command\n3. Copy the ID';

  @override
  String get openBot => 'Open bot →';

  @override
  String get telegramIdConfirmed => 'Telegram ID confirmed!';

  @override
  String get step2EnterCode => 'Step 2: Enter the code from bot';

  @override
  String get whereToGetCode => 'Where to get the code?';

  @override
  String get codeInstructions =>
      '1. Send /code command to bot\n2. Bot will send you a 4-digit code\n3. Enter the code here';

  @override
  String coinReward(int reward) {
    return '+$reward coins reward';
  }

  @override
  String get next => 'Next';

  @override
  String get verify => 'Verify';

  @override
  String coinEarned(int reward) {
    return '+$reward coins earned!';
  }

  @override
  String get taskAlreadyCompleted =>
      'This task has already been completed today';

  @override
  String get telegramVerify => 'Telegram Verification';

  @override
  String get enterTelegramIdLabel => 'Enter Telegram ID:';

  @override
  String get telegramIdInstructions2 =>
      '1. Write to @userinfobot in Telegram\n2. Press /start\n3. Copy the number from \"Id:\" line';

  @override
  String get openUserInfoBot => 'Open @userinfobot →';

  @override
  String get check => 'Check';

  @override
  String get subscriptionNotFound =>
      'Subscription not found! Subscribe to the channel and try again.';

  @override
  String get telegramChannel => 'Telegram Channel';

  @override
  String get subscribedToChannel =>
      'Did you subscribe to the Telegram channel?';

  @override
  String get no => 'No';

  @override
  String get yesSubscribed => 'Yes, I subscribed';

  @override
  String get subscribedToInstagram => 'Did you follow the Instagram page?';

  @override
  String get taskCompletedQuestion => 'Did you complete the task?';

  @override
  String get shareAppText =>
      'TDM Training - the easiest way to earn UC! Download the app and collect coins!';

  @override
  String get share => 'Share';

  @override
  String get sharedApp => 'Did you share the app?';

  @override
  String get adNotLoaded => 'Ad failed to load';

  @override
  String get taskTypeDailyBonus => 'Daily bonus';

  @override
  String get taskTypeInviteFriend => 'Invite friend';

  @override
  String get taskTypeAd => 'Ad';

  @override
  String get taskTypeGame => 'Game';

  @override
  String get taskTypeApp => 'App';

  @override
  String get taskTypeShare => 'Share';

  @override
  String get taskTypeRate => 'Rate';

  @override
  String get todayProgress => 'Today\'s progress';

  @override
  String get noTasksYet => 'No tasks yet';

  @override
  String get newTasksComingSoon => 'New tasks will be added soon';

  @override
  String get yourReferralCode => 'Your referral code';

  @override
  String get copy => 'Copy';

  @override
  String get referralEarnInfo => 'Get +100 coins for each referral!';

  @override
  String get haveReferralCode => 'Have a referral code?';

  @override
  String get confirm => 'Confirm';

  @override
  String get referralEarnHint => 'Enter referral code and get +50 coins!';

  @override
  String get enter6DigitCode => 'Enter 6-digit code';

  @override
  String get referralSuccess =>
      '+50 coins received! The referrer also got +100 coins.';

  @override
  String get referralCodeNotFound => 'Code not found or already used';

  @override
  String get taskCompleted => 'Completed';

  @override
  String get enterTelegramIdError => 'Enter Telegram ID';

  @override
  String get invalidIdFormat => 'Invalid ID format';

  @override
  String get subscribeFirst =>
      'Subscribe to the bot first and send /code command';

  @override
  String get serverError => 'Server connection error';

  @override
  String get checkInternet => 'Check your internet connection';

  @override
  String get enter4DigitCode => 'Enter 4-digit code';

  @override
  String get wrongCode => 'Wrong code';

  @override
  String get yesCompleted => 'Yes, I completed it';

  @override
  String referralShareText(String code) {
    return 'Download TDM Training and enter my referral code: $code\n+50 coins for your friend, +100 coins for you!';
  }

  @override
  String get sendCodeToBot => 'Send /code command to bot';

  @override
  String get ucShopBuyViaId => 'Buy UC via ID';

  @override
  String get ucShopDesc =>
      'Make payment, upload receipt, UC will be sent after admin confirmation';

  @override
  String get ucPricesList => 'UC PRICES';

  @override
  String get orderHistory => 'ORDER HISTORY';

  @override
  String get noOrdersYet => 'No orders yet';

  @override
  String get enterYourPubgId => 'Enter your ID';

  @override
  String get selectImage => 'Select photo';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get receiptSelected => 'Receipt selected';

  @override
  String get uploadReceipt => 'Upload receipt photo';

  @override
  String get paymentNote =>
      'Upload payment receipt. UC will be sent after admin confirmation.';

  @override
  String get imageUploadFailed => 'Image upload failed. Please try again.';

  @override
  String get orderAccepted => 'Order accepted! Admin will review.';

  @override
  String get submitting => 'Submitting...';

  @override
  String get placeOrder => 'Place order';

  @override
  String get ucStatusPending => 'Awaiting receipt';

  @override
  String get ucStatusConfirmed => 'Receipt confirmed';

  @override
  String get ucStatusCompleted => 'Completed';

  @override
  String get ucStatusRejected => 'Rejected';

  @override
  String get ucStatusUnknown => 'Unknown';

  @override
  String get som => 'UZS';

  @override
  String priceSom(String price) {
    return '$price UZS';
  }

  @override
  String get dailyLimit => 'Daily Limit';

  @override
  String get dailyLimitReached =>
      'You\'ve reached today\'s maximum game limit!';

  @override
  String dailyGameLimitInfo(int count) {
    return 'You can play $count times per day';
  }

  @override
  String get tryAgainTomorrow => 'Try again tomorrow!';

  @override
  String get gamePreparingLoading => 'Preparing game...';

  @override
  String get adFailedRetry => 'Ad failed to load. Please try again.';

  @override
  String matchFinishedTitle(int number) {
    return 'Match $number Finished!';
  }

  @override
  String get coinEarnedGame => '+1 Coin earned!';

  @override
  String get averageTimeLabel => 'Avg. time:';

  @override
  String get hitsLabel => 'Hits:';

  @override
  String get missesLabel => 'Misses:';

  @override
  String get passedLabel => 'Passed:';

  @override
  String get crashedLabel => 'Crashed:';

  @override
  String remainingMatchesInfo(int count) {
    return 'You can play $count more matches today';
  }

  @override
  String get nextMatch => 'Next Match';

  @override
  String get tapToJump => 'Tap to Jump!';

  @override
  String get passThroughPipes => 'Fly through the pipes';

  @override
  String get timeLabel => 'Time:';

  @override
  String get targetsLabel => 'Targets:';

  @override
  String get targetSmall => 'Small';

  @override
  String get targetLarge => 'Large';

  @override
  String matchLabel(int number) {
    return 'Match $number';
  }

  @override
  String flappyModeMatch(int number) {
    return 'Flappy Mode - Match $number';
  }

  @override
  String rewardCoins(int coins) {
    return '+$coins Coin';
  }

  @override
  String get backToLevels => 'Levels';

  @override
  String get miniPubgDestroyEnemies => 'Destroy the enemies!';

  @override
  String gamesLeftWarning(int count) {
    return 'Only $count games left!';
  }

  @override
  String get autoFire => 'Auto-fire';

  @override
  String get selectLevel => 'SELECT LEVEL';

  @override
  String get miniPubgEasyDesc => 'Slow enemies';

  @override
  String get miniPubgMediumDesc => 'Faster movement';

  @override
  String get miniPubgHardDesc => 'Very fast enemies';

  @override
  String get back => 'Back';

  @override
  String get killRewardInfo => '10+ kills = 1 Coin';

  @override
  String get remaining => 'Remaining';

  @override
  String gamesCount(int count) {
    return '$count games';
  }

  @override
  String waveNumber(int number) {
    return 'Wave $number';
  }

  @override
  String get controlHintAutoFire => 'Swipe left-right';

  @override
  String get controlHintManual => 'Swipe and tap';

  @override
  String get gameOverTitle => 'GAME OVER!';

  @override
  String get enemies => 'Enemies';

  @override
  String get maxComboLabel => 'Max Combo';

  @override
  String get accuracyShort => 'Accuracy';

  @override
  String get coinsEarnedLabel => 'COINS EARNED';

  @override
  String get menuButton => 'MENU';

  @override
  String get playAgain => 'PLAY AGAIN';

  @override
  String get promoCodeTitle => 'Telegram Bot Task';

  @override
  String get promoCodeDesc =>
      'Complete tasks in our Telegram bot and get a promo code!';

  @override
  String get openTelegramBot => 'Open Telegram Bot';

  @override
  String get enterPromoCode => 'Enter promo code';

  @override
  String get redeemCode => 'Redeem';

  @override
  String promoCodeSuccess(int coins) {
    return 'Congratulations! +$coins coins added!';
  }

  @override
  String get promoCodeInvalid => 'Promo code not found';

  @override
  String get promoCodeUsed => 'This promo code has already been used';

  @override
  String get promoCodeError => 'An error occurred. Please try again';

  @override
  String get ucServiceBadge => '100% GENUINE AND REAL';

  @override
  String get ucServiceDesc2 =>
      'Best UC service! Fast, reliable PUBG Mobile UC purchase at the lowest prices. All transactions are guaranteed.';

  @override
  String get ucOrderViaTelegram => 'Order via Telegram';

  @override
  String get ucServiceFeature1 => 'Fast delivery (5-30 minutes)';

  @override
  String get ucServiceFeature2 => 'Lowest prices';

  @override
  String get ucServiceFeature3 => '24/7 support';

  @override
  String get ucServiceFeature4 => '100% secure transaction';
}
