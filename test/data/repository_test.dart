import 'dart:io';
import 'package:bloom/data/bloom_repository.dart';
import 'package:bloom/integration/bloom_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

HabitDraft habit({String title = 'Read', int daily = 20, int weekly = 3}) =>
    HabitDraft(
      title: title,
      category: 'Learning',
      unit: 'pages',
      dailyTarget: daily,
      weeklyTarget: weekly,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Directory dir;
  late BloomRepository repo;
  late DateTime now;
  late SharedPreferences prefs;
  late String path;
  Future<void> reopen() async {
    repo = await BloomRepository.open(
      path: path,
      factory: databaseFactoryFfi,
      preferences: prefs,
      clock: () => now,
    );
  }

  Future<int> addHabit() async {
    await repo.createHabit(habit());
    return (await repo.load()).habits.last.id;
  }

  CheckInDraft entry(
    int id, {
    DateTime? day,
    int progress = 0,
    CheckInStatus status = CheckInStatus.started,
    String note = '',
  }) => CheckInDraft(
    habitId: id,
    day: day ?? now,
    progress: progress,
    status: status,
    note: note,
  );

  setUp(() async {
    now = DateTime(2026, 10, 13, 10);
    dir = await Directory.systemTemp.createTemp('bloom_data_');
    path = '${dir.path}/test.db';
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await reopen();
  });
  tearDown(() async {
    await repo.close();
    await dir.delete(recursive: true);
  });

  test('habit CRUD, archival and immutable snapshots', () async {
    expect((await repo.load()).habits, isEmpty);
    await repo.createHabit(habit(title: '  Read  '));
    final first = (await repo.load()).habits.single;
    expect(first.title, 'Read');
    expect(first.createdAt, DateTime(2026, 10, 13));
    await repo.updateHabit(
      first.id,
      habit(title: 'Walk', daily: 10, weekly: 5),
    );
    expect((await repo.getHabit(first.id)).weeklyTarget, 5);
    await repo.setArchived(first.id, true);
    expect((await repo.getHabit(first.id)).archived, true);
    await repo.deleteHabit(first.id);
    expect((await repo.load()).habits, isEmpty);
    await expectLater(repo.getHabit(first.id), throwsStateError);
  });

  test('check-in CRUD/correction; child delete preserves parent', () async {
    final id = await addHabit();
    await repo.createCheckIn(entry(id, note: 'start'));
    final saved = (await repo.load()).checkIns.single;
    expect((await repo.getCheckIn(saved.id)).note, 'start');
    now = DateTime(2026, 10, 14);
    await repo.updateCheckIn(
      saved.id,
      entry(
        id,
        progress: 20,
        status: CheckInStatus.completed,
        note: 'correction',
      ),
    );
    final corrected = await repo.getCheckIn(saved.id);
    expect(corrected.day, now);
    expect(corrected.status, CheckInStatus.completed);
    expect(corrected.note, 'correction');
    await repo.deleteCheckIn(saved.id);
    expect((await repo.load()).checkIns, isEmpty);
    expect((await repo.getHabit(id)).id, id);
  });

  test(
    'invalid titles, targets and missing IDs fail without records',
    () async {
      for (final draft in [
        habit(title: ' \n '),
        habit(daily: 0),
        habit(daily: -1),
        habit(daily: 100001),
        habit(weekly: 0),
        habit(weekly: 8),
      ]) {
        await expectLater(repo.createHabit(draft), throwsArgumentError);
      }
      expect((await repo.load()).habits, isEmpty);
      await expectLater(repo.updateHabit(9, habit()), throwsStateError);
      await expectLater(repo.deleteHabit(9), throwsStateError);
      await expectLater(repo.deleteCheckIn(9), throwsStateError);
      await expectLater(repo.createCheckIn(entry(9)), throwsStateError);
    },
  );

  test(
    'progress/status/date validation and duplicate correction rollback',
    () async {
      final id = await addHabit();
      for (final draft in [
        entry(id, progress: -1),
        entry(id, progress: 21),
        entry(id, progress: 1),
        entry(id, status: CheckInStatus.completed),
        entry(id, status: CheckInStatus.inProgress),
        entry(id, day: DateTime(2026, 10, 12)),
        entry(id, day: DateTime(2026, 10, 14)),
        entry(id, day: DateTime.utc(2026, 10, 13)),
      ]) {
        await expectLater(repo.createCheckIn(draft), throwsArgumentError);
      }
      await repo.createCheckIn(entry(id));
      await expectLater(
        repo.createCheckIn(entry(id, day: DateTime(2026, 10, 13, 23, 59))),
        throwsA(isA<DatabaseException>()),
      );
      final first = (await repo.load()).checkIns.single;
      now = DateTime(2026, 10, 14);
      await repo.createCheckIn(entry(id));
      await expectLater(
        repo.updateCheckIn(first.id, entry(id, note: 'must roll back')),
        throwsA(isA<DatabaseException>()),
      );
      expect((await repo.getCheckIn(first.id)).note, '');
      expect((await repo.load()).checkIns, hasLength(2));
    },
  );

  test(
    'Start/resume, Finish guard, demotion, Reset affects one day only',
    () async {
      final id = await addHabit();
      await expectLater(repo.updateProgress(id, now, 1), throwsStateError);
      await Future.wait(List.generate(5, (_) => repo.start(id, now)));
      expect((await repo.load()).checkIns, hasLength(1));
      await expectLater(repo.finish(id, now), throwsStateError);
      await repo.updateProgress(id, now, 20);
      expect(
        (await repo.load()).checkIns.single.status,
        CheckInStatus.inProgress,
      );
      await repo.finish(id, now);
      await repo.start(id, now);
      expect(
        (await repo.load()).checkIns.single.status,
        CheckInStatus.completed,
      );
      await repo.updateProgress(id, now, 19);
      expect(
        (await repo.load()).checkIns.single.status,
        CheckInStatus.inProgress,
      );
      await repo.updateProgress(id, now, 20);
      await repo.finish(id, now);
      now = DateTime(2026, 10, 14);
      await repo.start(id, now);
      await repo.updateProgress(id, now, 12);
      await repo.reset(id, now);
      final entries = (await repo.load()).checkIns;
      expect(entries.first.status, CheckInStatus.completed);
      expect(entries.last.progress, 0);
      expect(entries.last.status, CheckInStatus.started);
    },
  );

  test('target edits atomically normalize existing entries', () async {
    final id = await addHabit();
    await repo.createCheckIn(
      entry(id, progress: 20, status: CheckInStatus.completed),
    );
    await repo.updateHabit(id, habit(daily: 10));
    expect((await repo.load()).checkIns.single.progress, 10);
    expect((await repo.load()).checkIns.single.status, CheckInStatus.completed);
    await repo.updateHabit(id, habit(daily: 30));
    expect(
      (await repo.load()).checkIns.single.status,
      CheckInStatus.inProgress,
    );
    await expectLater(
      repo.updateHabit(id, habit(daily: 0)),
      throwsArgumentError,
    );
    expect((await repo.getHabit(id)).dailyTarget, 30);
  });

  test(
    'raw SQLite enforces FK, unique, status, bounds, dates and cascade',
    () async {
      final id = await addHabit();
      final db = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          singleInstance: false,
          onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
        ),
      );
      try {
        expect(
          (await db.rawQuery('PRAGMA foreign_keys')).single.values.single,
          1,
        );
        final row = {
          'habit_id': id,
          'date': '2026-10-13',
          'progress': 0,
          'status': 'started',
        };
        for (final invalid in [
          {...row, 'habit_id': 999},
          {...row, 'status': 'fake'},
          {...row, 'progress': 21},
          {...row, 'progress': 1, 'status': 'completed'},
          {...row, 'date': '2026-02-30'},
          {...row, 'date': '2026-10-12'},
        ]) {
          await expectLater(
            db.insert('check_ins', invalid),
            throwsA(isA<DatabaseException>()),
          );
        }
        await db.insert('check_ins', row);
        await expectLater(
          db.insert('check_ins', row),
          throwsA(isA<DatabaseException>()),
        );
        await repo.deleteHabit(id);
        expect(await db.query('check_ins'), isEmpty);
      } finally {
        await db.close();
      }
    },
  );

  test(
    'file close/reopen preserves records, settings and no duplicate seeding',
    () async {
      final id = await addHabit();
      await repo.start(id, now);
      await repo.saveSettings(
        const SettingsView(
          defaultTarget: 25,
          weekStartsMonday: false,
          reducedMotion: true,
        ),
      );
      await repo.close();
      await repo.close();
      await expectLater(repo.load(), throwsStateError);
      await reopen();
      await repo.start(id, now);
      final result = await repo.load();
      expect(result.habits, hasLength(1));
      expect(result.checkIns, hasLength(1));
      expect(result.settings.defaultTarget, 25);
      expect(result.settings.weekStartsMonday, false);
      expect(result.settings.reducedMotion, true);
      expect(() => result.habits.clear(), throwsUnsupportedError);
    },
  );

  test(
    'independent connections serialize concurrent Start without duplicates',
    () async {
      final id = await addHabit();
      final other = await BloomRepository.open(
        path: path,
        factory: databaseFactoryFfi,
        preferences: prefs,
        clock: () => now,
      );
      try {
        await Future.wait([repo.start(id, now), other.start(id, now)]);
        expect((await repo.load()).checkIns, hasLength(1));
        expect((await other.load()).checkIns, hasLength(1));
      } finally {
        await other.close();
      }
    },
  );

  test('helper gateway never saves the suggested target', () async {
    final id = await addHabit();
    for (var offset = 0; offset < 14; offset++) {
      now = DateTime(2026, 10, 13 + offset);
      await repo.createCheckIn(
        entry(
          id,
          progress: offset < 8 ? 20 : 0,
          status: offset < 8 ? CheckInStatus.completed : CheckInStatus.started,
        ),
      );
    }
    final suggestion = await repo.suggestGoal(id, now);
    expect(suggestion.daysPerWeek, 4);
    expect((await repo.getHabit(id)).weeklyTarget, 3);
  });
}
