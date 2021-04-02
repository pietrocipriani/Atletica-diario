import 'package:atletica/athlete_role/main.dart';
import 'package:atletica/coach_role/main.dart';
import 'package:atletica/global_widgets/mode_selector_route.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/persistence/user_helper/coach_helper.dart';
import 'package:flutter/material.dart';

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
            style: Theme.of(context).textTheme.headline3.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).primaryColor,
                ),
          ),
          Expanded(child: Container()),
          StreamBuilder<double>(
            initialData: 0,
            stream: login(context: context),
            builder: (context, snapshot) {
              print('login progress: ${snapshot.data}');
              if (snapshot.data == 1) {
                print('in');
                WidgetsBinding.instance.addPostFrameCallback(
                  (d) {
                    print ('called navigator!');
                    return Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          if (user == null) return ModeSelectorRoute();
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
