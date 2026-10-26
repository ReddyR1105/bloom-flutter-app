import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../helper/goal_suggestion.dart';
import '../integration/bloom_gateway.dart';
import 'settings_store.dart';
import 'validation.dart';

/// SQLite owner. Inject a database factory/path for real SQLite host tests.
class BloomRepository implements BloomGateway {
  BloomRepository._(this._db, this._settings, this._clock);
  final Database _db;
  final SettingsStore _settings;
  final DateTime Function() _clock;
  bool _closed = false;
  Future<void>? _closing;

  static Future<BloomRepository> open({
    String? path,
    DatabaseFactory? factory,
    SharedPreferences? preferences,
    DateTime Function()? clock,
  }) async {
    final selected = factory ?? databaseFactory;
    final settings = SettingsStore(
      preferences ?? await SharedPreferences.getInstance(),
    );
    final location =
        path ?? p.join(await selected.getDatabasesPath(), 'bloom.db');
    final db = await selected.openDatabase(
      location,
      options: OpenDatabaseOptions(
        version: 1,
        singleInstance: false,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: _create,
        onUpgrade: (_, oldVersion, newVersion) async {
          throw StateError(
            'Unsupported migration $oldVersion → $newVersion. Keep the database and update the app.',
          );
        },
      ),
    );
    return BloomRepository._(db, settings, clock ?? DateTime.now);
  }

  static Future<void> _create(Database db, int version) async {
    await db.execute('''CREATE TABLE habits (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL CHECK(length(trim(title)) > 0),
      category TEXT NOT NULL CHECK(length(trim(category)) > 0),
      unit TEXT NOT NULL CHECK(length(trim(unit)) > 0),
      daily_target INTEGER NOT NULL CHECK(typeof(daily_target) = 'integer' AND daily_target BETWEEN 1 AND 100000),
      weekly_target INTEGER NOT NULL CHECK(typeof(weekly_target) = 'integer' AND weekly_target BETWEEN 1 AND 7),
      created_at TEXT NOT NULL CHECK(length(created_at) = 10 AND date(created_at, '+0 days') IS created_at),
      archived INTEGER NOT NULL DEFAULT 0 CHECK(archived IN (0, 1))
    )''');
    await db.execute('''CREATE TABLE check_ins (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      habit_id INTEGER NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
      date TEXT NOT NULL CHECK(length(date) = 10 AND date(date, '+0 days') IS date),
      progress INTEGER NOT NULL CHECK(typeof(progress) = 'integer' AND progress >= 0),
      status TEXT NOT NULL CHECK(status IN ('started', 'in_progress', 'completed')),
      note TEXT NOT NULL DEFAULT '',
      UNIQUE(habit_id, date)
    )''');
    for (final action in ['INSERT', 'UPDATE']) {
      await db.execute(
        '''CREATE TRIGGER check_in_${action.toLowerCase()} BEFORE $action ON check_ins BEGIN
        SELECT RAISE(ABORT, 'Check-in progress/status/date is invalid for this habit')
        WHERE NEW.progress > (SELECT daily_target FROM habits WHERE id = NEW.habit_id)
          OR (NEW.status = 'started' AND NEW.progress <> 0)
          OR (NEW.status = 'in_progress' AND NEW.progress = 0)
          OR (NEW.status = 'completed' AND NEW.progress <> (SELECT daily_target FROM habits WHERE id = NEW.habit_id))
          OR NEW.date < (SELECT created_at FROM habits WHERE id = NEW.habit_id);
      END''',
      );
    }
    await db.execute(
      '''CREATE TRIGGER habit_target AFTER UPDATE OF daily_target ON habits BEGIN
      UPDATE check_ins SET progress = MIN(progress, NEW.daily_target),
        status = CASE
          WHEN progress = 0 THEN 'started'
          WHEN status = 'completed' AND progress >= NEW.daily_target THEN 'completed'
          ELSE 'in_progress' END
      WHERE habit_id = NEW.id;
    END''',
    );
    await db.execute(
      '''CREATE TRIGGER habit_creation BEFORE UPDATE OF created_at ON habits BEGIN
      SELECT RAISE(ABORT, 'Habit creation date cannot be changed') WHERE NEW.created_at <> OLD.created_at;
    END''',
    );
  }

