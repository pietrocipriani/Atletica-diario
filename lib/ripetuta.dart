import 'package:Atletica/allenamento.dart';
import 'package:Atletica/database.dart';
import 'package:Atletica/duration_picker.dart';
import 'package:Atletica/recupero.dart';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:flutter/material.dart';
import 'package:mdi/mdi.dart';

List<Template> templates;

class Template {
  final int id;
  String name;
  Tipologia tipologia;
  double lastTarget;
  String get formattedTarget {
    if (lastTarget == null) return null;
    return '${tipologia.targetFormatter(lastTarget)} ${tipologia.targetSuffix ?? ''}';
  }

  Template(
      {@required this.id,
      @required this.name,
      @required this.tipologia,
      this.lastTarget});
  Template.from(Map<String, dynamic> raw) : this.id = raw['id'] {
    name = raw['name'];
    tipologia = Tipologia.values
        .firstWhere((tipologia) => tipologia.name == raw['tipologia']);
    lastTarget = raw['lastTarget'];
  }

  Map<String, dynamic> get asMap => {
        'name': name,
        'tipologia': tipologia.name,
        'lastTarget': lastTarget,
        'lastRecupero': null, // TODO
      };
}

class RegularExpressions {
  static final RegExp time = RegExp(
      "^\\s*(\\d+\\s*'\\s*)?([0-5]?[0-9]([.,]\\d\\d?)?\\s*\"\\s*)?\\s*\$");
  static final RegExp integer = RegExp(r'^\d+$');
  static final RegExp real = RegExp(r'^\d+(.\d+)?$');
}

Template getTemplate(String name) => templates.firstWhere(
      (template) => template?.name == name,
      orElse: () => null,
    );
bool hasTemplate(String name) => templates.any(
      (template) => template?.name == name,
    );

class Tipologia {
  final String name;
  final Widget Function({Color color}) icon;
  final Function(double value) targetFormatter;
  final RegExp targetValidator;
  final String targetScheme;
  final String targetSuffix;
  final double Function(String target) targetParser;

  Tipologia({
    @required this.name,
    @required this.icon,
    @required this.targetFormatter,
    @required this.targetValidator,
    @required this.targetScheme,
    @required this.targetParser,
    this.targetSuffix,
  });

  static List<Tipologia> values = [
    corsaDist,
    corsaTemp,
    palestra,
    esercizi,
  ];

  static final Tipologia corsaDist = Tipologia(
    name: 'corsa',
    icon: ({color = Colors.black}) => Icon(
      Icons.directions_run,
      color: color,
    ),
    targetFormatter: (target) => target == null
        ? ''
        : (target < 60 ? '' : "${target ~/ 60}'") +
            (target >= 60 && target - target.truncate() == 0
                ? (target % 60).toStringAsFixed(0).padLeft(2, '0')
                : (target % 60).toStringAsFixed(2).padLeft(5, '0')) +
            '"',
    targetValidator: RegularExpressions.time,
    targetScheme: "es: 1' 20\"",
    targetParser: (target) {
      target.replaceAll(',', '.');
      String match = RegExp(r"\d+\s*'").stringMatch(target) ?? "0'";
      int min = int.tryParse(match?.substring(0, match.length - 1)) ?? 0;
      match = RegExp(r'\d+(.\d+)?\s*"').stringMatch(target) ?? '0"';
      double sec = double.tryParse(match?.substring(0, match.length - 1)) ?? 0;
      return min * 60 + sec;
    },
  );
  static final Tipologia corsaTemp = Tipologia(
    name: 'corsa a tempo',
    icon: ({color = Colors.black}) => Stack(
      alignment: Alignment.center,
      overflow: Overflow.visible,
      children: <Widget>[
        Icon(
          Icons.directions_run,
          color: color,
        ),
        Positioned(
          right: -3,
          bottom: -3,
          child: Icon(
            Icons.timer,
            size: 10,
            color: color,
          ),
        ),
      ],
    ),
    targetFormatter: (target) => target?.round() ?? '',
    targetValidator: RegularExpressions.integer,
    targetScheme: 'es: 5000 m',
    targetSuffix: 'm',
    targetParser: (target) => double.parse(target),
  );
  static final Tipologia palestra = Tipologia(
    name: 'palestra',
    icon: ({color = Colors.black}) => Icon(
      Mdi.weightLifter,
      color: color,
    ),
    targetFormatter: (target) => target?.round() ?? '',
    targetValidator: RegularExpressions.integer,
    targetScheme: 'es: 40 kg',
    targetSuffix: 'kg',
    targetParser: (target) => double.parse(target),
  );
  static final Tipologia esercizi = Tipologia(
    name: 'esercizi',
    icon: ({color = Colors.black}) => Icon(Mdi.yoga, color: color),
    targetFormatter: (target) => target?.round() ?? '',
    targetValidator: RegularExpressions.integer,
    targetScheme: 'es: 20x',
    targetSuffix: 'x',
    targetParser: (target) => double.parse(target),
  );
}

