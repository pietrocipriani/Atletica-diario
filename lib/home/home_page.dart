import 'package:AtleticaCoach/persistence/auth.dart';
import 'package:AtleticaCoach/persistence/user_helper/coach_helper.dart';
import 'package:AtleticaCoach/results/result.dart';
import 'package:AtleticaCoach/results/results_edit_route.dart';
import 'package:AtleticaCoach/results/simple_training.dart';
import 'package:AtleticaCoach/schedule/schedule.dart';
import 'package:AtleticaCoach/training/allenamento.dart';
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

  /// must listen `onAthleteCallbacks` because insertion/removal
  /// can change schedule's disponibility
  /// ```
  /// Iterable<Schedule> get avaiableSchedules =>
  ///   schedules.values.where((s) => s.athletes.isNotEmpty && s.isValid);
  /// ```
  @override
  void initState() {
    callback.f = (_) => setState(() {});
    CoachHelper.onSchedulesCallbacks.add(callback);

    CoachHelper.onAthleteCallbacks.add(callback);
    super.initState();
  }

  @override
  void dispose() {
    CoachHelper.onSchedulesCallbacks.remove(callback.stopListening);
    CoachHelper.onAthleteCallbacks.remove(callback);
    super.dispose();
  }

  Widget _todayTrainingWidget(final Schedule s) {
    final Allenamento a = s.todayTraining;
    assert(a != null);
    return ListTile(
      title: Text(
        s.todayTraining.name,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      leading: IconButton(
        icon: Icon(Mdi.poll),
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultsEditRoute(
                Result(
                  training: SimpleTraining.from(a),
                  athletes: s.athletesRefs,
                ),
              ),
            )),
        color: Colors.black,
      ),
      subtitle: Text(
        s.joinAthletes,
        style: Theme.of(context).textTheme.overline.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColorDark,
            ),
      ),
      /*trailing: IconButton(
        icon: Icon(Icons.play_arrow),
        onPressed: () {},
        color: Colors.black,
      ),*/
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
