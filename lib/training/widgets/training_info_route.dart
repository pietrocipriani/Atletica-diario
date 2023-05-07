import 'package:atletica/global_widgets/custom_dismissible.dart';
import 'package:atletica/global_widgets/custom_expansion_tile.dart';
import 'package:atletica/global_widgets/custom_list_tile.dart';
import 'package:atletica/global_widgets/delete_confirm_dialog.dart';
import 'package:atletica/global_widgets/resizable_text_field.dart';
import 'package:atletica/global_widgets/times_widget.dart';
import 'package:atletica/recupero/recupero.dart';
import 'package:atletica/recupero/recupero_dialog.dart';
import 'package:atletica/recupero/recupero_widget.dart';
import 'package:atletica/refactoring/coach/src/control/ripetuta/ripetuta_dialog.dart';
import 'package:atletica/refactoring/common/common.dart';
import 'package:atletica/refactoring/utils/singular_plural.dart';
import 'package:atletica/ripetuta/ripetuta.dart';
import 'package:atletica/ripetuta/template.dart';
import 'package:atletica/training/training.dart';
import 'package:atletica/training/serie.dart';
import 'package:atletica/training/widgets/tags_selector_widget.dart';
import 'package:flutter/material.dart';

/// Route for a single training configuration
class TrainingInfoRoute extends StatefulWidget {
  /// The `Training` to display
  final Training allenamento;
  TrainingInfoRoute({required this.allenamento});
  @override
  _TrainingInfoRouteState createState() => _TrainingInfoRouteState();
}

/// Class for putting the overlay RecuperoWidget in the correct position
class _RecuperoWidgetFollower extends StatelessWidget {
  /// The `Recupero` to display
  final Recupero rec;

  /// The `LayerLink` for position
  final LayerLink link;
  _RecuperoWidgetFollower({required this.rec, required this.link});

  @override
  Widget build(BuildContext context) => CompositedTransformFollower(
        link: link,
        showWhenUnlinked: false,
        child: RecuperoWidget(recupero: rec),
        followerAnchor: Alignment.centerLeft,
      );
}

class _TrainingInfoRouteState extends State<TrainingInfoRoute> {
  bool editTitle = false;
  bool collapsedDescription = true;
  late TextEditingController _titleController =
      TextEditingController(text: widget.allenamento.name);

  List<Serie> get serie => widget.allenamento.serie;

  // TODO: riorganizzare i widget
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Widget title = editTitle
        ? TextFormField(
            style: theme.textTheme.titleLarge,
            controller: _titleController,
          )
        : Text(widget.allenamento.name);

    final List<Widget> actions = [
      if (editTitle)
        IconButton(
          icon: Icon(Icons.lightbulb_outline),
          onPressed: () =>
              _titleController.text = widget.allenamento.suggestName,
          tooltip: "Suggerisci il nome in base agli esercizi.",
        ),
      if (editTitle)
        IconButton(
          icon: Icon(Icons.cancel),
          onPressed: () => setState(() {
            editTitle = !editTitle;
            _titleController.text = widget.allenamento.name;
          }),
          tooltip: "Annulla le modifiche.",
        ),
      IconButton(
          icon: Icon(editTitle ? Icons.check : Icons.edit),
          onPressed: () => setState(() {
                editTitle = !editTitle;
                widget.allenamento.name = _titleController.text;
              }),
          tooltip: "Salva le modifiche."),
    ];

    final FloatingActionButton fab = FloatingActionButton(
      onPressed: () {
        serie.add(Serie());
        setState(() {});
      },
      child: Icon(Icons.add),
      mini: true,
      tooltip: "Aggiungi una serie.",
    );

    final List<Widget> children = serie
        .expand((serie) => [
              _SerieWidget(
                serie: serie,
                training: widget.allenamento,
                onCallback: () => setState(() {}),
                onDismissed: () {
                  this.serie.remove(serie);
                  setState(() {});
                },
                //follower: serie.link,
              ),
              CompositedTransformTarget(
                link: serie.link,
                key: ValueKey(serie.link),
                child: Container(),
              ),
            ])
        .toList();

