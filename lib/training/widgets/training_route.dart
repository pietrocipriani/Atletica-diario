import 'package:atletica/global_widgets/custom_dismissible.dart';
import 'package:atletica/global_widgets/custom_expansion_tile.dart';
import 'package:atletica/global_widgets/custom_list_tile.dart';
import 'package:atletica/global_widgets/delete_confirm_dialog.dart';
import 'package:atletica/global_widgets/leading_info_widget.dart';
import 'package:atletica/main.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/persistence/user_helper/coach_helper.dart';
import 'package:atletica/refactoring/utils/pair.dart';
import 'package:atletica/training/training.dart';
import 'package:atletica/training/training_description.dart';
import 'package:atletica/training/widgets/training_dialog.dart';
import 'package:atletica/training/widgets/training_info_route.dart';
import 'package:flutter/material.dart';

class TrainingRoute extends StatefulWidget {
  @override
  _TrainingRouteState createState() => _TrainingRouteState();
}

class _TrainingRouteState extends State<TrainingRoute> {
  final PageController _controller = PageController();
  String? tag1, tag2;

  /// the `callback` triggered when modifies occours
  late final Callback callback = Callback((_, c) => setState(() {}));

  /// sign `callback` into [CoachHelper.onTrainingCallbacks] to listen on snapshots
  @override
  void initState() {
    Training.signInGlobal(callback);
    super.initState();
  }

  /// remove `callback` from [CoachHelper.onTrainingCallbacks]
  @override
  void dispose() {
    Training.signOutGlobal(callback.stopListening);
    super.dispose();
  }

  static const Duration kAnimDuration = const Duration(milliseconds: 500);

  @override
  Widget build(BuildContext context) {
    final Widget _fab = FloatingActionButton(
      onPressed: () async {
        final TagPair? tags = await showDialog<TagPair>(
          context: context,
          builder: (context) => TrainingDialog(tag1: tag1, tag2: tag2),
        );
        if (tags != null) {
          tag1 = tags.value1;
          tag2 = tags.value2;
          setState(() {});
          _controller.animateToPage(
            2,
            curve: Curves.fastOutSlowIn,
            duration: kAnimDuration,
          );
        }
      },
      child: Icon(Icons.add),
      mini: true,
    );

    return Scaffold(
      appBar: AppBar(title: Text('ALLENAMENTI')),
      body: PageView(
        children: [
          TrainingRouteFolder(
            onSelected: (t) {
              setState(() => tag1 = t);
              _controller.animateToPage(
                1,
                curve: Curves.fastOutSlowIn,
                duration: kAnimDuration,
              );
            },
          ),
          if (tag1 != null)
            TrainingRouteFolder(
              tag1: tag1,
              onBack: () => _controller.previousPage(
                curve: Curves.fastOutSlowIn,
                duration: kAnimDuration,
              ),
              onSelected: (t) {
                setState(() => tag2 = t);
                _controller.animateToPage(
                  2,
                  curve: Curves.fastOutSlowIn,
                  duration: kAnimDuration,
                );
              },
            ),
          if (tag2 != null)
            TrainingRouteFolder(
              tag1: tag1,
              tag2: tag2,
              onBack: () => _controller.previousPage(
                curve: Curves.fastOutSlowIn,
                duration: kAnimDuration,
              ),
            ),
        ],
        controller: _controller,
      ),
      floatingActionButton: _fab,
    );
  }
}

/// [Route] which displays the list of existing [Training] (coach)
class TrainingRouteFolder extends StatefulWidget {
  final String? tag1, tag2;
  final void Function(String t)? onSelected;
  final String? selected;
  final void Function()? onBack;
  TrainingRouteFolder({
    this.tag1,
    this.tag2,
    this.onSelected,
    this.selected,
    this.onBack,
  }) : assert(!(tag2 != null && tag1 == null), 'must set tag1 before tag2');

  @override
  _TrainingRouteFolderState createState() => _TrainingRouteFolderState();
}

/// [State] for [TrainingRoute]
class _TrainingRouteFolderState extends State<TrainingRouteFolder> {
  static const Widget _emptyMessage = Center(child: Text('non hai creato ancora nessun allenamento'));

  bool get _hasItems => Training.hasItems(widget.tag1, widget.tag2);

