import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:app_installer/app_installer.dart';
import 'package:atletica/main.dart';
import 'package:atletica/refactoring/common/src/control/notifications/notifications.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

class Release {
  final Reference ref;
  final String versionName;
  final int versionCode;
  final String changelog;
  final DateTime uploadTime;
  final Uint8List? md5;

  Release({
    required this.ref,
    required this.versionName,
    required this.versionCode,
    required final String changelog,
    required this.uploadTime,
    final String? md5,
  })  : changelog = changelog.replaceAll(RegExp(r'^\*\s*', multiLine: true), ' \u{2022} '),
        md5 = md5 == null ? null : base64.decode(md5);
}

StreamSubscription<String?>? _subscription;

Release? release;

Future<void> checkAndInstallNewRelease() async {
  release ??= await checkNewRelease();
  if (release == null) return;
  _subscription ??= notificationSelected.listen((payload) async {
    if (payload != 'install-release') return;
    if (release != null) if (!(await installRelease(release!))) _showErrorNotification(release!);
  });
  await _showNotification(release!);
}

Future<Release?> checkNewRelease() async {
  if (kIsWeb || !Platform.isAndroid) return null;
  try {
    final Reference release = FirebaseStorage.instance.ref('release/release.apk');
    final FullMetadata meta = await release.getMetadata();

    final PackageInfo package = await PackageInfo.fromPlatform();
    final int currentVersion = int.parse(package.buildNumber);

    final int lastVersion = int.parse(meta.customMetadata!['version-code']!);

    if (lastVersion <= currentVersion) {
      print('$lastVersion vs $currentVersion');
      return null;
    }

    return Release(
      ref: release,
      versionName: meta.customMetadata!['version-name']!,
      versionCode: lastVersion,
      changelog: meta.customMetadata!['changelog']!,
      uploadTime: meta.updated!,
      md5: meta.md5Hash,
    );
    /*final Future<bool?> dialog = showNewReleaseDialog(
      context: context,
      version: meta.customMetadata!['version-name']!,
      changelog: meta.customMetadata!['changelog']!,
      updateTime: meta.updated!,
    );*/
  } catch (e, s) {
    print(e);
    print(s);
    return null;
  }
}

Future<bool> installRelease(final Release release) async {
  try {
    final Directory dir = await getTemporaryDirectory();
    final File rel = File('${dir.path}${Platform.pathSeparator}release.apk');
    if (!rel.existsSync()) rel.createSync(recursive: true);

    final Uint8List? data = await release.ref.getData(100 * 1024 * 1024);
    if (data == null) return false;
    if (release.md5 != null) {
      final Digest dataMd5 = md5.convert(data);
      if (!listEquals(dataMd5.bytes, release.md5)) return false;
    }
    rel.writeAsBytesSync(data, flush: true);

    await AppInstaller.installApk(rel.path);
    return true;
  } catch (e, s) {
    print(e);
    print(s);
    return false;
  }
}

Future<void> _showErrorNotification(final Release release) async {
  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'new-release',
    'update notification',
    channelDescription: 'shows notifications when a new app version is avaiable',
    ticker: 'update error',
    onlyAlertOnce: true,
    showWhen: true,
    when: release.uploadTime.millisecondsSinceEpoch,
  );
  final NotificationDetails details = NotificationDetails(android: androidDetails);
  await notificationPlugin.show(
    1,
    'ERROR',
    'error during the installation of version ${release.versionName}',
    details,
    payload: 'install-release',
  );
}

Future<void> _showNotification(final Release release) async {
  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'new-release',
    'update notification',
    channelDescription: 'shows notifications when a new app version is avaiable',
    ticker: 'new release avaiable',
    visibility: NotificationVisibility.public,
    styleInformation: BigTextStyleInformation(release.changelog),
    onlyAlertOnce: true,
    showWhen: true,
    when: release.uploadTime.millisecondsSinceEpoch,
  );
  final NotificationDetails details = NotificationDetails(android: androidDetails);
  await notificationPlugin.show(
    0,
    'NEW RELEASE ${release.versionName}',
    release.changelog,
    details,
    payload: 'install-release',
  );
}
