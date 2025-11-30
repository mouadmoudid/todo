import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _taskController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser;

  void _addTask() async {
    if (_taskController.text.trim().isEmpty) return;

    await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('tasks')
        .add({
      'title': _taskController.text.trim(),
      'done': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _taskController.clear();
  }

  void _toggleDone(DocumentSnapshot task) async {
    await task.reference.update({'done': !task['done']});
  }

  void _deleteTask(DocumentSnapshot task) async {
    await task.reference.delete();
  }

  void _editTask(DocumentSnapshot task) {
    _taskController.text = task['title'];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modifier la tâche'),
        content: TextField(
          controller: _taskController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Titre de la tâche',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _taskController.clear();
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await task.reference.update({'title': _taskController.text.trim()});
              Navigator.pop(context);
              _taskController.clear();
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    await AuthService().logout();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes tâches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: const InputDecoration(
                      hintText: 'Nouvelle tâche',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addTask,
                  child: const Text('Ajouter'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(_user!.uid)
                  .collection('tasks')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Aucune tâche pour le moment'));
                }

                final tasks = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Card(
                      child: ListTile(
                        leading: Checkbox(
                          value: task['done'],
                          onChanged: (_) => _toggleDone(task),
                        ),
                        title: Text(
                          task['title'],
                          style: TextStyle(
                            decoration: task['done']
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editTask(task),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteTask(task),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
