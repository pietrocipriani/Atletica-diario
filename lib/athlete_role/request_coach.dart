import 'package:atletica/global_widgets/animated_text.dart';
import 'package:atletica/global_widgets/logout_button.dart';
import 'package:atletica/global_widgets/runas_button.dart';
import 'package:atletica/global_widgets/swap_button.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/persistence/user_helper/athlete_helper.dart';
import 'package:flutter/material.dart';

class RequestCoachRoute extends StatefulWidget {
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

  @override
  void dispose() {
    AthleteHelper.onCoachChanged.remove(callback.stopListening);
    super.dispose();
  }

  bool get _hasText =>
      controller.text.isNotEmpty && _nameController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (userA.hasCoach)
      WidgetsBinding.instance?.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) Navigator.pop(context);
      });

    return WillPopScope(
      onWillPop: () => Future.value(false),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text('RICHIESTA'),
          actions: [
            LogoutButton(context: context),
            SwapButton(context: context),
            if (user.admin) RunasButton(context: context),
          ],
        ),
        body: Padding(
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
                  if (userA.needsRequest)
                    TextFormField(
                      controller: controller,
                      autofocus: false,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (str) => str == null || str.isEmpty
                          ? 'Inserire un UID'
                          : str == userA.uid
                              ? 'Non puoi inviare la richiesta a te stesso'
                              : null,
                      decoration: InputDecoration(
                        helperText: "inserisci l'uid dell'allenatore",
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  if (userA.needsRequest)
                    TextFormField(
                      controller: _nameController,
                      decoration:
                          InputDecoration(helperText: "inserisci il tuo nome"),
                      textCapitalization: TextCapitalization.words,
                    ),
                  if (userA.hasRequest)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        AnimatedText(
                          text: 'in attesa di risposta',
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
                    label: Text(userA.coach == null ? 'invia' : 'cancella'),
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
