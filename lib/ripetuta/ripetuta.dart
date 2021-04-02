import 'package:atletica/global_widgets/custom_dismissible.dart';
import 'package:atletica/global_widgets/custom_list_tile.dart';
import 'package:atletica/recupero/recupero_dialog.dart';
import 'package:atletica/ripetuta/template.dart';
import 'package:atletica/recupero/recupero.dart';
import 'package:atletica/training/serie.dart';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:flutter/material.dart';

class Ripetuta {
  final LayerLink link = LayerLink();

  String template;

  /// `target` int secondi per `Tipologia.corsaDist`, in metri per `Tipologia.salto, Tipologia.lancio`, in metri per `Tipologia.corsaTemp`
  double target;

  int ripetizioni;
  Recupero nextRecupero, recupero;

  Ripetuta(
      {@required this.template,
      this.target,
      this.ripetizioni = 1,
      this.nextRecupero,
      this.recupero}) {
    nextRecupero ??= Recupero();
    recupero ??= Recupero();
  }
  Ripetuta.parse(Map raw) {
    template = raw['template'];
    target = raw['target']?.toDouble();
    recupero = Recupero(raw['recupero']);
    ripetizioni = raw['times'];
    nextRecupero = Recupero(raw['recuperoNext']);
  }

  Map<String, dynamic> get asMap => {
        'template': template,
        'target': target,
        'recupero': recupero.recupero,
        'times': ripetizioni,
        'recuperoNext': nextRecupero.recupero
      };

