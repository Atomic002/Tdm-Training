import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import '../../utils/app_colors.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _botTokenController = TextEditingController();
  final _channelController = TextEditingController();
  final _instagramController = TextEditingController();
  final _maxAdsController = TextEditingController();
  final _maxGamesController = TextEditingController();
  final _coinsPerAdController = TextEditingController();
  final _referralRewardController = TextEditingController();
  final _referralBonusController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _botTokenController.dispose();
    _channelController.dispose();
    _instagramController.dispose();
    _maxAdsController.dispose();
    _maxGamesController.dispose();
    _coinsPerAdController.dispose();
    _referralRewardController.dispose();
    _referralBonusController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _firestoreService.getSettings();
      if (mounted) {
        setState(() {
          _botTokenController.text = settings['telegramBotToken'] ?? '';
          _channelController.text = settings['telegramChannelUsername'] ?? '';
          _instagramController.text = settings['instagramPageUrl'] ?? '';
          _maxAdsController.text = '${settings['maxDailyAds'] ?? 10}';
          _maxGamesController.text = '${settings['maxDailyGames'] ?? 20}';
          _coinsPerAdController.text = '${settings['coinsPerAd'] ?? 5}';
          _referralRewardController.text = '${settings['referralReward'] ?? 100}';
          _referralBonusController.text = '${settings['referralBonusForReferred'] ?? 50}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await _firestoreService.updateSettings({
        'telegramBotToken': _botTokenController.text.trim(),
        'telegramChannelUsername': _channelController.text.trim(),
        'instagramPageUrl': _instagramController.text.trim(),
        'maxDailyAds': int.tryParse(_maxAdsController.text.trim()) ?? 10,
        'maxDailyGames': int.tryParse(_maxGamesController.text.trim()) ?? 20,
        'coinsPerAd': int.tryParse(_coinsPerAdController.text.trim()) ?? 5,
        'referralReward': int.tryParse(_referralRewardController.text.trim()) ?? 100,
        'referralBonusForReferred':
            int.tryParse(_referralBonusController.text.trim()) ?? 50,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sozlamalar saqlandi'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saqlashda xatolik'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
    if (mounted) setState(() => _isSaving = false);
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
          'Ilova sozlamalari',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveSettings,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Text('Saqlash',
                    style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Telegram section
                  _buildSectionHeader('Telegram', Icons.send, Colors.blue),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _botTokenController,
                    label: 'Bot Token',
                    hint: '123456:ABC-DEF...',
                    obscure: true,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _channelController,
                    label: 'Kanal username',
                    hint: '@kanal_nomi',
                  ),

                  const SizedBox(height: 24),

                  // Instagram section
                  _buildSectionHeader('Instagram', Icons.camera_alt, Colors.pink),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _instagramController,
                    label: 'Sahifa URL',
                    hint: 'https://instagram.com/sahifa',
                  ),

                  const SizedBox(height: 24),

                  // Limits section
                  _buildSectionHeader('Limitlar', Icons.tune, Colors.orange),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _maxAdsController,
                          label: 'Max kunlik reklama',
                          hint: '10',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _maxGamesController,
                          label: 'Max kunlik o\'yin',
                          hint: '20',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _coinsPerAdController,
                    label: 'Har reklama uchun coin',
                    hint: '5',
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 24),

                  // Referral section
                  _buildSectionHeader(
                      'Taklif tizimi', Icons.person_add, Colors.green),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _referralRewardController,
                          label: 'Taklif qiluvchiga',
                          hint: '100',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _referralBonusController,
                          label: 'Taklif qilinuvchiga',
                          hint: '50',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
