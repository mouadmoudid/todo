import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final bool isDone;
  final Timestamp? createdAt;

  Task({
    required this.id,
    required this.title,
    required this.isDone,
    this.createdAt,
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Task(
        id: doc.id,
        title: data['title'] ?? '',
        isDone: data['isDone'] ?? false, // Correction du nom de champ
        createdAt: data['createdAt'] as Timestamp?);
  }
}