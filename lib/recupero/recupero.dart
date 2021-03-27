
class Recupero {
  static final int DEFAULT_TIME = 3*60;
  dynamic _recupero;

  Recupero([this._recupero = 3*60])
      : assert(_recupero is String || (_recupero is int && _recupero >= 0));
  dynamic get recupero => _recupero;
  set recupero(final dynamic recupero) {
    if (recupero == null) return;
    assert(recupero is int || recupero is String,
        'cannot set recupero as ${recupero.runtimeType}');
    if (recupero is int && recupero < 0)
      throw ArgumentError('Il recupero non può essere negativo');
    _recupero = recupero;
  }

  void switchType([final String defaultLength = '']) {
    if (recupero is int) recupero = defaultLength;
    else recupero = DEFAULT_TIME;
  }

  @override
  String toString() => recupero is int
      ? '${_recupero ~/ 60}:${(_recupero % 60).toString().padLeft(2, '0')}'
      : recupero;
}
