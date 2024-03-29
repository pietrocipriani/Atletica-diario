import 'package:atletica/athlete_role/athlete_main_page.dart';
import 'package:atletica/coach_role/main.dart';
import 'package:atletica/global_widgets/mode_selector_route.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/persistence/user_helper/coach_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Column(
        children: <Widget>[
          Expanded(child: Container()),
          Image.asset('assets/icon.png'),
          Text(
            'ATLETICA',
            style: Theme.of(context).textTheme.headline3!.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).primaryColor,
                ),
          ),
          Expanded(child: Container()),
          StreamBuilder<double>(
            initialData: 0,
            stream: login(context: context),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(snapshot.error.toString()),
                    content: Text(snapshot.stackTrace.toString()),
                    actions: [
                      TextButton(
                        onPressed: () => Clipboard.setData(ClipboardData(
                            text: '${snapshot.error}\n${snapshot.stackTrace}')),
                        child: Text('copia errore'),
                      )
                    ],
                  ),
                );
              }
              print('login progress: ${snapshot.data}');
              if (snapshot.connectionState == ConnectionState.done) {
                print('in');
                WidgetsBinding.instance!.addPostFrameCallback(
                  (d) {
                    print('called navigator!');
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          if (rawUser == null) return ModeSelectorRoute();
                          if (user is CoachHelper) return CoachMainPage();
                          return AthleteMainPage();
                        },
                      ),
                    );
                  },
                );
              }
              return Container(
                child: LinearProgressIndicator(
                  value: snapshot.data,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                height: 1,
                margin: const EdgeInsets.only(left: 8, right: 8, bottom: 20),
              );
            },
          )
        ],
      ),
    );
  }
}
