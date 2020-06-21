import 'package:Atletica/allenamento.dart';
import 'package:Atletica/atleta.dart';
import 'package:Atletica/database.dart';
import 'package:Atletica/running_training.dart';
import 'package:Atletica/tabella.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mdi/mdi.dart';
import 'package:package_info/package_info.dart';
import 'package:vibration/vibration.dart';

const double kListTileHeight = 72.0;

PackageInfo packageInfo;
GoogleSignInAccount user;
GoogleSignInAuthentication auth;
FirebaseUser firebaseUser;

bool canVibrate, vibrationAmplitude, vibrationCustomPattern;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  packageInfo = await PackageInfo.fromPlatform();
  () async {
    user = await GoogleSignIn(
      signInOption: SignInOption.standard,
    ).signIn();
    auth = await user.authentication;
    firebaseUser = (await FirebaseAuth.instance.signInWithCredential(
      GoogleAuthProvider.getCredential(
        idToken: auth.idToken,
        accessToken: auth.accessToken,
      ),
    ))
        .user;
  }();
  await init();
  canVibrate = await Vibration.hasVibrator();
  vibrationAmplitude = await Vibration.hasAmplitudeControl();
  vibrationCustomPattern = await Vibration.hasCustomVibrationsSupport();

  print ('canVibrate: $canVibrate');
  print ('amplitude: $vibrationAmplitude');
  print ('customVibration: $vibrationCustomPattern');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Atletica',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  MyHomePageState createState() => MyHomePageState();
}

final List<RunningTraining> runningTrainings = <RunningTraining>[];
List<Map<String, dynamic>> _routes(void Function(void Function()) setState) => [
      {
        'icon': Icons.schedule,
        'route': PlansRoute(),
        'setState': null,
        'tooltip':
            'programma gli allenamenti per uno specifico gruppo di atleti',
      },
      {
        'icon': Icons.directions_run,
        'route': AthletesRoute(),
        'setState': setState,
        'tooltip': 'gestisci i tuoi atleti',
      },
      {
        'icon': Mdi.table,
        'route': PlansRoute(),
        'setState': null,
        'tooltip': 'gestisci i programmi di lavoro',
      },
      {
        'icon': Icons.fitness_center,
        'route': TrainingRoute(),
        'setState': setState,
        'tooltip': 'gestisci gli allenamenti',
      }
    ];

class MyHomePageState extends State<MyHomePage> {
  GlobalKey<ScaffoldState> _scaffold = GlobalKey<ScaffoldState>();

  MyHomePageState() {
    _trainingsErrorSnackBar = _createSnackBar(true);
    _athletesErrorSnackBar = _createSnackBar(false);
    _bgDecoration = BoxDecoration(
      image: DecorationImage(
        image: _bg,
        colorFilter: ColorFilter.mode(
          Colors.grey[100],
          BlendMode.srcIn,
        ),
      ),
    );
    _fab = FloatingActionButton(
      onPressed: () async {
        if (allenamenti.isEmpty ||
            groups.every((group) => group.atleti.isEmpty))
          _scaffold.currentState.showSnackBar(_snackBar);
        else {
          Iterable<RunningTraining> result =
              await RunningTraining.fromDialog(context: context);
          if (result != null) setState(() => runningTrainings.addAll(result));
        }
      },
      tooltip: 'inizia un allenamento non programmato',
      child: Icon(Icons.play_arrow),
    );
    _bnb = _BottomAppBar(
      startRoute: _startRoute,
      routes: _routes(setState),
    );
  }

  Image _icon = Image.asset('assets/icon.png', width: 64, height: 64);
  AssetImage _bg = AssetImage('assets/speed.png');

  SnackBar _trainingsErrorSnackBar, _athletesErrorSnackBar;
  SnackBar get _snackBar =>
      allenamenti.isEmpty ? _trainingsErrorSnackBar : _athletesErrorSnackBar;

