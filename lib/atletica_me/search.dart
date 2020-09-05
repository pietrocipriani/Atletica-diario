import 'package:Atletica/atletica_me/athlete.dart';
import 'package:Atletica/atletica_me/loading_widget.dart';
import 'package:Atletica/atletica_me/search_athletes.dart';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:flutter/material.dart';

class SearchWidget extends StatefulWidget {
  final String initialName;
  final void Function(Athlete a) onSelected;

  SearchWidget({@required this.initialName, @required this.onSelected});

  @override
  State<StatefulWidget> createState() => _SearchWidgetState(initialName);
}

class _SearchWidgetState extends State<SearchWidget> {
  final TextEditingController _controller;
  final GlobalKey<AutoCompleteTextFieldState<Athlete>> _key = GlobalKey();

  AutoCompleteTextField<Athlete> _actf;

  bool _loading = false;
  String loaded;

  _SearchWidgetState(final String initialName)
      : _controller = TextEditingController(text: initialName);

  @override
  void initState() {
    _actf = AutoCompleteTextField<Athlete>(
      controller: _controller,
      decoration: InputDecoration(helperText: "inserisci il tuo nome"),
      itemSubmitted: widget.onSelected,
      clearOnSubmit: false,
      key: _key,
      suggestions: [],
      textCapitalization: TextCapitalization.words,
      itemBuilder: (context, athlete) => AthleteItemWidget(athlete),
      itemSorter: (a1, a2) => a1.name.compareTo(a2.name),
      itemFilter: (suggestion, query) => true,
      textSubmitted: (data) => _load(),
      textChanged: (data) => _load(),
      minLength: 3,
    );
    _load();
    super.initState();
  }

  Future<void> _load() async {
    final String query = _controller.text;
    if (query == loaded) {
      if (_loading) {
        _loading = false;
        if (mounted) setState(() {});
      }
      return;
    }
    await Future.delayed(const Duration(milliseconds: 300));
    if (query != _controller.text) return;
    if (!_loading) {
      _loading = true;
      if (mounted) setState(() {});
    }

    final Iterable<Athlete> res = await searchAthletes(query);
    if (query == _controller.text && _loading) {
      _actf.updateSuggestions(res.toList());
      setState(() {
        loaded = query;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(child: _actf),
        if (_loading) Container(height: 48, child: LoadingWidget())
      ],
    );
  }
}
