import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'package:flutter_application_1/screens/admin/admin_users_screen.dart';
import 'package:flutter_application_1/screens/admin/admin_tasks_screen.dart';
import 'package:flutter_application_1/screens/admin/admin_exchanges_screen.dart';
import 'package:flutter_application_1/screens/admin/admin_settings_screen.dart';
import 'package:flutter_application_1/screens/admin/admin_announcements_screen.dart';
import 'package:flutter_application_1/screens/admin/admin_uc_orders_screen.dart';
import '../../utils/app_colors.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  int _totalUsers = 0;
  int _activeToday = 0;
  int _pendingExchanges = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final total = await _firestoreService.getTotalUsersCount();
      final active = await _firestoreService.getActiveUsersToday();
      final pending = await _firestoreService.getAllPendingExchanges();

      if (mounted) {
        setState(() {
          _totalUsers = total;
          _activeToday = active;
          _pendingExchanges = pending.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
          'ADMIN PANEL',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Stats cards
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Jami userlar',
                        '$_totalUsers',
                        Icons.people,
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Bugun faol',
                        '$_activeToday',
                        Icons.person_pin,
                        AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Kutilmoqda',
                        '$_pendingExchanges',
                        Icons.pending_actions,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Menu items
              _buildAdminMenuItem(
                title: 'Foydalanuvchilar',
                subtitle: 'Barcha userlarni ko\'rish va boshqarish',
                icon: Icons.people,
                color: AppColors.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminUsersScreen(),
                  ),
                ).then((_) => _loadStats()),
              ),
              const SizedBox(height: 12),
              _buildAdminMenuItem(
                title: 'Vazifalar',
                subtitle: 'Vazifalarni qo\'shish va boshqarish',
                icon: Icons.assignment,
                color: Colors.green,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminTasksScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildAdminMenuItem(
                title: 'UC so\'rovlar',
                subtitle: '$_pendingExchanges ta kutilayotgan so\'rov',
                icon: Icons.swap_horiz,
                color: Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminExchangesScreen(),
                  ),
                ).then((_) => _loadStats()),
              ),
              const SizedBox(height: 12),
              _buildAdminMenuItem(
                title: 'E\'lonlar',
                subtitle: 'Yangiliklar va e\'lonlarni boshqarish',
                icon: Icons.campaign,
                color: Colors.purple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminAnnouncementsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildAdminMenuItem(
                title: 'UC Buyurtmalar',
                subtitle: 'UC sotib olish buyurtmalari',
                icon: Icons.shopping_cart,
                color: Colors.teal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminUCOrdersScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildAdminMenuItem(
                title: 'Sozlamalar',
                subtitle: 'Telegram, Instagram, limitlar',
                icon: Icons.settings,
                color: AppColors.info,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminSettingsScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminMenuItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
