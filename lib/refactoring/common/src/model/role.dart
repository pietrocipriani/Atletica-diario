import 'package:atletica/refactoring/common/common.dart';

enum Role {
  coach,
  athlete;

  static Role? parse(final String? raw) {
    if (raw == null) return null;
    if (raw == coach.name) return coach;
    if (raw == athlete.name) return athlete;
    throw ArgumentError.value(raw);
  }
}