import 'package:atletica/refactoring/utils/distance.dart';
import 'package:sealed_unions/factories/doublet_factory.dart';
import 'package:sealed_unions/implementations/union_2_impl.dart';
import 'package:sealed_unions/union_2.dart';

class ResultValue extends Union2Impl<Duration, Distance> {
  static const Doublet<Duration, Distance> _factory = Doublet();

  factory ResultValue.duration(final Duration duration) => ResultValue._(_factory.first(duration));
  factory ResultValue.distance(final Distance distance) => ResultValue._(_factory.second(distance));

  ResultValue._(final Union2<Duration, Distance> union) : super(union);

  Object get value => join((_) => _, (_) => _);

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    return other is ResultValue && value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}
