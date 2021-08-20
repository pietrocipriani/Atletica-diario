import 'package:atletica/global_widgets/resizable_text_field.dart';
import 'package:atletica/global_widgets/splash_screen.dart';
import 'package:atletica/main.dart';
import 'package:atletica/persistence/auth.dart' as auth;
import 'package:atletica/persistence/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:atletica/persistence/user_helper/athlete_helper.dart';
import 'package:mdi/mdi.dart';

class PreferencesRoute extends StatefulWidget {
  // TODO: route popped on setState
  @override
  State<StatefulWidget> createState() => _PreferencesRouteState();
}

class _PreferencesRouteState extends State<PreferencesRoute> {
  String writeToDeveloper = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('IMPOSTAZIONI')),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('LOGOUT'),
            onTap: () async {
              await auth.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => SplashScreen()),
                (_) => false,
              );
            },
            trailing: Icon(Icons.arrow_forward_ios),
          ),
          ListTile(
            leading: Icon(Icons.swap_vert),
            title: Text('CAMBIA RUOLO'),
            onTap: () async {
              await auth.user.userReference.update({
                'role': auth.user is AthleteHelper ? COACH_ROLE : ATHLETE_ROLE
              });
              auth.user = auth.user.user;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => SplashScreen()),
                (_) => false,
              );
            },
            trailing: Icon(Icons.arrow_forward_ios),
          ),
          if (auth.user.admin)
            ListTile(
              leading: Icon(Mdi.console),
              title: Text('# RUNAS'),
              onTap: () async {
                String? runas = await _showRunasDialog(context: context);
                if (runas == null) return;
                if (runas == auth.user.user.uid) runas = null;

                await auth.user.realUser.update({'runas': runas});
                auth.user = auth.user.user;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => SplashScreen()),
                  (_) => false,
                );
              },
              trailing: Icon(Icons.arrow_forward_ios),
            ),
          ListTile(
            leading: Icon(Icons.dark_mode),
            title: Text('DARK MODE'),
            subtitle: Text(
                'alpha: known bugs'), // TODO: update dialog skipped on brightness != themedata.system
            trailing: Switch(
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: (v) {
                themeMode = v ? ThemeMode.dark : ThemeMode.light;
                auth.user.userReference
                    .update({'themeMode': themeMode.toString()});
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: ResizableTextField(
                  onChanged: (t) => writeToDeveloper = t,
                  hint: 'complains / requests / suggestions',
                ),
              ),
              IconButton(
                onPressed: () async {
                  if (writeToDeveloper.isNotEmpty) {
                    try {
                      await FirebaseStorage.instance
                          .ref(
                              'complains/${DateTime.now().microsecondsSinceEpoch}${auth.user.uid}.txt')
                          .putString(
                            writeToDeveloper,
                            metadata: SettableMetadata(
                              contentType: 'plain/text',
                              contentEncoding: 'UTF-8',
                            ),
                          );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('messaggio inviato!')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  } else
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('non è possibile inviare un messaggio vuoto!'),
                      ),
                    );
                },
                icon: Icon(Icons.send),
              )
            ],
          )
        ],
      ),
    );
  }
}

Future<String?> _showRunasDialog({required final BuildContext context}) =>
    showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        content: FutureBuilder<QuerySnapshot>(
          future: firestore.collection('users').orderBy('name').get(),
          builder: (context, snapshot) =>
              _RunasDialog(snapshot.data?.docs ?? []),
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
                    onTap: () => Navigator.pop(context, user.id),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        user["name"],
                        style: user.id == auth.user.user.uid
                            ? Theme.of(context)
                                .textTheme
                                .subtitle2!
                                .copyWith(color: Colors.green)
                            : Theme.of(context).textTheme.subtitle2,
                      ),
                    ),
                  ),
                ),
          ),
      );
}
