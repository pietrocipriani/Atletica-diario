import 'package:Atletica/global_widgets/animated_text.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:flutter/material.dart';

class RequestCoachRoute extends StatefulWidget {
  @override
  _RequestCoachRoute createState() => _RequestCoachRoute();
}

class _RequestCoachRoute extends State<RequestCoachRoute> {
  final Callback callback = Callback();
  final TextEditingController controller = TextEditingController();

  @override
  void initState() {
    callback.f = (_) => setState(() {});
    CoachRequest.onResponseCallbacks.add(callback);
    super.initState();
  }

  @override
  void dispose() {
    CoachRequest.onResponseCallbacks.remove(callback.stopListening);
    super.dispose();
  }

  bool get _hasText => controller.text != null && controller.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (userA.coach is BasicUser)
      WidgetsBinding.instance
          .addPostFrameCallback((_) => Navigator.pop(context));
    return WillPopScope(
      onWillPop: () => Future.value(
          false), // TODO: check if it block also code pop (not only ui interaction)
      child: Padding(
        padding: MediaQuery.of(context).padding,
        child: Material(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                const Text(
                  "Inserisci qui sotto l'uid del tuo allenatore per inviargli una richiesta. Una volta ricevuta una risposta affermativa, si verrà automaticamente reindirizzati alla Home! Potrebbe richiedere molto tempo.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                userA.coach == null
                    ? TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          helperText: "inserisci l'uid dell'allenatore",
                        ),
                        onChanged: (value) => setState(() {}),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          AnimatedText(
                            text: 'in attesa di risposta',
                            style: Theme.of(context)
                                .textTheme
                                .headline6
                                .copyWith(
                                    color: Theme.of(context).primaryColorDark),
                          ),
                          Icon(Icons.check_circle, color: Colors.green)
                        ],
                      ),
                const SizedBox(height: 10),
                RaisedButton.icon(
                  onPressed: userA.coach == null
                      ? _hasText
                          ? () => userA.requestCoach(uid: controller.text)
                          : null
                      : userA.coach is CoachRequest
                          ? () => userA.coach.deleteRequest()
                          : null,
                  label: Text(userA.coach == null ? 'invia' : 'cancella'),
                  icon: Icon(userA.coach == null ? Icons.send : Icons.clear),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
