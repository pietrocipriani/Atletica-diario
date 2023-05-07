import 'package:atletica/athlete_role/athlete_main_page.dart';
import 'package:atletica/athlete_role/request_coach.dart';
import 'package:atletica/coach_role/main.dart';
import 'package:atletica/refactoring/common/src/control/firebase/user_helper/user_helper.dart';
import 'package:atletica/refactoring/common/src/control/globals.dart';
import 'package:atletica/refactoring/common/src/model/role.dart';
import 'package:atletica/refactoring/common/src/view/enhanced_future_builder.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:get/get.dart';

/// The screen for choosing what is your role. When splitted it will be unnecessary.
class RoleGate extends StatelessWidget {
  static const String routeName = 'role-picker';

  @override
  Widget build(BuildContext context) {
    return EnhancedFutureBuilder<HelpersReturnType>(
      future: UserHelper.generateHelpers(Globals.user),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // TODO: loading page
          return Center(child: PlatformCircularProgressIndicator());
          // ModeSelectorRoute(userHelper: snapshot.data!);
        } else if (snapshot.hasError) {
          // TODO: error widget
          print(snapshot.error);
          print(snapshot.stackTrace);
          return SafeArea(
            child: Container(
              color: platformThemeData(
                context,
                material: (theme) => theme.colorScheme.error,
                cupertino: (theme) => CupertinoColors.systemRed,
              ),
              child: Text(snapshot.error.toString()),
            ),
          );
        } else {
          return Center(child: PlatformCircularProgressIndicator());
        }
      },
      onResult: (snapshot) {
        if (snapshot.hasData) {
          Globals.coach = snapshot.data!.coach;
          Globals.athlete = snapshot.data!.athlete;
          switch (Globals.role) {
            case Role.athlete:
              if (Globals.athlete.hasCoach) {
                Get.offNamed(AthleteMainPage.routeName);
              } else {
                Get.offNamed(RequestCoachRoute.routeName);
              }
              break;
            case Role.coach:
              Get.offNamed(CoachMainPage.routeName);
              break;
          }
          return false;
        }
        return true;
      },
    );
  }
}
