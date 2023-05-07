import 'package:atletica/persistence/firestore.dart';
import 'package:atletica/refactoring/common/common.dart';
import 'package:atletica/refactoring/common/src/control/globals.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:get/get.dart';

/// Screen for preferences, view user profile and logout
class PreferencesRoute extends StatefulWidget {
  static const String routeName = '/settings';

  // TODO: route popped on setState
  @override
  State<StatefulWidget> createState() => _PreferencesRouteState();
}

class _PreferencesRouteState extends State<PreferencesRoute> {
  String writeToDeveloper = '';

  String? _title,
      _logout,
      _changeRole,
      _runas,
      _darkMode,
      _showAsAthlete,
      _showAsAthleteDescription,
      _fictionalAthletes,
      _changeLang,
      _complains,
      _sent,
      _emptyMessage;

  @override
  void didChangeDependencies() {
    final AppLocalizations loc = AppLocalizations.of(context)!;
    _title = loc.preferences.toUpperCase();
    _logout = loc.logout.toUpperCase();
    _changeRole = loc.changeRole.toUpperCase();
    _runas = '# ${loc.runAs.toUpperCase()}';
    _darkMode = loc.darkMode.toUpperCase();
    _showAsAthlete = loc.showAsAthlete.toUpperCase();
    _showAsAthleteDescription = loc.showAsAthleteDescription;
    _fictionalAthletes = loc.fictionalAthletes.toUpperCase();
    _changeLang = loc.changeLanguage.toUpperCase();
    _complains = loc.complainsPlaceholder;
    _sent = loc.messageSent;
    _emptyMessage = loc.cannotSendMessage;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return ProfileScreen(
      actions: [
        SignedOutAction((context) => Get.offAllNamed(AuthGate.routeName)),
      ],
      //showMFATile: true,
      children: [
        PreferencesActionButton(
          icon: Icons.swap_vert,
          text: _changeRole!,
          action: () async {
            // Check how if changing Globals.helper breaks something and if
            // the RoleGate can withstand an already initialized userHelper
            await Globals.switchRole();
            Get.offAllNamed(RoleGate.routeName);
          },
        ),
        if (Globals.helper.admin)
          PreferencesActionButton(
            icon: MdiIcons.console,
            text: _runas!,
            action: () async {
              String? runas = await _showRunasDialog(context: context);
              if (runas == null) return;
              if (runas == Globals.helper.user.uid) runas = null;

              await Globals.helper.realUser.update({'runas': runas});
              Globals.user = Globals.helper.user;
              Get.offAllNamed(RoleGate.routeName);
            },
          ),
        /*if (Globals.helper.isCoach)
          PreferencesSwitch(
            icon: Icons.build_circle,
            text: _showAsAthlete!,
            description: _showAsAthleteDescription,
            value: auth.userC.showAsAthlete,
            onSwitch: (s) async {
              await auth.user.userReference.update({'showAsAthlete': s});
              setState(() => auth.userC.showAsAthlete = s);
              if (s && !Athlete.exists(auth.user.userReference))
                auth.user.userReference
                    .collection('athletes')
                    .doc(auth.user.userReference.id)
                    .set({'nickname': 'Tu'});
            },
          ),
        if (Globals.helper.isCoach)
          PreferencesSwitch(
            icon: Icons.build_circle,
            text: _fictionalAthletes!,
            value: auth.userC.fictionalAthletes,
            onSwitch: (s) async {
              await auth.user.userReference.update({'fictionalAthletes': s});
              setState(() => auth.userC.fictionalAthletes = s);
            },
          ),
        if (auth.user.isCoach)
          PreferencesSwitch(
            icon: Icons.build_circle,
            text: "MOSTRA VARIANTI",
            description:
                "possibilità di inserire le varianti agli allenamenti per differenti target",
            disabled: true,
            value: auth.userC.showVariants,
            onSwitch: (s) async {
              await auth.user.userReference.update({'showVariants': s});
              setState(() => auth.userC.showVariants = s);
            },
          ),
        PreferencesActionButton(
          icon: Icons.translate,
          text: _changeLang!,
          disabled: true,
          action: () {},
        ),*/
        /*Row(
          children: [
            Expanded(
              child: ResizableTextField(
                onChanged: (t) => writeToDeveloper = t,
                hint: _complains,
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
                      SnackBar(content: Text(_sent!)),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                } else
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(_emptyMessage!)));
              },
              icon: Icon(Icons.send),
            )
          ],
        )*/
      ],
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
                        style: user.id == Globals.user.uid
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

class PreferencesActionButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final void Function() action;
  final String? description;
  final bool disabled;
  PreferencesActionButton({
    required this.icon,
    required this.text,
    required this.action,
    this.description,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      onTap: action,
      enabled: !disabled,
      trailing: Icon(Icons.arrow_forward_ios),
      subtitle: description == null ? null : Text(description!),
    );
  }
}

class PreferencesSwitch extends StatelessWidget {
  final IconData icon;
  final String text;
  final void Function(bool newValue) onSwitch;
  final bool value;
  final String? description;
  final bool disabled;
  PreferencesSwitch({
    required this.icon,
    required this.text,
    required this.onSwitch,
    required this.value,
    this.description,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      enabled: !disabled,
      trailing: Switch(value: value, onChanged: disabled ? null : onSwitch),
      subtitle: description == null ? null : Text(description!),
    );
  }
}
