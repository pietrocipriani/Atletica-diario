import 'dart:collection';

import 'package:atletica/persistence/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Cache<K extends Object, V> with Notifier {
  late final SplayTreeMap<K, V> _cache;

  Cache([int Function(K, K)? compare]) {
    if (compare == null && K == DocumentReference)
      compare = (a, b) {
        return (a as DocumentReference)
            .path
            .compareTo((b as DocumentReference).path);
      };
    _cache = SplayTreeMap(compare);
  }

  void reset() {
    _cache.clear();
  }

  V? remove(final K ref) {
    return _cache.remove(ref);
  }

  Iterable<V> get values => _cache.values;
  bool get isEmpty => _cache.isEmpty;
  bool get isNotEmpty => _cache.isNotEmpty;
  int get length => _cache.length;

  bool contains(final K key) => _cache.containsKey(key);
  V? operator [](final K key) => _cache[key];
  void operator []=(final K key, final V value) {
    _cache[key] = value;
  }
}
