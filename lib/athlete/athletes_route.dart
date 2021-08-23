import 'dart:async';

import 'package:atletica/athlete/athlete_widget.dart';
import 'package:atletica/athlete/athlete.dart';
import 'package:atletica/global_widgets/custom_dismissible.dart';
import 'package:atletica/global_widgets/custom_list_tile.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AthletesRoute extends StatefulWidget {
  @override
  _AthletesRouteState createState() => _AthletesRouteState();
}

final AppBar _appBar = AppBar(title: Text('ATLETI'));

class _AthletesRouteState extends State<AthletesRoute> {
  late final Callback<Athlete> _callback = Callback((_, c) => setState(() {}));
  Icon? _requestIcon;
  TextStyle? _subtitle1Bold, _overlineBoldPrimaryDark;
  bool _showUidInfo = false;

  @override
  void initState() {
    Athlete.signInGlobal(_callback);
    Athlete.requests.forEach((r) => r.signIn(_callback));
    super.initState();
  }

  @override
  void dispose() {
    Athlete.signOutGlobal(_callback.stopListening);
    Athlete.fullAthletes.forEach((r) => r.signOut(_callback));
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
                .overline!
                .copyWith(fontWeight: FontWeight.normal),
          ),
          textAlign: TextAlign.justify,
        ),
      );

  // FIXME: unmounted error
  Widget _requestWidget(Athlete request) {
    final Widget title = Text(request.name, style: _subtitle1Bold);

    final Widget content = CustomListTile(
      leading: _requestIcon!,
      title: title,
      onTap: () => Athlete.fromDialog(context: context, request: request),
    );
    final FutureOr<void> Function(DismissDirection dir) onDismissed =
        (direction) async {
      await userC.refuseRequest(request.reference);
    };
    final Future<bool?> Function(DismissDirection dir) confirmDismiss =
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
    _overlineBoldPrimaryDark ??= Theme.of(context).textTheme.overline!.copyWith(
        fontWeight: FontWeight.bold, color: Theme.of(context).primaryColorDark);

    final bool hasRequests = Athlete.hasRequests;
    final bool hasAthletes = Athlete.hasAthletes;
    final bool hasChildren = hasRequests || hasAthletes;

    final List<Widget> children = <Widget>[
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () => setState(() => _showUidInfo = !_showUidInfo),
            color: _showUidInfo ? Theme.of(context).primaryColorDark : null,
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
      children
          .addAll(Athlete.requests.map((request) => _requestWidget(request)));
    }

    if (hasAthletes) {
      children.add(_subtitle('i tuoi atleti'));
      children.addAll(
        Athlete.athletes.map(
          (atleta) => AthleteWidget(
            atleta: atleta,
            overlineBoldPrimaryDark: _overlineBoldPrimaryDark!,
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
      floatingActionButton: userC.fictionalAthletes
          ? FloatingActionButton(
              onPressed: () => Athlete.fromDialog(context: context),
              child: Icon(Icons.add),
              mini: true,
            )
          : null,
    );
  }
}
