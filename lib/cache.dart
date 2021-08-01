import 'dart:collection';

import 'package:atletica/persistence/auth.dart';

class Cache<K, V> {
  final SplayTreeMap<K, V> _cache = SplayTreeMap();
  final List<Callback> callbacks = [];

  void signIn(final Callback c) => callbacks.add(c);
  void signOut(final Callback c) => callbacks.remove(c);

  void reset() {
    _cache.clear();
    callbacks.forEach((c) => c.f?.call(null));
  }

  V? remove(final K ref) {
    final V? t = _cache.remove(ref);
    if (t != null) notifyAll(ref);
    return t;
  }

  Iterable<V> get values => _cache.values;
  bool get isEmpty => _cache.isEmpty;
  bool get isNotEmpty => _cache.isNotEmpty;
  int get length => _cache.length;

  bool contains(final K key) => _cache.containsKey(key);
  V? operator [](final K key) => _cache[key];
  void operator []=(final K key, final V value) {
    callbacks.forEach((c) => c.f?.call(value));
    _cache[key] = value;
  }

  void notifyAll([final value]) {
    callbacks.forEach((c) => c.f?.call(value));
  }
}
