import 'dart:io';

import 'package:atletica/athlete_role/athlete_main_page.dart';
import 'package:atletica/athlete_role/request_coach.dart';
import 'package:atletica/coach_role/main.dart';
import 'package:atletica/firebase_options.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/preferences.dart';
import 'package:atletica/refactoring/common/src/view/auth_gate.dart';
import 'package:atletica/refactoring/common/src/view/get_platform_app.dart';
import 'package:atletica/refactoring/common/src/view/role_gate.dart';
import 'package:atletica/themes/dark_theme.dart';
import 'package:atletica/themes/light_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';

const double kListTileHeight = 72.0;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  FirebaseUIAuth.configureProviders([
    if (!Platform.isAndroid) GoogleProvider(clientId: '263594363462-k8t7l78a8cksdj1v9ckhq4cvtl9hd1q4.apps.googleusercontent.com'),
    if (Platform.isAndroid) GoogleProvider(clientId: '263594363462-k13bignr5fp7mt7l3cmsa54bup01mvbp.apps.googleusercontent.com'), 
  ]);

  if (!kIsWeb) FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return PlatformProvider(
      initialPlatform: kDebugMode ? TargetPlatform.iOS : defaultTargetPlatform,
      settings: PlatformSettingsData(platformStyle: PlatformStyleData(web: PlatformStyle.Cupertino)),
      builder: (context) {
        //return Obx(() {
        return GetPlatformApp(
          title: 'Atletica',
          initialRoute: FirebaseAuth.instance.currentUser == null ? '/login' : '/role-picker',
          routes: {
            '/login': (context) => AuthGate(),
            '/role-picker': (context) => RoleGate(),
            '/coach': (context) => CoachMainPage(),
            '/athlete': (context) => AthleteMainPage(),
            RequestCoachRoute.routeName: (context) => RequestCoachRoute(),
            '/preferences': (context) => PreferencesRoute(),
            //'/': (context) =>
          },
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          material: (context, platform) => MaterialAppData(
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: /* hasRole ? user.themeMode : */ ThemeMode.system, // TODO: obx doesn't works because the first time ThemeMode.system is not an observable
          ),
          cupertino: (context, platform) => CupertinoAppData(
            theme: CupertinoThemeData(
              brightness: Brightness.light,
              primaryColor: CupertinoColors.systemOrange,
            ),
          ),
        );
        //});
      },
    );
  }
}

/* class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  /// initialize locale for `DateFormat` from `package:intl`
  @override
  void initState() {
    initializeDateFormatting('it');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!hasRole)

      /// requests [role] selection (if not choosen)
      WidgetsBinding.instance.addPostFrameCallback(
        (d) => showModeSelectorRoute(context: context),
      );

    /// `Scaffold` requested for snackbars
    return Scaffold(body: HomePageWidget());
  }
} */

/// a conventional function for starting a `route` with given `context`
/// and an optional `setState(() {})` if the ui can change after the pop
void startRoute({required BuildContext context, required Widget route, void Function(void Function())? setState}) async {
  await Navigator.push(context, MaterialPageRoute(builder: (context) => route));
  setState?.call(() {});
}

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereNullable(final bool Function(T) f, {T? Function()? orElse}) {
    try {
      return firstWhere(f);
    } on StateError {
      return orElse?.call();
    }
  }
}

