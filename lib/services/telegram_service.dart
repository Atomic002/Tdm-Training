import 'dart:convert';
import 'package:http/http.dart' as http;
import 'firestore_service.dart';

class TelegramService {
  static final TelegramService _instance = TelegramService._internal();
  factory TelegramService() => _instance;
  TelegramService._internal();

  final FirestoreService _firestoreService = FirestoreService();

  /// Telegram user ID orqali kanalga obuna bo'lganligini tekshirish
  /// [telegramUserId] — foydalanuvchi Telegram ID (raqam)
  Future<bool> verifyChannelSubscriptionById(int telegramUserId) async {
    try {
      final settings = await _firestoreService.getSettings();
      final botToken = settings['telegramBotToken'] as String?;
      final channelUsername = settings['telegramChannelUsername'] as String?;

      if (botToken == null || botToken.isEmpty) {
        print('DEBUG [Telegram]: Bot token topilmadi');
        return false;
      }

      if (channelUsername == null || channelUsername.isEmpty) {
        print('DEBUG [Telegram]: Kanal username topilmadi');
        return false;
      }

      final channel = channelUsername.startsWith('@')
          ? channelUsername
          : '@$channelUsername';

      print('DEBUG [Telegram]: Tekshirish: user=$telegramUserId, channel=$channel');

      final url = Uri.parse(
        'https://api.telegram.org/bot$botToken/getChatMember'
        '?chat_id=$channel'
        '&user_id=$telegramUserId',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      print('DEBUG [Telegram]: Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('DEBUG [Telegram]: Data: $data');

        if (data['ok'] == true) {
          final status = data['result']?['status'] ?? '';
          print('DEBUG [Telegram]: Status: $status');

          // member, administrator, creator, restricted — kanalda bor
          return status == 'member' ||
              status == 'administrator' ||
              status == 'creator' ||
              status == 'restricted';
        }
      }

      final errorData = json.decode(response.body);
      print('DEBUG [Telegram]: Error: ${errorData['description']}');
      return false;
    } catch (e) {
      print('DEBUG [Telegram]: Exception: $e');
      return false;
    }
  }

  /// Bot token ni tekshirish
  Future<bool> verifyBotToken(String botToken) async {
    try {
      final url = Uri.parse('https://api.telegram.org/bot$botToken/getMe');
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['ok'] == true;
      }
      return false;
    } catch (e) {
      print('DEBUG [Telegram]: Bot token tekshirishda xato: $e');
      return false;
    }
  }

  /// Bot ma'lumotlarini olish
  Future<Map<String, dynamic>?> getBotInfo() async {
    try {
      final settings = await _firestoreService.getSettings();
      final botToken = settings['telegramBotToken'] as String?;

      if (botToken == null || botToken.isEmpty) return null;

      final url = Uri.parse('https://api.telegram.org/bot$botToken/getMe');
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true) {
          return data['result'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Kanal linkini olish
  Future<String?> getChannelLink() async {
    try {
      final settings = await _firestoreService.getSettings();
      final channelUsername = settings['telegramChannelUsername'] as String?;
      if (channelUsername == null || channelUsername.isEmpty) return null;

      final username = channelUsername.replaceAll('@', '');
      return 'https://t.me/$username';
    } catch (e) {
      print('DEBUG [Telegram]: Error getting channel link: $e');
      return null;
    }
  }

  /// Bot linkini olish (deep link bilan)
  Future<String?> getBotLink({String? startParam}) async {
    try {
      final settings = await _firestoreService.getSettings();
      final botToken = settings['telegramBotToken'] as String?;

      if (botToken == null || botToken.isEmpty) return null;

      // Bot username ni olish
      final botInfo = await getBotInfo();
      if (botInfo == null) return null;

      final botUsername = botInfo['username'] as String?;
      if (botUsername == null) return null;

      if (startParam != null) {
        return 'https://t.me/$botUsername?start=$startParam';
      }
      return 'https://t.me/$botUsername';
    } catch (e) {
      return null;
    }
  }

  /// Firestore'da saqlangan Telegram ID ni olish
  Future<int?> getSavedTelegramId(String uid) async {
    try {
      final user = await _firestoreService.getUser(uid);
      if (user == null) return null;

      // User model'da telegramId field'i bo'lishi kerak
      // Hozircha null qaytaramiz
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Telegram sozlamalari mavjudligini tekshirish
  Future<bool> isConfigured() async {
    try {
      final settings = await _firestoreService.getSettings();
      final botToken = settings['telegramBotToken'] as String?;
      final channelUsername = settings['telegramChannelUsername'] as String?;

      return botToken != null &&
             botToken.isNotEmpty &&
             channelUsername != null &&
             channelUsername.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
