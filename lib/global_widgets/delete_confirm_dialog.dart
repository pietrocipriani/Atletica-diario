import 'package:flutter/material.dart';

/// basic dialog to ask if the user really wants to delete `name`
Future<bool> showDeleteConfirmDialog({
  @required BuildContext context,
  @required String name,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => _deleteConfirmDialog(context: context, name: name),
  );
}

final Widget _title = Text('Conferma eliminazione');

AlertDialog _deleteConfirmDialog({
  @required BuildContext context,
  @required String name,
}) {
  final TextStyle bold = TextStyle(fontWeight: FontWeight.bold);

  final Widget content = RichText(
    text: TextSpan(
        text: 'Sei sicuro di voler eliminare ',
        style: TextStyle(color: Colors.black),
        children: [
          TextSpan(text: name, style: bold),
          TextSpan(text: '? Una volta cancellato non sarà più recuperabile!'),
        ]),
    textAlign: TextAlign.justify,
  );

  final Widget cancel = FlatButton(
    onPressed: () => Navigator.pop(context, false),
    child: Text('Annulla', style: TextStyle(color: Colors.grey)),
  );
  final Widget confirm = FlatButton(
    onPressed: () => Navigator.pop(context, true),
    child: Text('Elimina', style: TextStyle(color: Colors.red)),
  );

  return AlertDialog(
    title: _title,
    content: content,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    actions: <Widget>[cancel, confirm],
  );
}
