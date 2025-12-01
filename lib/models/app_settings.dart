import 'package:flutter/material.dart';

class AppSettings {
  /// 0 = system, 1 = light, 2 = dark
  final int themeModeIndex;
  final int primaryColorValue;
  final double textScaleFactor;

  const AppSettings({
    required this.themeModeIndex,
    required this.primaryColorValue,
    required this.textScaleFactor,
  });

  ThemeMode get themeMode {
    switch (themeModeIndex) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Color get primaryColor => Color(primaryColorValue);

  AppSettings copyWith({int? themeModeIndex, int? primaryColorValue, double? textScaleFactor}) {
    return AppSettings(
      themeModeIndex: themeModeIndex ?? this.themeModeIndex,
      primaryColorValue: primaryColorValue ?? this.primaryColorValue,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
    );
  }

  static const defaultSettings = AppSettings(
    themeModeIndex: 0,
    primaryColorValue: 0xFF2196F3, // default blue
    textScaleFactor: 1.0,
  );
}