class Ripetuta {
  final int id;
  final LayerLink link = LayerLink();

  Template template;

  /// `target` int secondi per `Tipologia.corsaDist`, in metri per `Tipologia.salto, Tipologia.lancio`, in metri per `Tipologia.corsaTemp`
  double target;

  int recupero, ripetizioni;
  Recupero nextRecupero;

  Ripetuta(
      {@required this.id,
      @required this.template,
      this.recupero = 3 * 60,
      this.nextRecupero,
      this.ripetizioni = 1,
      this.target});
  Ripetuta.parse(Map<String, dynamic> raw) : this.id = raw['id'] {
    template =
        templates.firstWhere((template) => template.id == raw['template']);
    target = raw['target'];
    recupero = raw['recupero'];
    ripetizioni = raw['times'];
    nextRecupero = Recupero(raw['recuperoNext']);
    allenamenti
        .firstWhere((allenamento) => allenamento.id == raw['allenamento'])
        .serie
        .firstWhere((serie) => serie.id == raw['serie'])
        .ripetute
        .add(this);
  }

  static Future<bool> fromDialog(
      {@required BuildContext context, @required Serie serie}) async {
    Template template;
    TextEditingController controller = TextEditingController();
    double target;
    return showDialog<bool>(
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
              AutoCompleteTextField<String>(
                itemSubmitted: (value) {
                  setState(() {
                    template = getTemplate(value);
                    target = template.lastTarget;
                  });
                },
                controller: controller,
                clearOnSubmit: false,
                key: GlobalKey(),
                textSubmitted: (value) async {
                  bool dist = RegExp(r'\d+\s*[mM][\s$]').hasMatch(value);
                  bool temp =
                      RegExp(r'\d+\s*(mins?)||(h(ours?)?)').hasMatch(value);
                  template = getTemplate(value) ??
                      Template(
                        id: await db.insert('Templates', {
                          'name': value,
                          'tipologia': (dist
                                  ? Tipologia.corsaDist
                                  : temp
                                      ? Tipologia.corsaTemp
                                      : Tipologia.esercizi)
                              ?.name,
                        }),
                        name: value,
                        tipologia: dist
                            ? Tipologia.corsaDist
                            : temp ? Tipologia.corsaTemp : null,
                      );
                  setState(() => target = template.lastTarget);
                },
                suggestions:
                    templates.map<String>((template) => template.name).toList(),
                itemBuilder: (context, suggestion) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: RichText(
                    text: TextSpan(
                      text: suggestion.substring(
                          0, suggestion.indexOf(controller.text)),
                      style: TextStyle(
                        color: Colors.black,
                      ),
                      children: [
                        TextSpan(
                          text: controller.text,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: suggestion.substring(
                              suggestion.indexOf(controller.text) +
                                  controller.text.length),
                        ),
                      ],
                    ),
                  ),
                ),
                itemSorter: (a, b) {
                  if (a.startsWith(controller.text) ==
                      b.startsWith(controller.text)) return a.compareTo(b);
                  if (a.startsWith(controller.text)) return -1;
                  return 1;
                },
                itemFilter: (suggestion, query) => suggestion.contains(query),
              ),
              if (template != null)
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
                            color: templates.contains(template)
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
                                    db.update(
                                      'Templates',
                                      {'tipologia': tipologia.name},
                                      where: 'id = ?',
                                      whereArgs: [template.name],
                                    );
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
                ),
              if (template != null)
                TextFormField(
                  controller:
                      TextEditingController(text: template.formattedTarget),
                  decoration: InputDecoration(
                    hintText: 'target',
                    suffixText: template.tipologia.targetSuffix,
                  ),
                  autovalidate: true,
                  validator: (value) {
                    //print ('match("$value"): ${template.tipologia.targetValidator.hasMatch(value)}');
                    if (template.tipologia.targetValidator.hasMatch(value))
                      return null;
                    return template.tipologia.targetScheme;
                  },
                  onChanged: (value) {
                    if (template.tipologia.targetValidator.hasMatch(value))
                      target = template.tipologia.targetParser(value);
                  },
                )
            ],
          ),
          actions: <Widget>[
            FlatButton(
              onPressed: () {
                if (template != null && !templates.contains(template))
                  db.delete('Templates',
                      where: 'id = ?', whereArgs: [template.id]);
                Navigator.pop(context, false);
              },
              child: Text('Annulla'),
            ),
            FlatButton(
              onPressed: () async {
                if (!templates.contains(template)) templates.add(template);
                template.lastTarget = target;
                db.update('Templates', {'lastTarget': target},
                    where: 'id = ?', whereArgs: [template.id]);

                serie.ripetute.add(Ripetuta(
                  id: await db.insert('Ripetute', {
                    'template': template.id,
                    'serie': serie.id,
                    'position': serie.ripetute.length,
                    'target': target,
                  }),
                  template: template,
                  nextRecupero: Recupero(3 * 60),
                  target: target,
                ));
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: Text('Conferma'),
            ),
          ],
        ),
      ),
    );
  }

  Widget widget(BuildContext context, void Function(void Function()) setState,
          {@required Serie serie}) =>
      Dismissible(
        key: ValueKey(this),
        direction: DismissDirection.startToEnd,
        onDismissed: (direction) {
          db.delete(
            'Ripetute',
            where: 'id = ?',
            whereArgs: [id],
          );
          setState(() {
            serie.ripetute.remove(this);
          });
        },
        background: Container(
            color: Theme.of(context).primaryColorLight,
            padding: const EdgeInsets.only(left: 16),
            alignment: Alignment.centerLeft,
            child: Icon(Icons.delete)),
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: ListTile(
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
                            ? Colors.grey[300]
                            : Theme.of(context).primaryColorDark,
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
                            ? Colors.grey[300]
                            : Theme.of(context).primaryColorDark,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    setState(() => ripetizioni = ripetizioni % 20 + 1);
                    db.update(
                      'Ripetute',
                      {'times': ripetizioni},
                      where: 'id = ?',
                      whereArgs: [id],
                    );
                  },
                  onLongPress: () {
                    db.update(
                      'Ripetute',
                      {'times': 1},
                      where: 'id = ?',
                      whereArgs: [id],
                    );
                    setState(() => ripetizioni = 1);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'x',
                        style: Theme.of(context).textTheme.overline,
                      ),
                      Text(
                        ripetizioni.toString(),
                        style: Theme.of(context).textTheme.headline5.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Color.lerp(
                                Theme.of(context).primaryColorDark,
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
            title: Text(template.name),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  template.tipologia.name,
                  style: Theme.of(context).textTheme.overline.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColorDark,
                      ),
                ),
                Text(
                  template.tipologia.targetFormatter(target),
                  style: Theme.of(context).textTheme.overline.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                )
              ],
            ),
            trailing: Stack(
              alignment: Alignment.bottomCenter,
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.timer),
                  onPressed: ripetizioni > 1
                      ? () async {
                          recupero = (await showDurationDialog(
                                      context, Duration(seconds: recupero)))
                                  ?.inSeconds ??
                              recupero;
                          setState(() {});
                        }
                      : null,
                  color: Colors.black,
                  disabledColor: Colors.grey[300],
                ),
                if (ripetizioni > 1)
                  Text(
                    '${recupero ~/ 60}:${(recupero % 60).toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.overline,
                  ),
              ],
            ),
          ),
        ),
      );
}
