import 'package:cloud_firestore/cloud_firestore.dart';

class _Reference<T> {}
typedef Collection<T> = List<T>;

class User {
  String name;
  _Reference<User>? coach;
  String? atleticaMeId;
  Timestamp? lastUpdate;
  @deprecated
  String? themeMode;
  bool? fictionalAthletes;
  bool? showAsAthlete;
  String? sesso;
  String? role;
  Collection<UserResult> results = [];

  User(
    this.name, [
    this.coach,
    this.atleticaMeId,
    this.lastUpdate,
    this.themeMode,
    this.fictionalAthletes,
    this.showAsAthlete,
    this.sesso,
    this.role,
  ]);
}

class UserResult {
  _Reference<User> coach;
  _Reference<UserTraining> training;
  List results;
  int? fatigue;
  String? info;
  Timestamp? date;

  UserResult(
    this.coach,
    this.training,
    this.results, [
    this.fatigue,
    this.info,
    this.date,
  ]);
}

class UserTemplate {
  double lastTarget;
  String? tipologia;

  UserTemplate(
    this.lastTarget, [
    this.tipologia,
  ]);
}

class UserRequest {
  String nickname;
  bool? accepted;

  UserRequest(
    this.nickname, [
    this.accepted,
  ]);
}

class UserAthlete {
  String nickname;
  String group;
  Collection<UserAthleteResult> results = [];

  UserAthlete(
    this.nickname,
    this.group,
  );
}

@deprecated
class UserAthleteResult {
  _Reference<User> coach;
  _Reference<UserTraining> training;
  List results;
  int? fatigue;
  String? info;
  Timestamp? date;

  UserAthleteResult(
    this.coach,
    this.training,
    this.results, [
    this.fatigue,
    this.info,
    this.date,
  ]);
}

class UserPlan {
  
}

class UserSchedule {}

class UserTraining {}
