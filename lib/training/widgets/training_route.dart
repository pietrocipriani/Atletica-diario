import 'package:Atletica/global_widgets/custom_dismissible.dart';
import 'package:Atletica/global_widgets/custom_expansion_tile.dart';
import 'package:Atletica/global_widgets/custom_list_tile.dart';
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
  final String tag1, tag2;
  TrainingRoute([this.tag1, this.tag2])
      : assert(!(tag2 != null && tag1 == null), 'must set tag1 before tag2');

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

  /// returns `true` if `a` can be shown, otherwise `false`
  static bool _shouldDisplay(Allenamento a) => !a.dismissed;

  bool get _hasItems {
    if (widget.tag1 == null) return trainingsTree.isNotEmpty;
    if (widget.tag2 == null)
      return trainingsTree[widget.tag1]?.isNotEmpty ?? false;
    if (!trainingsTree.containsKey(widget.tag1)) return false;
    return trainingsTree[widget.tag1][widget.tag2]?.isNotEmpty ?? false;
  }

  String get _title {
    if (widget.tag1 == null) return 'ALLENAMENTI';
    if (widget.tag2 == null) return 'ALLENAMENTI/${widget.tag1}';
    return 'ALLENAMENTI/${widget.tag1}/${widget.tag2}';
  }

  Iterable<Widget> get _children {
    if (widget.tag2 != null)
      return trainingsTree[widget.tag1][widget.tag2]
          .values
          .where(_shouldDisplay)
          .map((t) => _TrainingWidget(t));

    if (widget.tag1 != null)
      return trainingsTree[widget.tag1]
          .keys
          .map((t2) => _PathWidget(t2, widget.tag1));

    return trainingsTree.keys.map((t1) => _PathWidget(t1));
  }

  @override
  Widget build(BuildContext context) {
    final Widget _fab = FloatingActionButton(
      onPressed: () => Allenamento.create(widget.tag1, widget.tag2),
      child: Icon(Icons.add),
    );
    
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: !_hasItems ? _emptyMessage : ListView(children: _children.toList()),
      floatingActionButton: _fab,
    );
  }
}

class _PathWidget extends StatelessWidget {
  final String tag;
  final String path;

  _PathWidget(this.tag, [this.path]);

  @override
  Widget build(BuildContext context) {
    final String tag1 = path ?? tag;
    final String tag2 = path == null ? null : tag;
    final int trainingsCount = trainingsValues.where((t) =>
        (tag1 == null || tag1 == t.tag1) && (tag2 == null || tag2 == t.tag2)).length;
    return CustomListTile(
      title: Text(
        tag,
        style: TextStyle(fontWeight: FontWeight.normal),
      ),
      leading: LeadingInfoWidget(
        info: '$trainingsCount',
        bottom: singularPlural('allenament', 'o', 'i', trainingsCount),
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.arrow_forward_ios,
          size: 18,
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrainingRoute(
              path ?? tag,
              path == null ? null : tag,
            ),
          ),
        ),
      ),
    );
  }
}

/// class for displaying a `training` preview
class _TrainingWidget extends StatelessWidget {
  /// the `training` to display
  final Allenamento training;
  final Key _key;

  _TrainingWidget(this.training) : _key = ValueKey(training);

  @override
  Widget build(BuildContext context) {
    final String description = (training.descrizione?.isEmpty ?? true)
        ? 'nessuna descrizione'
        : training.descrizione;

    final List<Widget> children = <Widget>[
      Text(
        description,
        style: Theme.of(context)
            .textTheme
            .overline
            .copyWith(fontWeight: FontWeight.normal),
        textAlign: TextAlign.justify,
      ),
      const SizedBox(height: 10),
    ];

    TrainingDescription.fromTraining(context, training)
        .forEach((r) => children.add(r));

    return CustomDismissible(
      key: _key,
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
            child: Column(children: children),
          )
        ],
        leading: LeadingInfoWidget(
          info: training.countRipetute().toString(),
          bottom: singularPlural('ripetut', 'a', 'e', training.countRipetute()),
        ),
      ),
    );
  }
}
