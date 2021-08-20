import 'package:atletica/cache.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/recupero/recupero.dart';
import 'package:atletica/ripetuta/ripetuta.dart';
import 'package:atletica/training/serie.dart';
import 'package:atletica/training/variant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';

/// list of `weekdays` names in [italian] locale
final List<String> weekdays = dateTimeSymbolMap()['it'].WEEKDAYS;

/// list of `weekdays` short names in [italian] locale
final List<String> shortWeekDays = dateTimeSymbolMap()['it'].SHORTWEEKDAYS;

/// class for [trainings] representation
class Training with Notifier<Training> {
  static final Cache<DocumentReference, Training> _cache = Cache();
  static final Map<String, Map<String, Map<DocumentReference, Training>>>
      _cacheTree = {};

  static void Function(Callback c) signInGlobal = _cache.signIn;
  static void Function(Callback c) signOutGlobal = _cache.signOut;

  static void cacheReset() {
    _cache.reset();
    _cacheTree.clear();
  }

  static void remove(final DocumentReference ref) {
    final Training? a = _cache.remove(ref);
    if (a != null) _cacheTree[a.tag1]![a.tag2]!.remove(ref);
    if (a != null) _cache.notifyAll(a, Change.DELETED);
  }

  static Iterable<Training> get trainings => _cache.values;
  static int trainingsCount([final String? tag1, final String? tag2]) {
    return trainings
        .where((t) =>
            (tag1 == null || tag1 == t.tag1) &&
            (tag2 == null || tag2 == t.tag2))
        .length;
  }

  static Iterable fromPath([final String? tag1, final String? tag2]) {
    if (tag1 == null) return _cacheTree.keys;
    if (tag2 == null) return _cacheTree[tag1]?.keys ?? fromPath();
    return _cacheTree[tag1]?[tag2]?.values ?? fromPath(tag1);
  }

  static Set<String> tag2s([final String? tag1]) {
    return (_cacheTree[tag1]?.keys ?? const Iterable<String>.empty())
        .followedBy(_cacheTree.entries
            .where((e) => e.key != tag1)
            .expand((e) => e.value.keys))
        .toSet();
  }

  static bool isNameInUse(final String name) =>
      trainings.any((t) => t.name == name);

  static bool get isEmpty => _cache.isEmpty;
  static bool get isNotEmpty => _cache.isNotEmpty;
  static bool hasItems([final String? tag1, final String? tag2]) {
    if (tag1 == null) return _cacheTree.isNotEmpty;
    if (tag2 == null) return _cacheTree[tag1]?.isNotEmpty ?? false;
    return _cacheTree[tag1]?[tag2]?.isNotEmpty ?? false;
  }

  static Training? tryOf(final DocumentReference? ref) {
    if (ref == null) return null;
    try {
      return Training.of(ref);
    } on StateError {
      return null;
    }
  }

  factory Training.of(final DocumentReference ref) {
    final Training? a = _cache[ref];
    if (a == null) throw StateError('cannot find Training of ${ref.path}');
    return a;
  }

  /// `reference` to corresponding [firestore] doc
  final DocumentReference reference;

  /// `name` is the identifier for the current [training]
  ///
  /// `descrizione` contains [notes] & [description] for the current [training]
  ///
  /// `tag1` is a tag for trainings folding
  ///
  /// `tag2` is a tag for trainings subfolding
  String name, descrizione, tag1, tag2;

  /// `serie` is a `List` containing all the `Serie`s composing the [training]
  final List<Serie> serie = <Serie>[];

  final List<Variant> variants = [];

  /// creates an instance from [firestore] `DocumentSnapshot`
  ///
  /// adds `this` to `allenamenti`
  factory Training.parse(final DocumentSnapshot raw) {
    final Training a = _cache[raw.reference] ??= Training._parse(raw);
    ((_cacheTree[a.tag1] ??= {})[a.tag2] ??= {})[raw.reference] = a;
    _cache.notifyAll(a, Change.ADDED);
    return a;
  }
  Training._parse(final DocumentSnapshot raw)
      : reference = raw.reference,
        name = raw['name'],
        descrizione = raw['description'] ?? '',
        tag1 = raw.getNullable('tag1') ?? defaultTag,
        tag2 = raw.getNullable('tag2') ?? defaultTag {
    raw['serie']?.forEach((raw) => Serie.parse(this, raw));
    if (raw.getNullable('variants') == null)
      Variant.fromOldMode(this);
    else
      raw['variants'].forEach((raw) => Variant.parse(raw, this));
  }
  factory Training.update(final DocumentSnapshot raw) {
    final Training a = Training.of(raw.reference);
    a.name = raw['name'];
    a.descrizione = raw['description'];

    a.serie.clear();
    raw['serie']?.forEach((raw) => Serie.parse(a, raw));

    a.tag1 = raw['tag1'];
    a.tag2 = raw['tag2'];

    a.variants.clear();
    raw['variants']?.forEach((raw) => Variant.parse(raw, a));

    a.notifyAll(a, Change.UPDATED);
    return a;
  }