  static Future<Ripetuta> fromDialog({@required BuildContext context}) async {
    SimpleTemplate template;
    TextEditingController controller = TextEditingController();
    double target;
    return showDialog<Ripetuta>(
      barrierDismissible: false,
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          scrollable: true,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('RIPETUTA'),
          content: Column(
            children: <Widget>[
              AutoCompleteTextField<Template>(
                itemSubmitted: (value) {
                  setState(() {
                    template = value;
                    target = template.lastTarget;
                  });
                },
                controller: controller,
                clearOnSubmit: false,
                key: GlobalKey(),
                textSubmitted: (value) {
                  /*bool dist = RegExp(r'\d+\s*[mM][\s$]').hasMatch(value);
                  bool temp =
                      RegExp(r'\d+\s*(mins?)||(h(ours?)?)').hasMatch(value);*/

                  template = templates[value] ??
                      SimpleTemplate(
                        name: value,
                        tipologia: Tipologia.corsaDist,
                      );
                  setState(() => target = template.lastTarget);
                },
                suggestions: templates.values
                    .where((template) => template != null)
                    .toList(),
                itemBuilder: (context, suggestion) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: RichText(
                    text: TextSpan(
                      text: suggestion.name.substring(
                          0, suggestion.name.indexOf(controller.text)),
                      style: Theme.of(context).textTheme.subtitle2,
                      children: [
                        TextSpan(
                          text: controller.text,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: suggestion.name.substring(
                              suggestion.name.indexOf(controller.text) +
                                  controller.text.length),
                        ),
                      ],
                    ),
                  ),
                ),
                itemSorter: (a, b) {
                  if (a.name.startsWith(controller.text) ==
                      b.name.startsWith(controller.text))
                    return a.name.compareTo(b.name);
                  if (a.name.startsWith(controller.text)) return -1;
                  return 1;
                },
                itemFilter: (suggestion, query) =>
                    suggestion.name.contains(query),
              ),
              /*if (template != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Stack(
                    overflow: Overflow.visible,
                    children: <Widget>[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: templates.containsValue(template)
                                ? Colors.red
                                : Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: Tipologia.values
                              .map(
                                (tipologia) => GestureDetector(
                                  onTap: () => setState(() {
                                    template.tipologia = tipologia;
                                  }),
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 500),
                                    width: 42,
                                    height: 42,
                                    margin: const EdgeInsets.all(4.0),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        if (template.tipologia == tipologia)
                                          BoxShadow(
                                            blurRadius: 8,
                                            spreadRadius: -3,
                                            offset: Offset(2, 2),
                                          ),
                                      ],
                                      shape: BoxShape.circle,
                                      color: template.tipologia == tipologia
                                          ? Theme.of(context).primaryColorDark
                                          : Theme.of(context).primaryColorLight,
                                    ),
                                    child: tipologia.icon(
                                      color: template.tipologia == tipologia
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        top: -Theme.of(context).textTheme.overline.fontSize / 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            color: Theme.of(context).dialogBackgroundColor,
                            child: Text(
                              templates.contains(template)
                                  ? 'modifica tutti i ${template.name}'
                                  : 'definisci ${template.name}',
                              style:
                                  Theme.of(context).textTheme.overline.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: templates.contains(template)
                                            ? Colors.red
                                            : Theme.of(context).accentColor,
                                      ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),*/
              if (template != null)
                TextFormField(
                  controller:
                      TextEditingController(text: template.formattedTarget),
                  decoration: InputDecoration(
                    hintText: 'target',
                    suffixText: template.tipologia.targetSuffix,
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    if (template.tipologia.targetValidator(value)) return null;
                    return template.tipologia.targetScheme;
                  },
                  onChanged: (value) {
                    if (template.tipologia.targetValidator(value))
                      target = template.tipologia.targetParser(value);
                  },
                )
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context, null);
              },
              child: Text('Annulla'),
            ),
            TextButton(
              onPressed: template == null
                  ? null
                  : () async {
                      template.lastTarget = target ?? template.lastTarget;
                      await template.create();

                      final Ripetuta ripetuta = Ripetuta(
                        template: template.name,
                        target: target,
                      );

                      Navigator.pop(context, ripetuta);
                    },
              child: Text('Conferma'),
            ),
          ],
        ),
      ),
    );
  }

  Widget widget(
    BuildContext context,
    void Function(void Function()) setState, {
    @required Serie serie,
  }) {
    final ThemeData theme = Theme.of(context);
    return CustomDismissible(
      key: ValueKey(this),
      direction: DismissDirection.startToEnd,
      onDismissed: (direction) => setState(() => serie.ripetute.remove(this)),
      child: Container(
        color: theme.scaffoldBackgroundColor,
        child: CustomListTile(
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  InkWell(
                    onTap: this == serie.ripetute.first
                        ? null
                        : () {
                            int index = serie.ripetute.indexOf(this);
                            serie.ripetute.insert(
                                index - 1, serie.ripetute.removeAt(index));
                            setState(() {});
                          },
                    child: Icon(
                      Icons.expand_less,
                      color: this == serie.ripetute.first
                          ? theme.disabledColor
                          : theme.primaryColorDark,
                    ),
                  ),
                  InkWell(
                    onTap: this == serie.ripetute.last
                        ? null
                        : () {
                            int index = serie.ripetute.indexOf(this);
                            serie.ripetute.insert(
                                index + 1, serie.ripetute.removeAt(index));
                            setState(() {});
                          },
                    child: Icon(
                      Icons.expand_more,
                      color: this == serie.ripetute.last
                          ? theme.disabledColor
                          : theme.primaryColorDark,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => setState(() => ripetizioni = ripetizioni % 20 + 1),
                onLongPress: () => setState(() => ripetizioni = 1),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text('x', style: theme.textTheme.overline),
                    Text(
                      ripetizioni.toString(),
                      style: theme.textTheme.headline5.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Color.lerp(
                          theme.primaryColorDark,
                          Colors.redAccent[700],
                          ripetizioni / 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          title: Text(template),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              if (templates[template] != null)
                Text(
                  templates[template].tipologia.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColorDark,
                  ),
                ),
              if (templates[template] != null)
                Text(templates[template].tipologia.targetFormatter(target))
            ],
          ),
          trailing: Stack(
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.timer),
                onPressed: ripetizioni > 1
                    ? () async {
                        await showRecoverDialog(context, recupero);
                        setState(() {});
                      }
                    : null,
                color: theme.iconTheme.color,
                disabledColor: theme.disabledColor,
              ),
              if (ripetizioni > 1)
                Text(
                  recupero.toString(),
                  style: theme.textTheme.overline,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
