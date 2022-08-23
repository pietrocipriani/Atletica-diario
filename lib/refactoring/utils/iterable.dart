extension IterableExtension<T> on Iterable<T> {
  /// separate `this` elements with the ones from `supplier` which is recomputed every time
  // TODO: better a single computation?
  Iterable<S> separate<S>(final S Function() supplier) sync* {
    final Iterator<T> iterator = this.iterator;
    if (!iterator.moveNext()) return;
    yield iterator.current as S; // TODO: How can I write <S super T> in dart?

    while (iterator.moveNext()) {
      yield supplier();
      yield iterator.current as S;
    }
  }
}