  // A second SQLite connection may briefly own the write lock. Retry only
  // busy/locked transactions, which SQLite rolls back before this callback is
  // repeated. Callbacks contain database operations only, no external effects.
  Future<T> _transaction<T>(Future<T> Function(Transaction) action) async {
    for (var attempt = 0; ; attempt++) {
      _ensureOpen();
      try {
        return await _db.transaction(action);
      } on DatabaseException catch (error) {
        final code = error.getResultCode();
        if (attempt >= 4 || (code != 5 && code != 6)) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 10 * (1 << attempt)));
      }
    }
  }

  void _ensureOpen() {
    if (_closed) {
      throw StateError('Bloom database is closed. Open a new repository.');
    }
  }

  HabitView _habit(Map<String, Object?> row) => HabitView(
    id: row['id'] as int,
    title: row['title'] as String,
    category: row['category'] as String,
    unit: row['unit'] as String,
    dailyTarget: row['daily_target'] as int,
    weeklyTarget: row['weekly_target'] as int,
    createdAt: parseDay(row['created_at'] as String),
    archived: row['archived'] == 1,
  );
  CheckInView _entry(Map<String, Object?> row) => CheckInView(
    id: row['id'] as int,
    habitId: row['habit_id'] as int,
    day: parseDay(row['date'] as String),
    progress: row['progress'] as int,
    status: switch (row['status']) {
      'started' => CheckInStatus.started,
      'in_progress' => CheckInStatus.inProgress,
      'completed' => CheckInStatus.completed,
      _ => throw StateError('Corrupt saved status'),
    },
    note: row['note'] as String,
  );
  Map<String, Object?> _habitValues(HabitDraft value) => {
    'title': value.title.trim(),
    'category': value.category.trim(),
    'unit': value.unit.trim(),
    'daily_target': value.dailyTarget,
    'weekly_target': value.weeklyTarget,
  };
  Map<String, Object?> _entryValues(CheckInDraft value) => {
    'habit_id': value.habitId,
    'date': dayKey(value.day),
    'progress': value.progress,
    'status': switch (value.status) {
      CheckInStatus.started => 'started',
      CheckInStatus.inProgress => 'in_progress',
      CheckInStatus.completed => 'completed',
    },
    'note': value.note,
  };
  Future<HabitView> _getHabit(DatabaseExecutor db, int id) async {
    final rows = await db.query('habits', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) {
      throw StateError('Habit $id does not exist. Refresh the list.');
    }
    return _habit(rows.single);
  }

  Future<CheckInView> _getEntry(DatabaseExecutor db, int id) async {
    final rows = await db.query('check_ins', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) {
      throw StateError('Check-in $id does not exist. Refresh history.');
    }
    return _entry(rows.single);
  }

  Future<HabitView> getHabit(int id) async {
    _ensureOpen();
    return _getHabit(_db, id);
  }

  Future<CheckInView> getCheckIn(int id) async {
    _ensureOpen();
    return _getEntry(_db, id);
  }

  @override
  Future<BloomSnapshot> load() async {
    _ensureOpen();
    return _transaction(
      (tx) async => BloomSnapshot(
        habits: List.unmodifiable(
          (await tx.query('habits', orderBy: 'id')).map(_habit),
        ),
        checkIns: List.unmodifiable(
          (await tx.query('check_ins', orderBy: 'date, id')).map(_entry),
        ),
        settings: _settings.load(),
      ),
    );
  }

  @override
  Future<void> createHabit(HabitDraft draft) async {
    _ensureOpen();
    validateHabit(draft);
    await _db.insert('habits', {
      ..._habitValues(draft),
      'created_at': dayKey(_clock()),
    });
  }

  @override
  Future<void> updateHabit(int id, HabitDraft draft) async {
    _ensureOpen();
    validateHabit(draft);
    if (await _db.update(
          'habits',
          _habitValues(draft),
          where: 'id = ?',
          whereArgs: [id],
        ) !=
        1) {
      throw StateError('Habit $id does not exist.');
    }
  }

  Future<void> setArchived(int id, bool archived) async {
    _ensureOpen();
    if (await _db.update(
          'habits',
          {'archived': archived ? 1 : 0},
          where: 'id = ?',
          whereArgs: [id],
        ) !=
        1) {
      throw StateError('Habit $id does not exist.');
    }
  }

  @override
  Future<void> deleteHabit(int id) async {
    _ensureOpen();
    if (await _db.delete('habits', where: 'id = ?', whereArgs: [id]) != 1) {
      throw StateError('Habit $id does not exist.');
    }
  }

  @override
  Future<void> createCheckIn(CheckInDraft draft) async {
    _ensureOpen();
    await _transaction((tx) async {
      validateEntry(draft, await _getHabit(tx, draft.habitId), _clock());
      await tx.insert('check_ins', _entryValues(draft));
    });
  }

  @override
  Future<void> updateCheckIn(int id, CheckInDraft draft) async {
    _ensureOpen();
    await _transaction((tx) async {
      await _getEntry(tx, id);
      validateEntry(draft, await _getHabit(tx, draft.habitId), _clock());
      await tx.update(
        'check_ins',
        _entryValues(draft),
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  @override
  Future<void> deleteCheckIn(int id) async {
    _ensureOpen();
    if (await _db.delete('check_ins', where: 'id = ?', whereArgs: [id]) != 1) {
      throw StateError('Check-in $id does not exist.');
    }
  }

  @override
  Future<void> start(int habitId, DateTime day) async {
    _ensureOpen();
    await _transaction((tx) async {
      final draft = CheckInDraft(
        habitId: habitId,
        day: day,
        progress: 0,
        status: CheckInStatus.started,
        note: '',
      );
      validateEntry(draft, await _getHabit(tx, habitId), _clock());
      final rows = await tx.query(
        'check_ins',
        where: 'habit_id = ? AND date = ?',
        whereArgs: [habitId, dayKey(day)],
      );
      if (rows.isEmpty) await tx.insert('check_ins', _entryValues(draft));
    });
  }

  Future<void> _change(
    int habitId,
    DateTime day, {
    int? progress,
    bool finish = false,
  }) async {
    _ensureOpen();
    await _transaction((tx) async {
      final habit = await _getHabit(tx, habitId);
      final rows = await tx.query(
        'check_ins',
        where: 'habit_id = ? AND date = ?',
        whereArgs: [habitId, dayKey(day)],
      );
      if (rows.isEmpty) {
        throw StateError(
          'Start this day before updating, finishing or resetting it.',
        );
      }
      final old = _entry(rows.single);
      final nextProgress = progress ?? old.progress;
      if (finish && nextProgress != habit.dailyTarget) {
        throw StateError('Reach the daily target before finishing.');
      }
      final status =
          finish ||
              (old.status == CheckInStatus.completed &&
                  nextProgress == habit.dailyTarget)
          ? CheckInStatus.completed
          : nextProgress == 0
          ? CheckInStatus.started
          : CheckInStatus.inProgress;
      final draft = CheckInDraft(
        habitId: habitId,
        day: day,
        progress: nextProgress,
        status: status,
        note: old.note,
      );
      validateEntry(draft, habit, _clock());
      await tx.update(
        'check_ins',
        _entryValues(draft),
        where: 'id = ?',
        whereArgs: [old.id],
      );
    });
  }

  @override
  Future<void> updateProgress(int habitId, DateTime day, int progress) =>
      _change(habitId, day, progress: progress);
  @override
  Future<void> finish(int habitId, DateTime day) =>
      _change(habitId, day, finish: true);
  @override
  Future<void> reset(int habitId, DateTime day) =>
      _change(habitId, day, progress: 0);
  @override
  Future<void> saveSettings(SettingsView settings) async {
    _ensureOpen();
    await _settings.save(settings);
  }

  @override
  Future<GoalSuggestionView> suggestGoal(int habitId, DateTime today) async {
    _ensureOpen();
    return _transaction((tx) async {
      final habit = await _getHabit(tx, habitId);
      final entries = (await tx.query(
        'check_ins',
        where: 'habit_id = ?',
        whereArgs: [habitId],
      )).map(_entry).toList();
      final result = calculateGoal(
        habit: habit,
        checkIns: entries,
        today: today,
      );
      return GoalSuggestionView(
        daysPerWeek: result.daysPerWeek,
        explanation: result.explanation,
      );
    });
  }

  @override
  Future<void> close() {
    _closed = true;
    return _closing ??= _db.close();
  }
}
