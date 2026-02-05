import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String type; // news, youtube, promo, update, image, ucShop
  final String title;
  final String? description;
  final String? imageUrl;
  final String? videoUrl;
  final String? actionUrl;
  final String? actionText;
  final bool isActive;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  AnnouncementModel({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.imageUrl,
    this.videoUrl,
    this.actionUrl,
    this.actionText,
    this.isActive = true,
    this.order = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnnouncementModel(
      id: doc.id,
      type: data['type'] ?? 'news',
      title: data['title'] ?? '',
      description: data['description'],
      imageUrl: data['imageUrl'],
      videoUrl: data['videoUrl'],
      actionUrl: data['actionUrl'],
      actionText: data['actionText'],
      isActive: data['isActive'] ?? true,
      order: data['order'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'actionUrl': actionUrl,
      'actionText': actionText,
      'isActive': isActive,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  AnnouncementModel copyWith({
    String? id,
    String? type,
    String? title,
    String? description,
    String? imageUrl,
    String? videoUrl,
    String? actionUrl,
    String? actionText,
    bool? isActive,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      actionText: actionText ?? this.actionText,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// E'lon turi nomlari
  static String getTypeName(String type) {
    switch (type) {
      case 'news':
        return 'Yangilik';
      case 'youtube':
        return 'YouTube';
      case 'promo':
        return 'Reklama';
      case 'update':
        return 'Yangilanish';
      case 'image':
        return 'Rasm';
      case 'ucShop':
        return 'UC Do\'koni';
      default:
        return 'Boshqa';
    }
  }

  static List<String> get allTypes => [
        'news',
        'youtube',
        'promo',
        'update',
        'image',
        'ucShop',
      ];
}
