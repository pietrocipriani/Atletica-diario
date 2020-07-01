import 'package:Atletica/persistence/firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

Future<void> showModeSelectorRoute({@required BuildContext context}) =>
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Ruolo'),
        content: ModeSelectorRoute(),
      ),
    );

class ModeSelectorRoute extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Expanded(
          child: DottedBorder(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Text(
                  'in modalità allenatore puoi creare e programmare gli allenamenti, gestire i tuoi atleti e inserire i risultati.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.overline,
                ),
                RaisedButton(
                  onPressed: () async {
                    await setRole('coach');
                    Navigator.pop(context);
                  },
                  child: Text('ALLENATORE'),
                ),
              ],
            ),
            borderType: BorderType.RRect,
            radius: Radius.circular(20),
            padding: const EdgeInsets.all(16),
            color: Colors.grey,
            dashPattern: [6, 4],
          ),
        ),
        const SizedBox(height: 8,),
        Expanded(
          child: DottedBorder(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Text(
                  'in modalità atleta puoi visualizzare gli allenamenti condivisi dal tuo allenatore e inserire i tuoi risultati.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.overline,
                ),
                RaisedButton(
                  onPressed: () async {
                    await setRole('athlete');
                    Navigator.pop(context);
                  },
                  child: Text('ATLETA'),
                ),
              ],
            ),
            borderType: BorderType.RRect,
            radius: Radius.circular(20),
            padding: const EdgeInsets.all(16),
            color: Colors.grey,
            dashPattern: [6, 4],
          ),
        ),
      ],
    );
  }
}
