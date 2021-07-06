import 'package:atletica/persistence/firestore.dart';
import 'package:atletica/global_widgets/splash_screen.dart';
import 'package:atletica/persistence/auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mdi/mdi.dart';

class RunasButton extends IconButton {
  RunasButton({@required final BuildContext context})
      : super(
          icon: Icon(Mdi.console),
          tooltip: '# RUNAS',
          onPressed: () async {
            String runas = await _showRunasDialog(context: context);
            if (runas == null) return;
            if (runas == auth.user.user.uid) runas = null;

            await auth.user.realUser.updateData({'runas': runas});
            auth.user = auth.user.user;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => SplashScreen()),
              (_) => false,
            );
          },
        );
}

Future<String> _showRunasDialog({@required final BuildContext context}) =>
    showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        content: FutureBuilder<QuerySnapshot>(
          future: firestore.collection('users').orderBy('name').getDocuments(),
          builder: (context, snapshot) =>
              _RunasDialog(snapshot.data?.documents ?? []),
        ),
      ),
    );

class _RunasDialog extends StatefulWidget {
  final List<DocumentSnapshot> users;
  _RunasDialog(this.users);

  @override
  _RunasDialogState createState() => _RunasDialogState();
}

class _RunasDialogState extends State<_RunasDialog> {
  final TextEditingController _controller = TextEditingController(text: '');

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _controller,
            onChanged: (_) => setState(() {}),
          ),
          Container(height: 16)
        ]..addAll(
            widget.users
                .where((user) =>
                    user['name'] != null &&
                    _controller.text
                        .toLowerCase()
                        .split(' ')
                        .every(user['name'].toLowerCase().contains))
                .map(
                  (user) => GestureDetector(
                    onTap: () => Navigator.pop(context, user.documentID),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        user["name"],
                        style: user.documentID == auth.user.user.uid
                            ? Theme.of(context)
                                .textTheme
                                .subtitle2
                                .copyWith(color: Colors.green)
                            : Theme.of(context).textTheme.subtitle2,
                      ),
                    ),
                  ),
                ),
          ),
      );
}
