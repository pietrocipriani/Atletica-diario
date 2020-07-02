import 'package:Atletica/athlete_role/request_coach.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:flutter/material.dart';

class AthleteMainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (userA.coach == null || userA.coach is CoachRequest)
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RequestCoachRoute()),
        ),
      );
    return Scaffold();
  }
}
