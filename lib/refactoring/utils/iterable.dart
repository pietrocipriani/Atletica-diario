extension IterableExtension<T> on Iterable<T> {
  Iterable<S> separate<S>(final S Function() supplier) sync* {
    final Iterator<T> iterator = this.iterator;
    if (!iterator.moveNext()) return;
    yield iterator.current as S; // How can I write <S super T> in dart?

    while (iterator.moveNext()) {
      yield supplier();
      yield iterator.current as S;
    }
  }
}
