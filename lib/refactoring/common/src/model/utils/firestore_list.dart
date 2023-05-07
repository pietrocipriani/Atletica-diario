import 'package:get/get.dart';

class FirestoreList<E> extends RxList<E> {
  FirestoreList([List<E> initial = const []]) : super(initial);

  factory FirestoreList.filled(int length, E fill, {bool growable = false}) {
    return FirestoreList(List.filled(length, fill, growable: growable));
  }

  factory FirestoreList.empty({bool growable = false}) {
    return FirestoreList(List.empty(growable: growable));
  }

  /// Creates a list containing all [elements].
  factory FirestoreList.from(Iterable elements, {bool growable = true}) {
    return FirestoreList(List.from(elements, growable: growable));
  }

  /// Creates a list from [elements].
  factory FirestoreList.of(Iterable<E> elements, {bool growable = true}) {
    return FirestoreList(List.of(elements, growable: growable));
  }

  /// Generates a list of values.
  factory FirestoreList.generate(int length, E generator(int index),
      {bool growable = true}) {
    return FirestoreList(List.generate(length, generator, growable: growable));
  }

  /// Creates an unmodifiable list containing all [elements].
  factory FirestoreList.unmodifiable(Iterable elements) {
    return FirestoreList(List.unmodifiable(elements));
  }
}
