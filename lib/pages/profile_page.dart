import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../services/task_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: const Text('Cette action est irréversible. Supprimer votre compte ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Try deleting the Firebase account. This may fail if re-auth is required.
      await user.delete();
      // Sign out locally
      await AuthService().logout();

      if (context.mounted) {
        // Return to login
        Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
      }
    } catch (e) {
      // If deletion requires recent authentication this will fail; show helpful message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Impossible de supprimer le compte — reconnectez-vous puis réessayez.'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil utilisateur'),
      ),
      body: user == null
          ? const Center(child: Text('Aucun utilisateur connecté'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (user.photoURL != null)
                    CircleAvatar(backgroundImage: NetworkImage(user.photoURL!), radius: 48)
                  else
                    const CircleAvatar(child: Icon(Icons.person), radius: 48),

                  const SizedBox(height: 12),
                  Text(user.displayName ?? 'Utilisateur', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(user.email ?? '', style: Theme.of(context).textTheme.bodyMedium),

                  const SizedBox(height: 20),
                  const Divider(),

                  StreamBuilder<List>(
                    stream: TaskService().getTasksStream(),
                    builder: (context, snapshot) {
                      final count = snapshot.hasData ? snapshot.data!.length : 0;
                      return ListTile(
                        leading: const Icon(Icons.list_alt),
                        title: const Text('Nombre total de tâches'),
                        trailing: Text('$count'),
                      );
                    },
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _deleteAccount(context),
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Supprimer le compte'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    ),
                  ),

                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await AuthService().logout();
                        if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Déconnexion'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
