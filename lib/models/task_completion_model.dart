import 'package:cloud_firestore/cloud_firestore.dart';

class TaskCompletionModel {
  final String id;
  final String uid;
  final String taskId;
  final int reward;
  final DateTime completedAt;
  final String? date; // YYYY-MM-DD for daily tasks

  TaskCompletionModel({
    required this.id,
    required this.uid,
    required this.taskId,
    required this.reward,
    required this.completedAt,
    this.date,
  });

  factory TaskCompletionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskCompletionModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      taskId: data['taskId'] ?? '',
      reward: data['reward'] ?? 0,
      completedAt:
          (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      date: data['date'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'taskId': taskId,
      'reward': reward,
      'completedAt': Timestamp.fromDate(completedAt),
      'date': date,
    };
  }
}
