import 'package:atletica/refactoring/common/common.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Globals {
  static User? _user;

  static User get user => _user ?? FirebaseAuth.instance.currentUser!;
  static set user(final User user) {
    assert(_user == null);
    _user = user;
  }

  static CoachHelper? _coach;

  static CoachHelper get coach => _coach!;
  static set coach(final CoachHelper coach) {
    assert(_coach == null && _athlete == null);
    _coach = coach;
  }

  static AthleteHelper? _athlete;

  static AthleteHelper get athlete => _athlete!;
  static set athlete(final AthleteHelper athlete) {
    assert(_coach == null && _athlete == null);
    _athlete = athlete;
  }

  static UserHelper get userHelper => _coach ?? _athlete!;
}
