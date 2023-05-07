import 'package:atletica/athlete_role/athlete_main_page.dart';
import 'package:atletica/coach_role/main.dart';
import 'package:atletica/refactoring/common/common.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class Globals {
  static User? _user;
  static Role role = Role.coach;

  /// Switches the current role. If the user was without role, no role is picked.
  /// The role is switched synchronously, the changes on the database are asynchronous.
  static Future<void> switchRole() async {
    switch (role) {
      case Role.athlete:
        role = Role.coach;
        Get.offNamed(CoachMainPage.routeName);
        break;
      case Role.coach:
        role = Role.athlete;
        Get.offNamed(AthleteMainPage.routeName);
        break;
    }
    await helper.userReference.update({'role': role.name});
  }

  static User get user => _user ?? FirebaseAuth.instance.currentUser!;
  static set user(final User user) {
    assert(_user == null);
    _user = user;
  }

  static AthleteHelper? _athlete;
  // TODO: is it safe?
  static AthleteHelper get athlete => _athlete!;
  static set athlete(final AthleteHelper athlete) {
    assert(_athlete == null);
    _athlete = athlete;
  }

  static CoachHelper? _coach;
  // TODO: is it safe?
  static CoachHelper get coach => _coach!;
  static set coach(final CoachHelper coach) {
    assert(_coach == null);
    _coach = coach;
  }

  static UserHelper get helper {
    switch (role) {
      case Role.athlete:
        return athlete;
      case Role.coach:
        return coach;
    }
  }

  /// destroys the helper before logging out
  static void logout() {
    _coach?.logout();
    _athlete?.logout();
    _coach = _athlete = null;
  }
}
