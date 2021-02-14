import 'dart:async';

import 'package:Atletica/athlete/athlete_widget.dart';
import 'package:Atletica/athlete/atleta.dart';
import 'package:Atletica/global_widgets/custom_dismissible.dart';
import 'package:Atletica/global_widgets/custom_list_tile.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/persistence/user_helper/coach_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AthletesRoute extends StatefulWidget {
  @override
  _AthletesRouteState createState() => _AthletesRouteState();
}

final AppBar _appBar = AppBar(title: Text('ATLETI'));

class _AthletesRouteState extends State<AthletesRoute> {
  final Callback _callback = Callback();
  Icon _requestIcon;
  TextStyle _subtitle1Bold, _overlineBoldPrimaryDark;
  bool _showUidInfo = false;

  @override
  void initState() {
    _callback.f = (_) => setState(() {});
    CoachHelper.onRequestCallbacks.add(_callback);
    CoachHelper.onAthleteCallbacks.add(_callback);

    super.initState();
  }

  @override
  void dispose() {
    _callback.stopListening;
    CoachHelper.onRequestCallbacks.remove(_callback);
    CoachHelper.onAthleteCallbacks.remove(_callback);
    super.dispose();
  }

  /// titles for subgroups (requests & athletes)
  Widget _subtitle(String name) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        name,
        style: Theme.of(context).textTheme.headline6,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget get _uidInfo => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: RichText(
          text: TextSpan(
            text: 'questo è il tuo ',
            children: [
              TextSpan(
                text: 'user id',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              TextSpan(
                  text:
                      ', condividilo con i tuoi atleti per sincronizzare i dati. '),
              TextSpan(
                text: 'TAP TO COPY',
                style: TextStyle(fontWeight: FontWeight.w900),
              )
            ],
            style: Theme.of(context)
                .textTheme
                .overline
                .copyWith(fontWeight: FontWeight.normal),
          ),
          textAlign: TextAlign.justify,
        ),
      );

  Widget _requestWidget(Athlete request) {
    final Widget title = Text(request.name, style: _subtitle1Bold);

    final Widget content = CustomListTile(
      leading: _requestIcon,
      title: title,
      onTap: () => Athlete.fromDialog (context: context, request: request),
    );
    final FutureOr<void> Function(DismissDirection dir) onDismissed =
        (direction) async {
      await userC.refuseRequest(request.reference);
    };
    final Future<bool> Function(DismissDirection dir) confirmDismiss =
        (dir) async {
      if (dir == DismissDirection.startToEnd) return true;
      return await Athlete.fromDialog(context: context, request: request);
    };

    return CustomDismissible(
      key: ValueKey(request),
      child: content,
      firstBackgroundIcon: Icons.clear,
      secondBackgroundIcon: Icons.check,
      onDismissed: onDismissed,
      confirmDismiss: confirmDismiss,
    );
  }

  @override
  Widget build(BuildContext context) {
    _requestIcon ??= Icon(
      Icons.new_releases,
      color: Theme.of(context).primaryColorDark,
    );
    _subtitle1Bold ??= Theme.of(context)
        .textTheme
        .subtitle1
        .copyWith(fontWeight: FontWeight.bold);
    _overlineBoldPrimaryDark ??= Theme.of(context).textTheme.overline.copyWith(
        fontWeight: FontWeight.bold, color: Theme.of(context).primaryColorDark);

    final bool hasRequests = userC.requests.isNotEmpty;
    final bool hasAthletes = userC.athletes.isNotEmpty;
    final bool hasChildren = hasRequests || hasAthletes;

    final List<Widget> children = <Widget>[
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () => setState(() => _showUidInfo = !_showUidInfo),
            color: _showUidInfo
                ? Theme.of(context).primaryColorDark
                : Colors.black,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: () => Clipboard.setData(ClipboardData(text: userC.uid)),
              child: Text(
                userC.uid,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColorDark,
                ),
              ),
            ),
          )
        ],
      )
    ];
    if (_showUidInfo) children.add(_uidInfo);
    if (hasRequests) {
      children.add(_subtitle('nuove richieste'));
      children.addAll(userC.requests.map((request) => _requestWidget(request)));
    }

    if (hasAthletes) {
      children.add(_subtitle('i tuoi atleti'));
      children.addAll(
        userC.athletes.map(
          (atleta) => AthleteWidget(
            atleta: atleta,
            subtitle1Bold: _subtitle1Bold,
            overlineBoldPrimaryDark: _overlineBoldPrimaryDark,
            onModified: () => setState(() {}),
          ),
        ),
      );
    }

    final Widget body = hasChildren
        ? ListView(children: children)
        : Column(
            children: children
              ..add(Center(child: Text('non hai nessun atleta'))),
          );

    return Scaffold(
      appBar: _appBar,
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Athlete.fromDialog(context: context),
        child: Icon(Icons.add),
      ),
    );
  }
}
