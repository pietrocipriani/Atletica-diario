import 'dart:async';

import 'package:Atletica/allenamento.dart';
import 'package:Atletica/animated_text.dart';
import 'package:Atletica/atleta.dart';
import 'package:Atletica/auth.dart';
import 'package:Atletica/database.dart';
import 'package:Atletica/running_training.dart';
import 'package:Atletica/shedule.dart';
import 'package:Atletica/tabella.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mdi/mdi.dart';
import 'package:package_info/package_info.dart';
import 'package:vibration/vibration.dart';

const double kListTileHeight = 72.0;

/* 
TODO: user sign out
TODO: block app on user login refuse
*/
PackageInfo packageInfo;

bool canVibrate, vibrationAmplitude, vibrationCustomPattern;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  packageInfo = await PackageInfo.fromPlatform();
  FlutterError.onError = Crashlytics.instance.recordFlutterError;
  await init();
  canVibrate = await Vibration.hasVibrator();
  vibrationAmplitude = await Vibration.hasAmplitudeControl();
  vibrationCustomPattern = await Vibration.hasCustomVibrationsSupport();
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
        'route': ScheduleRoute(),
        'setState': null,
        'tooltip':
            'programma gli allenamenti per uno specifico gruppo di atleti',
      },
      {
        'icon': Icons.directions_run,
        'route': AthletesRoute(),
        'hasNotice': () => user?.requests?.isNotEmpty ?? false,
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
    _routesBnb = _routes(setState);
  }

  Image _icon = Image.asset('assets/icon.png', width: 64, height: 64);
  AssetImage _bg = AssetImage('assets/speed.png');

  SnackBar _trainingsErrorSnackBar, _athletesErrorSnackBar;
  SnackBar get _snackBar =>
      allenamenti.isEmpty ? _trainingsErrorSnackBar : _athletesErrorSnackBar;

  FloatingActionButton _fab;
  List<Map<String, dynamic>> _routesBnb;

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
    final Widget info = Expanded(
        child: Column(
      children: <Widget>[
        Text(packageInfo.appName, style: Theme.of(context).textTheme.headline6),
        Text(packageInfo.version, style: Theme.of(context).textTheme.overline),
      ],
    ));
    final Widget divider = Container(
      color: Colors.grey[300],
      width: double.infinity,
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 10),
    );
    final Widget gitHub = row(Mdi.github, 'github.com');
    final Widget support = row(Icons.mail, 'qui ci va la mail di supporto');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: <Widget>[
            FlatButton(
              onPressed: () => showLicensePage(context: context),
              child: Text('Licenze'),
            ),
            FlatButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            )
          ],
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[_icon, info],
              ),
              divider,
              gitHub,
              SizedBox(height: 10),
              support,
            ],
          ),
          scrollable: true,
        ),
      ),
    );
  }

  void _showProfileDialog() async {
    TextEditingController coachController = TextEditingController();
    Callback<Event> callback;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        if (callback == null) {
          callback = Callback((evt) => setState(() {}));
          if (user.coach is CoachRequest)
            user.coach.waitForResponse(onValue: callback);
        }
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(user?.name ?? 'utente anonimo'),
          scrollable: true,
          content: Column(
            children: <Widget>[
              Text(
                "L'uid è l'identificativo del tuo account, condividilo con i tuoi atleti per sincronizzare allenamenti e risultati. (tap to copy on clipboard)",
                textAlign: TextAlign.justify,
                style: Theme.of(context)
                    .textTheme
                    .overline
                    .copyWith(color: Colors.grey),
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Text(
                    'uid: ',
                    style: Theme.of(context)
                        .textTheme
                        .overline
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () =>
                          Clipboard.setData(ClipboardData(text: user.uid)),
                      child: Text(
                        user.uid,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  )
                ],
              ),
              SizedBox(
                height: 10,
              ),
              if (user?.coach == null || user.coach is CoachRequest)
                RichText(
                  text: TextSpan(
                      text:
                          "Se sei un atleta, inserisci qui sotto l'uid del tuo allenatore. Per permettere la valutazione della richiesta, verranno condivisi con l'allenatore l'indirizzo email ('",
                      style: Theme.of(context)
                          .textTheme
                          .overline
                          .copyWith(color: Colors.grey),
                      children: [
                        TextSpan(
                          text: user.email,
                          style: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: "') ed il nome dell'account ('"),
                        TextSpan(
                          text: user.name,
                          style: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: "')."),
                      ]),
                  textAlign: TextAlign.justify,
                ),
              user.coach == null
                  ? Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: coachController,
                            autofocus: false,
                            onChanged: (text) => setState(() {}),
                            decoration: InputDecoration(
                                hintText: "uid dell'allenatore"),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.send),
                          onPressed: coachController.text.isNotEmpty
                              ? () => user.requestCoach(
                                    coach: coachController.text,
                                    onValue: callback,
                                  )
                              : null,
                        )
                      ],
                    )
                  : Row(
                      children: <Widget>[
                        AnimatedText(
                          text: 'in attesa di conferma',
                          style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ],
          ),
          actions: <Widget>[
            FlatButton(
              onPressed: () => changeAccount(context: context),
              child: Text(
                'Cambia account',
                style: TextStyle(color: Colors.red),
              ),
            ),
            FlatButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        );
      }),
    );
    callback?.active = false;
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

  final Callback<Event> callback = Callback<Event>();

  @override
  void initState() {
    initializeDateFormatting('it');
    callback.f = (evt) => setState(() {});
    if (user == null)
      login(context: context).then((value) {
        user.requestCallbacks.add(callback);
        setState(() {});
      });
    super.initState();
  }

  @override
  void dispose() {
    user?.requestCallbacks?.remove(callback..active = false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppBar appBar = AppBar(
      title: Text('Atletica'),
      actions: <Widget>[
        IconButton(
          icon: user == null
              ? Icon(Icons.account_circle)
              : ClipOval(
                  child: Image.network(user.user.photoUrl ?? '',
                      errorBuilder: (context, exception, stack) =>
                          Icon(Icons.account_circle))),
          color: Colors.black,
          onPressed: _showProfileDialog,
        ),
        IconButton(
          icon: Icon(Icons.info_outline),
          onPressed: _showAboutDialog,
        ),
      ],
    );
    Widget content = runningTrainings.isNotEmpty
        ? SingleChildScrollView(child: Column(children: runningTrainings))
        : Text('Nessun allenamento in programma per oggi!');
    content = Container(
        alignment:
            runningTrainings.isEmpty ? Alignment.center : Alignment.topCenter,
        decoration: _bgDecoration,
        child: content);

    return Scaffold(
      key: _scaffold,
      appBar: appBar,
      body: content,
      floatingActionButton: _fab,
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar:
          _BottomAppBar(startRoute: _startRoute, routes: _routesBnb),
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
                        if (route['hasNotice']?.call() ?? false)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red,
                              ),
                            ),
                          )
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
