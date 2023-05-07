import 'package:atletica/global_widgets/animated_text.dart';
import 'package:atletica/global_widgets/preferences_button.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/refactoring/coach/src/view/target/target_category_icon.dart';
import 'package:atletica/refactoring/common/common.dart';
import 'package:atletica/refactoring/common/src/control/globals.dart';
import 'package:atletica/refactoring/common/src/view/enum_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:get/get.dart';

class RequestCoachRoute extends StatefulWidget {
  static const String routeName = '/athlete/request-coach';

  RequestCoachRoute();

  @override
  _RequestCoachRoute createState() => _RequestCoachRoute();
}

class _RequestCoachRoute extends State<RequestCoachRoute> {
  late final Callback callback = Callback((_, c) => setState(() {}));
  final TextEditingController controller = TextEditingController();
  final RxString _uid = ''.obs;

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

  bool get _isValid {
    return _uid.isNotEmpty &&
        Globals.helper.name != null &&
        Globals.helper.name!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Get off of this route
    // if (Globals.helper.hasCoach) WidgetsBinding.instance.addPostFrameCallback((_) => widget.onCoachFound());
    return PlatformScaffold(
      appBar: PlatformAppBar(
        automaticallyImplyLeading: false,
        title: Text(_request!),
        trailingActions: [PreferencesButton(context: context)],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_infoText != null)
                Text(_infoText!, textAlign: TextAlign.justify),
              const SizedBox(height: 10),
              // if (Globals.helper.needsRequest)
              PlatformTextField(
                controller: controller,
                autofocus: true,
                onChanged: (v) => _uid.value = v,
                /* 
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (str) => str == null || str.isEmpty
                    ? _insertUid
                    : str == Globals.helper.uid
                        ? _loopback
                        : null, */
                hintText: _insertUidPlaceholder,
                // onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 8),
              const EditableUserDisplayName(),
              /* PlatformTextField(
                autofocus: false,
                hintText: _insertNamePlaceholder,
                controller: _nameController,
                material: (context, platform) => MaterialTextFieldData(
                  decoration: InputDecoration(labelText: _insertNamePlaceholder),
                ),
                textCapitalization: TextCapitalization.words,
              ), */
              EnumSelector<TargetCategory>(
                values: TargetCategory.values,
                iconBuilder: (_, c) => TargetCategoryIcon(c),
                backgroundColor: (c) => c.color,
                leading: Text('Categoria:'),
              ),

              if (Globals.athlete.hasRequest)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    AnimatedText(
                      text: _waitingForResponse!,
                      // style: Theme.of(context).textTheme.headline6!.copyWith(color: Theme.of(context).primaryColorDark),
                    ),
                    Icon(Icons.check_circle, color: Colors.green)
                  ],
                ),
              const SizedBox(height: 10),
              /*Obx(
                () =>*/
              PlatformElevatedButton(
                onPressed: Globals.athlete.needsRequest
                    ? _isValid
                        ? () => Globals.athlete.requestCoach(
                              uid: controller.text,
                              nickname: Globals.helper.name!,
                            )
                        : null
                    : Globals.athlete.hasRequest
                        ? () => Globals.athlete.deleteCoachSubscription()
                        : null,
                child: Text(Globals.athlete.coach == null ? _send! : _cancel!),

                // label: Text(Globals.coach == null ? _send! : _cancel!),
                /* materialIcon: Icon(Globals.coach == null ? Icons.send : Icons.clear),
                  cupertinoIcon: Icon(Globals.coach == null ? CupertinoIcons.paperplane_fill : CupertinoIcons.clear), */
              ),
              //)
            ],
          ),
        ),
      ),
    );
  }
}
