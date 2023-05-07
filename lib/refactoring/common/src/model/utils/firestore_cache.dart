import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';

typedef _Data = Map<String, Object?>;
typedef Document = DocumentReference<_Data>;

/// An HashMap implemented cache updated automatically by firestore events via listeners
// TODO: lazy cache (?): load data since it is requested.
//  * stops after there are no listeners? (could be a parameter)
class FirestoreCache<T> {
  /// The `Collection` this cache is listening to
  final CollectionReference<_Data> _collection;

  /// The actual cache
  final HashMap<Document, T?> _cache = HashMap();

  /// The subscription handle for cancelation
  StreamSubscription<QuerySnapshot<_Data>>? _subscription;

  /// Method for constructiong `T`s from firestore
  final T Function(DocumentSnapshot<_Data>) create;

  /// Optional method for updating existing values.
  /// If not given, modified elements are removed and reconstructed
  final void Function(T, DocumentSnapshot<_Data>)? edit;

  /// Optional method to perform actions when an element has been removed
  final void Function(T)? finalize;

  FirestoreCache({
    required final CollectionReference<_Data> collection,
    required this.create,
    this.edit,
    this.finalize,
  }) : _collection = collection {
    _subscription = _collection.snapshots().listen(_handleEvent);
  }

  void _handleEvent(final QuerySnapshot<_Data> event) {
    for (final change in event.docChanges) {
      // show must go on
      try {
        switch (change.type) {
          case DocumentChangeType.added:
            _cache[change.doc.reference] = create(change.doc);
            break;
          case DocumentChangeType.modified:
            final e = _cache[change.doc.id];
            if (edit != null && e != null)
              edit!(e, change.doc);
            else {
              if (finalize != null && e != null) finalize!(e);
              _cache[change.doc.reference] = create(change.doc);
            }

            break;
          case DocumentChangeType.removed:
            final T? e = _cache.remove(change.doc.id);
            if (finalize != null && e != null) finalize!(e);
            break;
        }
      } catch (e, s) {
        // TODO: notify exception
        print(e);
        print(s);
      }
    }
  }

  /// Cancel the subscription. After this call the cache shouldn't be used anymore
  void cancel() {
    _subscription?.cancel();
    _subscription = null;
  }

  bool contains(final Document key) => _cache.containsKey(key);
}
