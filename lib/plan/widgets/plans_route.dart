import 'package:atletica/persistence/auth.dart';
import 'package:atletica/plan/plan.dart';
import 'package:atletica/plan/widgets/plan_widget.dart';
import 'package:flutter/material.dart';

class PlansRoute extends StatefulWidget {
  @override
  _PlansRouteState createState() => _PlansRouteState();
}

class _PlansRouteState extends State<PlansRoute>
    with SingleTickerProviderStateMixin {
  late final Callback callback = Callback((_, c) => setState(() {}));

  @override
  void initState() {
    Plan.signInGlobal(callback);
    super.initState();
  }

  @override
  void dispose() {
    Plan.signOutGlobal(callback.stopListening);
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
          if (await Plan.fromDialog(context: context)) setState(() {});
        },
        child: Icon(Icons.add),
        mini: true,
      ),
      body: ListView(
        children: Plan.plans.map((plan) => PlanWidget(plan)).toList(),
      ),
    );
  }
}
