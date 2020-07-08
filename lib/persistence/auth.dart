import 'dart:async';
import 'dart:io';

import 'package:Atletica/persistence/firestore.dart';
import 'package:Atletica/persistence/user_helper/athlete_helper.dart';
import 'package:Atletica/persistence/user_helper/coach_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

GoogleSignIn _googleSignIn = GoogleSignIn(signInOption: SignInOption.standard);
FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
GoogleSignInAccount _guser;
GoogleSignInAuthentication _auth;

dynamic _user;
set user(dynamic user) {
  assert(user == null || user is FirebaseUser || user is FirebaseUserHelper);
  _user = user;
}

bool get hasRole => _user != null && _user is FirebaseUserHelper;
FirebaseUserHelper get user => hasRole ? _user : null;
AthleteHelper get userA => _user is AthleteHelper ? _user : null;
CoachHelper get userC => _user is CoachHelper ? _user : null;
dynamic get rawUser => _user;

abstract class FirebaseUserHelper {
  final FirebaseUser user;
  final String uid, name, email;
  final DocumentReference userReference;

  FirebaseUserHelper({@required this.user, @required this.userReference})
      : assert(user != null),
        uid = user.uid,
        name = user.displayName,
        email = user.email;
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
  user = await _firebaseAuth.currentUser();
  if (rawUser != null) {
    await initFirestore();
    yield 1;
    return;
  }
  do {
    _guser =
        await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
    if (_guser == null) await requestLoginDialog(context: context);
  } while (_guser == null);
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
  yield N / N;
}

Future<void> logout() async {
  await _firebaseAuth.signOut();
  await _googleSignIn.signOut();
  user = null;
}

void changeAccount({@required BuildContext context}) async {
  await logout();
  await for (double _ in login(context: context));
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
        FlatButton(
          onPressed: Platform.isAndroid ? () => SystemNavigator.pop() : null,
          child: Text(
            'Exit',
            style: TextStyle(color: Colors.red),
          ),
        ),
        FlatButton.icon(
          onPressed: () {
            Navigator.pop(ctx);
            login(context: context);
          },
          shape: StadiumBorder(side: BorderSide(color: Colors.grey[300])),
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