    return Scaffold(
      appBar: AppBar(title: title, actions: actions),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          TagsSelectorWidget(training: widget.allenamento),
          ResizableTextField(
            onChanged: (text) => widget.allenamento.descrizione = text,
            initialText: widget.allenamento.descrizione,
            hint: 'inserisci la descrizione (opzionale)',
          ),
          /*if (userC.showVariants)
            VariantSelectionWidget(
              variants: widget.allenamento.variants,
              onVariantChanged: (v) => setState(() => active = v),
            ),*/
          Expanded(
            child: Stack(
              children: <Widget>[
                ReorderableListView(
                  onReorder: (oldI, newI) => setState(() {
                    if (newI > oldI) newI--;
                    oldI ~/= 2;
                    newI ~/= 2;
                    serie.insert(newI, serie.removeAt(oldI));
                  }),
                  children: children,
                ),
                for (Serie s in this.serie.where((s) => s != this.serie.last))
                  _RecuperoWidgetFollower(link: s.link, rec: s.nextRecupero)
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: fab,
    );
  }
}

class _SerieWidget extends StatefulWidget {
  final Serie serie;
  final Training training;
  final void Function()? onDismissed;
  final void Function()? onCallback;
  final String name;
  final LayerLink? follower;

  _SerieWidget({
    required this.training,
    required this.serie,
    this.onDismissed,
    this.onCallback,
    this.follower,
  })  : name = 'serie #${training.serie.indexOf(serie) + 1}',
        super(key: ValueKey(serie));

  @override
  State<StatefulWidget> createState() => _SerieWidgetState();
}

class _SerieWidgetState extends State<_SerieWidget> {
  List<Ripetuta> get ripetute => widget.serie.ripetute;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final Widget subtitle = Text(
      singPlurIT(
        '${widget.serie.ripetuteCount} ripetuta',
        widget.serie.ripetuteCount,
      ),
      style: TextStyle(color: theme.primaryColorDark),
    );

    return CustomDismissible(
      key: ValueKey(widget.serie),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (d) => showDeleteConfirmDialog(
        context: context,
        name: widget.name,
      ),
      onDismissed: (direction) => widget.onDismissed?.call(),
      child: CustomExpansionTile(
        children: [
          Stack(
            children: [
              ReorderableListView(
                  shrinkWrap: true,
                  onReorder: (oldI, newI) => setState(() {
                        if (newI > oldI) newI--;
                        oldI ~/= 2;
                        newI ~/= 2;
                        ripetute.insert(newI, ripetute.removeAt(oldI));
                      }),
                  children: widget.serie.ripetute
                      .expand((rip) => [
                            _RipetutaWidget(
                              rip: rip,
                              serie: widget.serie,
                              onChanged: () => setState(() {}),
                              onDismissed: () => setState(() {}),
                            ),
                            if (rip != widget.serie.ripetute.last)
                              CompositedTransformTarget(
                                key: ValueKey(rip.link),
                                link: rip.link,
                                child: Container(
                                  width: double.infinity,
                                  height: 0,
                                ),
                              ),
                          ])
                      .toList()),
              for (Ripetuta rip in widget.serie.ripetute)
                _RecuperoWidgetFollower(link: rip.link, rec: rip.nextRecupero),
            ],
          )
        ],
        follower: widget.follower,
        title: widget.name,
        subtitle: subtitle,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _RecuperoButton(
              enabled: widget.serie.ripetizioni > 1,
              rec: widget.serie.recupero,
              onChanged: () => setState(() {}),
            ),
            IconButton(
              icon: Icon(Icons.add_circle),
              onPressed: () async {
                final Ripetuta? rip = await createRipetuta(context);
                if (rip == null) return;
                setState(() => widget.serie.ripetute.add(rip));
              },
              color: theme.iconTheme.color,
            ),
          ],
        ),
        leading: TimesWidget(
          onChanged: (c) => setState(() => widget.serie.ripetizioni = c),
          max: 10,
          value: widget.serie.ripetizioni,
        ),
      ),
    );
  }
}

class _RipetutaWidget extends StatefulWidget {
  final Ripetuta rip;
  final Serie serie;
  final void Function()? onChanged;
  final void Function() onDismissed;

  _RipetutaWidget({
    required this.rip,
    required this.serie,
    this.onChanged,
    required this.onDismissed,
  }) : super(key: ValueKey(rip));

  @override
  _RipetutaWidgetState createState() => _RipetutaWidgetState();
}

// TODO: use observables
class _RipetutaWidgetState extends State<_RipetutaWidget> {
  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return CustomDismissible(
      key: ValueKey(widget.rip),
      direction: DismissDirection.horizontal,
      onDismissed: (direction) async {
        widget.serie.ripetute.remove(widget.rip);
        widget.onDismissed();
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) return true;
        final Ripetuta? rip = await editRipetuta(context, widget.rip);
        if (rip == null) return false;
        assert(rip == widget.rip);
        return false;
      },
      child: Container(
        //color: theme.scaffoldBackgroundColor,
        child: CustomListTile(
          leading: TimesWidget(
            onChanged: (c) {
              setState(() => widget.rip.ripetizioni = c);
              widget.onChanged?.call();
            },
            max: 20,
            value: widget.rip.ripetizioni,
          ),
          title: Text(widget.rip.template),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              if (widget.rip.hasConcreteTemplate)
                Text(
                  templates[widget.rip.template]!.tipologia.name,
                  style: TextStyle(
                    inherit: true,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColorDark,
                  ),
                ),
              if (widget.rip.hasConcreteTemplate)
                TargetView(
                  target: widget.rip.target,
                  tipologia: widget.rip.resolveTemplate.tipologia,
                )
            ],
          ),
          trailing: _RecuperoButton(
            rec: widget.rip.recupero,
            enabled: widget.rip.ripetizioni > 1,
            onChanged: () => setState(() {}),
          ),
        ),
      ),
    );
  }
}

class _RecuperoButton extends StatelessWidget {
  final void Function()? onChanged;
  final bool enabled;
  final Recupero rec;
  _RecuperoButton({this.onChanged, this.enabled = true, required this.rec});

  @override
  Widget build(BuildContext context) {
    final IconButton btn = IconButton(
      icon: Icon(enabled ? Icons.timer : Icons.timer_off),
      onPressed: enabled
          ? () async {
              await showRecoverDialog(context, rec);
              onChanged?.call();
            }
          : null,
      disabledColor: Theme.of(context).disabledColor,
      color: Theme.of(context).iconTheme.color,
    );
    if (!enabled) return btn;
    return Stack(
      alignment: Alignment.bottomCenter,
      children: <Widget>[
        btn,
        Text(
          rec.toString(),
          style: Theme.of(context).textTheme.labelSmall,
        )
      ],
    );
  }
}
