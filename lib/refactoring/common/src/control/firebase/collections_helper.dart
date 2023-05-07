import 'dart:async';

import 'package:atletica/refactoring/common/src/control/firebase/user_helper/user_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

typedef UserHelperCollection = EnhancedCollectionReference<UserHelper>;
typedef UserHelperDocument = EnhancedDocumentReference<UserHelper>;
typedef UserHelperSnapshot = EnhancedDocumentSnapshot<UserHelper>;

extension CollectionHelper on FirebaseFirestore {}

/// firebase Collection.withConverter doesn't allow FutureOr returns
class EnhancedCollectionReference<T> {
  final CollectionReference<Map<String, Object?>> collection;
  final FutureOr<T> Function(
    DocumentSnapshot<Map<String, Object?>>,
    SnapshotOptions?,
  ) fromFirestore;
  final Map<String, Object?> Function(T, SetOptions?) toFirestore;

  EnhancedCollectionReference({
    required this.collection,
    required this.fromFirestore,
    required this.toFirestore,
  });

  EnhancedDocumentReference<T> doc([final String? path]) {
    return EnhancedDocumentReference(
      document: collection.doc(path),
      fromFirestore: fromFirestore,
      toFirestore: toFirestore,
    );
  }
}

class EnhancedDocumentReference<T> {
  final DocumentReference<Map<String, Object?>> document;
  final FutureOr<T> Function(
    DocumentSnapshot<Map<String, Object?>>,
    SnapshotOptions?,
  ) fromFirestore;
  final Map<String, Object?> Function(T, SetOptions?) toFirestore;

  EnhancedDocumentReference({
    required this.document,
    required this.fromFirestore,
    required this.toFirestore,
  });

  Future<EnhancedDocumentSnapshot<T>> get() async {
    final snap = await document.get();
    final T? result = snap.exists ? await fromFirestore(snap, null) : null;
    return EnhancedDocumentSnapshot(result, snap.exists, this, snap.id);
  }

  Future<void> set(final T value) async {
    document.set(toFirestore(value, null));
  }
}

class EnhancedDocumentSnapshot<T> {
  final T? _data;
  final bool exists;
  final EnhancedDocumentReference<T> reference;
  final String id;

  EnhancedDocumentSnapshot(this._data, this.exists, this.reference, this.id);

  T? data() => _data;
}
