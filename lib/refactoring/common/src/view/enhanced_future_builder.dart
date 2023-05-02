import 'dart:async';

import 'package:flutter/cupertino.dart';

/// A [FutureBuilder] which can perform more tasks on [Future] completition
class EnhancedFutureBuilder<T> extends StatefulWidget {
  const EnhancedFutureBuilder({
    super.key,
    this.future,
    this.initialData,
    required this.builder,
    this.onResult,
  });

  final Future<T>? future;
  final AsyncWidgetBuilder<T> builder;
  final T? initialData;

  /// gets the [AsyncSnapshot] of the result before the `builder` does.
  ///
  /// Userful for calling navigators instead of rebuilding.
  ///
  /// If returns `true` the widget is rebuilded, otherwise the result is consumed.
  final FutureOr<bool> Function(AsyncSnapshot<T>)? onResult;

  @override
  State<EnhancedFutureBuilder<T>> createState() => _FutureBuilderState<T>();
}

/// State for [EnhancedFutureBuilder].
class _FutureBuilderState<T> extends State<EnhancedFutureBuilder<T>> {
  /// An object that identifies the currently active callbacks. Used to avoid
  /// calling setState from stale callbacks, e.g. after disposal of this state,
  /// or after widget reconfiguration to a new Future.
  Object? _activeCallbackIdentity;
  late AsyncSnapshot<T> _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot = widget.initialData == null ? AsyncSnapshot<T>.nothing() : AsyncSnapshot<T>.withData(ConnectionState.none, widget.initialData as T);
    _subscribe();
  }

  @override
  void didUpdateWidget(final EnhancedFutureBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.future != widget.future) {
      if (_activeCallbackIdentity != null) {
        _unsubscribe();
        _snapshot = _snapshot.inState(ConnectionState.none);
      }
      _subscribe();
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _snapshot);

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    if (widget.future != null) {
      final Object callbackIdentity = Object();
      _activeCallbackIdentity = callbackIdentity;
      widget.future!.then<void>((T data) async {
        if (_activeCallbackIdentity == callbackIdentity) {
          _snapshot = AsyncSnapshot<T>.withData(ConnectionState.done, data);
          if (await widget.onResult?.call(_snapshot) ?? true) setState(() {});
        }
      }, onError: (Object error, StackTrace stackTrace) async {
        if (_activeCallbackIdentity == callbackIdentity) {
          _snapshot = AsyncSnapshot<T>.withError(ConnectionState.done, error, stackTrace);
          if (await widget.onResult?.call(_snapshot) ?? true) setState(() {});
        }
      });
      _snapshot = _snapshot.inState(ConnectionState.waiting);
    }
  }

  void _unsubscribe() {
    _activeCallbackIdentity = null;
  }
}
