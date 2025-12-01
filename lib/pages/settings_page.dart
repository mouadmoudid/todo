import 'package:flutter/material.dart';

import '../services/settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsService _service = SettingsService();

  final List<Color> _presetColors = const [
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.deepOrange,
    Colors.teal,
    Colors.pink,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AnimatedBuilder(
          animation: _service,
          builder: (_, __) {
            final settings = _service.settings;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thème', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  RadioListTile<int>(
                    value: 0,
                    groupValue: settings.themeModeIndex,
                    title: const Text('Système'),
                    onChanged: (v) async => await _service.updateThemeMode(v ?? 0),
                  ),
                  RadioListTile<int>(
                    value: 1,
                    groupValue: settings.themeModeIndex,
                    title: const Text('Clair'),
                    onChanged: (v) async => await _service.updateThemeMode(v ?? 1),
                  ),
                  RadioListTile<int>(
                    value: 2,
                    groupValue: settings.themeModeIndex,
                    title: const Text('Sombre'),
                    onChanged: (v) async => await _service.updateThemeMode(v ?? 2),
                  ),

                  const SizedBox(height: 16),
                  const Text('Couleur primaire', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _presetColors.map((c) {
                      final selected = c.value == settings.primaryColorValue;
                      return GestureDetector(
                        onTap: () => _service.updatePrimaryColor(c.value),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            border: selected ? Border.all(width: 3, color: Colors.black) : null,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(backgroundColor: c, radius: 22),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                  const Text('Taille du texte', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Slider(
                    min: 0.8,
                    max: 1.3,
                    divisions: 5,
                    value: settings.textScaleFactor,
                    label: '${(settings.textScaleFactor * 100).round()}%',
                    onChanged: (value) => setState(() => _service.updateTextScale(value)),
                  ),

                  const SizedBox(height: 40),
                  Text('Aperçu', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Texte d’exemple — taille et couleur primaire appliquées', style: Theme.of(context).textTheme.bodyLarge),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
