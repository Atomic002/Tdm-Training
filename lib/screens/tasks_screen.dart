import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'package:flutter_application_1/services/telegram_service.dart';
import 'package:flutter_application_1/services/admob_service.dart';
import 'package:flutter_application_1/models/task_model.dart';
import 'package:flutter_application_1/models/app_user.dart';
import 'package:flutter_application_1/widgets/ad_banner.dart';
import '../utils/app_colors.dart';

class TasksScreen extends StatefulWidget {
  final VoidCallback onUpdate;

  const TasksScreen({super.key, required this.onUpdate});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TelegramService _telegramService = TelegramService();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  Set<String> _completedTaskIds = {};
  bool _isLoading = true;
  List<TaskModel> _tasks = [];
  AppUser? _appUser;

  @override
  void initState() {
    super.initState();
    _loadData();
    AdMobService.loadInterstitialAd();
  }

  @override
  void dispose() {
    _showInterstitialAdOnExit();
    super.dispose();
  }

  void _showInterstitialAdOnExit() {
    try {
      if (AdMobService.isInterstitialAdReady) {
        AdMobService.showInterstitialAd();
      }
    } catch (e) {
      print('Reklama ko\'rsatishda xatolik: $e');
    }
  }

  Future<void> _loadData() async {
    if (_uid == null) {
      print('DEBUG: UID null, foydalanuvchi login qilmagan');
      return;
    }
    setState(() => _isLoading = true);

    try {
      print('DEBUG: Vazifalarni yuklash boshlandi...');
      final tasks = await _firestoreService.getActiveTasks();
      print('DEBUG: ${tasks.length} ta vazifa topildi');
      for (var task in tasks) {
        print('DEBUG: Vazifa - ${task.title}, Type: ${task.type}, Active: ${task.isActive}');
      }

      final completed = await _firestoreService.getCompletedTaskIdsToday(_uid!);
      print('DEBUG: ${completed.length} ta vazifa bugun bajarilgan');

      final appUser = await _firestoreService.getUser(_uid!);

      if (mounted) {
        setState(() {
          _tasks = tasks;
          _completedTaskIds = completed;
          _appUser = appUser;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Ma\'lumotlarni yuklashda xatolik', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleTask(TaskModel task) async {
    if (_uid == null) return;
    if (_completedTaskIds.contains(task.id)) {
      _showSnackBar('Bu vazifa bugun bajarilgan');
      return;
    }

    switch (task.type) {
      case TaskType.telegramSubscribe:
        await _handleTelegramTask(task);
        break;
      case TaskType.instagramFollow:
        await _handleInstagramTask(task);
        break;
      case TaskType.dailyLogin:
        // Auto-completed on login
        _showSnackBar('Kunlik bonus login da avtomatik beriladi');
        break;
      case TaskType.inviteFriend:
        await _handleReferralTask(task);
        break;
      case TaskType.watchAd:
        await _handleWatchAdTask(task);
        break;
      case TaskType.playGame:
        _showSnackBar('O\'yin o\'ynab coin oling — Bosh menyuga qaytib o\'ynang');
        break;
    }
  }

  Future<void> _handleTelegramTask(TaskModel task) async {
    // Avval kanalni ochish
    final channelLink = await _telegramService.getChannelLink();
    if (channelLink != null) {
      final uri = Uri.parse(channelLink);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

    if (!mounted) return;

    // Tekshirish dialog
    final telegramUsername = await _showTelegramUsernameDialog();
    if (telegramUsername == null || telegramUsername.isEmpty) return;

    _showSnackBar('Obuna tekshirilmoqda...');

    final verified =
        await _telegramService.verifyChannelSubscription(telegramUsername);

    if (verified) {
      final success =
          await _firestoreService.completeTask(_uid!, task.id, task.reward);
      if (success) {
        setState(() => _completedTaskIds.add(task.id));
        widget.onUpdate();
        _showSnackBar('+${task.reward} coin oldiniz!');
      }
    } else {
      // Fallback — "Bajardim" tugmasi
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Tekshirib bo\'lmadi',
              style: TextStyle(color: AppColors.textPrimary)),
          content: const Text(
            'Telegram API orqali tekshirib bo\'lmadi. Obuna bo\'lgansiz deb hisoblansinmi?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Yo\'q',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ha, obuna bo\'ldim',
                  style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final success =
            await _firestoreService.completeTask(_uid!, task.id, task.reward);
        if (success) {
          setState(() => _completedTaskIds.add(task.id));
          widget.onUpdate();
          _showSnackBar('+${task.reward} coin oldiniz!');
        }
      }
    }
  }

  Future<String?> _showTelegramUsernameDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Telegram username',
            style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'username (@ siz)',
            hintStyle: TextStyle(color: AppColors.textSecondary),
            prefixText: '@',
            prefixStyle: TextStyle(color: AppColors.primary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bekor',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Tekshirish',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleInstagramTask(TaskModel task) async {
    if (task.link != null && task.link!.isNotEmpty) {
      final uri = Uri.parse(task.link!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Instagram',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Instagram sahifaga obuna bo\'ldingizmi?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Yo\'q',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ha, obuna bo\'ldim',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success =
          await _firestoreService.completeTask(_uid!, task.id, task.reward);
      if (success) {
        setState(() => _completedTaskIds.add(task.id));
        widget.onUpdate();
        _showSnackBar('+${task.reward} coin oldiniz!');
      } else {
        _showSnackBar('Bu vazifa bugun allaqachon bajarilgan');
      }
    }
  }

  Future<void> _handleReferralTask(TaskModel task) async {
    if (_appUser == null) return;

    await Share.share(
      'TDM Training ilovasini yuklab, mening taklif kodimni kiriting: ${_appUser!.referralCode}\n'
      'Ikkalamiz ham bonus coin olamiz!',
    );
  }

  Future<void> _handleWatchAdTask(TaskModel task) async {
    if (_uid == null) return;

    final canWatch = await _firestoreService.canWatchAd(_uid!);
    if (!canWatch) {
      _showSnackBar('Bugungi reklama limiti tugagan');
      return;
    }

    try {
      await AdMobService.showRewardedAd(
        onUserEarnedReward: (reward) async {
          final success = await _firestoreService.addCoinsForAd(_uid!);
          if (success && mounted) {
            setState(() => _completedTaskIds.add(task.id));
            widget.onUpdate();
            _showSnackBar('+${FirestoreService.coinsPerAd} coin oldiniz!');
          }
        },
        onRewardEarned: () {},
        onFailed: () {
          if (mounted) {
            _showSnackBar('Reklama yuklanmadi', isError: true);
          }
        },
      );
    } catch (e) {
      _showSnackBar('Reklama yuklanmadi', isError: true);
    }
  }

  IconData _getTaskIcon(TaskType type) {
    switch (type) {
      case TaskType.telegramSubscribe:
        return Icons.send;
      case TaskType.instagramFollow:
        return Icons.camera_alt;
      case TaskType.dailyLogin:
        return Icons.login;
      case TaskType.inviteFriend:
        return Icons.person_add;
      case TaskType.watchAd:
        return Icons.play_circle_filled;
      case TaskType.playGame:
        return Icons.sports_esports;
    }
  }

  Color _getTaskColor(TaskType type) {
    switch (type) {
      case TaskType.telegramSubscribe:
        return Colors.blue;
      case TaskType.instagramFollow:
        return Colors.pink;
      case TaskType.dailyLogin:
        return Colors.green;
      case TaskType.inviteFriend:
        return Colors.orange;
      case TaskType.watchAd:
        return Colors.amber;
      case TaskType.playGame:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'VAZIFALAR',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Referral code card
          if (_appUser != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.withOpacity(0.15), Colors.green.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.card_giftcard, color: Colors.green, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Taklif kodingiz:',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        Text(
                          _appUser!.referralCode,
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.green),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _appUser!.referralCode));
                      _showSnackBar('Kod nusxalandi!');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.green),
                    onPressed: () {
                      Share.share(
                        'TDM Training ilovasini yuklab, mening taklif kodimni kiriting: ${_appUser!.referralCode}',
                      );
                    },
                  ),
                ],
              ),
            ),

          // Referral code input
          if (_appUser != null && _appUser!.referredBy == null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: _ReferralCodeInput(
                firestoreService: _firestoreService,
                uid: _uid!,
                onSuccess: () {
                  widget.onUpdate();
                  _loadData();
                },
              ),
            ),

          // Tasks list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _tasks.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment, color: AppColors.textSecondary, size: 64),
                            SizedBox(height: 16),
                            Text(
                              'Hozircha vazifalar yo\'q',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Admin vazifalarni qo\'shganda shu yerda ko\'rinadi',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _tasks.length,
                          itemBuilder: (context, index) {
                            final task = _tasks[index];
                            final isCompleted = _completedTaskIds.contains(task.id);
                            return _buildTaskCard(task, isCompleted);
                          },
                        ),
                      ),
          ),

