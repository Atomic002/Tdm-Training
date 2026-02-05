import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/announcement_model.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../utils/app_colors.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  List<AnnouncementModel> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _isLoading = true);
    try {
      final list = await _firestoreService.getAllAnnouncements();
      if (mounted) {
        setState(() {
          _announcements = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreateDialog() {
    _showAnnouncementDialog(null);
  }

  void _showEditDialog(AnnouncementModel announcement) {
    _showAnnouncementDialog(announcement);
  }

  void _showAnnouncementDialog(AnnouncementModel? existing) {
    final titleController =
        TextEditingController(text: existing?.title ?? '');
    final descController =
        TextEditingController(text: existing?.description ?? '');
    final videoUrlController =
        TextEditingController(text: existing?.videoUrl ?? '');
    final actionUrlController =
        TextEditingController(text: existing?.actionUrl ?? '');
    final actionTextController =
        TextEditingController(text: existing?.actionText ?? '');
    final orderController =
        TextEditingController(text: (existing?.order ?? 0).toString());

    String selectedType = existing?.type ?? 'news';
    bool isActive = existing?.isActive ?? true;
    File? selectedImage;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              existing == null ? 'Yangi e\'lon' : 'E\'lonni tahrirlash',
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Turi
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    dropdownColor: AppColors.surface,
                    decoration: InputDecoration(
                      labelText: 'Turi',
                      labelStyle:
                          const TextStyle(color: AppColors.textSecondary),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
                    items: AnnouncementModel.allTypes
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(AnnouncementModel.getTypeName(t)),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedType = v);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Sarlavha
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Sarlavha *',
                      labelStyle:
                          const TextStyle(color: AppColors.textSecondary),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tavsif
                  TextField(
                    controller: descController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Tavsif',
                      labelStyle:
                          const TextStyle(color: AppColors.textSecondary),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Rasm tanlash
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 1024,
                              imageQuality: 80,
                            );
                            if (image != null) {
                              setDialogState(
                                  () => selectedImage = File(image.path));
                            }
                          },
                          icon: const Icon(Icons.image),
                          label: Text(selectedImage != null
                              ? 'Rasm tanlandi'
                              : 'Rasm tanlash'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ),
                      if (selectedImage != null || existing?.imageUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(Icons.check_circle,
                              color: AppColors.success, size: 24),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // YouTube URL
                  if (selectedType == 'youtube')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: videoUrlController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'YouTube URL',
                          labelStyle:
                              const TextStyle(color: AppColors.textSecondary),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color:
                                    AppColors.primary.withValues(alpha: 0.3)),
                          ),
                        ),
                      ),
                    ),

                  // Action URL
                  TextField(
                    controller: actionUrlController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Link (ixtiyoriy)',
                      labelStyle:
                          const TextStyle(color: AppColors.textSecondary),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Action text
                  TextField(
                    controller: actionTextController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Tugma matni (masalan: Ko\'rish)',
                      labelStyle:
                          const TextStyle(color: AppColors.textSecondary),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tartib
                  TextField(
                    controller: orderController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Tartib raqami',
                      labelStyle:
                          const TextStyle(color: AppColors.textSecondary),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Aktiv
                  SwitchListTile(
                    title: const Text('Aktiv',
                        style: TextStyle(color: AppColors.textPrimary)),
                    value: isActive,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setDialogState(() => isActive = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Bekor qilish',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (titleController.text.trim().isEmpty) return;

                        setDialogState(() => isSaving = true);

                        String? imageUrl = existing?.imageUrl;

                        // Rasm yuklash
                        if (selectedImage != null) {
                          final fileName =
                              '${DateTime.now().millisecondsSinceEpoch}.jpg';
                          imageUrl = await _storageService
                              .uploadAnnouncementImage(
                                  selectedImage!, fileName);
                        }

                        if (existing == null) {
                          // Yaratish
                          final announcement = AnnouncementModel(
                            id: '',
                            type: selectedType,
                            title: titleController.text.trim(),
                            description: descController.text.trim().isEmpty
                                ? null
                                : descController.text.trim(),
                            imageUrl: imageUrl,
                            videoUrl:
                                videoUrlController.text.trim().isEmpty
                                    ? null
                                    : videoUrlController.text.trim(),
                            actionUrl:
                                actionUrlController.text.trim().isEmpty
                                    ? null
                                    : actionUrlController.text.trim(),
                            actionText:
                                actionTextController.text.trim().isEmpty
                                    ? null
                                    : actionTextController.text.trim(),
                            isActive: isActive,
                            order:
                                int.tryParse(orderController.text) ?? 0,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          );
                          await _firestoreService
                              .createAnnouncement(announcement);
                        } else {
                          // Yangilash
                          await _firestoreService.updateAnnouncement(
                            existing.id,
                            {
                              'type': selectedType,
                              'title': titleController.text.trim(),
                              'description':
                                  descController.text.trim().isEmpty
                                      ? null
                                      : descController.text.trim(),
                              'imageUrl': imageUrl,
                              'videoUrl':
                                  videoUrlController.text.trim().isEmpty
                                      ? null
                                      : videoUrlController.text.trim(),
                              'actionUrl':
                                  actionUrlController.text.trim().isEmpty
                                      ? null
                                      : actionUrlController.text.trim(),
                              'actionText':
                                  actionTextController.text.trim().isEmpty
                                      ? null
                                      : actionTextController.text.trim(),
                              'isActive': isActive,
                              'order': int.tryParse(
                                      orderController.text) ??
                                  0,
                            },
                          );
                        }

                        if (mounted) {
                          Navigator.pop(context);
                          _loadAnnouncements();
                        }
                      },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
                child: Text(
                  isSaving
                      ? 'Saqlanmoqda...'
                      : (existing == null ? 'Yaratish' : 'Saqlash'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteAnnouncement(AnnouncementModel announcement) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('O\'chirish',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '"${announcement.title}" ni o\'chirmoqchimisiz?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Yo\'q',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Ha, o\'chir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Rasmni ham o'chirish
      if (announcement.imageUrl != null) {
        await _storageService.deleteImage(announcement.imageUrl!);
      }
      await _firestoreService.deleteAnnouncement(announcement.id);
      _loadAnnouncements();
    }
  }

  Future<void> _toggleActive(AnnouncementModel announcement) async {
    await _firestoreService.updateAnnouncement(
      announcement.id,
      {'isActive': !announcement.isActive},
    );
    _loadAnnouncements();
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
          'E\'lonlar',
          style: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primary),
            onPressed: _showCreateDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _announcements.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.campaign_outlined,
                          size: 64,
                          color: AppColors.textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      const Text(
                        'E\'lonlar yo\'q',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showCreateDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Yangi e\'lon'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAnnouncements,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _announcements.length,
                    itemBuilder: (context, index) {
                      final a = _announcements[index];
                      return _buildAnnouncementCard(a);
                    },
                  ),
                ),
    );
  }

  Widget _buildAnnouncementCard(AnnouncementModel a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: a.isActive
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AnnouncementModel.getTypeName(a.type),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: a.isActive
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    a.isActive ? 'Aktiv' : 'Noaktiv',
                    style: TextStyle(
                      color: a.isActive ? Colors.green : Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '#${a.order}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Title
            Text(
              a.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (a.description != null) ...[
              const SizedBox(height: 4),
              Text(
                a.description!,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Rasm ko'rsatish
            if (a.imageUrl != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  a.imageUrl!,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 60,
                    color: AppColors.background,
                    child: const Center(
                      child: Icon(Icons.broken_image,
                          color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    a.isActive
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => _toggleActive(a),
                  tooltip: a.isActive ? 'Yashirish' : 'Ko\'rsatish',
                ),
                IconButton(
                  icon: const Icon(Icons.edit,
                      color: AppColors.primary, size: 20),
                  onPressed: () => _showEditDialog(a),
                ),
                IconButton(
                  icon: const Icon(Icons.delete,
                      color: AppColors.danger, size: 20),
                  onPressed: () => _deleteAnnouncement(a),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
