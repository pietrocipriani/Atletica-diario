import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

GoogleSignIn _googleSignIn = GoogleSignIn(signInOption: SignInOption.standard);
FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
GoogleSignInAccount _user;
GoogleSignInAuthentication _auth;

FirebaseUserHelper user;

Future<dynamic> _get(String path, {DatabaseReference root}) async {
  TransactionResult res = await _child(path, root: root)
      .runTransaction((mutableData) => Future.value(mutableData));
  return res.dataSnapshot?.value;
}

Future<bool> _set(String path, dynamic value, {DatabaseReference root}) async {
  bool ok = true;
  await _child(path, root: root).set(value).catchError((e, s) => ok = false);
  return ok;
}

DatabaseReference _child(String path, {DatabaseReference root}) {
  root ??= _reference;
  if (path == null) return root;
  return root.child(path);
}

class CoachRequest {
  final FirebaseUserHelper user;
  final String uid;

  CoachRequest(this.user, this.uid);

  Callback<Event> callback;
  StreamSubscription<Event> subscription;

  void waitForResponse({@required Callback<Event> onValue}) {
    if (onValue != null && onValue != callback) {
      callback?.active = false;
      callback = onValue;
    }
    subscription?.cancel();
    print('listening ${user._coachRequests.toString()}/${user.uid}');
    subscription = _child(user.uid, root: user._coachRequests)
        .onValue
        .listen((event) async {
      print('changed: ${event.snapshot.value}');
      print('callback: ${callback?.active}');
      if (event.snapshot.value == null) {
        /*if (_get('users/$uid') == null) {
          print ('get: ${await _get('users/$uid')}');
          print ((await _get('users/$uid')).runtimeType.toString());
          user.coach = BasicUser(uid: uid);
          subscription.cancel();
        } else*/
        subscription.cancel();
        await _set(null, null, root: user._reverseRequest);
        if (user.coach == this) user.coach = null;
      }
      callback?.call(event);
    });
  }
}

class BasicUser {
  final String uid;
  String name, email;
  BasicUser({@required this.uid, this.name, this.email});
  BasicUser.parse(Map<String, dynamic> raw)
      : uid = raw['uid'],
        name = raw['name'],
        email = raw['email'];
  BasicUser.snapshot(DataSnapshot data)
      : uid = data.key,
        name = data.value['name'],
        email = data.value['email'];
}

class FirebaseUserHelper {
  final FirebaseUser user;
  final String uid, name, email;
  final DatabaseReference _requests, _reverseRequest, _user;
  DatabaseReference get _coachRequests => _child('requests/${coach.uid}');
  dynamic _coach;

  set coach (dynamic coach) {
    assert (coach == null || coach is BasicUser || coach is CoachRequest);
    //print (StackTrace.current);
    if (coach == _coach) return;
    if (coach == null) {
      print ('coach = null');
      print (StackTrace.current);
    }
    else print ('coach = ${coach.uid}');
    if (_coach != null && _coach is CoachRequest) _coach.subscription?.cancel();
    _coach = coach;
  }
  get coach => _coach;

  FirebaseUserHelper(this.user)
      : assert(user != null),
        uid = user.uid,
        name = user.displayName,
        email = user.email,
        _requests = _reference.child('requests').child(user.uid),
        _reverseRequest = _reference.child('reverseRequest').child(user.uid),
        _user = _reference.child('users').child(user.uid) {
    _init();
  }

  void _init() async {
    await _set(null, {'name': name, 'email': email}, root: _user);
    await _getCoach();
    addAthletesRequestsListeners();
  }

  Future<bool> requestCoach(
      {@required String coach, @required Callback<Event> onValue}) async {
    if (coach == null ||
        uid == coach ||
        (this.coach != null && this.coach is BasicUser)) return null;
    print(this.coach);
    if (this.coach != null)
      await _set(uid, null, root: _coachRequests);

    bool ok = await _set('coach', coach, root: _reverseRequest);
    if (ok) {
      this.coach = CoachRequest(this, coach);
      this.coach.waitForResponse(onValue: onValue);
      await _set(
        uid,
        {'name': name, 'email': email},
        root: _coachRequests,
      );
    }
    return ok;
  }

  Future<void> _getCoach({Callback<Event> onValue}) async {
    String coachUid = await _get('coach', root: _user);
    if (coachUid != null) {
      coach = BasicUser(uid: coachUid);
      _set(null, null, root: _reverseRequest);
      return;
    }
    coachUid = await _get('coach', root: _reverseRequest);
    if (coachUid == null) return;
    if (await _get(uid, root: _coachRequests) == null) {
      await _set(null, null, root: _reverseRequest);
      return;
    }
    coach = CoachRequest(this, coachUid);
    coach.waitForResponse(onValue: onValue);
  }

  List<BasicUser> requests = [];
  List<Callback<Event>> requestCallbacks = <Callback<Event>>[];

  void addAthletesRequestsListeners() {
    _child(null, root: _requests)
      ..onChildAdded.listen((evt) {
        print('added');
        requests.add(BasicUser.snapshot(evt.snapshot));
        requestCallbacks.forEach((callback) => callback.call(evt));
      })
      ..onChildChanged.listen((evt) {
        requests
            .where((request) => request.uid == evt.snapshot.value['uid'])
            .forEach((request) {
          request.name = evt.snapshot.value['name'];
          request.email = evt.snapshot.value['email'];
        });
        requestCallbacks.forEach((callback) => callback.call(evt));
      })
      ..onChildRemoved.listen((evt) {
        print('removed');
        requests.removeWhere((request) => request.uid == evt.snapshot.key);
        requestCallbacks.forEach((callback) => callback.call(evt));
      })
      ..onChildMoved.listen((evt) => print('moved'));
  }

  Future<void> acceptRequest(BasicUser request) async {
    refuseRequest(request.uid);
    _child('athletes', root: _user).push().set(request.uid);
  }

  Future<void> refuseRequest(String uid) async {
    await _set(uid, null, root: _requests);
    requests.removeWhere((request) => request.uid == uid);
  }
}

FirebaseDatabase _database = FirebaseDatabase.instance
  ..setPersistenceEnabled(true);
DatabaseReference _reference = _database.reference();

Future<void> login({@required BuildContext context}) async {
  FirebaseUser firebaseUser = await _firebaseAuth.currentUser();
  if (firebaseUser != null) {
    user = FirebaseUserHelper(firebaseUser);
    return;
  }
  _user = await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
  if (_user == null) {
    requestLoginDialog(context: context);
    return;
  }
  _auth = await _user.authentication;
  // TODO: if user is different, ask for keep or drop database resources
  firebaseUser = (await _firebaseAuth.signInWithCredential(
    GoogleAuthProvider.getCredential(
      idToken: _auth.idToken,
      accessToken: _auth.accessToken,
    ),
  ))
      .user;
  if (firebaseUser == null) return;
  user = FirebaseUserHelper(firebaseUser);
}

Future<void> logout() async {
  await _firebaseAuth.signOut();
  await _googleSignIn.signOut();
  user = null;
}

void changeAccount({@required BuildContext context}) async {
  String prevMail = user?.email;
  await logout();
  await login(context: context);
  if (user?.email != null && user?.email != prevMail) {
    // TODO: delete database (and download the one on cloud) if the user is different (and new user is not null)
  }
}

void requestLoginDialog({@required BuildContext context}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Login'),
      content: Text(
        'Il login è necessario per il backup dei dati e per la comunicazione Allenatore/Atleta.\nInformazioni come la mail e il nome verranno condivisi solo fra questi ultimi.',
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
