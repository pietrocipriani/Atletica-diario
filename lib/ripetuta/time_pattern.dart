bool matchTimePattern(String? s, [bool onlySec = false, bool isPace = false]) {
  if (s == null || s.isEmpty) return false;
  if (isPace && s.endsWith('/km')) return matchTimePattern(s.substring(0, s.length - 3), onlySec);
  final String? raw = RegExp(onlySec ? r'^\s*[0-5]?\d' : r'^\s*\d+').stringMatch(s);
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

Duration? parseTimePattern(String? s) {
  if (s == null || s.isEmpty) return null;
  final RegExp digits = RegExp(r'\s*\d+\s*');
  final String? raw = digits.stringMatch(s);
  if (raw == null) return null;
  final int parsed = int.parse(raw);

  s = s.substring(raw.length).trim();
  final String l1 = s[0];
  s = s.substring(1).trim();

  if (l1 == "'") {
    if (s.isEmpty) return Duration(milliseconds: parsed * 60 * 1000);
    return Duration(milliseconds: parsed * 60 * 1000) + (parseTimePattern(s) ?? Duration.zero);
  } else if (l1 == '"' || l1 == '.') {
    if (s.isEmpty) return Duration(milliseconds: parsed * 1000);
    return Duration(milliseconds: parsed * 1000 + int.parse(digits.stringMatch(s)!.padRight(2, '0')) * 10);
  } else
    return null;
}
