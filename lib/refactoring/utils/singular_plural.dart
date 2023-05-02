import 'dart:collection';

/// it cache for reiterated requests. Maps singulars with plurals
///
/// en cache is not required since recomputation is simpler than search
final Map<String, String> _itConversions = HashMap();

/// Returns the singular or plural form of `singular` based on the value of `count`
///
/// It is not garanteed the correctness of the result, check the code before use of the shortcut.
/// If singular ends with 'o' the plural ends with 'i', 'a' -> 'e', 'e' -> 'i'
String singPlurIT(final String singular, final int count) {
  if (count == 1 || count == -1) return singular;
  {
    final String? plural = _itConversions[singular];
    if (plural != null) return plural;
  }
  final int lastIndex = singular.length - 1;
  final String base = singular.substring(0, lastIndex);
  final String end = singular[lastIndex];
  final String pluralEnd = const {'o': 'i', 'a': 'e', 'e': 'i'}[end]!; // the eventual throw is expected: the developer must check the applicability of this function

  return _itConversions[singular] = '$base$pluralEnd';
}

/// Returns the singular or plural form of `singular` based on the value of `count`
///
/// doesn't work with exceptions
String singPlurEN(final String singular, final int count) {
  if (count == 1 || count == -1) return singular;
  return '${singular}s';
}
