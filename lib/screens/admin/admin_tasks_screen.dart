import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'package:flutter_application_1/models/task_model.dart';
import '../../utils/app_colors.dart';

class AdminTasksScreen extends StatefulWidget {
  const AdminTasksScreen({super.key});

  @override
  State<AdminTasksScreen> createState() => _AdminTasksScreenState();
}

class _AdminTasksScreenState extends State<AdminTasksScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<TaskModel> _tasks = [];
  bool _isLoading = true;
  Map<String, int> _completionCounts = {};

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _firestoreService.getAllTasks();
      final counts = await _firestoreService.getTaskCompletionCounts();
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _completionCounts = counts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddTaskDialog() {
    _showTaskFormDialog(null);
  }

  void _showEditTaskDialog(TaskModel task) {
    _showTaskFormDialog(task);
  }

  void _showTaskFormDialog(TaskModel? existingTask) {
    final titleController =
        TextEditingController(text: existingTask?.title ?? '');
    final descriptionController =
        TextEditingController(text: existingTask?.description ?? '');
    final rewardController =
        TextEditingController(text: '${existingTask?.reward ?? 50}');
    final linkController =
        TextEditingController(text: existingTask?.link ?? '');
    final orderController =
        TextEditingController(text: '${existingTask?.order ?? _tasks.length + 1}');
    TaskType selectedType = existingTask?.type ?? TaskType.telegramSubscribe;
    bool isActive = existingTask?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            existingTask == null ? 'Yangi vazifa' : 'Vazifani tahrirlash',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Task type
                DropdownButtonFormField<TaskType>(
                  value: selectedType,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Turi',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                  items: TaskType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getTaskTypeName(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Sarlavha',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Tavsif',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rewardController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Mukofot (coin)',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: linkController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Link (ixtiyoriy)',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: orderController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Tartib raqami',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Faol',
                      style: TextStyle(color: AppColors.textPrimary)),
                  value: isActive,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setDialogState(() => isActive = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Bekor',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final description = descriptionController.text.trim();
                final reward = int.tryParse(rewardController.text.trim()) ?? 50;
                final link = linkController.text.trim();
                final order = int.tryParse(orderController.text.trim()) ?? 1;

                if (title.isEmpty) return;

                if (existingTask == null) {
                  // Yangi vazifa
                  final task = TaskModel(
                    id: '',
                    type: selectedType,
                    title: title,
                    description: description,
                    reward: reward,
                    isActive: isActive,
                    link: link.isNotEmpty ? link : null,
                    order: order,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  await _firestoreService.createTask(task);
                } else {
                  // Tahrirlash
                  await _firestoreService.updateTask(existingTask.id, {
                    'type': selectedType.name,
                    'title': title,
                    'description': description,
                    'reward': reward,
                    'isActive': isActive,
                    'link': link.isNotEmpty ? link : null,
                    'order': order,
                  });
                }

                Navigator.pop(ctx);
                _loadTasks();
              },
              child: const Text('Saqlash',
                  style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTask(TaskModel task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('O\'chirish',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '"${task.title}" vazifasini o\'chirishni xohlaysizmi?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Yo\'q',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ha, o\'chirish',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _firestoreService.deleteTask(task.id);
      _loadTasks();
    }
  }

  void _showTaskStatsDialog(TaskModel task) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    final stats = await _firestoreService.getTaskStats(task.id);
    final completions = await _firestoreService.getTaskCompletions(task.id);

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.8),
                      AppColors.accent.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getTaskTypeName(task.type),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              // Statistics
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatBox(
                        'Umumiy',
                        '${stats['totalCompletions'] ?? 0}',
                        '${stats['uniqueUsers'] ?? 0} user',
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatBox(
                        'Bugun',
                        '${stats['todayCompletions'] ?? 0}',
                        '${stats['todayUniqueUsers'] ?? 0} user',
                        AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.textSecondary, height: 1),
              // Users list
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.people, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Vazifani bajargan foydalanuvchilar',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: completions.isEmpty
                    ? const Center(
                        child: Text(
                          'Hali hech kim bajarmagan',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: completions.length,
                        itemBuilder: (context, index) {
                          final completion = completions[index];
                          final user = completion['user'];
                          final completedAt =
                              completion['completedAt'] as DateTime;
                          final reward = completion['reward'] as int;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: user.photoUrl != null
                                      ? NetworkImage(user.photoUrl!)
                                      : null,
                                  backgroundColor: AppColors.primary,
                                  child: user.photoUrl == null
                                      ? Text(
                                          user.displayName.isNotEmpty
                                              ? user.displayName[0]
                                                  .toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                              color: Colors.white),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.displayName.isEmpty
                                            ? 'User'
                                            : user.displayName,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        _formatDateTime(completedAt),
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '+$reward',
                                    style: const TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Hozirgina';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} daqiqa oldin';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} soat oldin';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} kun oldin';
    } else {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
    }
  }

  String _getTaskTypeName(TaskType type) {
    switch (type) {
      case TaskType.telegramSubscribe:
        return 'Telegram obuna';
      case TaskType.instagramFollow:
        return 'Instagram obuna';
      case TaskType.youtubeSubscribe:
        return 'YouTube obuna';
      case TaskType.youtubeWatch:
        return 'YouTube video ko\'rish';
      case TaskType.tikTokFollow:
        return 'TikTok follow';
      case TaskType.facebookLike:
        return 'Facebook like';
      case TaskType.dailyLogin:
        return 'Kunlik kirish';
      case TaskType.inviteFriend:
        return 'Do\'st taklif';
      case TaskType.watchAd:
        return 'Reklama ko\'rish';
      case TaskType.playGame:
        return 'O\'yin o\'ynash';
      case TaskType.appDownload:
        return 'Ilova yuklab olish';
      case TaskType.shareApp:
        return 'Ilovani ulashish';
      case TaskType.rateApp:
        return 'Ilovaga baho berish';
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
          'Vazifalar boshqaruvi',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _tasks.isEmpty
              ? const Center(
                  child: Text(
                    'Vazifalar yo\'q. + tugmasini bosib qo\'shing',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTasks,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return _buildTaskTile(task);
                    },
                  ),
                ),
    );
  }

  Widget _buildTaskTile(TaskModel task) {
    final completionCount = _completionCounts[task.id] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: task.isActive
              ? AppColors.success.withOpacity(0.3)
              : AppColors.danger.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => _showEditTaskDialog(task),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (task.isActive ? AppColors.success : AppColors.danger)
                    .withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                task.isActive ? Icons.check_circle : Icons.cancel,
                color: task.isActive ? AppColors.success : AppColors.danger,
              ),
            ),
            title: Text(
              task.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getTaskTypeName(task.type)} | +${task.reward} coin',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 14,
                      color: completionCount > 0 ? AppColors.primary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$completionCount ta bajarilgan',
                      style: TextStyle(
                        color: completionCount > 0 ? AppColors.primary : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: completionCount > 0 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.bar_chart, color: AppColors.primary, size: 20),
                  onPressed: () => _showTaskStatsDialog(task),
                  tooltip: 'Statistika',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.danger, size: 20),
                  onPressed: () => _deleteTask(task),
                  tooltip: 'O\'chirish',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
