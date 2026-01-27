import 'package:cloud_firestore/cloud_firestore.dart';

class ExchangeModel {
  final String id;
  final String uid;
  final int coins;
  final int ucAmount;
  final String nickname;
  final String pubgId;
  final String status; // pending, completed, rejected
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? processedBy;

  ExchangeModel({
    required this.id,
    required this.uid,
    required this.coins,
    required this.ucAmount,
    required this.nickname,
    required this.pubgId,
    this.status = 'pending',
    required this.createdAt,
    this.processedAt,
    this.processedBy,
  });

  factory ExchangeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExchangeModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      coins: data['coins'] ?? 0,
      ucAmount: data['ucAmount'] ?? 0,
      nickname: data['nickname'] ?? '',
      pubgId: data['pubgId'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      processedAt: (data['processedAt'] as Timestamp?)?.toDate(),
      processedBy: data['processedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'coins': coins,
      'ucAmount': ucAmount,
      'nickname': nickname,
      'pubgId': pubgId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'processedAt':
          processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'processedBy': processedBy,
    };
  }

  String get formattedDate =>
      '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
}
