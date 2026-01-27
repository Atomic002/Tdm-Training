import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskType {
  telegramSubscribe,
  instagramFollow,
  dailyLogin,
  inviteFriend,
  watchAd,
  playGame,
}

class TaskModel {
  final String id;
  final TaskType type;
  final String title;
  final String description;
  final int reward;
  final bool isActive;
  final String? link;
  final String iconName;
  final int order;
  final int dailyLimit;
  final bool requiresVerification;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.reward,
    this.isActive = true,
    this.link,
    this.iconName = 'star',
    this.order = 0,
    this.dailyLimit = 1,
    this.requiresVerification = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      type: _parseTaskType(data['type'] ?? 'watchAd'),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      reward: data['reward'] ?? 0,
      isActive: data['isActive'] ?? true,
      link: data['link'],
      iconName: data['iconName'] ?? 'star',
      order: data['order'] ?? 0,
      dailyLimit: data['dailyLimit'] ?? 1,
      requiresVerification: data['requiresVerification'] ?? false,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'title': title,
      'description': description,
      'reward': reward,
      'isActive': isActive,
      'link': link,
      'iconName': iconName,
      'order': order,
      'dailyLimit': dailyLimit,
      'requiresVerification': requiresVerification,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static TaskType _parseTaskType(String type) {
    switch (type) {
      case 'telegramSubscribe':
        return TaskType.telegramSubscribe;
      case 'instagramFollow':
        return TaskType.instagramFollow;
      case 'dailyLogin':
        return TaskType.dailyLogin;
      case 'inviteFriend':
        return TaskType.inviteFriend;
      case 'watchAd':
        return TaskType.watchAd;
      case 'playGame':
        return TaskType.playGame;
      default:
        return TaskType.watchAd;
    }
  }

  TaskModel copyWith({
    String? title,
    String? description,
    int? reward,
    bool? isActive,
    String? link,
    String? iconName,
    int? order,
    int? dailyLimit,
    bool? requiresVerification,
  }) {
    return TaskModel(
      id: id,
      type: type,
      title: title ?? this.title,
      description: description ?? this.description,
      reward: reward ?? this.reward,
      isActive: isActive ?? this.isActive,
      link: link ?? this.link,
      iconName: iconName ?? this.iconName,
      order: order ?? this.order,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      requiresVerification: requiresVerification ?? this.requiresVerification,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
