import 'package:atletica/training/allenamento.dart';
import 'package:flutter/material.dart';

class TrainingsWrapper extends StatefulWidget {
  final Widget Function(Allenamento a) builder;

  TrainingsWrapper ({@required this.builder});

  @override
  _TrainingsWrapperState createState() => _TrainingsWrapperState();
}

class _TrainingsWrapperState extends State<TrainingsWrapper> {
  String tag1, tag2;

  Iterable get _directoryValues {
    if (tag1 == null || !trainingsTree.containsKey(tag1))
      return trainingsTree.keys;
    if (tag2 == null || !trainingsTree[tag1].containsKey(tag2))
      return trainingsTree[tag1].keys;
    return trainingsTree[tag1][tag2].values;
  }

  Widget _child(dynamic value) => value is Allenamento
      ? widget.builder(value)
      : Padding(
          padding: const EdgeInsets.all(4.0),
          child: GestureDetector(
            onTap: () => setState(() => tag1 == null ? tag1 = value : tag2 = value),
            child: Chip(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: Theme.of(context).dialogBackgroundColor,
              shape: StadiumBorder(
                side: BorderSide(
                  color: Theme.of(context).primaryColor,
                ),
              ),
              label: Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .overline
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );

  @override
  Widget build(BuildContext context) {
    final TextStyle overline = Theme.of(context).textTheme.overline;
    final Widget child = Wrap(
      alignment: WrapAlignment.center,
      children: _directoryValues.map(_child).toList(),
    );
    return Column(
      children: [
        Row(
          children: [
            if (tag1 != null)
              IconButton(
                icon: Icon(Icons.arrow_back_ios, size: 12),
                onPressed: () => setState(() {
                  if (tag2 == null) tag1 = null;
                  else tag2 = null;
                }),
              ),
            Expanded(
              child: Container(
                alignment: Alignment.centerRight,
                height: 42,
                child: Text(
                  path,
                  style: overline,
                  maxLines: 1,
                  textAlign: TextAlign.end,
                ),
              ),
            ),
          ],
        ),
        child,
      ],
    );
  }

  String get path {
    if (tag1 == null) return '/';
    if (tag2 == null) return '/$tag1/';
    return '/$tag1/$tag2';
  }
}
