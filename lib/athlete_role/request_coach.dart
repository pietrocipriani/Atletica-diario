import 'package:atletica/global_widgets/animated_text.dart';
import 'package:atletica/global_widgets/preferences_button.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/persistence/user_helper/athlete_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RequestCoachRoute extends StatefulWidget {
  final void Function() onCoachFound;

  RequestCoachRoute({required this.onCoachFound});

  @override
  _RequestCoachRoute createState() => _RequestCoachRoute();
}

class _RequestCoachRoute extends State<RequestCoachRoute> {
  late final Callback callback = Callback((_, c) => setState(() {}));
  final TextEditingController controller = TextEditingController(),
      _nameController = TextEditingController(text: userA.name);

  @override
  void initState() {
    AthleteHelper.onCoachChanged.add(callback);
    super.initState();
  }

  String? _infoText,
      _request,
      _send,
      _cancel,
      _insertUid,
      _loopback,
      _insertUidPlaceholder,
      _insertNamePlaceholder,
      _waitingForResponse;

  @override
  void didChangeDependencies() {
    final AppLocalizations loc = AppLocalizations.of(context)!;
    _infoText = loc.requestCoachInfoText;
    _request = loc.request.toUpperCase();
    _send = loc.send;
    _cancel = loc.cancel;
    _insertUid = loc.insertUid;
    _loopback = loc.coachRequestLoopBack;
    _insertUidPlaceholder = loc.coachRequestUid;
    _insertNamePlaceholder = loc.insertNamePlaceholder;
    _waitingForResponse = loc.waitingForResponse;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    AthleteHelper.onCoachChanged.remove(callback.stopListening);
    super.dispose();
  }

  bool get _hasText =>
      controller.text.isNotEmpty && _nameController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (userA.hasCoach) widget.onCoachFound();

    return WillPopScope(
      onWillPop: () => Future.value(false),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(_request!),
          actions: [PreferencesButton(context: context)],
        ),
        body: Padding(
          padding: MediaQuery.of(context).padding,
          child: Material(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(_infoText!, textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  if (userA.needsRequest)
                    TextFormField(
                      controller: controller,
                      autofocus: false,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (str) => str == null || str.isEmpty
                          ? _insertUid
                          : str == userA.uid
                              ? _loopback
                              : null,
                      decoration: InputDecoration(
                        helperText: _insertUidPlaceholder,
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  if (userA.needsRequest)
                    TextFormField(
                      controller: _nameController,
                      decoration:
                          InputDecoration(helperText: _insertNamePlaceholder),
                      textCapitalization: TextCapitalization.words,
                    ),
                  if (userA.hasRequest)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        AnimatedText(
                          text: _waitingForResponse!,
                          style: Theme.of(context)
                              .textTheme
                              .headline6!
                              .copyWith(
                                  color: Theme.of(context).primaryColorDark),
                        ),
                        Icon(Icons.check_circle, color: Colors.green)
                      ],
                    ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: userA.needsRequest
                        ? _hasText
                            ? () => userA.requestCoach(
                                  uid: controller.text,
                                  nickname: _nameController.text,
                                )
                            : null
                        : userA.hasRequest
                            ? () => userA.deleteCoachSubscription()
                            : null,
                    label: Text(userA.coach == null ? _send! : _cancel!),
                    icon: Icon(userA.coach == null ? Icons.send : Icons.clear),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
