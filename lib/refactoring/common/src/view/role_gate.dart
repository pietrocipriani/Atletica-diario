import 'package:atletica/athlete_role/request_coach.dart';
import 'package:atletica/global_widgets/mode_selector_route.dart';
import 'package:atletica/refactoring/common/src/control/firebase/user_helper/athlete_helper.dart';
import 'package:atletica/refactoring/common/src/control/firebase/user_helper/coach_helper.dart';
import 'package:atletica/refactoring/common/src/control/firebase/user_helper/user_helper.dart';
import 'package:atletica/refactoring/common/src/control/globals.dart';
import 'package:atletica/refactoring/common/src/view/enhanced_future_builder.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:get/get.dart';

class RoleGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('role picker widget');
    return EnhancedFutureBuilder<UserHelper>(
      future: UserHelper.of(Globals.user),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ModeSelectorRoute(userHelper: snapshot.data!);
        } else if (snapshot.hasError) {
          // TODO: error widget
          print(snapshot.error);
          print(snapshot.stackTrace);
          return SafeArea(
            child: Container(
              color: platformThemeData(
                context,
                material: (theme) => theme.errorColor,
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
        if (snapshot.hasData && (snapshot.data is CoachHelper || snapshot.data is AthleteHelper)) {
          if (snapshot.data is CoachHelper) {
            Globals.coach = snapshot.data as CoachHelper;
            Get.offNamed('/coach');
          } else if (snapshot.data is AthleteHelper) {
            Globals.athlete = snapshot.data as AthleteHelper;
            if (Globals.athlete.hasCoach) {
              Get.offNamed('/athlete');
            } else {
              Get.offNamed(RequestCoachRoute.routeName);
            }
          }
          return false;
        }
        return true;
      },
    );
  }
}
