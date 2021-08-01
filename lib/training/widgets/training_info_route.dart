import 'package:atletica/global_widgets/custom_dismissible.dart';
import 'package:atletica/global_widgets/custom_expansion_tile.dart';
import 'package:atletica/global_widgets/delete_confirm_dialog.dart';
import 'package:atletica/global_widgets/resizable_text_field.dart';
import 'package:atletica/recupero/recupero_dialog.dart';
import 'package:atletica/recupero/recupero_widget.dart';
import 'package:atletica/ripetuta/ripetuta.dart';
import 'package:atletica/training/training.dart';
import 'package:atletica/training/serie.dart';
import 'package:atletica/training/variant.dart';
import 'package:atletica/training/widgets/tags_selector_widget.dart';
import 'package:flutter/material.dart';

class TrainingInfoRoute extends StatefulWidget {
  final Training allenamento;
  TrainingInfoRoute({required this.allenamento});
  @override
  _TrainingInfoRouteState createState() => _TrainingInfoRouteState();
}

class _TrainingInfoRouteState extends State<TrainingInfoRoute> {
  bool editTitle = false;
  bool collapsedDescription = true;
  late TextEditingController _titleController =
      TextEditingController(text: widget.allenamento.name);
  Variant? active;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: editTitle
            ? TextFormField(
                style: theme.textTheme.headline6!
                    .copyWith(color: theme.colorScheme.onPrimary),
                controller: _titleController,
              )
            : Text(widget.allenamento.name),
        actions: <Widget>[
          if (editTitle)
            IconButton(
                icon: Icon(Icons.cancel),
                onPressed: () => setState(() {
                      editTitle = !editTitle;
                      _titleController.text = widget.allenamento.name;
                    })),
          IconButton(
            icon: Icon(editTitle ? Icons.check : Icons.edit),
            onPressed: () => setState(() {
              editTitle = !editTitle;
              widget.allenamento.name = _titleController.text;
            }),
          ),
        ],
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          TagsSelectorWidget(widget.allenamento),
          ResizableTextField(
            onChanged: (text) => widget.allenamento.descrizione = text,
            initialText: widget.allenamento.descrizione,
            hint: 'inserisci la descrizione (opzionale)',
          ),
          /*VariantSelectionWidget(
            variants: widget.allenamento.variants,
            active: active,
            onVariantChanged: (v) => setState(() => active = v),
          ),*/
          Expanded(
            child: SingleChildScrollView(
              child: Stack(
                children: () sync* {
                  yield Column(
                    children: () sync* {
                      for (Serie serie in widget.allenamento.serie) {
                        yield CustomDismissible(
                          key: ValueKey(serie),
                          direction: DismissDirection.startToEnd,
                          confirmDismiss: (d) => showDeleteConfirmDialog(
                            context: context,
                            name:
                                'serie #${widget.allenamento.serie.indexOf(serie) + 1}',
                          ),
                          onDismissed: (direction) => setState(
                              () => widget.allenamento.serie.remove(serie)),
                          child: CustomExpansionTile(
                            children: [
                              if (serie.ripetute.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.only(
                                      top: 4, bottom: 20, right: 4, left: 4),
                                  color: theme.primaryColor,
                                  child: Stack(
                                    children: () sync* {
                                      yield Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: () sync* {
                                            for (Ripetuta rip
                                                in serie.ripetute) {
                                              yield rip.widget(
                                                  context, setState,
                                                  serie: serie,
                                                  active: active ??
                                                      widget.allenamento
                                                          .variants.first);
                                              if (rip != serie.ripetute.last)
                                                yield CompositedTransformTarget(
                                                  link: rip.link,
                                                  child: Container(
                                                    width: double.infinity,
                                                    height: 0,
                                                  ),
                                                );
                                            }
                                          }()
                                              .toList());
                                      for (Ripetuta rip in serie.ripetute.where(
                                          (rip) =>
                                              rip != serie.ripetute.last &&
                                              rip.nextRecupero != null))
                                        yield CompositedTransformFollower(
                                          showWhenUnlinked: false,
                                          link: rip.link,
                                          child: RecuperoWidget(
                                              recupero: rip.nextRecupero),
                                          offset: const Offset(0, -16),
                                        );
                                    }()
                                        .toList(),
                                  ),
                                )
                            ],
                            title:
                                'serie #${widget.allenamento.serie.indexOf(serie) + 1}',
                            subtitle: Text(
                              '${serie.ripetuteCount} ripetut${serie.ripetuteCount == 1 ? 'a' : 'e'}',
                              style: TextStyle(color: theme.primaryColorDark),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: <Widget>[
                                    IconButton(
                                      icon: Icon(
                                        serie.ripetizioni > 1
                                            ? Icons.timer
                                            : Icons.timer_off,
                                      ),
                                      onPressed: serie.ripetizioni > 1
                                          ? () async {
                                              await showRecoverDialog(
                                                  context, serie.recupero);
                                              setState(() {});
                                            }
                                          : null,
                                      disabledColor: theme.disabledColor,
                                      color: theme.iconTheme.color,
                                    ),
                                    if (serie.ripetizioni > 1)
                                      Text(
                                        serie.recupero.toString(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .overline,
                                      )
                                  ],
                                ),
                                IconButton(
                                  icon: Icon(Icons.add_circle),
                                  onPressed: () async {
                                    final Pair<Ripetuta, double>? rip =
                                        await Ripetuta.fromDialog(
                                            context: context);
                                    if (rip == null) return;
                                    setState(() {
                                      serie.ripetute.add(rip.v1);
                                      widget.allenamento.variants.forEach(
                                          (v) => v.targets[rip.v1] = rip.v2);
                                    });
                                  },
                                  color: theme.iconTheme.color,
                                ),
                              ],
                            ),
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    InkWell(
                                      onTap: serie ==
                                              widget.allenamento.serie.first
                                          ? null
                                          : () {
                                              int index = widget
                                                  .allenamento.serie
                                                  .indexOf(serie);
                                              widget.allenamento.serie.insert(
                                                index - 1,
                                                widget.allenamento.serie
                                                    .removeAt(index),
                                              );
                                              setState(() {});
                                            },
                                      child: Icon(
                                        Icons.expand_less,
                                        color: serie ==
                                                widget.allenamento.serie.first
                                            ? theme.disabledColor
                                            : theme.primaryColorDark,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: serie ==
                                              widget.allenamento.serie.last
                                          ? null
                                          : () {
                                              int index = widget
                                                  .allenamento.serie
                                                  .indexOf(serie);
                                              widget.allenamento.serie.insert(
                                                index + 1,
                                                widget.allenamento.serie
                                                    .removeAt(index),
                                              );
                                              setState(() {});
                                            },
                                      child: Icon(
                                        Icons.expand_more,
                                        color: serie ==
                                                widget.allenamento.serie.last
                                            ? theme.disabledColor
                                            : theme.primaryColorDark,
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() => serie.ripetizioni =
                                        serie.ripetizioni % 10 + 1);
                                  },
                                  onLongPress: () {
                                    setState(() => serie.ripetizioni = 1);
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        'x',
                                        style: Theme.of(context)
                                            .textTheme
                                            .overline,
                                      ),
                                      Text(
                                        serie.ripetizioni.toString(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline5!
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Color.lerp(
                                                Theme.of(context)
                                                    .primaryColorDark,
                                                Colors.redAccent[700],
                                                serie.ripetizioni / 10,
                                              ),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                        if (serie != widget.allenamento.serie.last)
                          yield CompositedTransformTarget(
                            link: serie.link,
                            child: Container(
                              height: 0,
                              width: double.infinity,
                            ),
                          );
                      }
                    }()
                        .toList(),
                  );
                  for (Serie serie in widget.allenamento.serie
                      .where((serie) => serie != widget.allenamento.serie.last))
                    yield CompositedTransformFollower(
                      link: serie.link,
                      showWhenUnlinked: false,
                      child: RecuperoWidget(recupero: serie.nextRecupero),
                      offset: const Offset(0, -16),
                    );
                }()
                    .toList(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => widget.allenamento.serie.add(Serie())),
        child: Icon(Icons.add),
      ),
    );
  }
}
