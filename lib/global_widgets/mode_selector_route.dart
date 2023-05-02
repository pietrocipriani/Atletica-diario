import 'package:atletica/coach_role/main.dart';
import 'package:atletica/refactoring/common/common.dart';
import 'package:atletica/refactoring/common/src/model/role.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:get/get.dart';

/* Future<void> showModeSelectorRoute({required BuildContext context}) => showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Ruolo'),
        content: ModeSelectorRoute(),
      ),
    ); */

class ModeSelectorRoute extends StatelessWidget {
  final UserHelper userHelper;

  ModeSelectorRoute({required this.userHelper});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context)!;
    final String coachInfo = loc.coachRoleInfoText;
    final String athleteInfo = loc.athleteRoleInfoText;
    final String coach = loc.coach;
    final String athlete = loc.athlete;

    return Padding(
      padding: MediaQuery.of(context).padding,
      child: PlatformScaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: DottedBorder(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      Text(
                        coachInfo,
                        textAlign: TextAlign.center,
                        // style: Theme.of(context).textTheme.overline,
                      ),
                      PlatformElevatedButton(
                        onPressed: () async {
                          Get.put<CoachHelper>(await userHelper.setRole(Role.coach), tag: 'coachHelper', permanent: true);
                          Get.offNamed('/coach');
                        },
                        child: Text(coach.toUpperCase()),
                      ),
                    ],
                  ),
                  borderType: BorderType.RRect,
                  radius: Radius.circular(20),
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey,
                  dashPattern: [6, 4],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: DottedBorder(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      Text(
                        athleteInfo,
                        textAlign: TextAlign.center,
                        // style: Theme.of(context).textTheme.overline,
                      ),
                      PlatformElevatedButton(
                        onPressed: () async {
                          Get.put<AthleteHelper>(await userHelper.setRole(Role.athlete), tag: 'athleteHelper', permanent: true);
                          Get.offNamed('/athlete');
                        },
                        child: Text(athlete.toUpperCase()),
                      ),
                    ],
                  ),
                  borderType: BorderType.RRect,
                  radius: Radius.circular(20),
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey,
                  dashPattern: [6, 4],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
