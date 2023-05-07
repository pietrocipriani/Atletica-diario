import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';

final FlutterLocalNotificationsPlugin notificationPlugin =
    FlutterLocalNotificationsPlugin();
// TODO: remember what this is for
final BehaviorSubject<String?> notificationSelected = BehaviorSubject();

Future<void> initNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('ic_launcher');

  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await notificationPlugin.initialize(
    initializationSettings,
    // TODO: onSelectNotification: (payload) => notificationSelected.add(payload),
  );
}
