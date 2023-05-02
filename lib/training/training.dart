import 'package:atletica/cache.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/recupero/recupero.dart';
import 'package:atletica/refactoring/common/src/control/globals.dart';
import 'package:atletica/ripetuta/ripetuta.dart';
import 'package:atletica/ripetuta/template.dart';
import 'package:atletica/training/serie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';

/// list of `weekdays` names in [italian] locale
final List<String> weekdays = dateTimeSymbolMap()['it'].WEEKDAYS;

/// list of `weekdays` short names in [italian] locale
final List<String> shortWeekDays = dateTimeSymbolMap()['it'].SHORTWEEKDAYS;

/// class for [trainings] representation
class Training with Notifier<Training> {
  static final Cache<DocumentReference, Training> _cache = Cache();
  static final Map<String, Map<String, Map<DocumentReference, Training>>> _cacheTree = {};

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
    return trainings.where((t) => (tag1 == null || tag1 == t.tag1) && (tag2 == null || tag2 == t.tag2)).length;
  }

  static Iterable fromPath([final String? tag1, final String? tag2]) {
    if (tag1 == null) return _cacheTree.keys;
    if (tag2 == null) return _cacheTree[tag1]?.keys ?? fromPath();
    return _cacheTree[tag1]?[tag2]?.values ?? fromPath(tag1);
  }

  static Set<String> tag2s([final String? tag1]) {
    return (_cacheTree[tag1]?.keys ?? const Iterable<String>.empty()).followedBy(_cacheTree.entries.where((e) => e.key != tag1).expand((e) => e.value.keys)).toSet();
  }

  static bool isNameInUse(final String name) => trainings.any((t) => t.name == name);
  static bool isNameInUseStrict(
    final String name,
    final String tag1,
    final String tag2,
  ) =>
      trainings.any((t) => t.name == name && t.tag1 == tag1 && t.tag2 == tag2);

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

  // final List<Variant> variants = [];

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
        tag1 = (raw.getNullable('tag1') ?? defaultTag) as String,
        tag2 = (raw.getNullable('tag2') ?? defaultTag) as String {
    final List? variants = ((raw.getNullable('variants') as List?)?[0] as Map<String, Object?>?)?['targets'] as List?;

    if (variants == null) {
      raw['serie'].forEach((raw) => Serie.parse(this, raw));
    } else {
      // TODO: mark this training as legacy
      raw['serie'].forEach((raw) => Serie.parseLegacy(this, raw, List.from(variants)));
    }

    /* if (raw.getNullable('variants') == null)
      Variant.fromOldMode(this);
    else 
      raw['variants'].forEach((raw) => Variant.parse(raw, this)); */
  }
  factory Training.update(final DocumentSnapshot raw) {
    final Training a = Training.of(raw.reference);
    a.name = raw['name'];
    a.descrizione = raw['description'];

    a.serie.clear();

    final List? variants = (raw.getNullable('variants') as Map<String, Object?>?)?['targets'] as List?;
    if (variants == null) {
      raw['serie'].forEach((raw) => Serie.parse(a, raw));
    } else {
      raw['serie'].forEach((raw) => Serie.parseLegacy(a, raw, List.from(variants)));
    }

    a.tag1 = raw['tag1'];
    a.tag2 = raw['tag2'];

    a.notifyAll(a, Change.UPDATED);
    return a;
  }

  static const defaultTag = 'generico';

  /// adds a new [doc] to [firestore/$userC/trainings/]
  ///
  /// [training] is initialized with a progressive `name`, `null` `description`
  /// and an empty `serie`
  static Future<void> create({
    required final String name,
    final String? tag1,
    final String? tag2,
    final List<Serie>? serie,
  }) {
    return Globals.coach.userReference.collection('trainings').add({
      'name': name,
      'description': '',
      'serie': serie?.map((serie) => serie.asMap).toList() ?? [],
      'tag1': tag1 ?? defaultTag,
      'tag2': tag2 ?? defaultTag,
    });
  }

  /// returns `index`th `Ripetuta` for `this`
  Ripetuta ripetutaFromIndex(int index) {
    final int initialIndex = index;
    for (Serie s in serie) for (int i = 0; i < s.ripetizioni; i++) for (Ripetuta r in s.ripetute) for (int j = 0; j < r.ripetizioni; j++) if (--index < 0) return r;
    throw IndexError(initialIndex, ripetute);
  }

  /// returns all the [ripetute] as an `Iterable`
  /// (not grouped in [Serie]s)
  Iterable<Ripetuta> get ripetute sync* {
    for (Serie s in serie) for (int i = 0; i < s.ripetizioni; i++) for (Ripetuta r in s.ripetute) for (int j = 0; j < r.ripetizioni; j++) yield r;
  }

  Iterable<Recupero> get recuperi sync* {
    for (Serie s in serie) {
      yield* s.recuperi;
      if (s != serie.last) yield s.nextRecupero;
    }
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
    final DocumentReference reference = copy ? Globals.coach.userReference.collection('trainings').doc() : this.reference;

    return reference.set({
      'name': name,
      'description': descrizione,
      'serie': serie.map((serie) => serie.asMap).toList(),
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
  int get ripetuteCount => serie.fold(0, (sum, serie) => sum + serie.ripetuteCount);

  @override
  String toString() => name;

  String get suggestName => serie.map((s) => s.suggestName).join(' + ');

  static const String _mult = r'(\d+)\s*[x×]\s*';
  static final RegExp _parenthesis = RegExp(r'\([^\)]*\)');
  static final RegExp _separator = RegExp(r"\s*[\-\/,\+]\s*");
  static final RegExp _serie = RegExp(
    '^(?:$_mult)?\\(([^\\)]*)\\)|(?:(?:$_mult)?$_mult)?(.+)\$',
    dotAll: true,
  );
  static final RegExp _ripRegExp = RegExp("^(?:$_mult)?(\\d+\\s*[(?:k?M|m)'\"(?:hs)(?:min)]?)\\s*\$");
  static final RegExp _genericRipRegExp = RegExp(
    '^(?:$_mult)?(.+)\$',
    dotAll: true,
  );

  static bool isParsableName(final String name) {
    final Iterable<RegExpMatch> pMatches = _parenthesis.allMatches(name);
    final List<RegExpMatch> sMatches = pMatches.isEmpty && !RegExp(_mult).hasMatch(name) ? [] : _separator.allMatches(name).where((s) => pMatches.every((p) => p.start > s.start || p.end < s.end)).toList();
    final List<String> series = List.generate(sMatches.length + 1, (i) => name.substring(i == 0 ? 0 : sMatches[i - 1].end, i == sMatches.length ? null : sMatches[i].start));

    final List<RegExpMatch?> matches = series.map(_serie.firstMatch).toList();
    if (matches.any((s) => s == null)) return false;

    return matches.whereType<RegExpMatch>().every((match) {
      final String rip = match.group(2) ?? match.group(5)!;
      final List<String> split = rip.split(_separator);
      return split.every((s) {
        s = s.trim();
        final RegExpMatch? match = _genericRipRegExp.firstMatch(s);
        if (match == null) return false;
        final String ripName = match.group(2)!.trim();
        final RegExpMatch? match2 = RegExp(r'(\d+)(.*)', dotAll: true).firstMatch(ripName);
        final RegExp matcher = RegExp(
          match2 == null ? '^\s*${RegExp.escape(ripName)}\s*\$' : '^\s*${match2.group(1)}\s*${RegExp.escape(match2.group(2)!)}\s*\$',
          caseSensitive: false,
        );
        if (templates.keys.any(matcher.hasMatch)) return true;
        return _ripRegExp.hasMatch(s);
      });
    });
  }

  static List<Serie>? parseName(final String name) {
    final Iterable<RegExpMatch> pMatches = _parenthesis.allMatches(name);
    final List<RegExpMatch> sMatches = pMatches.isEmpty && !RegExp(_mult).hasMatch(name) ? [] : _separator.allMatches(name).where((s) => pMatches.every((p) => p.start > s.start || p.end < s.end)).toList();
    final List<String> series = List.generate(
      sMatches.length + 1,
      (i) => name.substring(i == 0 ? 0 : sMatches[i - 1].end, i == sMatches.length ? null : sMatches[i].start),
    );

    final List<RegExpMatch?> matches = series.map(_serie.firstMatch).toList();

    return matches.map<Serie>((final match) {
      final int times = int.parse(match!.group(1) ?? match.group(3) ?? '1');
      final String rip = match.group(2) ?? match.group(5)!;
      final List<String> split = rip.split(_separator);
      return Serie(
        ripetizioni: times,
        ripetute: split.map((s) {
          s = s.trim();
          final RegExpMatch genericMatch = _genericRipRegExp.firstMatch(s)!;
          final String ripName = genericMatch.group(2)!.trim();
          final RegExpMatch? match2 = RegExp(r'^(\d+)\s*(.+)?$', dotAll: true).firstMatch(ripName);
          final RegExp matcher = RegExp(
            match2 == null ? '^\\s*${RegExp.escape(ripName)}\\s*\$' : '^\\s*${match2.group(1)}\\s*${RegExp.escape(match2.group(2) ?? 'M')}\\s*\$',
            caseSensitive: false,
          );
          final String template = templates.keys.firstWhere(
            matcher.hasMatch,
            orElse: () {
              final RegExpMatch match = _ripRegExp.firstMatch(s)!;
              final String rip = match.group(2)!;
              return rip;
            },
          );
          final int times = int.parse(match.group(4) ?? genericMatch.group(1) ?? '1');
          return Ripetuta(template: template, ripetizioni: times);
        }),
      );
    }).toList();
  }
  // TODO: reverse: training from name
}