  FloatingActionButton _fab;
  _BottomAppBar _bnb;

  BoxDecoration _bgDecoration;

  void _startRoute(
      {@required Widget route, void Function(void Function()) setState}) async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (context) => route));
    setState?.call(() {});
  }

  void _showAboutDialog() {
    final Widget Function(IconData icon, String label) row = (icon, label) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Icon(icon),
          Text(label,
              style: Theme.of(context).textTheme.overline.copyWith(
                    color: Theme.of(context).primaryColorDark,
                    fontWeight: FontWeight.bold,
                  ))
        ],
      );
    };
    final Widget divider = Container(
      color: Colors.grey[300],
      width: double.infinity,
      height: 1,
      margin: const EdgeInsets.only(bottom: 10),
    );
    final Widget gitHub = row(Mdi.github, 'github.com');
    final Widget uid = row(Mdi.accountCircle, firebaseUser?.uid ?? '...');

    showAboutDialog(
        context: context,
        applicationVersion: packageInfo.version,
        applicationIcon: _icon,
        children: [divider, gitHub, SizedBox(height: 10), uid]);
  }

  SnackBar _createSnackBar(bool t) => SnackBar(
        content: Text('nessun ${t ? 'allenamento' : 'atleta'} disponibile'),
        action: SnackBarAction(
          label: 'CREA',
          onPressed: () => _startRoute(
              route: t ? TrainingRoute() : AthletesRoute(), setState: setState),
        ),
        duration: Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
      );

  @override
  void initState() {
    initializeDateFormatting('it');
    super.initState();
  }

  // TODO: fix target parser che con 7.20" prende solamente 20"

  @override
  Widget build(BuildContext context) {
    final AppBar appBar = AppBar(
      title: Text('Atletica'),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.info_outline),
          onPressed: _showAboutDialog,
        ),
      ],
    );
    Widget content = runningTrainings.isNotEmpty
        ? ListView(children: runningTrainings)
        : Text('Nessun allenamento in programma per oggi!');
    content = Container(
        alignment: Alignment.center, decoration: _bgDecoration, child: content);

    return Scaffold(
      key: _scaffold,
      appBar: appBar,
      body: content,
      floatingActionButton: _fab,
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: _bnb,
    );
  }
}

class _BottomAppBar extends StatelessWidget {
  final Row routes;

  _BottomAppBar(
      {@required
          void Function(
                  {@required Widget route,
                  void Function(void Function()) setState})
              startRoute,
      @required
          List<Map<String, dynamic>> routes})
      : this.routes = Row(
          children: routes
              .map((route) => IconButton(
                    icon: Stack(
                      overflow: Overflow.visible,
                      children: <Widget>[
                        Positioned(
                          child: Icon(route['icon'], color: Colors.black12),
                          left: 3,
                          top: 3,
                        ),
                        Icon(route['icon']),
                      ],
                    ),
                    onPressed: () => startRoute(
                        route: route['route'], setState: route['setState']),
                  ))
              .toList(),
        );

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: routes,
      notchMargin: 8,
      shape: CircularNotchedRectangle(),
      color: Theme.of(context).primaryColor,
    );
  }
}

AlertDialog deleteConfirmDialog(BuildContext context, String name) {
  return AlertDialog(
    title: Text('Conferma eliminazione'),
    content: RichText(
      text: TextSpan(
          text: 'Sei sicuro di voler eliminare ',
          style: Theme.of(context).textTheme.bodyText2,
          children: [
            TextSpan(
              text: name,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: '? Una volta cancellato non sarà più recuperabile!',
            )
          ]),
      textAlign: TextAlign.justify,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    actions: <Widget>[
      FlatButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text(
          'Annulla',
          style: TextStyle(color: Colors.grey),
        ),
      ),
      FlatButton(
        onPressed: () => Navigator.pop(context, true),
        child: Text(
          'Elimina',
          style: TextStyle(color: Colors.red),
        ),
      ),
    ],
  );
}
