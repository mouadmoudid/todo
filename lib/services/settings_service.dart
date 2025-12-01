import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_settings.dart';

class SettingsService extends ChangeNotifier {
  static const _keyThemeMode = 'theme_mode_index';
  static const _keyPrimaryColor = 'primary_color_value';
  static const _keyTextScale = 'text_scale_factor';
  static const _keyRecentColors = 'recent_colors';

  // Helper to make per-user keys for SharedPreferences
  String _userKey(String uid, String key) => '${uid}_$key';

  // Recent colors history (most recent first). Stored as ARGB int values.
  final List<int> _recentColors = [];
  List<int> get recentColors => List.unmodifiable(_recentColors);
  static const int _maxRecent = 8;
  AppSettings _settings = AppSettings.defaultSettings;
  // (import from device feature removed) — no pending import flag

  // devicePrefsAvailable and importDevicePrefsForCurrentUser functionality removed

  AppSettings get settings => _settings;

  static final SettingsService _instance = SettingsService._internal();

  factory SettingsService() => _instance;

  SettingsService._internal();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Load global (device) prefs as fallback for non-authenticated state
    final themeIndex = prefs.getInt(_keyThemeMode) ?? AppSettings.defaultSettings.themeModeIndex;
    final primaryColor = prefs.getInt(_keyPrimaryColor) ?? AppSettings.defaultSettings.primaryColorValue;
    final textScale = prefs.getDouble(_keyTextScale) ?? AppSettings.defaultSettings.textScaleFactor;
    final recentList = prefs.getStringList(_keyRecentColors);
    if (recentList != null) {
      _recentColors.clear();
      _recentColors.addAll(recentList.map((s) => int.tryParse(s)).whereType<int>());
    }

    _settings = AppSettings(
      themeModeIndex: themeIndex,
      primaryColorValue: primaryColor,
      textScaleFactor: textScale,
    );

    notifyListeners();
    // If a user is already signed in on startup, load their settings immediately
    final existing = FirebaseAuth.instance.currentUser;
    if (existing != null) {
      // On start, prefer Firestore settings for signed-in user, otherwise try user-local prefs.
      final loaded = await _loadFromFirestore(existing.uid);
        if (!loaded) {
            // try to load per-user local prefs (don't overwrite Firestore with device-level prefs)
            final loadedLocal = await _loadFromLocalForUser(existing.uid, prefs);
            if (!loadedLocal) {
              // no per-user prefs found — use default app settings (isolate accounts)
              _settings = AppSettings.defaultSettings;
              _recentColors.clear();
              notifyListeners();
            }
          }
      }

