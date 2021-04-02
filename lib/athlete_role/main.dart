import 'package:atletica/athlete_role/request_coach.dart';
import 'package:atletica/global_widgets/custom_calendar.dart';
import 'package:atletica/global_widgets/logout_button.dart';
import 'package:atletica/global_widgets/swap_button.dart';
import 'package:atletica/results/pbs/pbs_page_route.dart';
import 'package:atletica/results/result.dart';
import 'package:atletica/date.dart';
import 'package:atletica/global_widgets/custom_expansion_tile.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/persistence/user_helper/athlete_helper.dart';
import 'package:atletica/results/results_edit_dialog.dart';
import 'package:atletica/schedule/schedule.dart';
import 'package:atletica/training/allenamento.dart';
import 'package:atletica/training/training_description.dart';
import 'package:flutter/material.dart';
import 'package:mdi/mdi.dart';
import 'package:table_calendar/table_calendar.dart';

class AthleteMainPage extends StatefulWidget {
  @override
  _AthleteMainPageState createState() => _AthleteMainPageState();
}

class _AthleteMainPageState extends State<AthleteMainPage> {
  final CalendarController controller = CalendarController();
  final Callback _callback = Callback();

  @override
  void initState() {
    AthleteHelper.onResultCallbacks.add(_callback..f = (v) => setState(() {}));
    super.initState();
  }

  @override
  void dispose() {
    AthleteHelper.onResultCallbacks.remove(_callback.stopListening);
    super.dispose();
  }

  Widget _trainingWidget(
      final ScheduledTraining s, final ScheduledTraining compatible) {
    final Result result = compatible == null
        ? null
        : userA.getResult(Date.fromDateTime(controller.selectedDay));
    final Allenamento a = s.work;
    print({0: 't', 1: 'e', 2: 's', 3: 't'}.entries.map((e) => e.value));
    if (a == null) return Container();
    print('no container!');
    final bool greyed = s != compatible && compatible != null;
    return CustomExpansionTile(
      title: a.name,
      titleColor: !greyed ? null : Theme.of(context).disabledColor,
      trailing: IconButton(
        icon: Icon(Mdi.poll),
        onPressed: Date.now() >= s.date && !greyed
            ? () => showResultsEditDialog(
                  context,
                  result ?? Result.empty(a, s.date),
                  (r) => userA.saveResult(results: r),
                )
            : null,
        color: IconTheme.of(context).color,
      ),
      leading: Radio<ScheduledTraining>(
        value: s,
        groupValue: compatible,
        onChanged: (st) {
          userA.saveResult(
            results: Result.empty(
              st.work,
              Date.fromDateTime(controller.selectedDay),
            ),
          );
        },
      ),
      children: [
        if (a.descrizione != null)
          Text(
            a.descrizione,
            style: Theme.of(context)
                .textTheme
                .overline
                .copyWith(fontWeight: FontWeight.normal),
            textAlign: TextAlign.justify,
          ),
        const SizedBox(height: 10),
      ]
          .followedBy(
              TrainingDescription.fromTraining(context, a, result, greyed))
          .toList(),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 40),
    );
  }

  Widget _resultWidget(final Result result) {
    if (result?.training == null) return Container();
    return CustomExpansionTile(
      title: '${result.training} (prev)',
      trailing: IconButton(
        icon: Icon(Mdi.poll),
        onPressed: Date.now() >= result.date
            ? () => showResultsEditDialog(
                  context,
                  result,
                  (r) => userA.saveResult(results: r),
                )
            : null,
        color: IconTheme.of(context).color,
      ),
      leading: Radio<ScheduledTraining>(
        value: null,
        groupValue: null,
        onChanged: (st) {},
      ),
      children: TrainingDescription.fromResults(context, result).toList(),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 40),
      /*trailing: IconButton(
        icon: Icon(Icons.play_arrow),
        onPressed: () {},
        color: Colors.black,
      ),*/
    );
  }

  ScheduledTraining get _compatibleST {
    if (controller.selectedDay == null) return null;
    final Result result =
        userA.getResult(Date.fromDateTime(controller.selectedDay));
    if (result == null) return null;
    if (userA.events[controller.selectedDay] == null) return null;

    for (final ScheduledTraining st in userA.events[controller.selectedDay])
      if (result.isCompatible(st)) return st;

    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!userA.hasCoach)
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RequestCoachRoute()),
        ),
      );
    final ThemeData theme = Theme.of(context);
    final ScheduledTraining compatibleST = _compatibleST;
    final Result result = controller.selectedDay == null
        ? null
        : userA.getResult(Date.fromDateTime(controller.selectedDay));
    List<Widget> children = <Widget>[
      if (result != null && compatibleST == null) _resultWidget(result)
    ];
    if (userA.events[controller.selectedDay] != null)
      children = children
          .followedBy(userA.events[controller.selectedDay]
              ?.where((st) =>
                  st == compatibleST ||
                  st.athletes.isEmpty ||
                  st.athletes.contains(userA.athleteCoachReference))
              ?.map((st) => _trainingWidget(st, compatibleST)))
          .toList();

    final CustomCalendar calendar = CustomCalendar(
      controller: controller,
      events: userA.events,
      onDaySelected: (d, evts, holidays) => setState(() {}),
    );

    return OrientationBuilder(builder: (context, orientation) {
      final Widget body = orientation == Orientation.portrait
          ? Column(children: [
              calendar,
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                height: 1,
                color: theme.disabledColor,
              ),
              Expanded(child: ListView(children: children)),
            ])
          : Padding(
              padding: MediaQuery.of(context).padding,
              child: Row(children: [
                AspectRatio(child: calendar, aspectRatio: 1),
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 20),
                  width: 1,
                  color: theme.disabledColor,
                ),
                Expanded(
                  child: ListView(
                    children: children,
                    padding: const EdgeInsets.all(0),
                  ),
                ),
              ]),
            );

      return Scaffold(
        appBar: orientation == Orientation.portrait
            ? AppBar(
                title: Text('Atletica - Atleta'),
                actions: [
                  IconButton(
                    icon: Icon(Mdi.podium),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PbsPageRoute()),
                      );
                    },
                  ),
                  LogoutButton(context: context),
                  SwapButton(context: context),
                ],
              )
            : null,
        body: body,
      );
    });
  }
}
