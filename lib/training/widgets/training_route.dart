import 'package:Atletica/global_widgets/custom_dismissible.dart';
import 'package:Atletica/global_widgets/custom_expansion_tile.dart';
import 'package:Atletica/global_widgets/delete_confirm_dialog.dart';
import 'package:Atletica/global_widgets/leading_info_widget.dart';
import 'package:Atletica/main.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/persistence/user_helper/coach_helper.dart';
import 'package:Atletica/training/allenamento.dart';
import 'package:Atletica/training/training_description.dart';
import 'package:flutter/material.dart';

/// [Route] which displays the list of existing [Allenamento] (coach)
class TrainingRoute extends StatefulWidget {
  @override
  _TrainingRouteState createState() => _TrainingRouteState();
}

/// [State] for [TrainingRoute]
class _TrainingRouteState extends State<TrainingRoute> {
  /// the `callback` triggered when modifies occours
  final Callback callback = Callback();

  /// sign `callback` into [CoachHelper.onTrainingCallbacks] to listen on snapshots
  @override
  void initState() {
    callback.f = (_) => setState(() {});
    CoachHelper.onTrainingCallbacks.add(callback);
    super.initState();
  }

  /// remove `callback` from [CoachHelper.onTrainingCallbacks]
  @override
  void dispose() {
    CoachHelper.onTrainingCallbacks.remove(callback.stopListening);
    super.dispose();
  }

  static const Widget _emptyMessage =
      Center(child: Text('non hai creato ancora nessun allenamento'));

  static const Widget _fab = FloatingActionButton(
    // TODO: controllare se si può togliere il setState
    onPressed: Allenamento.create,
    child: Icon(Icons.add),
  );

  /// returns `true` if `a` can be shown, otherwise `false`
  static bool _shouldDisplay(Allenamento a) => !a.dismissed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ALLENAMENTI')),
      body: allenamenti.isEmpty
          ? _emptyMessage
          : ListView(
              children: allenamenti.values
                  .where(_shouldDisplay)
                  .map((training) => _TrainingWidget(training))
                  .toList(),
            ),
      floatingActionButton: _fab,
    );
  }
}


class _TrainingWidget extends StatelessWidget {
  final Allenamento training;
  final Key key;

  _TrainingWidget(this.training) : key = ValueKey(training);

  @override
  Widget build(BuildContext context) {


    return CustomDismissible(
        key: key,
        onDismissed: (direction) => training.delete(),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd)
            return await showDeleteConfirmDialog(
              context: context,
              name: training.name,
            );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TrainingInfoRoute(allenamento: training),
            ),
          ).then((value) => training.save());
          return false;
        },
        child: CustomExpansionTile(
          title: training.name,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: <Widget>[
                  Text(
                    training.descrizione == null || training.descrizione.isEmpty
                        ? 'nessuna descrizione'
                        : training.descrizione,
                    style: Theme.of(context)
                        .textTheme
                        .overline
                        .copyWith(fontWeight: FontWeight.normal),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                ]
                    .followedBy(
                        TrainingDescription.fromTraining(context, training))
                    .toList(),
              ),
            )
          ],
          leading: LeadingInfoWidget(
            info: training.countRipetute().toString(),
            bottom:
                singularPlural('ripetut', 'a', 'e', training.countRipetute()),
          ),
        ),
      );
  }
}
