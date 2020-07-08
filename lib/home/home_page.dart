import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/persistence/user_helper/coach_helper.dart';
import 'package:Atletica/results/result.dart';
import 'package:Atletica/results/results_edit_route.dart';
import 'package:Atletica/results/simple_training.dart';
import 'package:Atletica/schedule/schedule.dart';
import 'package:Atletica/training/allenamento.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mdi/mdi.dart';

class HomePageWidget extends StatefulWidget {
  HomePageWidget({Key key}) : super(key: key);

  @override
  _HomePageWidgetState createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  BoxDecoration _bgDecoration = BoxDecoration(
    image: DecorationImage(
      image: AssetImage('assets/speed.png'),
      colorFilter: ColorFilter.mode(
        Colors.grey[100],
        BlendMode.srcIn,
      ),
    ),
  );

  final Callback callback = Callback();

  @override
  void initState() {
    callback.f = (_) => setState(() {});
    CoachHelper.onSchedulesCallbacks.add(callback);

    /// must listen `onAthleteCallbacks` because insertion/removal
    /// can change schedule's disponibility
    /// see `avaiableSchedules`
    CoachHelper.onAthleteCallbacks.add(callback);
    super.initState();
  }

  @override
  void dispose() {
    CoachHelper.onSchedulesCallbacks.remove(callback.stopListening);
    CoachHelper.onAthleteCallbacks.remove(callback);
    super.dispose();
  }

  Widget _todayTrainingWidget(Allenamento a) {
    return ListTile(
      title: Text(a.name),
      leading: IconButton(
        icon: Icon(Mdi.poll),
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultsEditRoute(
                Result(
                  training: SimpleTraining.from(a),
                  athletes: userC.athletes.map((a) => a.reference),
                ),
              ),
            )),
        color: Colors.black,
      ),
      trailing: IconButton(
        icon: Icon(Icons.play_arrow),
        onPressed: () {},
        color: Colors.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = todayTrainings.isNotEmpty
        ? ListView(
            children:
                todayTrainings.map((tt) => _todayTrainingWidget(tt)).toList(),
          )
        : Text('Nessun allenamento in programma per oggi!');
    return Container(
      alignment: todayTrainings.isEmpty ? Alignment.center : null,
      decoration: _bgDecoration,
      child: content,
    );
  }
}
