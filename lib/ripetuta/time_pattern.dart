bool matchTimePattern(String? s, [bool onlySec = false, bool isPace = false]) {
  if (s == null || s.isEmpty) return false;
  if (isPace && s.endsWith('/km'))
    return matchTimePattern(s.substring(0, s.length - 3), onlySec);
  final String? raw =
      RegExp(onlySec ? r'^\s*[0-5]?\d' : r'^\s*\d+').stringMatch(s);
  if (raw == null) return false;

  s = s.substring(raw.length).trim();
  if (s.isEmpty) return false;
  final String l1 = s[0];
  s = s.substring(1).trim();
  if (l1 == "'" && !onlySec) {
    if (s.isEmpty) return true;
    return matchTimePattern(s, true);
  } else if (l1 == '"' || l1 == '.') {
    if (s.isEmpty) return l1 == '"';
    return RegExp(l1 == '"' ? r'^\d\d?$' : r'^\d\d?\s*"?$').hasMatch(s);
  } else
    return false;
}

double? parseTimePattern(String? s) {
  if (s == null || s.isEmpty) return null;
  final RegExp digits = RegExp(r'\s*\d+\s*');
  final String? raw = digits.stringMatch(s);
  if (raw == null) return null;
  final int parsed = int.parse(raw);

  s = s.substring(raw.length).trim();
  final String l1 = s[0];
  s = s.substring(1).trim();

  if (l1 == "'") {
    if (s.isEmpty) return parsed * 60.0;
    return parsed * 60 + (parseTimePattern(s) ?? 0);
  } else if (l1 == '"' || l1 == '.') {
    if (s.isEmpty) return parsed.toDouble();
    return parsed + int.parse(digits.stringMatch(s)!.padRight(2, '0')) / 100;
  } else
    return null;
}
