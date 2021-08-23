import 'package:flutter/material.dart';

const Brightness _brightness = Brightness.dark;
const MaterialColor _primarySwatch = Colors.amber;
final Color _disabledColor = Colors.grey[700]!;

final TextTheme _textTheme = TextTheme(
  overline: TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.white,
    fontSize: 10,
    letterSpacing: 0,
  ),
);

final CardTheme _cardTheme = CardTheme(
  elevation: 6,
  margin: const EdgeInsets.all(8),
  shadowColor: Colors.black,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(20)),
    side: BorderSide(color: Colors.white),
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
  cardTheme: _cardTheme,
  errorColor: Colors.red[400],
  buttonTheme: ButtonThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  ),
  elevatedButtonTheme: _elevatedButtonTheme,
  chipTheme: _chipTheme,
  textTheme: _textTheme,
);
