import 'dart:async';

import 'package:Atletica/athlete/group.dart';
import 'package:Atletica/training/allenamento.dart';
import 'package:Atletica/athlete/atleta.dart';
import 'package:Atletica/ripetuta/ripetuta.dart';
import 'package:Atletica/plan/tabella.dart';
import 'package:sqflite/sqflite.dart';

Database db;

FutureOr<void> init() async {
  db = await openDatabase(
    'atletica.db',
    version: 1,
    onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    },
    onCreate: (db, version) async {
      Batch b = db.batch();
      b.execute('''CREATE TABLE Templates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(50) UNIQUE NOT NULL,
        tipologia VARCHAR(100) NOT NULL,
        lastTarget REAL,
        lastRecupero INT
      );''');
      b.execute('''CREATE TABLE Plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL
      );''');
      b.execute('''CREATE TABLE Trainings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        description TEXT
      )''');
      b.execute('''CREATE TABLE Weeks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan INT NOT NULL,
        position INT NOT NULL,
        lun INT, mar INT, mer INT, gio INT, ven INT, sab INT, dom INT,
        FOREIGN KEY (plan) REFERENCES Plans(id),
        FOREIGN KEY (lun) REFERENCES Trainings(id),
        FOREIGN KEY (mar) REFERENCES Trainings(id),
        FOREIGN KEY (mer) REFERENCES Trainings(id),
        FOREIGN KEY (gio) REFERENCES Trainings(id),
        FOREIGN KEY (ven) REFERENCES Trainings(id),
        FOREIGN KEY (sab) REFERENCES Trainings(id),
        FOREIGN KEY (dom) REFERENCES Trainings(id)
      );''');
      b.execute('''CREATE TABLE Series (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        allenamento INT NOT NULL,
        position INT NOT NULL,
        recupero INT DEFAULT 180,
        times INT DEFAULT 1,
        recuperoNext INT DEFAULT 180,
        FOREIGN KEY (allenamento) REFERENCES Trainings(id)
      );''');
      b.execute('''CREATE TABLE Ripetute (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        template INT NOT NULL,
        serie INT NOT NULL,
        position INT NOT NULL,
        target REAL,
        recupero INT DEFAULT 180,
        times INT DEFAULT 1,
        recuperoNext INT DEFAULT 180,
        FOREIGN KEY (template) REFERENCES Templates(id),
        FOREIGN KEY (serie) REFERENCES Series(id)
      );''');
      b.execute('''CREATE TABLE Groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        currentPlan INT,
        started TEXT,
        FOREIGN KEY (currentPlan) REFERENCES Plans(id)
      );''');
      b.execute('''CREATE TABLE Athletes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        workGroup INT NOT NULL,
        FOREIGN KEY (workGroup) REFERENCES Groups(id)
      );''');

      [50, 60, 80, 100, 120, 150, 200, 250, 300, 400, 500, 600, 800, 1000, 1200]
          .forEach((value) {
        b.insert('Templates', {
          'name': '$value M',
          'tipologia': Tipologia.corsaDist.name,
        });
      });
      b.insert('Groups', {
        'name': 'generico',
      });
      await b.commit();
    },
    onOpen: (db) async {
      templates =
          (await db.query('Templates')).map((e) => Template.from(e)).toList();

      groups = (await db.query(
        'Groups LEFT JOIN Plans ON Groups.currentPlan = Plans.id',
        columns: [
          'Groups.id',
          'Groups.name',
          'Plans.name AS planName',
          'Groups.started'
        ],
      ))
          .map((e) => Group.parse(e))
          .toList();

      (await db.query('Athletes', orderBy: 'name'))
          .forEach((raw) => Atleta.parse(raw));

      allenamenti = (await db.query('Trainings'))
          .map((raw) => Allenamento.parse(raw))
          .toList();
      (await db.query('Series', orderBy: 'allenamento, position'))
          .forEach((raw) => Serie.parse(raw));
      (await db.query('Ripetute LEFT JOIN Series ON Ripetute.serie = Series.id',
              columns: ['Ripetute.*', 'Series.allenamento'],
              orderBy: 'serie, position'))
          .forEach((raw) => Ripetuta.parse(raw));
      plans =
          (await db.query('Plans')).map((raw) => Tabella.parse(raw)).toList();
      (await db.query('Weeks', orderBy: 'plan, position')).forEach((raw) => Week.parse(raw));
    },
  );
}
