import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';
import '../models/uc_order_model.dart';
import '../services/firestore_service.dart';
import '../utils/app_colors.dart';
import '../widgets/ad_banner.dart';

class UCShopScreen extends StatefulWidget {
  const UCShopScreen({super.key});

  @override
  State<UCShopScreen> createState() => _UCShopScreenState();
}

class _UCShopScreenState extends State<UCShopScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static const String _telegramLink = 'https://t.me/Shadow_pubgm01';

  List<UCOrderModel> _myOrders = [];
  bool _isLoadingOrders = true;

  @override
  void initState() {
    super.initState();
    _loadMyOrders();
  }

  Future<void> _loadMyOrders() async {
    if (_uid == null) return;
    setState(() => _isLoadingOrders = true);
    try {
      final orders = await _firestoreService.getUserUCOrders(_uid!);
      if (mounted) {
        setState(() {
          _myOrders = orders;
          _isLoadingOrders = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingOrders = false);
    }
  }

  String _getStatusName(AppLocalizations l, String status) {
    switch (status) {
      case 'pending_receipt':
        return l.ucStatusPending;
      case 'receipt_confirmed':
        return l.ucStatusConfirmed;
      case 'completed':
        return l.ucStatusCompleted;
      case 'rejected':
        return l.ucStatusRejected;
      default:
        return l.ucStatusUnknown;
    }
  }

  Future<void> _openTelegram() async {
    HapticFeedback.mediumImpact();
    final uri = Uri.parse(_telegramLink);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l.ucShop,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Telegram servis banner
                  _buildServiceBanner(l),
                  const SizedBox(height: 20),

                  // Xususiyatlar
                  _buildFeatures(l),
                  const SizedBox(height: 20),

                  // UC narxlar
                  Text(
                    l.ucPricesList,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                    ),
                    itemCount: UCOrderModel.ucPrices.length,
                    itemBuilder: (context, index) {
                      final item = UCOrderModel.ucPrices[index];
                      return _buildUCCard(l, item);
                    },
                  ),

                  const SizedBox(height: 20),

                  // Telegram orqali buyurtma berish tugmasi
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openTelegram,
                      icon: const Icon(Icons.send, size: 20),
                      label: Text(
                        l.ucOrderViaTelegram,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0088CC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Buyurtmalar tarixi
                  if (_myOrders.isNotEmpty || _isLoadingOrders) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l.orderHistory,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        if (_isLoadingOrders)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_myOrders.length, (index) {
                      return _buildOrderHistoryCard(l, _myOrders[index]);
                    }),
                  ],
                ],
              ),
            ),
          ),
          const AdBannerWidget(),
        ],
      ),
    );
  }

  Widget _buildServiceBanner(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0088CC).withValues(alpha: 0.25),
            AppColors.accent.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF0088CC).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          // Icon va badge
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0088CC), AppColors.accent],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0088CC).withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.diamond,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
            ),
            child: Text(
              l.ucServiceBadge,
              style: const TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            l.ucShopBuyViaId,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            l.ucServiceDesc2,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Telegram button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openTelegram,
              icon: const Icon(Icons.send, size: 18),
              label: Text(l.ucOrderViaTelegram),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0088CC),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatures(AppLocalizations l) {
    final features = [
      {'icon': Icons.rocket_launch, 'text': l.ucServiceFeature1, 'color': Colors.orange},
      {'icon': Icons.attach_money, 'text': l.ucServiceFeature2, 'color': Colors.green},
      {'icon': Icons.headset_mic, 'text': l.ucServiceFeature3, 'color': Colors.blue},
      {'icon': Icons.verified_user, 'text': l.ucServiceFeature4, 'color': Colors.purple},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: features.map((f) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (f['color'] as Color).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(f['icon'] as IconData, color: f['color'] as Color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    f['text'] as String,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
                Icon(Icons.check_circle, color: Colors.green.withValues(alpha: 0.7), size: 20),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUCCard(AppLocalizations l, Map<String, int> item) {
    return GestureDetector(
      onTap: _openTelegram,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surface,
              AppColors.primary.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.diamond,
                      color: AppColors.accent, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${item['uc']}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    ' UC',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l.priceSom(UCOrderModel.formatPrice(item['price']!)),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHistoryCard(AppLocalizations l, UCOrderModel order) {
    final statusColor = _getStatusColor(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.diamond, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${order.ucAmount} UC',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  l.priceSom(UCOrderModel.formatPrice(order.priceUzs)),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusName(l, order.status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(order.createdAt),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending_receipt':
        return Colors.orange;
      case 'receipt_confirmed':
        return AppColors.info;
      case 'completed':
        return AppColors.success;
      case 'rejected':
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }
}
