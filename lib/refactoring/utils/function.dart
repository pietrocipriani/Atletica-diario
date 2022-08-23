extension FunctionExtension<R, P0> on R Function(P0) {
  /// returns a function that is the composition of `this` and `other`
  R Function(P1) compose<P1>(final P0 Function(P1) other) => (value) => this(other(value));
}