/* Future<bool> _coachReminder(
  final User user,
  final FirebaseFirestore firestore,
) async {
  final int today = DateTime.now().weekday;
  final List<int> workDays = [
    DateTime.monday,
    DateTime.wednesday,
    DateTime.friday,
  ]; // TODO: choosen by user
  if (!workDays.contains(today)) return false;
  final Query q = firestore.collection('users').doc(user.uid).collection('schedules').where('date', isEqualTo: Timestamp.fromDate(Date.now()));
  final QuerySnapshot snap = await q.get();
  return snap.docs.isEmpty;
}

Future<bool> _athleteReminder(
  final User user,
  final DocumentSnapshot snap,
  final FirebaseFirestore firestore,
) async {
  final String? coachUid = snap.getNullable('coach');
  if (coachUid == null) return false;
  final DocumentReference requestRef = firestore.collection('users').doc(coachUid).collection('athletes').doc(user.uid);
  final DocumentSnapshot requestSnap = await requestRef.get();
  if (!requestSnap.exists || requestSnap.getNullable('nickname') == null || requestSnap.getNullable('group') == null) return false;
  final Query schedulesQ = firestore.collection('users').doc(coachUid).collection('schedules').where('date', isEqualTo: Timestamp.fromDate(Date.now()));
  final bool hasSchedules = (await schedulesQ.get()).docs.isNotEmpty;
  final Query resultsQ = firestore.collection('users').doc(user.uid).collection('results').where('date', isEqualTo: Timestamp.fromDate(Date.now()));
  final bool hasResults = (await resultsQ.get()).docs.isNotEmpty;
  return !hasSchedules && !hasResults;
} */

/*void _isolateCallback() {
  Workmanager().executeTask((taskName, inputData) async {
    await Firebase.initializeApp();
    final GoogleSignIn _googleSignIn = GoogleSignIn(
        clientId:
            '263594363462-k8t7l78a8cksdj1v9ckhq4cvtl9hd1q4.apps.googleusercontent.com');
    FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

    final GoogleSignInAccount? _guser = await _googleSignIn.signInSilently();
    if (_guser == null) return true;
    final GoogleSignInAuthentication _auth = await _guser.authentication;

    final User? user = (await _firebaseAuth.signInWithCredential(
      GoogleAuthProvider.credential(
        idToken: _auth.idToken,
        accessToken: _auth.accessToken,
      ),
    ))
        .user;
    if (user == null) return true;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    final DocumentReference ref = firestore.collection('users').doc(user.uid);
    final DocumentSnapshot snap = await ref.get();
    if (!snap.exists) return true;
    final String? role = snap.getNullable('role');
    if (role == null) return true;
    if (taskName != '$role-reminder') return true;

    final bool ok;
    switch (role) {
      case 'coach':
        ok = await _coachReminder(user, firestore);
        break;
      case 'athlete':
        ok = await _athleteReminder(user, snap, firestore);
        break;
      default:
        return true;
    }

    if (!ok) return true;
    final FlutterLocalNotificationsPlugin notificationPlugin =
        FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await notificationPlugin.initialize(
      initializationSettings,
      onSelectNotification: (payload) async =>
          notificationSelected.add(payload),
    );

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      taskName,
      '$role reminder notification',
      channelDescription:
          'shows notifications when you haven\'t scheduled a training in a work day',
      ticker: 'training not set yet',
      onlyAlertOnce: true,
    );
    final NotificationDetails details =
        NotificationDetails(android: androidDetails);
    notificationPlugin.show(
      1,
      'Training Reminder',
      "you haven't scheduled a training for today yet!",
      details,
    );
    return true;
  });
}

void _initWorkmanager() {
  Workmanager().initialize(_isolateCallback);
  final TimeOfDay scheduleC = TimeOfDay(hour: 13, minute: 0);
  final TimeOfDay scheduleA = TimeOfDay(hour: 20, minute: 0);
  final TimeOfDay now = TimeOfDay.now();
  Duration delayC = Duration(
    hours: scheduleC.hour - now.hour,
    minutes: scheduleC.minute - now.minute,
  );
  Duration delayA = Duration(
    hours: scheduleA.hour - now.hour,
    minutes: scheduleA.minute - now.minute,
  );
  if (delayC.isNegative) delayC = delayC + const Duration(days: 1);
  if (delayA.isNegative) delayA = delayA + const Duration(days: 1);

  Workmanager().registerPeriodicTask(
    'coach-reminder',
    'coach-reminder',
    initialDelay: delayC,
    frequency: const Duration(days: 1),
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );
  Workmanager().registerPeriodicTask(
    'athlete-reminder',
    'athlete-reminder',
    initialDelay: delayA,
    frequency: const Duration(days: 1),
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );
}*/
