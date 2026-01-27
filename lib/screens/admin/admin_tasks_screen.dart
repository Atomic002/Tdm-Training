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

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _firestoreService.getAllTasks();
      if (mounted) {
        setState(() {
          _tasks = tasks;
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

  String _getTaskTypeName(TaskType type) {
    switch (type) {
      case TaskType.telegramSubscribe:
        return 'Telegram obuna';
      case TaskType.instagramFollow:
        return 'Instagram obuna';
      case TaskType.dailyLogin:
        return 'Kunlik kirish';
      case TaskType.inviteFriend:
        return 'Do\'st taklif';
      case TaskType.watchAd:
        return 'Reklama ko\'rish';
      case TaskType.playGame:
        return 'O\'yin o\'ynash';
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
      child: ListTile(
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
        subtitle: Text(
          '${_getTaskTypeName(task.type)} | +${task.reward} coin',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: AppColors.danger, size: 20),
          onPressed: () => _deleteTask(task),
        ),
      ),
    );
  }
}
