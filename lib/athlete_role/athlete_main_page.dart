import 'package:atletica/athlete_role/request_coach.dart';
import 'package:atletica/global_widgets/custom_main_page.dart';
import 'package:atletica/refactoring/common/src/control/globals.dart';
import 'package:atletica/results/result.dart';
import 'package:atletica/date.dart';
import 'package:atletica/global_widgets/custom_expansion_tile.dart';
import 'package:atletica/results/results_edit_dialog.dart';
import 'package:atletica/schedule/schedule.dart';
import 'package:atletica/training/training_description.dart';
import 'package:flutter/material.dart';
import 'package:mdi/mdi.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AthleteMainPage extends StatefulWidget {
  @override
  _AthleteMainPageState createState() => _AthleteMainPageState();
}

class _AthleteMainPageState extends State<AthleteMainPage> {
  String? section;
  @override
  void didChangeDependencies() {
    final AppLocalizations loc = AppLocalizations.of(context)!;
    section = loc.athlete;
    super.didChangeDependencies();
  }

  @override
  Widget build(final BuildContext context) {
    return CustomMainPage(
      section: section!,
      events: (dt) => Result.ofDate(dt).where((r) => r.isOrphan).cast<Object>().followedBy(ScheduledTraining.ofDate(dt).where((st) => st.athletesRefs.isEmpty || st.athletesRefs.any((r) => r == Globals.athlete.athleteCoachReference))).toList(),
      eventBuilder: (e) {
        if (e is ScheduledTraining)
          return TrainingWidget(
            scheduledTraining: e,
            checkbox: true,
            result: Result.ofSchedule(e),
          );
        else if (e is Result) return _ResultWidget(e);
        throw TypeError();
      },
    );
  }
}

class _ResultWidget extends StatelessWidget {
  final Result _result;
  _ResultWidget(this._result);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return CustomExpansionTile(
      title: _result.training,
      titleDecoration: TextDecoration.lineThrough,
      trailing: IconButton(
        icon: Icon(Mdi.poll),
        onPressed: Date.now() >= _result.date ? () => showResultsEditDialog(context, _result, Globals.athlete.saveResult) : null,
        color: theme.iconTheme.color,
      ),
      leading: Checkbox(
        value: true,
        onChanged: null,
        fillColor: MaterialStateProperty.all(theme.toggleableActiveColor),
        checkColor: theme.colorScheme.onPrimary,
      ),
      children: TrainingDescription.fromResults(_result).toList(),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
    );
  }
}
