/// returns the min between two [Comparable]s.
/// If the two elements are equal, `element1` is returned
T min<T extends Comparable<T>>(final T element1, final T? element2) {
  if (element2 == null) return element1;
  final int comparison = element1.compareTo(element2);

  if (comparison <= 0) return element1;
  return element2;
}
