import 'dart:async';

import 'package:atletica/refactoring/common/src/control/firebase/user_helper/athlete_helper.dart';
import 'package:atletica/refactoring/common/src/control/firebase/user_helper/coach_helper.dart';
import 'package:atletica/refactoring/common/src/control/firebase/user_helper/user_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension DocumentSnapshotExtension<T extends Object?> on DocumentSnapshot<T> {
  Object? getNullable(final String field) {
    try {
      return get(field);
    } on StateError {
      return null;
    }
  }

  T getLegacyFallback<T>(final List<String> fields) {
    assert(fields.isNotEmpty);
    StateError? error;
    for (final String field in fields) {
      try {
        return get(field);
      } on StateError catch (e) {
        error ??= e;
      }
    }
    throw error!;
  }
}

class BasicUser {
  final String uid;
  String? name;
  BasicUser({required this.uid, this.name});
  BasicUser.parse(Map<String, dynamic> raw)
      : uid = raw['uid'],
        name = raw['name'];
  BasicUser.snapshot(DocumentSnapshot snap)
      : uid = snap.id,
        name = snap['name'];
}

class Request extends BasicUser {
  final DocumentReference reference;
  Request({required this.reference, required String uid, String? name})
      : super(uid: uid, name: name);
}

Future<void> logout() async {
  FirebaseAuth.instance.signOut();
}

Future<bool?> showNewReleaseDialog({
  required BuildContext context,
  required final String version,
  required String changelog,
  required final DateTime updateTime,
}) {
  changelog =
      changelog.replaceAll(RegExp(r'^\*', multiLine: true), ' \u{2022} ');
  final String date = DateFormat.yMMMd('it_IT').format(updateTime);
  final String time = DateFormat.Hm('it_IT').format(updateTime);
  final TextStyle bold = const TextStyle(fontWeight: FontWeight.bold);

  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('NEW RELEASE'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RichText(
            text: TextSpan(
                text: 'la nuova versione ',
                children: [
                  TextSpan(text: version, style: bold),
                  TextSpan(text: ' del '),
                  TextSpan(text: date, style: bold),
                  TextSpan(text: ' ore '),
                  TextSpan(text: time, style: bold),
                  TextSpan(text: ' è disponibile!')
                ],
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(fontWeight: FontWeight.normal)),
          ),
          SizedBox(height: 4),
          Text('changelog:'),
          Text(changelog),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('ignora'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('installa'),
        ),
      ],
    ),
  );
}

class Callback<T> {
  bool active = true;
  void Function(T arg, Change c)? f;

  Callback([this.f]);

  void call(final T arg, final Change c) {
    if (active) f?.call(arg, c);
  }

  Callback<T> get stopListening {
    active = false;
    return this;
  }
}

enum Change { ADDED, UPDATED, DELETED }

mixin Notifier<T> {
  final List<Callback<T>> _callbacks = [];
  void signIn(final Callback<T> c) => _callbacks.add(c);
  bool signOut(final Callback<T> c) => _callbacks.remove(c);

  void notifyAll(final T arg, final Change change) {
    _callbacks.forEach((c) => c.call(arg, change));
  }
}
