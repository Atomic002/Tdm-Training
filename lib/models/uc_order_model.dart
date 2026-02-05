import 'package:cloud_firestore/cloud_firestore.dart';

class UCOrderModel {
  final String id;
  final String uid;
  final int ucAmount;
  final int priceUzs;
  final String pubgId;
  final String status; // pending_receipt, receipt_confirmed, completed, rejected
  final String? receiptImageUrl;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? receiptConfirmedAt;
  final String? receiptConfirmedBy;
  final DateTime? completedAt;
  final String? completedBy;

  UCOrderModel({
    required this.id,
    required this.uid,
    required this.ucAmount,
    required this.priceUzs,
    required this.pubgId,
    this.status = 'pending_receipt',
    this.receiptImageUrl,
    this.adminNote,
    required this.createdAt,
    this.receiptConfirmedAt,
    this.receiptConfirmedBy,
    this.completedAt,
    this.completedBy,
  });

  factory UCOrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UCOrderModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      ucAmount: data['ucAmount'] ?? 0,
      priceUzs: data['priceUzs'] ?? 0,
      pubgId: data['pubgId'] ?? '',
      status: data['status'] ?? 'pending_receipt',
      receiptImageUrl: data['receiptImageUrl'],
      adminNote: data['adminNote'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      receiptConfirmedAt:
          (data['receiptConfirmedAt'] as Timestamp?)?.toDate(),
      receiptConfirmedBy: data['receiptConfirmedBy'],
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      completedBy: data['completedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'ucAmount': ucAmount,
      'priceUzs': priceUzs,
      'pubgId': pubgId,
      'status': status,
      'receiptImageUrl': receiptImageUrl,
      'adminNote': adminNote,
      'createdAt': Timestamp.fromDate(createdAt),
      'receiptConfirmedAt': receiptConfirmedAt != null
          ? Timestamp.fromDate(receiptConfirmedAt!)
          : null,
      'receiptConfirmedBy': receiptConfirmedBy,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'completedBy': completedBy,
    };
  }

  /// UC narxlar ro'yxati
  static const List<Map<String, int>> ucPrices = [
    {'uc': 60, 'price': 13000},
    {'uc': 120, 'price': 26000},
    {'uc': 180, 'price': 38000},
    {'uc': 325, 'price': 62000},
    {'uc': 385, 'price': 73000},
    {'uc': 660, 'price': 125000},
    {'uc': 720, 'price': 137000},
    {'uc': 985, 'price': 185000},
    {'uc': 1320, 'price': 245000},
    {'uc': 1800, 'price': 299000},
    {'uc': 2125, 'price': 360000},
    {'uc': 3120, 'price': 540000},
    {'uc': 3850, 'price': 585000},
    {'uc': 5170, 'price': 825000},
    {'uc': 5650, 'price': 880000},
    {'uc': 8100, 'price': 1150000},
    {'uc': 12010, 'price': 1725000},
    {'uc': 16200, 'price': 2280000},
    {'uc': 20050, 'price': 2860000},
    {'uc': 24300, 'price': 3400000},
    {'uc': 32400, 'price': 4530000},
    {'uc': 40500, 'price': 5660000},
    {'uc': 50400, 'price': 7100000},
    {'uc': 81000, 'price': 11300000},
  ];

  /// Status nomini olish
  static String getStatusName(String status) {
    switch (status) {
      case 'pending_receipt':
        return 'Chek kutilmoqda';
      case 'receipt_confirmed':
        return 'Chek tasdiqlandi';
      case 'completed':
        return 'Bajarildi';
      case 'rejected':
        return 'Rad etildi';
      default:
        return 'Noma\'lum';
    }
  }

  /// Narxni formatlash (1,000,000 ko'rinishida)
  static String formatPrice(int price) {
    final str = price.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}
