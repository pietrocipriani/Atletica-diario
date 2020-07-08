import 'package:Atletica/global_widgets/mode_selector_route.dart';
import 'package:Atletica/global_widgets/splash_screen.dart';
import 'package:Atletica/home/home_page.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
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
  //Image _icon = Image.asset('assets/icon.png', width: 64, height: 64);

  /*void _showAboutDialog() {
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
  }*/

  /*void _showProfileDialog() async {
    TextEditingController coachController = TextEditingController();
    Callback<Event> callback;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        if (callback == null) {
          callback = Callback((evt) => setState(() {}));
          if (userA.coach is CoachRequest)
            userA.coach.waitForResponse(onValue: callback);
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
              if (userA?.coach == null || userA.coach is CoachRequest)
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
              userA.coach == null
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
                              ? () => userA.requestCoach(
                                    uid: coachController.text,
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
  }*/

  final Callback<Event> callback = Callback<Event>();

  @override
  void initState() {
    initializeDateFormatting('it');
    callback.f = (evt) => setState(() {});
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!hasRole)
      WidgetsBinding.instance.addPostFrameCallback(
        (d) => showModeSelectorRoute(context: context),
      );

    return Scaffold(
      body: HomePageWidget(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
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
