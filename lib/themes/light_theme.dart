import 'package:flutter/material.dart';

final Brightness _brightness = Brightness.light;
final MaterialColor _primarySwatch = Colors.amber;
final Color _disabledColor = Colors.grey[300]!;

final TextTheme _textTheme = TextTheme(
  overline: TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.black,
    fontSize: 10,
    letterSpacing: 0,
  ),
);

final ChipThemeData _chipTheme = ChipThemeData(
  backgroundColor: Colors.transparent,
  disabledColor: _disabledColor,
  selectedColor: Colors.transparent,
  secondarySelectedColor: Colors.transparent,
  padding: const EdgeInsets.all(4),
  labelStyle: _textTheme.overline!,
  secondaryLabelStyle: _textTheme.overline!,
  brightness: _brightness,
  side: BorderSide(color: _primarySwatch),
  checkmarkColor: _primarySwatch,
);

final CardTheme _cardTheme = CardTheme(
  elevation: 6,
  margin: const EdgeInsets.all(8),
  shadowColor: Colors.black,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(20)),
    side: BorderSide(color: Colors.black),
  ),
);

final DialogTheme _dialogTheme = DialogTheme(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
  contentTextStyle:
      _textTheme.overline?.copyWith(fontWeight: FontWeight.normal),
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

final IconThemeData _iconTheme = IconThemeData(color: Colors.black, opacity: 1);

ThemeData lightTheme = ThemeData(
  brightness: _brightness,
  primarySwatch: _primarySwatch,
  disabledColor: _disabledColor,
  dialogTheme: _dialogTheme,
  iconTheme: _iconTheme,
  cardTheme: _cardTheme,
  buttonTheme: ButtonThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  ),
  elevatedButtonTheme: _elevatedButtonTheme,
  chipTheme: _chipTheme,
  textTheme: _textTheme,
);
