import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'package:flutter_application_1/models/exchange_model.dart';
import '../../utils/app_colors.dart';

class AdminExchangesScreen extends StatefulWidget {
  const AdminExchangesScreen({super.key});

  @override
  State<AdminExchangesScreen> createState() => _AdminExchangesScreenState();
}

class _AdminExchangesScreenState extends State<AdminExchangesScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final String? _adminUid = FirebaseAuth.instance.currentUser?.uid;
  late TabController _tabController;

  List<Map<String, dynamic>> _pendingExchanges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadExchanges();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadExchanges() async {
    setState(() => _isLoading = true);
    try {
      final pending = await _firestoreService.getAllPendingExchanges();
      if (mounted) {
        setState(() {
          _pendingExchanges = pending;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(
      ExchangeModel exchange, String status) async {
    if (_adminUid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          status == 'completed' ? 'Tasdiqlash' : 'Rad etish',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          status == 'completed'
              ? '${exchange.ucAmount} UC ${exchange.nickname} ga yuborilganini tasdiqlaysizmi?'
              : 'Bu so\'rovni rad etasizmi? Coinlar qaytariladi.',
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
            child: Text(
              status == 'completed' ? 'Tasdiqlash' : 'Rad etish',
              style: TextStyle(
                color: status == 'completed' ? AppColors.success : AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _firestoreService.updateExchangeStatus(
        exchange.uid,
        exchange.id,
        status,
        _adminUid!,
      );
      _loadExchanges();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'completed'
                  ? '${exchange.ucAmount} UC tasdiqlandi'
                  : 'So\'rov rad etildi, coinlar qaytarildi',
            ),
            backgroundColor:
                status == 'completed' ? AppColors.success : AppColors.danger,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
          'UC so\'rovlar',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _pendingExchanges.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success, size: 64),
                      SizedBox(height: 16),
                      Text(
                        'Kutilayotgan so\'rovlar yo\'q',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadExchanges,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pendingExchanges.length,
                    itemBuilder: (context, index) {
                      final item = _pendingExchanges[index];
                      final exchange = item['exchange'] as ExchangeModel;
                      final userName = item['userName'] as String;
                      final userEmail = item['userEmail'] as String;
                      return _buildExchangeCard(exchange, userName, userEmail);
                    },
                  ),
                ),
    );
  }

  Widget _buildExchangeCard(
      ExchangeModel exchange, String userName, String userEmail) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Row(
            children: [
              const Icon(Icons.person, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName.isNotEmpty ? userName : 'Noma\'lum',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      userEmail,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(exchange.createdAt),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.textSecondary, height: 24),

          // Exchange details
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('PUBG Nickname', exchange.nickname),
                    const SizedBox(height: 4),
                    _infoRow('PUBG ID', exchange.pubgId),
                    const SizedBox(height: 4),
                    _infoRow('Coin sarflangan', '${exchange.coins}'),
                    const SizedBox(height: 4),
                    _infoRow('UC miqdori', '${exchange.ucAmount}'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _updateStatus(exchange, 'rejected'),
                  icon: const Icon(Icons.close, color: AppColors.danger, size: 18),
                  label: const Text('Rad etish',
                      style: TextStyle(color: AppColors.danger)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.danger),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _updateStatus(exchange, 'completed'),
                  icon: const Icon(Icons.check, color: Colors.white, size: 18),
                  label: const Text('Tasdiqlash',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
