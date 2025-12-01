import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

class SettingsService extends ChangeNotifier {
  static const _keyThemeMode = 'theme_mode_index';
  static const _keyPrimaryColor = 'primary_color_value';
  static const _keyTextScale = 'text_scale_factor';

  AppSettings _settings = AppSettings.defaultSettings;

  AppSettings get settings => _settings;

  static final SettingsService _instance = SettingsService._internal();

  factory SettingsService() => _instance;

  SettingsService._internal();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final themeIndex = prefs.getInt(_keyThemeMode) ?? AppSettings.defaultSettings.themeModeIndex;
    final primaryColor = prefs.getInt(_keyPrimaryColor) ?? AppSettings.defaultSettings.primaryColorValue;
    final textScale = prefs.getDouble(_keyTextScale) ?? AppSettings.defaultSettings.textScaleFactor;

    _settings = AppSettings(
      themeModeIndex: themeIndex,
      primaryColorValue: primaryColor,
      textScaleFactor: textScale,
    );

    notifyListeners();
  }

  Future<void> updateThemeMode(int index) async {
    _settings = _settings.copyWith(themeModeIndex: index);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, index);
  }

  Future<void> updatePrimaryColor(int colorValue) async {
    _settings = _settings.copyWith(primaryColorValue: colorValue);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPrimaryColor, colorValue);
  }

  Future<void> updateTextScale(double scale) async {
    _settings = _settings.copyWith(textScaleFactor: scale);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTextScale, scale);
  }
}
