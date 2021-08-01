import 'package:atletica/global_widgets/mode_selector_route.dart';
import 'package:atletica/global_widgets/splash_screen.dart';
import 'package:atletica/home/home_page.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/themes/dark_theme.dart';
import 'package:atletica/themes/light_theme.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

const double kListTileHeight = 72.0;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await Firebase.initializeApp();
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Atletica',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
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
      WidgetsBinding.instance!.addPostFrameCallback(
        (d) => showModeSelectorRoute(context: context),
      );

    /// `Scaffold` requested for snackbars
    return Scaffold(body: HomePageWidget());
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
    {required BuildContext context,
    required Widget route,
    void Function(void Function())? setState}) async {
  await Navigator.push(context, MaterialPageRoute(builder: (context) => route));
  setState?.call(() {});
}

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereNullable(final bool Function(T) f, {T? Function()? orElse}) {
    try {
      firstWhere(f);
    } on StateError {
      return orElse?.call();
    }
  }
}
