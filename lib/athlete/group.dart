import 'package:atletica/athlete/athlete.dart';

String? lastGroup;

class Group {
  final String name;
  Iterable<Athlete> get athletes =>
      Athlete.athletes.where((a) => a.group == name);

  static List<Group> get groups {
    final Set<String> values = Set.from(Athlete.athletes.map((a) => a.group!));
    if (values.isEmpty) values.add('generico');
    return List.unmodifiable(values.map((g) => Group(name: g)));
  }

  bool isContainedIn(final Iterable<Athlete> athletes) {
    return this.athletes.every(athletes.contains);
  }

  @override
  bool operator ==(dynamic other) => other is Group && other.name == name;

  const Group({required this.name});

  @override
  int get hashCode => name.hashCode;
}
