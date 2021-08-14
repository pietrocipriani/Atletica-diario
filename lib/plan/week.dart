import 'package:atletica/plan/plan.dart';
import 'package:atletica/plan/widgets/week_dialog.dart';
import 'package:atletica/training/training.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Week {
  Map<int, DocumentReference?> trainings;

  Week({final Map<int, DocumentReference?>? trainings})
      : trainings = trainings ?? {};
  Week.parse(final Plan p, Map raw)
      : trainings = raw.map((key, value) => MapEntry(int.parse(key), value)) {
    p.weeks.add(this);
  }

  Week.copy(Week week) : this.trainings = Map.from(week.trainings);

  Map<String, dynamic> get asMap =>
      trainings.map((key, value) => MapEntry(key.toString(), value));

  static Future<Week?> fromDialog(BuildContext context) {
    final Week week = Week();
    return showDialog<Week>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          scrollable: true,
          title: Text('definisci settimana'),
          content: WeekDialog(week),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, week),
              child: const Text('Conferma'),
            )
          ],
        ),
      ),
    );
  }

  @override
  String toString([bool extended = false]) {
    if (!extended)
      return () sync* {
        for (int i = 0; i < 7; i++) {
          final DocumentReference? ref = trainings[(i + DateTime.monday) % 7];
          if (ref == null) continue;
          final Training? t = Training.tryOf(ref);
          if (t != null) yield t;
        }
      }()
          .join(', ');
    return () sync* {
      for (int i = 0; i < weekdays.length; i++)
        yield '${weekdays[i]}: ${Training.tryOf(trainings[i]) ?? 'riposo'}';
    }()
        .join('\n');
  }
}