          const AdBannerWidget(),
        ],
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task, bool isCompleted) {
    final color = _getTaskColor(task.type);
    final icon = _getTaskIcon(task.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? AppColors.success.withOpacity(0.5) : color.withOpacity(0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isCompleted ? null : () => _handleTask(task),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isCompleted ? AppColors.success : color).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle : icon,
                    color: isCompleted ? AppColors.success : color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          color: isCompleted
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.success.withOpacity(0.2)
                        : Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: isCompleted ? AppColors.success : Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCompleted ? 'Bajarildi' : '+${task.reward}',
                        style: TextStyle(
                          color: isCompleted ? AppColors.success : Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReferralCodeInput extends StatefulWidget {
  final FirestoreService firestoreService;
  final String uid;
  final VoidCallback onSuccess;

  const _ReferralCodeInput({
    required this.firestoreService,
    required this.uid,
    required this.onSuccess,
  });

  @override
  State<_ReferralCodeInput> createState() => _ReferralCodeInputState();
}

class _ReferralCodeInputState extends State<_ReferralCodeInput> {
  final _controller = TextEditingController();
  bool _isApplying = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _applyCode() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.isEmpty || code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('6 belgili kod kiriting')),
      );
      return;
    }

    setState(() => _isApplying = true);

    final success =
        await widget.firestoreService.applyReferralCode(widget.uid, code);

    setState(() => _isApplying = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('+50 coin oldingiz! Taklif qiluvchi ham +100 coin oldi.'),
          backgroundColor: AppColors.success,
        ),
      );
      widget.onSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kod topilmadi yoki allaqachon ishlatilgan'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              style: const TextStyle(
                color: AppColors.textPrimary,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                hintText: 'Taklif kodini kiriting',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                counterText: '',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _isApplying ? null : _applyCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: _isApplying
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Tasdiqlash', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
