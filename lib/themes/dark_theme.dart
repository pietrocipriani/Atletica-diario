import 'package:flutter/material.dart';

final Brightness _brightness = Brightness.dark;
final MaterialColor _primarySwatch = Colors.amber;
final Color _disabledColor = Colors.grey[700];

final TextTheme _textTheme = TextTheme(
  overline: TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.white,
    fontSize: 10,
  ),
);

final ChipThemeData _chipTheme = ChipThemeData(
  backgroundColor: Colors.transparent,
  disabledColor: _disabledColor,
  selectedColor: Colors.transparent,
  secondarySelectedColor: Colors.transparent,
  padding: const EdgeInsets.all(4),
  labelStyle: _textTheme.overline,
  secondaryLabelStyle: _textTheme.overline,
  brightness: _brightness,
  side: BorderSide(color: _primarySwatch),
  checkmarkColor: _primarySwatch,
);

final DialogTheme _dialogTheme = DialogTheme(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
);

final ElevatedButtonThemeData _elevatedButtonTheme = ElevatedButtonThemeData(
  style: ButtonStyle(
    backgroundColor: MaterialStateColor.resolveWith((states) =>
        states.contains(MaterialState.disabled)
            ? _disabledColor
            : _primarySwatch),
    shape: MaterialStateProperty.all(StadiumBorder()),
  ),
);

final IconThemeData _iconTheme = IconThemeData(color: Colors.white, opacity: 1);

ThemeData darkTheme = ThemeData(
  brightness: _brightness,
  primarySwatch: _primarySwatch,
  primaryColor: _primarySwatch,
  primaryColorDark: _primarySwatch[700],
  primaryColorLight: _primarySwatch.withOpacity(0.2),
  accentColor: _primarySwatch[500],
  toggleableActiveColor: _primarySwatch[600],
  disabledColor: _disabledColor,
  dialogTheme: _dialogTheme,
  iconTheme: _iconTheme,
  buttonTheme: ButtonThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  ),
  elevatedButtonTheme: _elevatedButtonTheme,
  chipTheme: _chipTheme,
  textTheme: _textTheme,
);
