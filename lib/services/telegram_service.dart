import 'dart:convert';
import 'package:http/http.dart' as http;
import 'firestore_service.dart';

class TelegramService {
  static final TelegramService _instance = TelegramService._internal();
  factory TelegramService() => _instance;
  TelegramService._internal();

  final FirestoreService _firestoreService = FirestoreService();

  /// Telegram kanalga obuna bo'lganligini tekshirish
  /// [telegramUsername] — foydalanuvchi Telegram username (@ siz)
  Future<bool> verifyChannelSubscription(String telegramUsername) async {
    try {
      final settings = await _firestoreService.getSettings();
      final botToken = settings['telegramBotToken'] as String?;
      final channelUsername = settings['telegramChannelUsername'] as String?;

      if (botToken == null ||
          botToken.isEmpty ||
          channelUsername == null ||
          channelUsername.isEmpty) {
        print('Telegram bot token yoki kanal username topilmadi');
        return false;
      }

      // Telegram Bot API — getChatMember
      final channel =
          channelUsername.startsWith('@') ? channelUsername : '@$channelUsername';

      // Avval username orqali user_id olishga urinamiz
      // Telegram API username orqali to'g'ridan-to'g'ri getChatMember
      // ishlatishga ruxsat beradi agar user kanal a'zosi bo'lsa
      final url = Uri.parse(
        'https://api.telegram.org/bot$botToken/getChatMember'
        '?chat_id=$channel'
        '&user_id=@$telegramUsername',
      );

      final response = await http.get(url).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true) {
          final status = data['result']?['status'] ?? '';
          // member, administrator, creator — obuna bo'lgan
          return status == 'member' ||
              status == 'administrator' ||
              status == 'creator';
        }
      }

      // Agar username bilan ishlamasa, fallback
      print('Telegram API javob: ${response.statusCode} ${response.body}');
      return false;
    } catch (e) {
      print('Telegram tekshirish xatoligi: $e');
      return false;
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
      print('Error getting channel link: $e');
      return null;
    }
  }
}
