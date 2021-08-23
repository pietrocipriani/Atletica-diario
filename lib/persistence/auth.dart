import 'dart:async';
import 'dart:io';

import 'package:app_installer/app_installer.dart';
import 'package:atletica/persistence/firestore.dart';
import 'package:atletica/persistence/user_helper/athlete_helper.dart';
import 'package:atletica/persistence/user_helper/coach_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_storage/firebase_storage.dart' as storage;
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

GoogleSignIn _googleSignIn = GoogleSignIn(
  signInOption: SignInOption.standard,
  clientId:
      '263594363462-k8t7l78a8cksdj1v9ckhq4cvtl9hd1q4.apps.googleusercontent.com',
);
FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
GoogleSignInAccount? _guser;
GoogleSignInAuthentication? _auth;

extension DocumentSnapshotExtension<T extends Object?> on DocumentSnapshot<T> {
  T? getNullable<T>(final String field) {
    try {
      return this[field];
    } on StateError {
      return null;
    }
  }
}

Object? _user;
set user(dynamic user) {
  assert(user == null || user is FirebaseUserHelper || user is User,
      'user is ${user.runtimeType}');
  _user = user;
}

bool get hasRole => _user != null && _user is FirebaseUserHelper;
FirebaseUserHelper get user => _user as FirebaseUserHelper;
AthleteHelper get userA => _user as AthleteHelper;
CoachHelper get userC => _user as CoachHelper;
dynamic get rawUser => _user;

abstract class FirebaseUserHelper {
  final User user;
  final bool admin;
  String get uid => userReference.id;
  String? get name => user.displayName;
  String? get email => user.email;
  final DocumentReference userReference;
  final DocumentReference realUser;

  bool get isCoach;
  bool get isAthlete;

  FirebaseUserHelper({
    required this.user,
    required this.userReference,
    this.admin = false,
  }) : this.realUser = userFromUid(user.uid);
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

Stream<double> login({required BuildContext context}) async* {
  final int N = 4;
  yield 0;
  print('logging');

  if (rawUser != null) {
    print('already authenticated');
    if (rawUser is FirebaseUserHelper) return;
    await initFirestore();
    yield 1;
    return;
  }
  print('requesting google account');

  do {
    _guser =
        await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
    if (_guser == null) await requestLoginDialog(context: context);
  } while (_guser == null);

  print('authenticating google');

  yield 1 / N;
  _auth = await _guser!.authentication;
  yield 2 / N;

  user = (await _firebaseAuth.signInWithCredential(
    GoogleAuthProvider.credential(
      idToken: _auth!.idToken,
      accessToken: _auth!.accessToken,
    ),
  ))
      .user;
  yield 3 / N;

  assert(rawUser != null);
  await initFirestore();

  await checkForRelease(context: context);

  yield 1;
}

Future<void> checkForRelease({required final BuildContext context}) async {
  if (kIsWeb || !Platform.isAndroid) return;
  try {
    final storage.Reference release =
        storage.FirebaseStorage.instance.ref('release/release.apk');
    final storage.FullMetadata meta = await release.getMetadata();

    final PackageInfo package = await PackageInfo.fromPlatform();
    final int currentVersion = int.parse(package.buildNumber);

    final int lastVersion = int.parse(meta.customMetadata!['version-code']!);

    if (lastVersion <= currentVersion) {
      print('$lastVersion vs $currentVersion');
      return;
    }
    final Future<bool?> dialog = showNewReleaseDialog(
      context: context,
      version: meta.customMetadata!['version-name']!,
      changelog: meta.customMetadata!['changelog']!,
      updateTime: meta.updated!,
    );
    if (await dialog ?? false) {
      final Directory dir = await getTemporaryDirectory();
      final File rel = File('${dir.path}${Platform.pathSeparator}release.apk');
      if (!rel.existsSync()) rel.createSync(recursive: true);
      rel.writeAsBytesSync((await release.getData(100 * 1024 * 1024))!,
          flush: true);
      await AppInstaller.installApk(rel.path);
    }
  } catch (e, s) {
    print(e);
    print(s);
  }
}

Future<void> logout() async {
  await _firebaseAuth.signOut();
  await _googleSignIn.signOut();
  user = null;
}

void changeAccount({required BuildContext context}) async {
  await logout();
  await for (double _ in login(context: context)) {}
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
                    .overline
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

Future requestLoginDialog({required BuildContext context}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Login'),
      content: Text(
        'Il login è necessario per il backup dei dati e per la comunicazione Allenatore/Athlete.\nInformazioni come la mail e il nome verranno condivisi solo fra questi ultimi.',
        style: Theme.of(context).textTheme.overline,
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => SystemNavigator.pop(),
          child: Text(
            'Exit',
            style: TextStyle(color: Colors.red),
          ),
        ),
        TextButton.icon(
          onPressed: () {
            Navigator.pop(ctx);
            login(context: context);
          },
          style: ButtonStyle(
            shape: MaterialStateProperty.all(StadiumBorder(
              side: BorderSide(color: Theme.of(context).disabledColor),
            )),
          ),
          icon: CircleAvatar(
            radius: 12,
            backgroundColor: Colors.transparent,
            backgroundImage: AssetImage('assets/google_logo.png'),
          ),
          label: Text(
            'Login',
            style: TextStyle(color: Colors.grey),
          ),
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
