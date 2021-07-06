import 'package:atletica/persistence/auth.dart';
import 'package:atletica/recupero/recupero.dart';
import 'package:atletica/ripetuta/ripetuta.dart';
import 'package:atletica/training/serie.dart';
import 'package:atletica/training/variant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Map [DocumentReference] [Allenamento] of the existing [trainings]
///
/// populated by `CoachHelper` query snapshot listener
final Map<DocumentReference, Allenamento> _allenamenti = {};
final Map<String, Map<String, Map<DocumentReference, Allenamento>>>
    trainingsTree = {};
void trainingsReset() {
  _allenamenti.clear();
  trainingsTree.clear();
}

dynamic allenamenti(final DocumentReference ref,
    [final Allenamento allenamento]) {
  if (allenamento == null)
    return _allenamenti[ref];
  else {
    final Allenamento prev = _allenamenti[ref];
    _allenamenti[ref] = allenamento;
    if (prev != null &&
        (prev.tag1 != allenamento.tag1 || prev.tag2 != allenamento.tag2))
      trainingsTree[prev.tag1][prev.tag2].remove(prev.reference);
    ((trainingsTree[allenamento.tag1] ??= {})[allenamento.tag2] ??= {})[ref] =
        allenamento;
  }
}

Iterable<Allenamento> get trainingsValues => _allenamenti.values;
Allenamento removeTraining(final DocumentReference ref) {
  final Allenamento tr = _allenamenti.remove(ref);
  if (tr == null) return null;

  return trainingsTree[tr.tag1][tr.tag2].remove(ref);
}

bool get hasTrainings => _allenamenti.isNotEmpty;

/// list of `weekdays` names in [italian] locale
final List<String> weekdays = dateTimeSymbolMap()['it'].WEEKDAYS;

/// list of `weekdays` short names in [italian] locale
final List<String> shortWeekDays = dateTimeSymbolMap()['it'].SHORTWEEKDAYS;

/// class for [trainings] representation
class Allenamento {
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
  List<Serie> serie = <Serie>[];

  /// flag preventing [training] rendering (in `TrainingRoute`) if `dismissed`
  bool dismissed = false;

  List<Variant> variants;

  /// creates an instance from [firestore] `DocumentSnapshot`
  ///
  /// adds `this` to `allenamenti`
  Allenamento.parse(DocumentSnapshot raw)
      : assert(raw != null && raw['name'] != null),
        reference = raw.reference,
        name = raw['name'],
        descrizione = raw['description'],
        serie = raw['serie']?.map<Serie>((raw) => Serie.parse(raw))?.toList() ??
            <Serie>[],
        tag1 = raw['tag1'] ?? 'generico',
        tag2 = raw['tag2'] ?? 'generico' {
    variants = raw['variants'] == null
        ? [Variant.fromOldMode(this)]
        : raw['variants']
            .map<Variant>((raw) => Variant.parse(raw, this))
            .toList();
    allenamenti(reference, this);
  }

  /// adds a new [doc] to [firestore/$userC/trainings/]
  ///
  /// [training] is initialized with a progressive `name`, `null` `description`
  /// and an empty `serie`
  static Future<void> create([final String tag1, final String tag2]) {
    int index = _allenamenti.length + 1;
    while (_allenamenti.values.any((a) => a.name == 'training #$index'))
      index++;
    return user.userReference.collection('trainings').add({
      'name': 'training #$index',
      'description': null,
      'serie': [],
      'variants': const [Variant.emptyMap],
      'tag1': tag1 ?? 'generico',
      'tag2': tag2 ?? 'generico',
    });
  }

  /// returns `index`th `Ripetuta` for `this`
  Ripetuta ripetutaFromIndex(int index) {
    for (Serie s in serie)
      for (int i = 0; i < s.ripetizioni; i++)
        for (Ripetuta r in s.ripetute)
          for (int j = 0; j < r.ripetizioni; j++) if (--index < 0) return r;
    return null;
  }

  /// returns all the [ripetute] as an `Iterable`
  /// (not grouped in [Serie]s)
  Iterable<Ripetuta> get ripetute sync* {
    for (Serie s in serie)
      for (int i = 0; i < s.ripetizioni; i++)
        for (Ripetuta r in s.ripetute)
          for (int j = 0; j < r.ripetizioni; j++) yield r;
  }

  /// deletes current [training] from [firestore]
  Future<void> delete() {
    // TODO: checks for schedules
    dismissed = true;
    return reference.delete();
  }

  /// updates [firestore] doc with new data
  Future<void> save([final bool asNew = false]) {
    String name = this.name;
    if (asNew) {
      int copyNum = 1;
      while (_allenamenti.values.any((a) => a.name == '$name ($copyNum)'))
        copyNum++;
      name = '$name ($copyNum)';
    }

    return (asNew
            ? user.userReference.collection('trainings').document()
            : reference)
        .setData({
      'name': name,
      'description': descrizione,
      'serie': serie.map((serie) => serie.asMap).toList(),
      'variants': variants.map((v) => v.asMap(this)).toList(),
      'tag1': tag1?.trim(),
      'tag2': tag2?.trim(),
    });
  }

  /// returns `index`th [Recupero] for this
  Recupero recuperoFromIndex(int index) {
    index--;
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
  int countRipetute() {
    return serie.fold(0, (sum, serie) => sum + serie.ripetuteCount);
  }

  @override
  String toString() => name;
}
