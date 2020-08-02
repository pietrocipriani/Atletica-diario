import 'package:AtleticaCoach/global_widgets/alert_point.dart';
import 'package:AtleticaCoach/global_widgets/custom_list_tile.dart';
import 'package:AtleticaCoach/global_widgets/link_line/link_line.dart';
import 'package:AtleticaCoach/main.dart';
import 'package:AtleticaCoach/ripetuta/template.dart';
import 'package:AtleticaCoach/schedule/schedule.dart';
import 'package:AtleticaCoach/training/allenamento.dart';
import 'package:AtleticaCoach/athlete/atleta.dart';
import 'package:AtleticaCoach/ripetuta/ripetuta.dart';
import 'package:AtleticaCoach/global_widgets/stopwatch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:vibration/vibration.dart';

final int kCriticRemainingTime = 10;
final List<RunningTraining> runningTrainings = <RunningTraining>[];

bool _alreadyInserted(Schedule schedule) =>
    runningTrainings.any((rt) => rt.schedule == schedule);

void updateFromSchedules() {
  runningTrainings.removeWhere((rt) =>
      !schedules.containsKey(rt.schedule.reference) ||
      rt.schedule.athletes.isEmpty);
  schedules.values.where((s) => s.athletes.isNotEmpty).forEach((schedule) {
    if (_alreadyInserted(schedule)) return;
    final RunningTraining rt = RunningTraining.fromSchedule(schedule);
    if (rt != null) runningTrainings.add(rt);
  });
}

class RunningTraining extends StatefulWidget {
  final Schedule schedule;
  final Allenamento allenamento;

  RunningTraining(this.schedule, this.allenamento)
      : assert(allenamento != null);

  static RunningTraining fromSchedule(final Schedule schedule) {
    Allenamento training = schedule.todayTraining;
    if (training == null) return null;
    return RunningTraining(schedule, training);
  }

  bool get expired => schedule.todayTraining != allenamento;

  @override
  _RunningTrainingState createState() => _RunningTrainingState();
}

final Path play = Path()
  ..moveTo(20, 20)
  ..lineTo(20, 80)
  ..lineTo(80, 50)
  ..close();
final Path stop = Path()
  ..moveTo(20, 20)
  ..lineTo(20, 80)
  ..lineTo(80, 80)
  ..lineTo(80, 20)
  ..close();
final Path lap = Path()
  ..moveTo(50, 50)
  ..addOval(
    Rect.fromCenter(center: const Offset(0, 0), width: 60, height: 60),
  )
  ..relativeLineTo(0, -25)
  ..moveTo(40, 15)
  ..lineTo(60, 15);

