import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/persistence/user_helper/coach_helper.dart';
import 'package:Atletica/plan/tabella.dart';
import 'package:Atletica/plan/widgets/plan_widget.dart';
import 'package:flutter/material.dart';

class PlansRoute extends StatefulWidget {
  @override
  _PlansRouteState createState() => _PlansRouteState();
}

class _PlansRouteState extends State<PlansRoute>
    with SingleTickerProviderStateMixin {
  final Callback callback = Callback();

  @override
  void initState() {
    callback.f = (_) => setState(() {});
    CoachHelper.onPlansCallbacks.add(callback);
    super.initState();
  }

  @override
  void dispose() {
    CoachHelper.onPlansCallbacks.remove(callback.stopListening);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PIANI DI LAVORO'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (await Tabella.fromDialog(context: context)) setState(() {});
        },
        child: Icon(Icons.add),
      ),
      body: ListView(
        children: plans.values.map((plan) => PlanWidget(plan)).toList(),
      ),
    );
  }
}
