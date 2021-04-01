import 'package:flutter/material.dart';

final Brightness _brightness = Brightness.light;
final MaterialColor _primarySwatch = Colors.amber;

final TextTheme _textTheme = TextTheme(
  overline: TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.black,
    fontSize: 10,
  ),
);

final ChipThemeData _chipTheme = ChipThemeData(
  backgroundColor: Colors.transparent,
  disabledColor: Colors.grey[300],
  selectedColor: Colors.transparent,
  secondarySelectedColor: Colors.transparent,
  padding: const EdgeInsets.all(4),
  labelStyle: _textTheme.overline,
  secondaryLabelStyle: _textTheme.overline,
  brightness: _brightness,
  side: BorderSide(color: _primarySwatch),
  checkmarkColor: _primarySwatch,
);

ThemeData lightTheme = ThemeData(
  primarySwatch: _primarySwatch,
  dialogTheme: DialogTheme(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  ),
  buttonTheme: ButtonThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  ),
  chipTheme: _chipTheme,
  textTheme: _textTheme,
);