    // Listen for auth changes so we can load/save per-user settings
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        // On auth change: prefer Firestore. If Firestore doc missing, try per-user local prefs.
        final loaded = await _loadFromFirestore(user.uid);
        if (!loaded) {
          final prefs = await SharedPreferences.getInstance();
          final loadedLocal = await _loadFromLocalForUser(user.uid, prefs);
          if (!loadedLocal) {
            // No per-user prefs found — ensure new user starts with app defaults (no cross-account leakage)
            _settings = AppSettings.defaultSettings;
            _recentColors.clear();
            notifyListeners();
          }
          // do NOT automatically upload device/global prefs to the user's Firestore here
        } else {
          // loaded from Firestore — no import needed
        }
      } else {
        // signed out → revert to global/device preferences
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
    });
  }

  // importDevicePrefsForCurrentUser removed — importing device prefs is not supported

  Future<void> updateThemeMode(int index) async {
    _settings = _settings.copyWith(themeModeIndex: index);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // save per-user locally
      await prefs.setInt(_userKey(currentUser.uid, _keyThemeMode), index);
    } else {
      // save device/global fallback
      await prefs.setInt(_keyThemeMode, index);
    }
    if (currentUser != null) await _saveToFirestore(currentUser.uid);
  }

  Future<void> updatePrimaryColor(int colorValue) async {
    _settings = _settings.copyWith(primaryColorValue: colorValue);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await prefs.setInt(_userKey(currentUser.uid, _keyPrimaryColor), colorValue);
    } else {
      await prefs.setInt(_keyPrimaryColor, colorValue);
    }
    // record in recent colors
    await addRecentColor(colorValue);
    if (currentUser != null) await _saveToFirestore(currentUser.uid);
  }

  /// Add a color to recent history (most recent first) and persist per-user or device.
  Future<void> addRecentColor(int colorValue) async {
    // move to front
    _recentColors.removeWhere((c) => c == colorValue);
    _recentColors.insert(0, colorValue);
    if (_recentColors.length > _maxRecent) _recentColors.removeRange(_maxRecent, _recentColors.length);

    final prefs = await SharedPreferences.getInstance();
    final currentUser = FirebaseAuth.instance.currentUser;
    final saveList = _recentColors.map((c) => c.toString()).toList();

    if (currentUser != null) {
      await prefs.setStringList(_userKey(currentUser.uid, _keyRecentColors), saveList);
      await _saveToFirestore(currentUser.uid);
    } else {
      await prefs.setStringList(_keyRecentColors, saveList);
    }

    notifyListeners();
  }

  Future<void> removeRecentColor(int colorValue) async {
    _recentColors.removeWhere((c) => c == colorValue);
    final prefs = await SharedPreferences.getInstance();
    final currentUser = FirebaseAuth.instance.currentUser;
    final saveList = _recentColors.map((c) => c.toString()).toList();
    if (currentUser != null) {
      await prefs.setStringList(_userKey(currentUser.uid, _keyRecentColors), saveList);
      await _saveToFirestore(currentUser.uid);
    } else {
      await prefs.setStringList(_keyRecentColors, saveList);
    }

    notifyListeners();
  }

  Future<void> updateTextScale(double scale) async {
    _settings = _settings.copyWith(textScaleFactor: scale);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await prefs.setDouble(_userKey(currentUser.uid, _keyTextScale), scale);
    } else {
      await prefs.setDouble(_keyTextScale, scale);
    }
    if (currentUser != null) await _saveToFirestore(currentUser.uid);
  }

  // Save current settings to Firestore under users/<uid>/settings (doc: prefs)
  Future<void> _saveToFirestore(String uid) async {
    try {
      final doc = FirebaseFirestore.instance.collection('users').doc(uid).collection('settings').doc('prefs');
      await doc.set({
        _keyThemeMode: _settings.themeModeIndex,
        _keyPrimaryColor: _settings.primaryColorValue,
        _keyTextScale: _settings.textScaleFactor,
      }, SetOptions(merge: true));
    } catch (e) {
      // Non-fatal: keep working with SharedPreferences
      // You might want to log this in production
    }
  }

  // Load settings from Firestore for a user. Returns true if a doc existed and was loaded.
  Future<bool> _loadFromFirestore(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).collection('settings').doc('prefs').get();
      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null) return false;

      final themeIndex = (data[_keyThemeMode] is int) ? data[_keyThemeMode] as int : _settings.themeModeIndex;
      final primaryColor = (data[_keyPrimaryColor] is int) ? data[_keyPrimaryColor] as int : _settings.primaryColorValue;
      final textScale = (data[_keyTextScale] is num) ? (data[_keyTextScale] as num).toDouble() : _settings.textScaleFactor;

      _settings = AppSettings(
        themeModeIndex: themeIndex,
        primaryColorValue: primaryColor,
        textScaleFactor: textScale,
      );

      // persist user-local prefs
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_userKey(uid, _keyThemeMode), _settings.themeModeIndex);
      await prefs.setInt(_userKey(uid, _keyPrimaryColor), _settings.primaryColorValue);
      await prefs.setDouble(_userKey(uid, _keyTextScale), _settings.textScaleFactor);

      // recent colors
      final recent = data[_keyRecentColors];
      List<int> loadedRecent = [];
      if (recent is List) {
        loadedRecent = recent.map((e) => (e is num) ? e.toInt() : int.tryParse(e.toString())).whereType<int>().toList();
      }
      if (loadedRecent.isNotEmpty) {
        _recentColors.clear();
        _recentColors.addAll(loadedRecent.take(_maxRecent));
        await prefs.setStringList(_userKey(uid, _keyRecentColors), _recentColors.map((c) => c.toString()).toList());
      }

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Load local per-user preferences; returns true when found
  Future<bool> _loadFromLocalForUser(String uid, SharedPreferences prefs) async {
    final themeKey = _userKey(uid, _keyThemeMode);
    final colorKey = _userKey(uid, _keyPrimaryColor);
    final textKey = _userKey(uid, _keyTextScale);

    if (!prefs.containsKey(themeKey) && !prefs.containsKey(colorKey) && !prefs.containsKey(textKey)) return false;

    final themeIndex = prefs.getInt(themeKey) ?? _settings.themeModeIndex;
    final primaryColor = prefs.getInt(colorKey) ?? _settings.primaryColorValue;
    final textScale = prefs.getDouble(textKey) ?? _settings.textScaleFactor;

    // load recent colors from user-local
    final recentList = prefs.getStringList(_userKey(uid, _keyRecentColors));
    if (recentList != null) {
      _recentColors.clear();
      _recentColors.addAll(recentList.map((s) => int.tryParse(s)).whereType<int>());
      if (_recentColors.length > _maxRecent) _recentColors.removeRange(_maxRecent, _recentColors.length);
    }

    _settings = AppSettings(
      themeModeIndex: themeIndex,
      primaryColorValue: primaryColor,
      textScaleFactor: textScale,
    );

    notifyListeners();
    return true;
  }
}
