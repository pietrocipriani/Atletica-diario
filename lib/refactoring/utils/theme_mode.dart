import 'package:flutter/material.dart';

ThemeMode parseThemeMode(final String? raw) {
  if (raw == ThemeMode.dark.toString()) {
    return ThemeMode.dark;
  } else if (raw == ThemeMode.light.toString()) {
    return ThemeMode.light;
  }
  return ThemeMode.system;
}