  Iterable<Widget> get _children {
    if (widget.tag1 == null)
      return Training.fromPath().map(
        (e) => _PathWidget(
          tag: e,
          selected: e == widget.selected,
          onTap: widget.onSelected == null ? null : () => widget.onSelected!(e),
        ),
      );
    if (widget.tag2 == null)
      return Training.fromPath(widget.tag1).map(
        (e) => _PathWidget(
          tag: e,
          selected: e == widget.selected,
          path: widget.tag1!,
          onTap: widget.onSelected == null ? null : () => widget.onSelected!(e),
        ),
      );
    return Training.fromPath(widget.tag1, widget.tag2).map((e) => _TrainingWidget(e));
  }

  String get _path {
    if (widget.tag1 == null) return '/';
    if (widget.tag2 == null) return '/${widget.tag1}/';
    return '/${widget.tag1}/${widget.tag2}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasItems) return _emptyMessage;
    final Row path = Row(
      children: [
        if (widget.onBack != null)
          IconButton(
            icon: Icon(Icons.arrow_back_ios, size: 12),
            onPressed: widget.onBack,
          ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            child: Text(
              _path,
              style: Theme.of(context).textTheme.overline!.copyWith(fontWeight: FontWeight.normal),
              maxLines: 1,
              textAlign: TextAlign.end,
            ),
          ),
        ),
      ],
    );
    return Column(
      children: [
        path,
        Expanded(child: ListView(children: _children.toList())),
      ],
    );
  }
}

class _PathWidget extends StatelessWidget {
  final String tag1;
  final String? tag2;
  final int trainingsCount;
  final bool selected;
  final void Function()? onTap;

  _PathWidget({
    required final String tag,
    final String? path,
    this.onTap,
    this.selected = false,
  })  : tag1 = path ?? tag,
        tag2 = path == null ? null : tag,
        trainingsCount = Training.trainingsCount(
          path ?? tag,
          path == null ? null : tag,
        );

  @override
  Widget build(BuildContext context) {
    return CustomListTile(
      tileColor: selected ? Theme.of(context).bottomAppBarColor : null,
      title: Text(
        tag2 ?? tag1,
        style: TextStyle(fontWeight: FontWeight.normal),
      ),
      leading: LeadingInfoWidget(
        info: '$trainingsCount',
        bottom: singularPlural('allenament', 'o', 'i', trainingsCount),
      ),
      onTap: onTap,
    );
  }
}

/// class for displaying a `training` preview
class _TrainingWidget extends StatefulWidget {
  final Key _key;
  final Training training;
  _TrainingWidget(this.training) : _key = ValueKey(training);

  @override
  _TrainingWidgetState createState() => _TrainingWidgetState();
}

class _TrainingWidgetState extends State<_TrainingWidget> {
  /// the `training` to display
  int variant = 0;
  late final Callback<Training> _callback = Callback((t, c) => setState(() {}));

  @override
  void initState() {
    widget.training.signIn(_callback);
    super.initState();
  }

  @override
  void dispose() {
    widget.training.signOut(_callback.stopListening);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String description = widget.training.descrizione.isEmpty ? 'nessuna descrizione' : widget.training.descrizione;

    final List<Widget> children = <Widget>[
      Align(
        alignment: Alignment.center,
        child: Text(
          description,
          style: Theme.of(context).textTheme.overline!.copyWith(fontWeight: FontWeight.normal),
          textAlign: TextAlign.justify,
        ),
      ),
      const SizedBox(height: 10),
    ];

    children.addAll(TrainingDescription.fromTraining(widget.training));

    return CustomDismissible(
        key: widget._key,
        onDismissed: (direction) => widget.training.delete(),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd)
            return await showDeleteConfirmDialog(
              context: context,
              name: widget.training.name,
            );
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TrainingInfoRoute(allenamento: widget.training),
            ),
          );
          widget.training.save();
          return false;
        },
        child: CustomExpansionTile(
          title: widget.training.name,
          childrenPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
          children: children,
          leading: LeadingInfoWidget(
            info: widget.training.ripetuteCount.toString(),
            bottom: singularPlural('ripetut', 'a', 'e', widget.training.ripetuteCount),
          ),
          trailing: IconButton(
            icon: Icon(Icons.copy),
            onPressed: () => widget.training.save(true),
            color: IconTheme.of(context).color,
          ),
        )
        /*GestureDetector(
          onTap: () => setState(
              () => variant = (variant + 1) % widget.training.variants.length),
          onLongPress: () => setState(() => variant = 0),
          child: LeadingInfoWidget(
            info: '${variant + 1}',
            bottom: 'variante',
          ),
        ),*/

        );
  }
}
