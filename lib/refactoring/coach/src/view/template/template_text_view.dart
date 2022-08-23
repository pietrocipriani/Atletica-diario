import 'package:atletica/global_widgets/auto_complete_text_view.dart';
import 'package:atletica/refactoring/common/common.dart';
import 'package:atletica/ripetuta/template.dart';
import 'package:atletica/refactoring/utils/function.dart';
import 'package:flutter/cupertino.dart';

/// The Callback for when a [SimpleTemplate] has been choosen
typedef _SelectionCallback = void Function(SimpleTemplate);

// final RegExp _distancePattern = RegExp(r'\d+\s*[mM][\s$]'); with only two options we can choose distance for exclusion, needed if this resolution pattern cannot be applied anymore
final RegExp _timePattern = RegExp(r"\d+\s*(mins?)|'|(h(ours?)?)");

/// an [AutoCompleteTextView] for [SimpleTemplate] choice
class TemplateAutoCompleteTextView extends AutoCompleteTextView<SimpleTemplate> {
  TemplateAutoCompleteTextView({
    super.key,
    super.initialText,
    required final _SelectionCallback onSelected,
  }) : super(
          onSelected: onSelected,
          onSubmitted: onSelected.compose(_onSubmitted),
          displayStringForOption: (template) => template.name,
          optionsBuilder: _searchTemplate,
        );

  /// search for an existing [SimpleTemplate] of `value` and returns a new one if it is not found
  static SimpleTemplate _onSubmitted(final String value) {
    // bool dist = _distancePattern.hasMatch(value); see above
    bool time = _timePattern.hasMatch(value);

    final Tipologia tipologia;
    if (time) {
      tipologia = Tipologia.corsaTime;
    } else {
      tipologia = Tipologia.corsaDist;
    }

    return templates[value] ?? SimpleTemplate(name: value, tipologia: tipologia);
  }

  /// search for every [SimpleTemplate] with `name` compatible with `value`
  ///
  /// First the [SimpleTemplate] with names starting with `value` are shown, then every [SimpleTemplate] compatible in alphabetical order
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