class _RunningTrainingState extends State<RunningTraining>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _opacityAnim, _sizeAnimation;

  DateTime recuperoStartTime;
  bool _overtimeNotified = false;
  bool _criticNotified = false;
  Ticker t;
  int current = 0;
  Ripetuta rip;
  int rec;

  Map<Ripetuta, Map<Athlete, double>> results =
      <Ripetuta, Map<Athlete, double>>{};

  @override
  void initState() {
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _opacityAnim = Tween<double>(begin: 1, end: 0).animate(_controller);
    _sizeAnimation = Tween<double>(begin: 1, end: 2).animate(_controller);
    _next();
    results[rip] = <Athlete, double>{};
    t = Ticker((elapsed) => setState(() {}));
    t.start();
    super.initState();
  }

  void _next() {
    rip = widget.allenamento.ripetutaFromIndex(current);
    rec = widget.allenamento.recuperoFromIndex(current++)?.recupero;
    _overtimeNotified = _criticNotified = false;

    if (rec == null || rec < 10)
      _controller.repeat(reverse: true);
    else if (_controller.isAnimating) _controller.stop();

    if (rip == null) {
      runningTrainings.remove(widget);
      if (widget.schedule is TrainingSchedule)
        schedules.remove(widget.schedule);
      context.findAncestorStateOfType<MyHomePageState>().setState(() {});
    } else {
      results[rip] = <Athlete, double>{};
    }
  }

  @override
  void dispose() {
    t.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double remainingTime = recuperoStartTime == null || rec == null
        ? null
        : rec -
            DateTime.now().difference(recuperoStartTime).inMilliseconds / 1000;
    if (!_overtimeNotified && remainingTime != null && remainingTime < 0) {
      if (canVibrate) Vibration.vibrate(duration: 500);
      _overtimeNotified = true;
    }
    if (!_criticNotified &&
        remainingTime != null &&
        remainingTime < kCriticRemainingTime) {
      if (canVibrate) Vibration.vibrate(pattern: [0, 100, 100, 200]);
      _criticNotified = true;
    }
    double progress = remainingTime == null || remainingTime < 0
        ? null
        : 1 - remainingTime / rec;
    String timerString = tickerProvider.ticker?.isActive ?? false
        ? '${tickerProvider.elapsed.inMinutes}:${((tickerProvider.elapsed.inMilliseconds / 1000) % 60).toStringAsFixed(2).padLeft(5, '0')}"'
        : remainingTime == null
            ? '0:00'
            : '${remainingTime < 0 ? '-' : ''}${remainingTime.abs() ~/ 60}:${(remainingTime.abs() % 60).floor().toString().padLeft(2, '0')}';
    Widget title = Text(
      timerString,
      style: TextStyle(
        color: tickerProvider.ticker?.isActive ?? false
            ? null
            : remainingTime != null && remainingTime < 0
                ? Colors.red
                : rec == null
                    ? Color.fromRGBO(0, 0, 0, _opacityAnim.value)
                    : null,
        fontWeight: FontWeight.bold,
      ),
    );
    if (remainingTime != null &&
        remainingTime < kCriticRemainingTime &&
        remainingTime >= 0) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
      title = Transform.scale(
        scale: _sizeAnimation.value,
        child: title,
        alignment: Alignment.centerLeft,
      );
    } else if (remainingTime != null && remainingTime < 0) if (_controller
        .isAnimating) _controller.stop();
    return Dismissible(
      key: ValueKey(this),
      child: Column(
        children: <Widget>[
          CustomListTile(
            onTap: () => _timerDialog(context: context, rip: rip),
            title: title,
            leading: tickerProvider.ticker?.isActive ?? false
                ? TimerRunningIcon()
                : remainingTime != null && remainingTime < 0
                    ? Container(
                        child: AlertPoint(),
                        width: 10,
                        height: 10,
                      )
                    : null,
            subtitle: RichText(
              text: TextSpan(
                text: remainingTime != null && remainingTime > 0
                    ? 'seguito da '
                    : null,
                style: Theme.of(context)
                    .textTheme
                    .overline
                    .copyWith(color: Theme.of(context).primaryColorDark),
                children: [
                  TextSpan(
                    text: rip?.template ?? 'nulla',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  if (rip?.target != null) TextSpan(text: ' in '),
                  if (rip?.target != null)
                    TextSpan(
                      text: templates[rip.template]
                          .tipologia
                          .targetFormatter(rip.target),
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                ],
              ),
            ),
            /*trailing: IconButton(
              icon: Icon(Icons.skip_next),
              onPressed: remainingTime == null || remainingTime < 0
                  ? () {
                      setState(() {
                        recuperoStartTime = DateTime.now();
                        _next();
                      });
                    }
                  : null,
              disabledColor: Colors.black12,
              color: Colors.black,
            ),*/
          ),
          Container(
            height: 1,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            ),
          ),
        ],
      ),
      confirmDismiss: (direction) => Future.value(false),
    );
  }

  TickerProvider tickerProvider = TickerProvider();
  bool showResults = false;
  List<double> rawResults = <double>[];

  void _timerDialog(
      {@required BuildContext context, @required Ripetuta rip}) async {
    bool Function() lap = () {
      if (!tickerProvider.ticker.isActive) return false;
      rawResults.add(tickerProvider.elapsed.inMilliseconds / 1000);
      tickerProvider.lap();
      if (canVibrate) Vibration.vibrate(duration: 100);
      return true;
    };
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          scrollable: showResults ? true : false,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('CRONOMETRO'),
          content: showResults
              ? LinkLine(
                  results: rawResults,
                  rip: rip,
                  athletes: widget.schedule.athletes,
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    GestureDetector(
                      child: StopWatch(ticker: tickerProvider),
                      onTap: () {
                        if (!lap()) {
                          tickerProvider.ticker.start();
                          if (canVibrate) Vibration.vibrate(duration: 100);
                          setState(() {});
                        }
                      },
                    ),
                    Row(children: [
                      Expanded(
                        child: OutlineButton(
                          child: Icon(
                              tickerProvider.ticker?.isActive ?? false
                                  ? Icons.timer
                                  : Icons.play_arrow,
                              size: 36,
                              color: Colors.black),
                          padding: const EdgeInsets.all(16),
                          onPressed: () {
                            if (!lap()) {
                              tickerProvider.ticker.start();
                              if (canVibrate) Vibration.vibrate(duration: 100);
                              setState(() {});
                            }
                          },
                          shape: CircleBorder(),
                          borderSide: BorderSide(color: Colors.grey[300]),
                        ),
                      ),
                      Expanded(
                          child: Container(
                        height: 1,
                        color: Colors.grey[300],
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      )),
                      Expanded(
                        child: OutlineButton(
                          child: Icon(
                            Icons.stop,
                            size: 36,
                            color: tickerProvider.ticker?.isActive ?? false
                                ? Colors.red
                                : Colors.grey[300],
                          ),
                          padding: const EdgeInsets.all(16),
                          onPressed: tickerProvider.ticker?.isActive ?? false
                              ? () {
                                  if (canVibrate)
                                    Vibration.vibrate(duration: 200);
                                  tickerProvider.ticker.stop();
                                  showResults = true;
                                  rawResults.add(
                                      tickerProvider.elapsed.inMilliseconds /
                                          1000);
                                  rawResults.add(double.nan);
                                  setState(() {});

                                  this.setState(() {
                                    recuperoStartTime = DateTime.now();
                                    _next();
                                  });
                                  if (rip == null) {
                                    runningTrainings.remove(widget);
                                    context
                                        .findAncestorStateOfType<
                                            MyHomePageState>()
                                        .setState(() {});
                                  } else {
                                    this.results[rip] = <Athlete, double>{};
                                  }
                                }
                              : null,
                          shape: CircleBorder(),
                          borderSide: BorderSide(color: Colors.grey[300]),
                        ),
                      ),
                    ])
                  ],
                ),
        ),
      ),
    );
    if (showResults) {
      showResults = false;
      tickerProvider = TickerProvider();
      rawResults = <double>[];
    }
  }
}

class TickerProvider {
  Ticker ticker;
  Duration elapsed = Duration();
  bool muted = false;

  void Function(Duration elapsed) lapCallBack;

  Ticker createTicker(void Function() onTick) {
    Ticker ticker = Ticker((elapsed) {
      this.elapsed = elapsed;
      if (!muted) onTick?.call();
    });
    if (this.ticker != null) ticker.absorbTicker(this.ticker);
    muted = false;
    return this.ticker = ticker;
  }

  void lap() {
    lapCallBack?.call(elapsed);
  }
}
