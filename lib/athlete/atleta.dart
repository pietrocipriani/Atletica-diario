import 'dart:async';

import 'package:Atletica/athlete/athlete_dialog.dart';
import 'package:Atletica/athlete/group.dart';
import 'package:Atletica/training/allenamento.dart';
import 'package:Atletica/persistence/database.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqlite_api.dart';

class Atleta {
  final int id;
  String name;
  List<Allenamento> allenamenti = <Allenamento>[];

  Atleta(this.id, this.name);
  Atleta.parse(Map<String, dynamic> raw) : id = raw['id'] {
    name = raw['name'];
    groups.firstWhere((group) => group.id == raw['workGroup']).atleti.add(this);
  }

  static Future<bool> fromDialog(
      {@required BuildContext context, String name}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => dialog(context: context, name: name),
    );
  }

  static Future<Atleta> createSaveAddReturn({
    @required String name,
    @required Group group,
  }) async {
    final int id = await db.insert('Athletes', {
      'name': name,
      'workGroup': group.id,
    });
    final Atleta atleta = Atleta(id, name);
    group.atleti.add(atleta);
    return atleta;
  }

  Future<void> update({@required String name, @required Group group}) async {
    this.name = name;
    if (!group.atleti.contains(this)) {
      final currentGroup =
          groups.firstWhere((group) => group.atleti.contains(this));
      currentGroup.atleti.remove(this);
      group.atleti.add(this);
    }
    await db.update(
      'Athletes',
      {'name': name, 'workGroup': group.id},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// deleted `this` Atleta from both `db` and `currentGroup.atleti`.
  /// If `batch` is provided, it is used instead of `db`
  FutureOr<void> delete({Batch batch}) {
    final Group g = groups.firstWhere((group) => group.atleti.remove(this));
    bool shouldCommit = false;
    if (batch == null) {
      batch = db.batch();
      shouldCommit = true;
    }
    batch.delete('Athletes', where: 'id = ?', whereArgs: [id]);
    g.delete(batch: batch);
    if (shouldCommit) batch.commit();
  }

  Future<bool> modify({@required BuildContext context}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => dialog(context: context, atleta: this),
    );
  }
}
