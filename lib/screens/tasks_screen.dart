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

class _TasksScreenState extends State<TasksScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final TelegramService _telegramService = TelegramService();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  Set<String> _completedTaskIds = {};
  bool _isLoading = true;
  List<TaskModel> _tasks = [];
  AppUser? _appUser;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadData();
    AdMobService.loadInterstitialAd();
  }

  @override
  void dispose() {
    _animController.dispose();
    _showInterstitialAdOnExit();
    super.dispose();
  }

  void _showInterstitialAdOnExit() {
    try {
      if (AdMobService.isInterstitialAdReady) {
        AdMobService.showInterstitialAd();
      }
    } catch (e) {
      debugPrint('Reklama ko\'rsatishda xatolik: $e');
    }
  }

  Future<void> _loadData() async {
    if (_uid == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Login qilmagan! Iltimos qaytadan kiriting', isError: true);
      }
      return;
    }
    setState(() => _isLoading = true);

    try {
      final tasks = await _firestoreService.getActiveTasks();
      final completed = await _firestoreService.getCompletedTaskIdsToday(_uid!);
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
      debugPrint('Xatolik: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleTask(TaskModel task) async {
    if (_uid == null) return;

    HapticFeedback.selectionClick();

    switch (task.type) {
      case TaskType.telegramSubscribe:
        await _handleTelegramTask(task);
        break;
      case TaskType.instagramFollow:
        await _handleInstagramTask(task);
        break;
      case TaskType.youtubeSubscribe:
      case TaskType.youtubeWatch:
      case TaskType.tikTokFollow:
      case TaskType.facebookLike:
      case TaskType.appDownload:
        await _handleGenericLinkTask(task);
        break;
      case TaskType.dailyLogin:
        await _handleDailyLoginTask(task);
        break;
      case TaskType.inviteFriend:
        await _handleReferralTask(task);
        break;
      case TaskType.watchAd:
        await _handleWatchAdTask(task);
        break;
      case TaskType.playGame:
        Navigator.pop(context);
        break;
      case TaskType.shareApp:
        await _handleShareAppTask(task);
        break;
      case TaskType.rateApp:
        await _handleGenericLinkTask(task);
        break;
    }
  }

  Future<void> _handleTelegramTask(TaskModel task) async {
    // Avval kanal linkini ochish
    String? channelLink = task.link;
    if (channelLink == null || channelLink.isEmpty) {
      channelLink = await _telegramService.getChannelLink();
    }

    if (channelLink != null && channelLink.isNotEmpty) {
      final uri = Uri.parse(channelLink);
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        debugPrint('Telegram ochishda xato: $e');
      }
    }

    if (!mounted) return;

    // Foydalanuvchidan tasdiqlash so'rash
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.blue, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Telegram Kanal',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Telegram kanalga obuna bo\'ldingizmi?',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '+${task.reward} coin olasiz',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Yo\'q',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Ha, obuna bo\'ldim'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _firestoreService.completeTask(_uid!, task.id, task.reward);
      if (success) {
        HapticFeedback.heavyImpact();
        setState(() => _completedTaskIds.add(task.id));
        widget.onUpdate();
        _showSnackBar('+${task.reward} coin oldiniz!');
      } else {
        _showSnackBar('Bu vazifa bugun allaqachon bajarilgan', isError: true);
      }
    }
  }

  Future<void> _handleInstagramTask(TaskModel task) async {
    if (task.link != null && task.link!.isNotEmpty) {
      final uri = Uri.parse(task.link!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

    if (!mounted) return;

    final confirmed = await _showTaskConfirmDialog(
      icon: Icons.camera_alt,
      color: Colors.pink,
      title: 'Instagram',
      taskTitle: task.title,
      question: 'Instagram sahifaga obuna bo\'ldingizmi?',
      reward: task.reward,
    );

    if (confirmed == true) {
      final success = await _firestoreService.completeTask(_uid!, task.id, task.reward);
      if (success) {
        HapticFeedback.heavyImpact();
        setState(() => _completedTaskIds.add(task.id));
        widget.onUpdate();
        _showSnackBar('+${task.reward} coin oldiniz!');
      } else {
        _showSnackBar('Bu vazifa bugun allaqachon bajarilgan', isError: true);
      }
    }
  }

  Future<void> _handleGenericLinkTask(TaskModel task) async {
    if (task.link != null && task.link!.isNotEmpty) {
      final uri = Uri.parse(task.link!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

    if (!mounted) return;

    final confirmed = await _showTaskConfirmDialog(
      icon: _getTaskIcon(task.type),
      color: _getTaskColor(task.type),
      title: _getTaskTypeName(task.type),
      taskTitle: task.title,
      question: 'Vazifani bajardingizmi?',
      reward: task.reward,
    );

    if (confirmed == true) {
      final success = await _firestoreService.completeTask(_uid!, task.id, task.reward);
      if (success) {
        HapticFeedback.heavyImpact();
        setState(() => _completedTaskIds.add(task.id));
        widget.onUpdate();
        _showSnackBar('+${task.reward} coin oldiniz!');
      } else {
        _showSnackBar('Bu vazifa bugun allaqachon bajarilgan', isError: true);
      }
    }
  }

  Future<void> _handleShareAppTask(TaskModel task) async {
    await Share.share(
      'TDM Training - UC topishning eng oson yo\'li! Bu ilovani yuklab oling va coin to\'plang!',
    );

    if (!mounted) return;

    final confirmed = await _showTaskConfirmDialog(
      icon: Icons.share,
      color: Colors.purple,
      title: 'Ulashish',
      taskTitle: task.title,
      question: 'Ilovani ulashdingizmi?',
      reward: task.reward,
    );

    if (confirmed == true) {
      final success = await _firestoreService.completeTask(_uid!, task.id, task.reward);
      if (success) {
        HapticFeedback.heavyImpact();
        setState(() => _completedTaskIds.add(task.id));
        widget.onUpdate();
        _showSnackBar('+${task.reward} coin oldiniz!');
      } else {
        _showSnackBar('Bu vazifa bugun allaqachon bajarilgan', isError: true);
      }
    }
  }

  Future<void> _handleDailyLoginTask(TaskModel task) async {
    final success = await _firestoreService.completeTask(_uid!, task.id, task.reward);
    if (success) {
      HapticFeedback.heavyImpact();
      setState(() => _completedTaskIds.add(task.id));
      widget.onUpdate();
      _showSnackBar('+${task.reward} coin oldiniz!');
    } else {
      _showSnackBar('Bu vazifa bugun allaqachon bajarilgan', isError: true);
    }
  }

  Future<void> _handleReferralTask(TaskModel task) async {
    if (_appUser == null) return;

    await Share.share(
      'TDM Training ilovasini yuklab, mening taklif kodimni kiriting: ${_appUser!.referralCode}\n'
      'Do\'stingiz uchun +50 coin, siz uchun +100 coin!',
    );
  }

  Future<void> _handleWatchAdTask(TaskModel task) async {
    if (_uid == null) return;

    final canWatch = await _firestoreService.canWatchAd(_uid!);
    if (!canWatch) {
      _showSnackBar('Bugungi reklama limiti tugagan', isError: true);
      return;
    }

    try {
      await AdMobService.showRewardedAd(
        onUserEarnedReward: (reward) async {
          final success = await _firestoreService.addCoinsForAd(_uid!);
          if (success && mounted) {
            HapticFeedback.heavyImpact();
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

  Future<bool?> _showTaskConfirmDialog({
    required IconData icon,
    required Color color,
    required String title,
    required String taskTitle,
    required String question,
    required int reward,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              taskTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              question,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '+$reward coin olasiz',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Yo\'q',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Ha, bajardim'),
          ),
        ],
      ),
    );
  }

  String _getTaskTypeName(TaskType type) {
    switch (type) {
      case TaskType.telegramSubscribe:
        return 'Telegram';
      case TaskType.instagramFollow:
        return 'Instagram';
      case TaskType.youtubeSubscribe:
      case TaskType.youtubeWatch:
        return 'YouTube';
      case TaskType.tikTokFollow:
        return 'TikTok';
      case TaskType.facebookLike:
        return 'Facebook';
      case TaskType.dailyLogin:
        return 'Kunlik bonus';
      case TaskType.inviteFriend:
        return 'Do\'st taklif';
      case TaskType.watchAd:
        return 'Reklama';
      case TaskType.playGame:
        return 'O\'yin';
      case TaskType.appDownload:
        return 'Ilova';
      case TaskType.shareApp:
        return 'Ulashish';
      case TaskType.rateApp:
        return 'Baholash';
    }
  }

  IconData _getTaskIcon(TaskType type) {
    switch (type) {
      case TaskType.telegramSubscribe:
        return Icons.send;
      case TaskType.instagramFollow:
        return Icons.camera_alt;
      case TaskType.youtubeSubscribe:
        return Icons.play_circle_outline;
      case TaskType.youtubeWatch:
        return Icons.video_library;
      case TaskType.tikTokFollow:
        return Icons.music_note;
      case TaskType.facebookLike:
        return Icons.thumb_up;
      case TaskType.dailyLogin:
        return Icons.login;
      case TaskType.inviteFriend:
        return Icons.person_add;
      case TaskType.watchAd:
        return Icons.play_circle_filled;
      case TaskType.playGame:
        return Icons.sports_esports;
      case TaskType.appDownload:
        return Icons.download;
      case TaskType.shareApp:
        return Icons.share;
      case TaskType.rateApp:
        return Icons.star;
    }
  }

  Color _getTaskColor(TaskType type) {
    switch (type) {
      case TaskType.telegramSubscribe:
        return const Color(0xFF0088CC);
      case TaskType.instagramFollow:
        return const Color(0xFFE4405F);
      case TaskType.youtubeSubscribe:
      case TaskType.youtubeWatch:
        return const Color(0xFFFF0000);
      case TaskType.tikTokFollow:
        return const Color(0xFF000000);
      case TaskType.facebookLike:
        return const Color(0xFF1877F2);
      case TaskType.dailyLogin:
        return Colors.green;
      case TaskType.inviteFriend:
        return Colors.orange;
      case TaskType.watchAd:
        return Colors.amber;
      case TaskType.playGame:
        return AppColors.primary;
      case TaskType.appDownload:
        return Colors.teal;
      case TaskType.shareApp:
        return Colors.purple;
      case TaskType.rateApp:
        return Colors.amber.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _completedTaskIds.length;
    final totalCount = _tasks.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(completedCount, totalCount, progress),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: AppColors.primary,
                      child: CustomScrollView(
                        slivers: [
                          // Referral Section
                          if (_appUser != null)
                            SliverToBoxAdapter(
                              child: _buildReferralSection(),
                            ),

                          // Tasks Section
                          SliverPadding(
                            padding: const EdgeInsets.all(16),
                            sliver: _tasks.isEmpty
                                ? SliverFillRemaining(
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.assignment_outlined,
                                            color: AppColors.textSecondary.withValues(alpha: 0.5),
                                            size: 80,
                                          ),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'Hozircha vazifalar yo\'q',
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Tez orada yangi vazifalar qo\'shiladi',
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final task = _tasks[index];
                                        final isCompleted = _completedTaskIds.contains(task.id);
                                        return _buildTaskCard(task, isCompleted, index);
                                      },
                                      childCount: _tasks.length,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
            ),

            const AdBannerWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int completed, int total, double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.2),
            AppColors.accent.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Column(
        children: [
          // Top bar
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'VAZIFALAR',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: completed == total && total > 0
                          ? AppColors.success
                          : AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$completed/$total',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Progress bar
          if (total > 0) ...[
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Bugungi progress',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1.0 ? AppColors.success : AppColors.primary,
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReferralSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          // Referral code card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green.withValues(alpha: 0.2),
                  Colors.green.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.card_giftcard,
                        color: Colors.green,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Taklif kodingiz',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _appUser!.referralCode,
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              letterSpacing: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _appUser!.referralCode));
                          HapticFeedback.lightImpact();
                          _showSnackBar('Kod nusxalandi!');
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Nusxalash'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Share.share(
                            'TDM Training ilovasini yuklab, mening taklif kodimni kiriting: ${_appUser!.referralCode}\n'
                            'Do\'stingiz uchun +50 coin, siz uchun +100 coin!',
                          );
                        },
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Ulashish'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Har bir taklif uchun +100 coin oling!',
                        style: TextStyle(
                          color: Colors.green.shade300,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Referral code input (if not referred yet)
          if (_appUser!.referredBy == null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              child: _ReferralCodeInput(
                firestoreService: _firestoreService,
                uid: _uid!,
                onSuccess: () {
                  widget.onUpdate();
                  _loadData();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task, bool isCompleted, int index) {
    final color = _getTaskColor(task.type);
    final icon = _getTaskIcon(task.type);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              AppColors.surface,
              isCompleted
                  ? AppColors.success.withValues(alpha: 0.1)
                  : color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? AppColors.success.withValues(alpha: 0.5)
                : color.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isCompleted ? AppColors.success : color).withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isCompleted ? null : () => _handleTask(task),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isCompleted
                            ? [AppColors.success, AppColors.success.withValues(alpha: 0.7)]
                            : [color, color.withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (isCompleted ? AppColors.success : color).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isCompleted ? Icons.check : icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Content
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
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Reward
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: isCompleted
                              ? LinearGradient(
                                  colors: [
                                    AppColors.success.withValues(alpha: 0.2),
                                    AppColors.success.withValues(alpha: 0.1),
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    Colors.amber.withValues(alpha: 0.2),
                                    Colors.amber.withValues(alpha: 0.1),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isCompleted
                                ? AppColors.success.withValues(alpha: 0.5)
                                : Colors.amber.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCompleted ? Icons.check_circle : Icons.monetization_on,
                              color: isCompleted ? AppColors.success : Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
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
                ],
              ),
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
        SnackBar(
          content: const Text('6 belgili kod kiriting'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isApplying = true);

    final success = await widget.firestoreService.applyReferralCode(widget.uid, code);

    setState(() => _isApplying = false);

    if (success) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.celebration, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('+50 coin oldingiz! Taklif qiluvchi ham +100 coin oldi.'),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      widget.onSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Kod topilmadi yoki allaqachon ishlatilgan'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.redeem,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Taklif kodi bor?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    letterSpacing: 4,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'XXXXXX',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                      letterSpacing: 4,
                    ),
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isApplying ? null : _applyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isApplying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Tasdiqlash',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Taklif kodi kiritib +50 coin oling!',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
