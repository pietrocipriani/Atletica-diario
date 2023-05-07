/// cast the given `value` to `T`. If `value` is not a `T`, returns `else`.
T cast<T>(final Object? value, final T orElse) => value is T ? value : orElse;
