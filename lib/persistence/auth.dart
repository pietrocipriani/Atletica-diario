import 'dart:async';

import 'package:atletica/persistence/firestore.dart';
import 'package:atletica/persistence/user_helper/athlete_helper.dart';
import 'package:atletica/persistence/user_helper/coach_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

GoogleSignIn _googleSignIn = GoogleSignIn(
  signInOption: SignInOption.standard,
  clientId:
      '263594363462-k8t7l78a8cksdj1v9ckhq4cvtl9hd1q4.apps.googleusercontent.com',
);
FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
GoogleSignInAccount _guser;
GoogleSignInAuthentication _auth;

dynamic _user;
set user(dynamic user) {
  assert(user == null || user is FirebaseUserHelper || user is FirebaseUser,
      'user is ${user.runtimeType}');
  _user = user;
}

bool get hasRole => _user != null && _user is FirebaseUserHelper;
FirebaseUserHelper get user => hasRole ? _user : null;
AthleteHelper get userA => _user is AthleteHelper ? _user : null;
CoachHelper get userC => _user is CoachHelper ? _user : null;
dynamic get rawUser => _user;

abstract class FirebaseUserHelper {
  final FirebaseUser user;
  final bool admin;
  String get uid => userReference.documentID;
  String get name => user.displayName;
  String get email => user.email;
  final DocumentReference userReference;
  final DocumentReference realUser;

  FirebaseUserHelper({
    @required this.user,
    @required this.userReference,
    this.admin = false,
  })  : assert(user != null),
        this.realUser = userFromUid(user.uid);
}

class BasicUser {
  final String uid;
  String name;
  BasicUser({@required this.uid, this.name});
  BasicUser.parse(Map<String, dynamic> raw)
      : uid = raw['uid'],
        name = raw['name'];
  BasicUser.snapshot(DocumentSnapshot snap)
      : uid = snap.documentID,
        name = snap['name'];
}

class Request extends BasicUser {
  final DocumentReference reference;
  Request({@required this.reference, @required String uid, String name})
      : super(uid: uid, name: name);
}

Stream<double> login({@required BuildContext context}) async* {
  final int N = 4;
  yield 0;
  print('logging');

  if (rawUser != null) {
    print('already authenticated');
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
  _auth = await _guser.authentication;
  yield 2 / N;

  user = (await _firebaseAuth.signInWithCredential(
    GoogleAuthProvider.getCredential(
      idToken: _auth.idToken,
      accessToken: _auth.accessToken,
    ),
  ))
      .user;
  yield 3 / N;

  assert(rawUser != null);
  await initFirestore();
  yield 1;
}

Future<void> logout() async {
  await _firebaseAuth.signOut();
  await _googleSignIn.signOut();
  user = null;
}

void changeAccount({@required BuildContext context}) async {
  await logout();
  await for (double _ in login(context: context)) {}
}

Future requestLoginDialog({@required BuildContext context}) {
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
  void Function(T arg) f;

  Callback([this.f]);

  void call(T arg) {
    if (active) f?.call(arg);
  }

  Callback<T> get stopListening {
    active = false;
    return this;
  }
}
