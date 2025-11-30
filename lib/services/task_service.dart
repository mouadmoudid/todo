import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/task.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  // Référence vers la collection tasks de l'utilisateur
  CollectionReference get _taskCollection =>
      _firestore.collection('users').doc(userId).collection('tasks');

  // Stream des tâches (en temps réel)
  Stream<List<Task>> getTasksStream() {
    return _taskCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList());
  }

  // Ajouter une tâche
  Future<void> addTask(String title) async {
    await _taskCollection.add({
      'title': title,
      'isDone': false,
      'createdAt':
          FieldValue.serverTimestamp(), // 'createdAt' au lieu de 'done'
    });
  }

  // Modifier une tâche
  Future<void> updateTask(String taskId, String newTitle) async {
    await _taskCollection.doc(taskId).update({
      'title': newTitle,
    });
  }

  // Supprimer une tâche
  Future<void> deleteTask(String taskId) async {
    await _taskCollection.doc(taskId).delete();
  }
  // Basculer l'état 'done'
  Future<void> toggleTaskDone(Task task) async {
    await _taskCollection.doc(task.id).update({'isDone': !task.isDone});
  }
}
