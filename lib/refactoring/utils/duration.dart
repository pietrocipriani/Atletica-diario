extension DurationExtension on Duration {
  /// returns the [Duration] as [String] in the format
  /// `([days]d)?([hours]h)?([minutes]')?[seconds]"([cents])?`.
  ///
  /// example:
  /// ```dart
  ///   var d = const Duration(days: 1);
  ///   print(d.formatted); // 1d00h00'00"
  ///
  ///   d = const Duration(hours: 1);
  ///   print(d.formatted); // 1h00'00"
  ///
  ///   d = const Duration(minutes: 1);
  ///   print(d.formatted); // 1'00"
  ///
  ///   d = const Duration(seconds: 1);
  ///   print(d.formatted); // 1"00
  ///
  /// ```
  String get formatted {
    if (isNegative) throw UnsupportedError('unexpected negative duration');
    return _formatDays;
  }

  /// formats starting from day
  String get _formatDays {
    final int days = inDays;
    if (days == 0) return _formatHours;
    return '${days}d $_formatHours';
  }

  /// formats starting from hour
  String get _formatHours {
    final int hours = inHours % 24;
    final bool force = inHours >= 24; // forces the hour sections even if 0, two digits
    if (force) return '${hours.toString().padLeft(2, '0')}h $_formatMinutes';
    if (hours == 0) return _formatMinutes;
    return '${hours}h $_formatMinutes';
  }

  /// formats starting from minute
  String get _formatMinutes {
    final int minutes = inMinutes % 60;
    final bool force = inHours >= 60; // forces the minutes sections even if 0, two digits
    if (force) return "${minutes.toString().padLeft(2, '0')}'$_formatSeconds";
    if (minutes == 0) return _formatSeconds;
    return "$minutes'$_formatSeconds";
  }

  /// formats starting from second
  String get _formatSeconds {
    final int seconds = inSeconds % 60;
    final bool force = inSeconds >= 60; // forces the seconds sections even if 0, two digits
    if (force) return '${seconds.toString().padLeft(2, '0')}"$_formatMillis';
    return '$seconds"$_formatMillis';
  }

  /// formats starting from millis
  String get _formatMillis {
    final int millis = inMilliseconds % 1000;
    final bool hide = inSeconds >= 60 && millis == 0;
    if (hide) return '';
    return (millis ~/ 10).toString();
  }
}
