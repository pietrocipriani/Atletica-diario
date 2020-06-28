import 'dart:async';

import 'package:Atletica/athlete/athlete_widget.dart';
import 'package:Atletica/athlete/atleta.dart';
import 'package:Atletica/athlete/group.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AthletesRoute extends StatefulWidget {
  @override
  _AthletesRouteState createState() => _AthletesRouteState();
}

final AppBar _appBar = AppBar(title: Text('ATLETI'));

class _AthletesRouteState extends State<AthletesRoute> {
  final Callback<Event> _callback = Callback<Event>();
  Icon _requestIcon;
  TextStyle _subtitle1Bold, _overlineBoldPrimaryDark;
  FloatingActionButton _fab;

  @override
  void initState() {
    _callback.f = (evt) => setState(() {});
    user.requestCallbacks.add(_callback);

    _fab = FloatingActionButton(
      onPressed: () async {
        if (await Atleta.fromDialog(context: context) ?? false) setState(() {});
      },
      tooltip: 'aggiungi un atleta',
      child: Icon(Icons.add),
    );

    super.initState();
  }

  @override
  void dispose() {
    user.requestCallbacks.remove(_callback.stopListening);
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

  Widget _requestWidget(BasicUser request) {
    final Widget title = Text(request.name, style: _subtitle1Bold);
    final Widget subtitle =
        Text(request.email, style: _overlineBoldPrimaryDark);

    final Widget content = ListTile(
      leading: _requestIcon,
      title: title,
      subtitle: subtitle,
    );

    final Widget refuseBackground = Container(
      color: Theme.of(context).primaryColorLight,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 16),
      child: Icon(Icons.clear),
    );
    final Widget acceptBackground = Container(
      color: Colors.lightGreen[200],
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 16),
      child: Icon(Icons.check),
    );
    final FutureOr<void> Function(DismissDirection dir) onDismissed =
        (direction) async {
      if (direction == DismissDirection.startToEnd)
        await user.refuseRequest(request.uid);
      else
        await user.acceptRequest(request);
    };
    final Future<bool> Function(DismissDirection dir) confirmDismiss =
        (dir) async {
      if (dir == DismissDirection.startToEnd) return true;
      return await Atleta.fromDialog(context: context, name: request.name);
    };

    return Dismissible(
      key: ValueKey(request),
      child: content,
      background: refuseBackground,
      secondaryBackground: acceptBackground,
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

    final bool hasRequests = user?.requests?.isNotEmpty ?? false;
    final bool hasAthletes = groups.any((group) => group.atleti.isNotEmpty);
    final bool hasChildren = hasRequests || hasAthletes;

    final List<Widget> children = <Widget>[];
    if (hasRequests) {
      children.add(_subtitle('nuove richieste'));
      children.addAll(user.requests.map((request) => _requestWidget(request)));
    }

    if (hasAthletes) {
      children.add(_subtitle('i tuoi atleti'));
      children.addAll(
        groups.expand(
          (group) => group.atleti.map(
            (atleta) => AthleteWidget(
              atleta: atleta,
              group: group,
              subtitle1Bold: _subtitle1Bold,
              overlineBoldPrimaryDark: _overlineBoldPrimaryDark,
              onModified: () => setState(() {}),
            ),
          ),
        ),
      );
    }

    final Widget body = hasChildren
        ? ListView(children: children)
        : Center(child: Text('non hai nessun atleta'));

    return Scaffold(
      appBar: _appBar,
      body: body,
      floatingActionButton: _fab,
    );
  }
}
