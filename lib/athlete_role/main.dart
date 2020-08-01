import 'package:AtleticaCoach/athlete_role/request_coach.dart';
import 'package:AtleticaCoach/persistence/auth.dart';
import 'package:flutter/material.dart';

class AthleteMainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!userA.hasCoach)
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RequestCoachRoute()),
        ),
      );
    return Scaffold();
  }
}
