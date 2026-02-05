// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'PUBG TDM Training';

  @override
  String get loading => 'Загрузка...';

  @override
  String get pubgTdm => 'PUBG TDM';

  @override
  String get training => 'TRAINING';

  @override
  String get reaction => 'REACTION';

  @override
  String get improveReaction => 'Улучшите скорость реакции';

  @override
  String get testAccount => 'Тест аккаунт';

  @override
  String get testAccountWarning =>
      'на тест аккаунт UC не начисляется и постоянно использовать нельзя';

  @override
  String get testAccountCredentials =>
      'Email: testaccount@test.com\nПароль: 12345678';

  @override
  String get email => 'Email';

  @override
  String get password => 'Пароль';

  @override
  String get name => 'Имя';

  @override
  String get confirmPassword => 'Подтвердите пароль';

  @override
  String get nickname => 'Никнейм';

  @override
  String get pubgId => 'PUBG ID';

  @override
  String get enterEmail => 'Введите email';

  @override
  String get enterValidEmail => 'Введите корректный email';

  @override
  String get enterPassword => 'Введите пароль';

  @override
  String get passwordMinLength => 'Пароль должен содержать минимум 6 символов';

  @override
  String get enterName => 'Введите имя';

  @override
  String get nameMinLength => 'Имя должно содержать минимум 2 символа';

  @override
  String get confirmPasswordHint => 'Подтвердите пароль';

  @override
  String get passwordsNotMatch => 'Пароли не совпадают';

  @override
  String get login => 'Войти';

  @override
  String get or => 'или';

  @override
  String get signInWithGoogle => 'Войти через Google';

  @override
  String get noAccount => 'Нет аккаунта? ';

  @override
  String get register => 'Регистрация';

  @override
  String get createNewAccount => 'Создайте новый аккаунт';

  @override
  String get haveAccount => 'Уже есть аккаунт? ';

  @override
  String get termsAgreement =>
      'Продолжая, вы соглашаетесь\nс условиями использования';

  @override
  String get loginError => 'Ошибка входа';

  @override
  String get userNotFound => 'Пользователь не найден';

  @override
  String get wrongPassword => 'Неверный пароль';

  @override
  String get invalidEmail => 'Неверный формат email';

  @override
  String get invalidCredential => 'Неверный email или пароль';

  @override
  String get registerError => 'Ошибка при регистрации';

  @override
  String get emailAlreadyInUse => 'Этот email уже зарегистрирован';

  @override
  String get weakPassword => 'Слишком слабый пароль';

  @override
  String loginErrorWithDetails(String error) {
    return 'Ошибка входа: $error';
  }

  @override
  String get noInternet => 'Нет подключения к интернету!';

  @override
  String get noInternetDesc =>
      'Пожалуйста, подключитесь к интернету и попробуйте снова.';

  @override
  String get retry => 'Повторить';

  @override
  String get coins => 'Монеты';

  @override
  String get totalUC => 'Всего UC';

  @override
  String get start => 'НАЧАТЬ';

  @override
  String get startSubtitle => 'Играть Reaction Training';

  @override
  String get coinsMenu => 'МОНЕТЫ';

  @override
  String get coinsMenuSubtitle => 'Собирать монеты и обменивать на UC';

  @override
  String get ucShop => 'МАГАЗИН UC';

  @override
  String get ucShopSubtitle => 'Купить UC (за сумы)';

  @override
  String get tasks => 'ЗАДАНИЯ';

  @override
  String get tasksSubtitle => 'Выполняйте задания — получайте монеты';

  @override
  String get miniPubg => 'МИНИ PUBG';

  @override
  String get miniPubgSubtitle => 'Уничтожайте врагов и получайте монеты';

  @override
  String get leaderboard => 'РЕЙТИНГ';

  @override
  String get leaderboardSubtitle => 'Рейтинг лучших игроков';

  @override
  String get statistics => 'СТАТИСТИКА';

  @override
  String get statisticsSubtitle => 'Просмотр результатов';

  @override
  String get settings => 'НАСТРОЙКИ';

  @override
  String get settingsSubtitle => 'Настройки игры';

  @override
  String get adminPanel => 'АДМИН ПАНЕЛЬ';

  @override
  String get adminPanelSubtitle => 'Пользователи и настройки';

  @override
  String get news => 'НОВОСТИ';

  @override
  String get close => 'Закрыть';

  @override
  String get dataLoadError => 'Ошибка при загрузке данных';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get statsLabel => 'Статистика';

  @override
  String get streak => 'Серия';

  @override
  String streakDays(int count) {
    return '$count дн.';
  }

  @override
  String get total => 'Всего';

  @override
  String get referralCode => 'Реферальный код';

  @override
  String get yourCode => 'Ваш код:';

  @override
  String referralCount(int count) {
    return '$count приглашений';
  }

  @override
  String get codeCopied => 'Код скопирован!';

  @override
  String get appName => 'TDM Training';

  @override
  String get version => 'Версия 2.0.0';

  @override
  String get copyright => '© 2025 TDM Training. Все права защищены.';

  @override
  String get logout => 'Выйти';

  @override
  String get logoutConfirm => 'Вы хотите выйти из аккаунта?';

  @override
  String get cancel => 'Отмена';

  @override
  String get adLoading => 'Загрузка рекламы...';

  @override
  String get skipAd => 'Пропустить';

  @override
  String get user => 'Пользователь';

  @override
  String get difficultyTitle => 'Уровень сложности';

  @override
  String get selectDifficulty => 'Выберите уровень сложности';

  @override
  String get difficultyInfo => 'Каждый уровень имеет свою сложность';

  @override
  String get targetTime => 'Время цели:';

  @override
  String get targetSize => 'Размер цели:';

  @override
  String get scoreMultiplier => 'Множитель очков:';

  @override
  String get movingTargets => 'Движущиеся цели:';

  @override
  String get multipleTargets => 'Несколько целей:';

  @override
  String get yes => 'Да';

  @override
  String get diffEasy => 'ЛЕГКО';

  @override
  String get diffMedium => 'СРЕДНЕ';

  @override
  String get diffHard => 'СЛОЖНО';

  @override
  String get diffExpert => 'ЭКСПЕРТ';

  @override
  String get diffEasyDesc => 'Для начинающих';

  @override
  String get diffMediumDesc => 'Для игроков среднего уровня';

  @override
  String get diffHardDesc => 'Для опытных игроков';

  @override
  String get diffExpertDesc => 'Для профессиональных игроков';

  @override
  String get coinsAndUC => 'Ваши монеты и UC';

  @override
  String get dailyStatus => 'Дневной статус';

  @override
  String get games => 'Игры';

  @override
  String get ads => 'Реклама';

  @override
  String get earnCoins => 'Заработать монеты';

  @override
  String get watchAd => 'Смотреть рекламу';

  @override
  String adRewardInfo(int coins) {
    return '$coins монет за каждую рекламу';
  }

  @override
  String get adLimitReached => 'Лимит исчерпан';

  @override
  String get gameEarnInfo =>
      'Вы также можете заработать монеты играя! В зависимости от точности получите 0-10 монет.';

  @override
  String get ucExchange => 'Обмен на UC';

  @override
  String get exchangeUC => 'Обменять UC';

  @override
  String get notEnough => 'Недостаточно';

  @override
  String get recentExchanges => 'Последние обмены';

  @override
  String get exchangeHistoryEmpty => 'История обменов пуста';

  @override
  String get statusPending => 'Ожидает';

  @override
  String get statusApproved => 'Подтверждено';

  @override
  String get statusRejected => 'Отклонено';

  @override
  String get statusCompleted => 'Завершено';

  @override
  String available(int coins) {
    return 'Доступно: $coins монет';
  }

  @override
  String get selectExchangeAmount => 'Выберите сумму обмена:';

  @override
  String get enterYourInfo => 'Введите ваши данные:';

  @override
  String get exchange => 'Обменять';

  @override
  String get selectExchangeAmountError => 'Пожалуйста, выберите сумму обмена';

  @override
  String get enterNickname => 'Пожалуйста, введите никнейм';

  @override
  String get enterPubgId => 'Пожалуйста, введите PUBG ID';

  @override
  String get notEnoughCoins => 'Недостаточно монет';

  @override
  String get exchangeFailed => 'Обмен не удался';

  @override
  String errorOccurred(String error) {
    return 'Произошла ошибка: $error';
  }

  @override
  String get success => 'Успешно!';

  @override
  String get ucExchangeRequestAccepted => 'Запрос на обмен UC принят!';

  @override
  String get info => 'Данные:';

  @override
  String amount(int coins, int uc) {
    return 'Количество: $coins Монет → $uc UC';
  }

  @override
  String get adminReviewNote =>
      'Запрос будет рассмотрен администратором. UC будут зачислены после подтверждения.';

  @override
  String get ok => 'OK';

  @override
  String get adAlreadyLoading => 'Реклама уже загружается';

  @override
  String get adLimitReachedToday => 'Достигнут дневной лимит рекламы';

  @override
  String pleaseWait(String time) {
    return 'Пожалуйста, подождите $time';
  }

  @override
  String coinsAdded(int coins) {
    return '$coins монет добавлено!';
  }

  @override
  String get coinAddError => 'Ошибка при добавлении монет';

  @override
  String get adShowError => 'Ошибка при показе рекламы';

  @override
  String adShowErrorWithDetails(String error) {
    return 'Ошибка рекламы: $error';
  }

  @override
  String yourRank(int rank) {
    return 'Ваше место: #$rank';
  }

  @override
  String get noDataYet => 'Данных пока нет';

  @override
  String get you => 'Вы';

  @override
  String get overallStats => 'Общая статистика';

  @override
  String get overall => 'Общее';

  @override
  String get results => 'Результаты';

  @override
  String get levels => 'Уровни';

  @override
  String get bestScore => 'Лучший счет';

  @override
  String get averageScore => 'Средний счет';

  @override
  String get gamesPlayed => 'Сыграно игр';

  @override
  String get averageAccuracy => 'Средняя точность';

  @override
  String get detailedInfo => 'Подробная информация';

  @override
  String get totalHits => 'Всего попаданий:';

  @override
  String get totalMisses => 'Всего промахов:';

  @override
  String get totalShots => 'Всего выстрелов:';

  @override
  String get bestResult => 'Лучший результат:';

  @override
  String get score => 'Счет:';

  @override
  String get accuracy => 'Точность:';

  @override
  String get date => 'Дата:';

  @override
  String get clearStats => 'Очистить статистику';

  @override
  String get statsCleared => 'Статистика очищена';

  @override
  String get noResultsYet => 'Результатов пока нет';

  @override
  String get playToCollect => 'Играйте, чтобы собрать результаты!';

  @override
  String hits(int hits, int total) {
    return 'Попадания: $hits/$total';
  }

  @override
  String gamesPlayedCount(int count) {
    return '$count игр сыграно';
  }

  @override
  String get best => 'Лучший';

  @override
  String get notPlayedYet => 'На этом уровне ещё не играли';

  @override
  String get clearStatsConfirm =>
      'Все результаты и статистика будут удалены. Это действие нельзя отменить.';

  @override
  String get clear => 'Очистить';

  @override
  String get adLoadingText => 'Загрузка рекламы...';

  @override
  String get adLoadFailed => 'Реклама не загрузилась';

  @override
  String get startGame => 'СТАРТ';

  @override
  String get readyToPlay => 'Готов к игре';

  @override
  String matchNumber(int number) {
    return 'Матч #$number';
  }

  @override
  String get gameDuration => 'Длительность игры';

  @override
  String get targetSizeLabel => 'Размер цели';

  @override
  String get rewardLabel => 'Награда';

  @override
  String upToCoins(int coins) {
    return 'до $coins монет';
  }

  @override
  String get level => 'Уровень';

  @override
  String get lives => 'Жизни';

  @override
  String get reward => 'Награда';

  @override
  String get remainingGames => 'Осталось игр';

  @override
  String get language => 'Язык';

  @override
  String get uzbek => 'O\'zbekcha';

  @override
  String get russian => 'Русский';

  @override
  String get english => 'English';

  @override
  String get selectLanguage => 'Выберите язык';

  @override
  String get totalUsers => 'Всего юзеров';

  @override
  String get activeToday => 'Активных сегодня';

  @override
  String get pending => 'Ожидает';

  @override
  String get users => 'Пользователи';

  @override
  String get usersSubtitle => 'Просмотр и управление пользователями';

  @override
  String get tasksAdmin => 'Задания';

  @override
  String get tasksAdminSubtitle => 'Добавление и управление заданиями';

  @override
  String get ucRequests => 'Запросы UC';

  @override
  String ucRequestsSubtitle(int count) {
    return '$count ожидающих запросов';
  }

  @override
  String get announcements => 'Объявления';

  @override
  String get announcementsSubtitle => 'Управление новостями и объявлениями';

  @override
  String get ucOrders => 'Заказы UC';

  @override
  String get ucOrdersSubtitle => 'Заказы на покупку UC';

  @override
  String get settingsAdmin => 'Настройки';

  @override
  String get settingsAdminSubtitle => 'Telegram, Instagram, лимиты';

  @override
  String get notLoggedIn => 'Вы не авторизованы! Пожалуйста, войдите заново';

  @override
  String get taskWarning =>
      'Предупреждение: Ваша подписка (или выполненное задание) проверяется администраторами.\nЕсли вы обманете, с вашего аккаунта будет списано в 2 раза больше монет.';

  @override
  String get telegramIdTitle => 'Telegram ID';

  @override
  String get verificationCode => 'Код подтверждения';

  @override
  String get step1TelegramId => 'Шаг 1: Введите Telegram ID';

  @override
  String get howToGetTelegramId => 'Как узнать Telegram ID?';

  @override
  String get telegramIdInstructions =>
      '1. Перейдите к боту: @your_bot_name\n2. Отправьте команду /myid\n3. Скопируйте ID';

  @override
  String get openBot => 'Открыть бота →';

  @override
  String get telegramIdConfirmed => 'Telegram ID подтверждён!';

  @override
  String get step2EnterCode => 'Шаг 2: Введите код от бота';

  @override
  String get whereToGetCode => 'Где взять код?';

  @override
  String get codeInstructions =>
      '1. Отправьте боту команду /code\n2. Бот отправит вам 4-значный код\n3. Введите код здесь';

  @override
  String coinReward(int reward) {
    return '+$reward монет получите';
  }

  @override
  String get next => 'Далее';

  @override
  String get verify => 'Подтвердить';

  @override
  String coinEarned(int reward) {
    return '+$reward монет получено!';
  }

  @override
  String get taskAlreadyCompleted => 'Это задание уже выполнено сегодня';

  @override
  String get telegramVerify => 'Проверка Telegram';

  @override
  String get enterTelegramIdLabel => 'Введите Telegram ID:';

  @override
  String get telegramIdInstructions2 =>
      '1. Напишите @userinfobot в Telegram\n2. Нажмите /start\n3. Скопируйте число из строки \"Id:\"';

  @override
  String get openUserInfoBot => 'Открыть @userinfobot →';

  @override
  String get check => 'Проверить';

  @override
  String get subscriptionNotFound =>
      'Подписка не найдена! Подпишитесь на канал и попробуйте снова.';

  @override
  String get telegramChannel => 'Telegram Канал';

  @override
  String get subscribedToChannel => 'Вы подписались на Telegram канал?';

  @override
  String get no => 'Нет';

  @override
  String get yesSubscribed => 'Да, подписался';

  @override
  String get subscribedToInstagram => 'Вы подписались на Instagram?';

  @override
  String get taskCompletedQuestion => 'Вы выполнили задание?';

  @override
  String get shareAppText =>
      'TDM Training - самый простой способ получить UC! Скачайте приложение и собирайте монеты!';

  @override
  String get share => 'Поделиться';

  @override
  String get sharedApp => 'Вы поделились приложением?';

  @override
  String get adNotLoaded => 'Реклама не загрузилась';

  @override
  String get taskTypeDailyBonus => 'Ежедневный бонус';

  @override
  String get taskTypeInviteFriend => 'Пригласить друга';

  @override
  String get taskTypeAd => 'Реклама';

  @override
  String get taskTypeGame => 'Игра';

  @override
  String get taskTypeApp => 'Приложение';

  @override
  String get taskTypeShare => 'Поделиться';

  @override
  String get taskTypeRate => 'Оценить';

  @override
  String get todayProgress => 'Прогресс за сегодня';

  @override
  String get noTasksYet => 'Заданий пока нет';

  @override
  String get newTasksComingSoon => 'Скоро появятся новые задания';

  @override
  String get yourReferralCode => 'Ваш код приглашения';

  @override
  String get copy => 'Копировать';

  @override
  String get referralEarnInfo => 'Получите +100 монет за каждое приглашение!';

  @override
  String get haveReferralCode => 'Есть код приглашения?';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get referralEarnHint =>
      'Введите код приглашения и получите +50 монет!';

  @override
  String get enter6DigitCode => 'Введите 6-значный код';

  @override
  String get referralSuccess =>
      '+50 монет получено! Пригласивший тоже получил +100 монет.';

  @override
  String get referralCodeNotFound => 'Код не найден или уже использован';

  @override
  String get taskCompleted => 'Выполнено';

  @override
  String get enterTelegramIdError => 'Введите Telegram ID';

  @override
  String get invalidIdFormat => 'Неверный формат ID';

  @override
  String get subscribeFirst =>
      'Сначала подпишитесь на бота и отправьте команду /code';

  @override
  String get serverError => 'Ошибка подключения к серверу';

  @override
  String get checkInternet => 'Проверьте подключение к интернету';

  @override
  String get enter4DigitCode => 'Введите 4-значный код';

  @override
  String get wrongCode => 'Неверный код';

  @override
  String get yesCompleted => 'Да, выполнил';

  @override
  String referralShareText(String code) {
    return 'Скачайте TDM Training и введите мой код приглашения: $code\nВашему другу +50 монет, вам +100 монет!';
  }

  @override
  String get sendCodeToBot => 'Отправьте боту команду /code';

  @override
  String get ucShopBuyViaId => 'Покупайте UC через ID';

  @override
  String get ucShopDesc =>
      'Оплатите, загрузите чек, после подтверждения админом UC будет отправлен';

  @override
  String get ucPricesList => 'ЦЕНЫ НА UC';

  @override
  String get orderHistory => 'ИСТОРИЯ ЗАКАЗОВ';

  @override
  String get noOrdersYet => 'Заказов пока нет';

  @override
  String get enterYourPubgId => 'Введите ваш ID';

  @override
  String get selectImage => 'Выбрать фото';

  @override
  String get camera => 'Камера';

  @override
  String get gallery => 'Галерея';

  @override
  String get receiptSelected => 'Чек выбран';

  @override
  String get uploadReceipt => 'Загрузите фото чека';

  @override
  String get paymentNote =>
      'Загрузите чек оплаты. UC будет отправлен после подтверждения админом.';

  @override
  String get imageUploadFailed => 'Фото не загрузилось. Попробуйте снова.';

  @override
  String get orderAccepted => 'Заказ принят! Админ проверит.';

  @override
  String get submitting => 'Отправка...';

  @override
  String get placeOrder => 'Оформить заказ';

  @override
  String get ucStatusPending => 'Ожидание чека';

  @override
  String get ucStatusConfirmed => 'Чек подтверждён';

  @override
  String get ucStatusCompleted => 'Выполнено';

  @override
  String get ucStatusRejected => 'Отклонено';

  @override
  String get ucStatusUnknown => 'Неизвестно';

  @override
  String get som => 'сум';

  @override
  String priceSom(String price) {
    return '$price сум';
  }

  @override
  String get dailyLimit => 'Дневной лимит';

  @override
  String get dailyLimitReached =>
      'Достигнут максимальный лимит игр на сегодня!';

  @override
  String dailyGameLimitInfo(int count) {
    return 'Можно играть $count раз в день';
  }

  @override
  String get tryAgainTomorrow => 'Попробуйте завтра!';

  @override
  String get gamePreparingLoading => 'Подготовка к игре...';

  @override
  String get adFailedRetry => 'Реклама не загрузилась. Попробуйте снова.';

  @override
  String matchFinishedTitle(int number) {
    return 'Матч $number завершён!';
  }

  @override
  String get coinEarnedGame => '+1 монет получено!';

  @override
  String get averageTimeLabel => 'Среднее время:';

  @override
  String get hitsLabel => 'Попадания:';

  @override
  String get missesLabel => 'Промахи:';

  @override
  String get passedLabel => 'Пройдено:';

  @override
  String get crashedLabel => 'Столкновения:';

  @override
  String remainingMatchesInfo(int count) {
    return 'Сегодня можно ещё $count матч';
  }

  @override
  String get nextMatch => 'Следующий матч';

  @override
  String get tapToJump => 'Нажмите, чтобы прыгнуть!';

  @override
  String get passThroughPipes => 'Пролетайте через трубы';

  @override
  String get timeLabel => 'Время:';

  @override
  String get targetsLabel => 'Мишени:';

  @override
  String get targetSmall => 'Маленькие';

  @override
  String get targetLarge => 'Большие';

  @override
  String matchLabel(int number) {
    return 'Матч $number';
  }

  @override
  String flappyModeMatch(int number) {
    return 'Flappy Mode - Матч $number';
  }

  @override
  String rewardCoins(int coins) {
    return '+$coins монет';
  }

  @override
  String get backToLevels => 'Уровни';

  @override
  String get miniPubgDestroyEnemies => 'Уничтожьте врагов!';

  @override
  String gamesLeftWarning(int count) {
    return 'Осталось всего $count игр!';
  }

  @override
  String get autoFire => 'Авто-стрельба';

  @override
  String get selectLevel => 'ВЫБЕРИТЕ УРОВЕНЬ';

  @override
  String get miniPubgEasyDesc => 'Медленные враги';

  @override
  String get miniPubgMediumDesc => 'Быстрее движение';

  @override
  String get miniPubgHardDesc => 'Очень быстрые враги';

  @override
  String get back => 'Назад';

  @override
  String get killRewardInfo => '10+ убийств = 1 Coin';

  @override
  String get remaining => 'Осталось';

  @override
  String gamesCount(int count) {
    return '$count игр';
  }

  @override
  String waveNumber(int number) {
    return 'Волна $number';
  }

  @override
  String get controlHintAutoFire => 'Проведите влево-вправо';

  @override
  String get controlHintManual => 'Проведите и нажмите';

  @override
  String get gameOverTitle => 'ИГРА ОКОНЧЕНА!';

  @override
  String get enemies => 'Враги';

  @override
  String get maxComboLabel => 'Max Combo';

  @override
  String get accuracyShort => 'Точность';

  @override
  String get coinsEarnedLabel => 'МОНЕТЫ ПОЛУЧЕНЫ';

  @override
  String get menuButton => 'МЕНЮ';

  @override
  String get playAgain => 'ИГРАТЬ СНОВА';

  @override
  String get promoCodeTitle => 'Задание Telegram бота';

  @override
  String get promoCodeDesc =>
      'Выполните задания в нашем Telegram боте и получите промо-код!';

  @override
  String get openTelegramBot => 'Открыть Telegram бот';

  @override
  String get enterPromoCode => 'Введите промо-код';

  @override
  String get redeemCode => 'Активировать';

  @override
  String promoCodeSuccess(int coins) {
    return 'Поздравляем! +$coins монет добавлено!';
  }

  @override
  String get promoCodeInvalid => 'Промо-код не найден';

  @override
  String get promoCodeUsed => 'Этот промо-код уже использован';

  @override
  String get promoCodeError => 'Произошла ошибка. Попробуйте ещё раз';

  @override
  String get ucServiceBadge => '100% ЧЕСТНО И РЕАЛЬНО';

  @override
  String get ucServiceDesc2 =>
      'Лучший сервис UC! Быстрая, надёжная покупка PUBG Mobile UC по самым низким ценам. Все транзакции гарантированы.';

  @override
  String get ucOrderViaTelegram => 'Заказать через Telegram';

  @override
  String get ucServiceFeature1 => 'Быстрая доставка (5-30 минут)';

  @override
  String get ucServiceFeature2 => 'Самые низкие цены';

  @override
  String get ucServiceFeature3 => 'Поддержка 24/7';

  @override
  String get ucServiceFeature4 => '100% безопасная транзакция';
}
