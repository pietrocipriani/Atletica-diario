import 'package:Atletica/plan/widgets/week_dialog.dart';
import 'package:Atletica/training/allenamento.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Week {
  Map<int, DocumentReference> trainings;

  Week({this.trainings}) {
    trainings ??= <int, DocumentReference>{};
  }
  Week.parse(Map raw) {
    trainings = raw.map((key, value) => MapEntry(int.tryParse(key), value));
  }
  Week.copy(Week week) : this.trainings = Map.from(week.trainings);

  Map<String, dynamic> get asMap =>
      trainings.map((key, value) => MapEntry(key.toString(), value));

  static Future<Week> fromDialog(BuildContext context) {
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
      return trainings?.values
              ?.where((t) => t != null)
              ?.map((a) => allenamenti(a))
              ?.join(', ') ??
          'nessun allenamento';
    return () sync* {
      for (int i = 0; i < weekdays.length; i++)
        yield '${weekdays[i]}: ${allenamenti(trainings[i]) ?? 'riposo'}';
    }()
        .join('\n');
  }
}