  static const defaultTag = 'generico';

  /// adds a new [doc] to [firestore/$userC/trainings/]
  ///
  /// [training] is initialized with a progressive `name`, `null` `description`
  /// and an empty `serie`
  static Future<void> create([final String? tag1, final String? tag2]) {
    int index = _cache.length + 1;
    while (isNameInUse('training #$index')) index++;
    return user.userReference.collection('trainings').add({
      'name': 'training #$index',
      'description': '',
      'serie': [],
      'variants': const [Variant.emptyMap],
      'tag1': tag1 ?? defaultTag,
      'tag2': tag2 ?? defaultTag,
    });
  }

  /// returns `index`th `Ripetuta` for `this`
  Ripetuta ripetutaFromIndex(int index) {
    final int initialIndex = index;
    for (Serie s in serie)
      for (int i = 0; i < s.ripetizioni; i++)
        for (Ripetuta r in s.ripetute)
          for (int j = 0; j < r.ripetizioni; j++) if (--index < 0) return r;
    throw IndexError(initialIndex, ripetute);
  }

  /// returns all the [ripetute] as an `Iterable`
  /// (not grouped in [Serie]s)
  Iterable<Ripetuta> get ripetute sync* {
    for (Serie s in serie)
      for (int i = 0; i < s.ripetizioni; i++)
        for (Ripetuta r in s.ripetute)
          for (int j = 0; j < r.ripetizioni; j++) yield r;
  }

  Iterable<Recupero> get recuperi sync* {
    for (Serie s in serie) {
      yield* s.recuperi;
      if (s != serie.last) yield s.nextRecupero;
    }
  }

  bool isSerieRec(int index) {
    for (Serie s in serie) {
      if (index < 0) return false;
      if ((index + 1) % (s.ripetuteCount / s.ripetizioni) == 0 &&
          index ~/ (s.ripetuteCount / s.ripetizioni) < s.ripetizioni)
        return true;
      index -= s.ripetuteCount;
    }
    return false;
  }

  /// deletes current [training] from [firestore]
  Future<void> delete() {
    return reference.delete();
  }

  /// updates [firestore] doc with new data
  Future<void> save([final bool copy = false]) {
    String name = this.name;
    if (copy) {
      int copyNum = 1;
      while (isNameInUse('$name ($copyNum)')) copyNum++;
      name = '$name ($copyNum)';
    }
    final DocumentReference reference = copy
        ? user.userReference.collection('trainings').doc()
        : this.reference;

    return reference.set({
      'name': name,
      'description': descrizione,
      'serie': serie.map((serie) => serie.asMap).toList(),
      'variants': variants.map((v) => v.asMap(this)).toList(),
      'tag1': tag1.trim(),
      'tag2': tag2.trim(),
    });
  }

  /// returns `index`th [Recupero] for this
  Recupero? recuperoFromIndex(int index) {
    --index;
    if (index < 0) return null;
    for (Serie s in serie)
      for (int i = 1; i <= s.ripetizioni; i++)
        for (Ripetuta r in s.ripetute)
          for (int j = 1; j <= r.ripetizioni; j++)
            if (--index < 0) {
              if (j == r.ripetizioni) {
                if (r == s.ripetute.last) {
                  if (i == s.ripetizioni) {
                    if (s == serie.last)
                      return null;
                    else
                      return s.nextRecupero;
                  } else
                    return s.recupero;
                } else
                  return r.nextRecupero;
              } else
                return r.recupero;
            }
    return null;
  }

  /// returns the number of [Ripetuta] in `this` training
  int get ripetuteCount =>
      serie.fold(0, (sum, serie) => sum + serie.ripetuteCount);

  @override
  String toString() => name;

  String get suggestName => serie.map((s) => s.suggestName).join(' + ');
}
