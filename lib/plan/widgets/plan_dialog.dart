import 'package:atletica/athlete/athlete.dart';
import 'package:atletica/date.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/plan/plan.dart';
import 'package:atletica/schedule/athletes_picker.dart';
import 'package:flutter/material.dart';

class PlanDialog extends StatefulWidget {
  final Plan? plan;
  PlanDialog([this.plan]);

  @override
  _PlanDialogState createState() => _PlanDialogState();
}

class _PlanDialogState extends State<PlanDialog> {
  late String? name = widget.plan?.name;
  late DateTime? start = widget.plan?.start;
  late DateTime? stop = widget.plan?.stop;
  DateTime firstAvaiableStartDay = () {
    DateTime tr = Date.now();
    return tr.subtract(Duration(days: (tr.weekday - DateTime.monday) % 7));
  }();
  late final bool isNew = widget.plan == null;
  late List<Athlete> athletes = widget.plan?.athletes ?? [];

  @override
  void initState() {
    super.initState();

    if (stop?.isBefore(DateTime.now()) ??
        start?.isBefore(DateTime.now()) ??
        false) start = stop = null;
  }

  String? validator([String? s]) {
    s ??= name ?? '';
    if (s.isEmpty) return 'inserire il nome';
    if (Plan.plans.any((p) => p != widget.plan && p.name == s))
      return 'nome già in uso';
    return null;
  }

  String _format(DateTime? d) => d == null
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
              onChanged: (value) => setState(() => name = value),
            ),
            Row(
              children: <Widget>[
                Text('dal'),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      start = await showDatePicker(
                            context: context,
                            initialDate: start == null ||
                                    start!.isBefore(firstAvaiableStartDay)
                                ? firstAvaiableStartDay
                                : start!,
                            firstDate: firstAvaiableStartDay,
                            helpText: "seleziona la data di inizio",
                            selectableDayPredicate: (day) =>
                                day.weekday == DateTime.monday,
                            lastDate: firstAvaiableStartDay
                                .add(const Duration(days: 7 * 52)),
                          ) ??
                          start;
                      if (stop != null && start!.isAfter(stop!))
                        stop = start!.add(const Duration(days: 6));
                      setState(() {});
                    },
                    onLongPress: () => setState(() => start = stop = null),
                    child: Text(_format(start)),
                  ),
                ),
                Text('al'),
                Expanded(
                  child: TextButton(
                    onPressed: start == null
                        ? null
                        : () async {
                            stop = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      stop ?? start!.add(Duration(days: 6)),
                                  firstDate: start!,
                                  helpText:
                                      "seleziona la data di fine. Premi a lungo sulla data della schermata precendente per eliminare la scadenza.",
                                  selectableDayPredicate: (day) =>
                                      day.weekday == DateTime.sunday,
                                  lastDate: firstAvaiableStartDay
                                      .add(const Duration(days: 7 * 53)),
                                ) ??
                                stop;
                            setState(() {});
                          },
                    onLongPress: start == null
                        ? null
                        : () => setState(() => stop = null),
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
                      Plan.create(
                        name: name!,
                        athletes: athletes,
                        start: start,
                        stop: stop,
                      );
                    else
                      widget.plan!.update(
                        name: name,
                        athletes: athletes.map((a) => a.reference).toList(),
                        start: start,
                        stop: stop,
                        removingSchedules: start == null,
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
