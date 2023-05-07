import 'dart:async';

import 'package:atletica/athlete/athlete_widget.dart';
import 'package:atletica/athlete/athlete.dart';
import 'package:atletica/global_widgets/custom_dismissible.dart';
import 'package:atletica/global_widgets/custom_list_tile.dart';
import 'package:atletica/refactoring/common/src/control/globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AthletesRoute extends StatefulWidget {
  @override
  _AthletesRouteState createState() => _AthletesRouteState();
}

final AppBar _appBar = AppBar(title: Text('ATLETI'));

class _AthletesRouteState extends State<AthletesRoute> {
  Icon? _requestIcon;
  TextStyle? _subtitle1Bold, _labelSmallBoldPrimaryDark;

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
      await Globals.coach.refuseRequest(request.reference);
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
    _labelSmallBoldPrimaryDark ??= Theme.of(context)
        .textTheme
        .labelSmall!
        .copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColorDark);

    final bool hasRequests = Athlete.hasRequests;
    final bool hasAthletes = Athlete.hasAthletes;
    final bool hasChildren = hasRequests || hasAthletes;

    final List<Widget> children = <Widget>[_UidInfo()];
    if (hasRequests) {
      children.add(_SectionTitle(name: 'nuove richieste'));
      children
          .addAll(Athlete.requests.map((request) => _requestWidget(request)));
    }

    if (hasAthletes) {
      children.add(_SectionTitle(name: 'i tuoi atleti'));
      children.addAll(
        Athlete.athletes.map(
          (atleta) => AthleteWidget(
            atleta: atleta,
            labelSmallBoldPrimaryDark: _labelSmallBoldPrimaryDark!,
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
      floatingActionButton: Globals.coach.fictionalAthletes
          ? FloatingActionButton(
              onPressed: () => Athlete.fromDialog(context: context),
              child: Icon(Icons.add),
              mini: true,
            )
          : null,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String name;
  _SectionTitle({required this.name});

  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        name,
        style: Theme.of(context).textTheme.titleLarge,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _UidInfo extends StatefulWidget {
  @override
  _UidInfoState createState() => _UidInfoState();
}

class _UidInfoState extends State<_UidInfo> {
  bool _showUidInfo = false;

  @override
  Widget build(final BuildContext context) {
    final disclaimer = RichText(
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
            .labelSmall!
            .copyWith(fontWeight: FontWeight.normal),
      ),
      textAlign: TextAlign.justify,
    );

    return ListTile(
      leading: IconButton(
        icon: Icon(Icons.info),
        onPressed: () => setState(() => _showUidInfo = !_showUidInfo),
        color: _showUidInfo ? Theme.of(context).primaryColorDark : null,
      ),
      title: InkWell(
        child: Text(
          Globals.helper.uid,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColorDark,
          ),
        ),
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: Globals.helper.uid));
          Fluttertoast.showToast(msg: 'UID copiato con successo!');
        },
      ),
      subtitle: _showUidInfo ? disclaimer : null,
    );
    /*Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: InkWell(
            child: Text(
              Globals.helper.uid,
            ),
          ),
        )
      ],
    );*/
  }
}
