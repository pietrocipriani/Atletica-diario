import 'package:atletica/global_widgets/auto_complete_text_view.dart';
import 'package:atletica/refactoring/model/target.dart';
import 'package:atletica/refactoring/model/tipologia.dart';
import 'package:atletica/ripetuta/template.dart';
import 'package:flutter/cupertino.dart';

typedef _SelectionCallback = void Function(SimpleTemplate);

// final RegExp _distancePattern = RegExp(r'\d+\s*[mM][\s$]');
final RegExp _timePattern = RegExp(r"\d+\s*(mins?)|'|(h(ours?)?)");

class TemplateAutoCompleteTextView extends AutoCompleteTextView<SimpleTemplate> {
  TemplateAutoCompleteTextView({
    super.key,
    super.initialText,
    final _SelectionCallback? onSelected,
  }) : super(
          onSelected: onSelected,
          onSubmitted: (value) => _onSubmitted(value, onSelected),
          displayStringForOption: (template) => template.name,
          optionsBuilder: _searchTemplate,
        );

  static void _onSubmitted(final String value, final _SelectionCallback? onSelected) {
    // bool dist = _distancePattern.hasMatch(value);
    bool time = _timePattern.hasMatch(value);

    final Tipologia tipologia;
    if (time) {
      tipologia = Tipologia.corsaTime;
    } else {
      tipologia = Tipologia.corsaDist;
    }

    final SimpleTemplate template = templates[value] ?? SimpleTemplate(name: value, tipologia: tipologia);
    onSelected?.call(template);
  }

  static Iterable<SimpleTemplate> _searchTemplate(final TextEditingValue value) {
    final List<SimpleTemplate> ts = templates.values.where((t) => t.name.contains(value.text)).toList();
    ts.sort((a, b) {
      if (a.name.startsWith(value.text) == b.name.startsWith(value.text)) return a.name.compareTo(b.name);
      if (a.name.startsWith(value.text)) return -1;
      return 1;
    });
    return ts;
  }
}
