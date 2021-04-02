import 'package:atletica/athlete/atleta.dart';
import 'package:atletica/date.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/plan/tabella.dart';
import 'package:atletica/schedule/athletes_picker.dart';
import 'package:flutter/material.dart';

class PlanDialog extends StatefulWidget {
  final Tabella plan;
  PlanDialog([this.plan]);

  @override
  _PlanDialogState createState() => _PlanDialogState();
}

class _PlanDialogState extends State<PlanDialog> {
  String name;
  DateTime start,
      stop,
      firstAvaiableStartDay = () {
        DateTime tr = Date.now().dateTime;
        return tr.subtract(Duration(days: (tr.weekday - DateTime.monday) % 7));
      }();
  bool isNew;
  List<Athlete> athletes;

  @override
  void initState() {
    super.initState();
    name = widget.plan?.name;
    start = widget.plan?.start;
    stop = widget.plan?.stop;
    isNew = widget.plan == null;
    athletes = widget.plan?.athletes
            ?.map((a) => userC.rawAthletes[a])
            ?.where((a) => a != null)
            ?.toList() ??
        <Athlete>[];
  }

  String validator([String s]) {
    s ??= name ?? '';
    if (s.isEmpty) return 'inserire il nome';
    if (plans.values.any((p) => p != widget.plan && p.name == s))
      return 'nome già in uso';
    return null;
  }

  String _format(DateTime d) => d == null
      ? 'seleziona'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year % 100}';

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(isNew ? 'AGGIUNGI' : 'MODIFICA'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              initialValue: name,
              autofocus: false,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(labelText: 'nome'),
              validator: validator,
              onChanged: (value) {
                setState(() => name = value);
              },
            ),
            Row(
              children: <Widget>[
                Text('dal'),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      start = await showDatePicker(
                            context: context,
                            initialDate: start ?? firstAvaiableStartDay,
                            firstDate: firstAvaiableStartDay,
                            helpText: "seleziona la data di inizio",
                            selectableDayPredicate: (day) =>
                                day.weekday == DateTime.monday,
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          ) ??
                          start;
                      if (stop != null && start.isAfter(stop)) stop = start;
                      setState(() {});
                    },
                    onLongPress: start == null
                        ? null
                        : () => setState(() => start = stop = null),
                    child: Text(_format(start)),
                  ),
                ),
                Text('al'),
                Expanded(
                  child: TextButton(
                    onPressed: stop == null && start == null
                        ? null
                        : () async {
                            stop = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      stop ?? start.add(Duration(days: 6)),
                                  firstDate: start,
                                  helpText:
                                      "seleziona la data di fine. Premi a lungo sulla data della schermata precendente per eliminare la scadenza.",
                                  selectableDayPredicate: (day) =>
                                      day.weekday == DateTime.sunday,
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365)),
                                ) ??
                                stop;
                            setState(() {});
                          },
                    onLongPress:
                        stop == null ? null : () => setState(() => stop = null),
                    child: Text(_format(stop)),
                  ),
                )
              ],
            ),
            AthletesPicker(athletes, onChanged: (a) => setState(() {})),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annulla',
            ),
          ),
          TextButton(
            onPressed: validator() != null || (start == null) != (stop == null)
                ? null
                : () async {
                    if (isNew)
                      Tabella.create(
                        name: name,
                        athletes: athletes,
                        start: start,
                        stop: stop,
                      );
                    else
                      widget.plan.update(
                        name: name,
                        athletes: athletes,
                        start: start,
                        stop: stop,
                      );
                    Navigator.pop(context, true);
                  },
            child: Text(
              isNew ? 'Aggiungi' : 'Modifica',
            ),
          ),
        ],
      );
}
