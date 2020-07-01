import 'package:Atletica/athlete/athletes_route.dart';
import 'package:Atletica/global_widgets/mode_selector_route.dart';
import 'package:Atletica/global_widgets/splash_screen.dart';
import 'package:Atletica/home/home_page.dart';
import 'package:Atletica/schedule/schedule_route.dart';
import 'package:Atletica/training/allenamento.dart';
import 'package:Atletica/global_widgets/animated_text.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/persistence/database.dart';
import 'package:Atletica/plan/tabella.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
        dialogTheme: DialogTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        buttonTheme: ButtonThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      home: SplashScreen(),
      supportedLocales: [Locale('it')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  Image _icon = Image.asset('assets/icon.png', width: 64, height: 64);

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

  final Callback<Event> callback = Callback<Event>();

  @override
  void initState() {
    initializeDateFormatting('it');
    callback.f = (evt) => setState(() {});
    user.requestCallbacks.add(callback);
    super.initState();
  }

  @override
  void dispose() {
    user?.requestCallbacks?.remove(callback..active = false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (user.role == null)
      WidgetsBinding.instance.addPostFrameCallback(
        (d) => showModeSelectorRoute(context: context),
      );
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

    return Scaffold(
      appBar: appBar,
      body: HomePageWidget(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: _BottomAppBar(setState: setState),
    );
  }
}

class _BottomAppBar extends StatelessWidget {
  final void Function(void Function()) setState;

  _BottomAppBar({@required this.setState});

  Widget _sectionBtn({
    @required BuildContext context,
    @required IconData icon,
    @required Widget route,
    bool notify = false,
    bool onPop = false,
    String tooltip,
  }) =>
      IconButton(
        tooltip: tooltip,
        icon: Stack(
          alignment: Alignment.topRight,
          overflow: Overflow.visible,
          children: <Widget>[
            Positioned(
              child: Icon(icon, color: Colors.black12),
              left: 3,
              top: 3,
            ),
            Icon(icon, color: Colors.black),
            if (notify)
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              )
          ],
        ),
        onPressed: () => startRoute(
          context: context,
          route: route,
          setState: onPop ? setState : null,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Row(children: [
        _sectionBtn(
          context: context,
          icon: Icons.schedule,
          route: ScheduleRoute(),
          onPop: true,
          tooltip:
              'programma gli allenamenti per uno specifico gruppo di atleti',
        ),
        _sectionBtn(
            context: context,
            icon: Icons.directions_run,
            route: AthletesRoute(),
            notify: user?.requests?.isNotEmpty ?? false,
            tooltip: 'gestisci i tuoi atleti'),
        _sectionBtn(
            context: context,
            icon: Mdi.table,
            route: PlansRoute(),
            tooltip: 'gestisci i programmi di lavoro'),
        _sectionBtn(
            context: context,
            icon: Icons.fitness_center,
            route: TrainingRoute(),
            tooltip: 'gestisci gli allenamenti'),
      ]),
      color: Theme.of(context).primaryColor,
    );
  }
}

/// conventional (useless) function for italian words
/// ``` dart
/// // this returns 'allenamento'
/// singularPlural('allenament', 'o', 'i', 1);
/// // this returns 'allenamenti'
/// singularPlural('allenament', 'o', 'i', 2);
///
/// // this...:
/// singularPlural('allenament', 'o', 'i', count);
/// // ...is equal to:
/// 'allenament${count == 1 ? 'o', 'i'}'
/// ```
String singularPlural(String root, String singular, String plural, int count) {
  return '$root${count == 1 ? singular : plural}';
}

/// a conventional function for starting a `route` with given `context`
/// and an optional `setState(() {})` if the ui can change after the pop
void startRoute(
    {@required BuildContext context,
    @required Widget route,
    void Function(void Function()) setState}) async {
  await Navigator.push(context, MaterialPageRoute(builder: (context) => route));
  setState?.call(() {});
}
