import 'package:Atletica/running_training/running_training.dart';
import 'package:flutter/material.dart';

class HomePageWidget extends StatefulWidget {

  HomePageWidget ({Key key}) : super(key: key);

  @override
  _HomePageWidgetState createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  BoxDecoration _bgDecoration = BoxDecoration(
    image: DecorationImage(
      image: AssetImage('assets/speed.png'),
      colorFilter: ColorFilter.mode(
        Colors.grey[100],
        BlendMode.srcIn,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    Widget content = runningTrainings.isNotEmpty
        ? SingleChildScrollView(child: Column(children: runningTrainings))
        : Text('Nessun allenamento in programma per oggi!');
    return content = Container(
        alignment:
            runningTrainings.isEmpty ? Alignment.center : Alignment.topCenter,
        decoration: _bgDecoration,
        child: content);
  }
}
