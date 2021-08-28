import 'package:atletica/global_widgets/auto_complete_text_view.dart';
import 'package:atletica/ripetuta/template.dart';
import 'package:atletica/recupero/recupero.dart';
import 'package:atletica/training/serie.dart';
import 'package:flutter/material.dart';

class Pair<T, S> {
  final T v1;
  final S v2;
  Pair(this.v1, this.v2);
}

class Ripetuta {
  final LayerLink link = LayerLink();

  String template;

  /// `target` in secondi per `Tipologia.corsaDist`, in metri per `Tipologia.salto, Tipologia.lancio`, in metri per `Tipologia.corsaTemp`
  double? target;

  int ripetizioni;
  Recupero nextRecupero, recupero;

  Ripetuta({
    required this.template,
    this.ripetizioni = 1,
    final Recupero? nextRecupero,
    final Recupero? recupero,
  })  : nextRecupero = nextRecupero ?? Recupero(),
        recupero = recupero ?? Recupero();

  Ripetuta.parse(final Serie serie, final Map raw)
      : template = raw['template'],
        target = raw['target']?.toDouble(),
        recupero = Recupero(recupero: raw['recupero']),
        ripetizioni = raw['times'],
        nextRecupero = Recupero(recupero: raw['recuperoNext']) {
    serie.ripetute.add(this);
  }

  Map<String, dynamic> get asMap => {
        'template': template,
        'recupero': recupero.recupero,
        'times': ripetizioni,
        'recuperoNext': nextRecupero.recupero
      };

  Iterable<Recupero> get recuperi sync* {
    for (int i = 0; i < ripetizioni - 1; i++) yield recupero;
  }

  static Future<Pair<Ripetuta, double?>?> fromDialog(
      {required BuildContext context,
      Ripetuta? ripetuta,
      double? target}) async {
    SimpleTemplate? template = templates[ripetuta?.template];
    final GlobalKey _autoCompleteKey = GlobalKey();
    assert((ripetuta == null) == (template == null));
    return showDialog<Pair<Ripetuta, double?>>(
      barrierDismissible: false,
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => GestureDetector(
          onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
          child: AlertDialog(
            scrollable: true,
            title: Text('RIPETUTA'),
            content: Column(
              children: <Widget>[
                AutoCompleteTextView<SimpleTemplate>(
                  key: _autoCompleteKey,
                  initialText: template?.name,
                  onSelected: (value) {
                    setState(() {
                      template = value;
                      target = template?.lastTarget;
                    });
                  },
                  onSubmitted: (value) {
                    bool dist = RegExp(r'\d+\s*[mM][\s$]').hasMatch(value);
                    bool temp =
                        RegExp(r"\d+\s*(mins?)|'|(h(ours?)?)").hasMatch(value);

                    template = templates[value] ??
                        SimpleTemplate(
                          name: value,
                          tipologia: dist
                              ? Tipologia.corsaDist
                              : temp
                                  ? Tipologia.corsaTemp
                                  : Tipologia.corsaDist,
                        );
                    setState(() => target = template?.lastTarget);
                  },
                  displayStringForOption: (s) => s.name,
                  optionsBuilder: (v) {
                    final List<SimpleTemplate> ts = templates.values
                        .where((t) => t.name.contains(v.text))
                        .toList();
                    ts.sort((a, b) {
                      if (a.name.startsWith(v.text) ==
                          b.name.startsWith(v.text))
                        return a.name.compareTo(b.name);
                      if (a.name.startsWith(v.text)) return -1;
                      return 1;
                    });
                    return ts;
                  },
                ),
                if (template != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [Tipologia.corsaDist, Tipologia.corsaTemp]
                        .map(
                          (tipologia) => IconButton(
                            onPressed: () => setState(() {
                              template?.tipologia = tipologia;
                            }),
                            icon: tipologia.icon(),
                            color: template?.tipologia == tipologia
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).disabledColor,
                          ),
                        )
                        .toList(),
                  ),
                /*Positioned(
                        left: 20,
                        right: 20,
                        top: -Theme.of(context).textTheme.overline!.fontSize / 2,
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
                                  Theme.of(context).textTheme.overline!.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: templates.contains(template)
                                            ? Colors.red
                                            : Theme.of(context).accentColor,
                                      ),
                            ),
                          ),
                        ),
                      ),*/

                if (template != null)
                  TextFormField(
                    controller: TextEditingController(
                        text: template!.tipologia.targetFormatter(target)),
                    decoration: InputDecoration(
                      hintText: 'target',
                      suffixText: template!.tipologia.targetSuffix,
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (template!.tipologia.targetValidator(value))
                        return null;
                      return template!.tipologia.targetScheme;
                    },
                    onChanged: (value) {
                      if (template!.tipologia.targetValidator(value))
                        target = template!.tipologia.targetParser(value);
                    },
                  )
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Annulla'),
              ),
              TextButton(
                onPressed: template == null
                    ? null
                    : () async {
                        template!.lastTarget = target ?? template!.lastTarget;
                        if (template is Template)
                          await (template as Template).update();
                        else
                          await template!.create();

                        if (ripetuta == null)
                          ripetuta = Ripetuta(
                            template: template!.name,
                          );
                        else
                          ripetuta!.template = template!.name;

                        Navigator.pop(context,
                            Pair<Ripetuta, double?>(ripetuta!, target));
                      },
                child: Text('Conferma'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get suggestName {
    if (ripetizioni == 1) return template;
    return '${ripetizioni}x$template';
  }
}
