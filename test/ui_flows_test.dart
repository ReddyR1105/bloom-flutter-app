import 'package:bloom/integration/bloom_gateway.dart';
import 'package:bloom/ui/bloom_app.dart';
import 'package:bloom/ui/editors.dart';
import 'package:bloom/ui/habit_detail.dart';
import 'package:bloom/ui/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Explicit UI test double. Never imported by production, never evidence of
/// SQLite, preferences, the helper calculation or process-restart persistence.
class UiTestGateway implements BloomGateway {
  final habits = <HabitView>[];
  final entries = <CheckInView>[];
  var settings = const SettingsView();
  var closed = false;
  var writes = 0;
  var failLoad = false;
  var failSave = false;
  var nextId = 1;
  final goal = const GoalSuggestionView(
    daysPerWeek: 4,
    explanation: 'Test fixture: 8 completed days; try 4 days/week.',
  );
  HabitView addHabit() {
    final h = HabitView(
      id: nextId++,
      title: 'Read',
      category: 'Learning',
      unit: 'pages',
      dailyTarget: 20,
      weeklyTarget: 3,
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
    );
    habits.add(h);
    return h;
  }

  @override
  Future<BloomSnapshot> load() async {
    if (failLoad) throw StateError('Cannot open local database.');
    return BloomSnapshot(
      habits: List.of(habits),
      checkIns: List.of(entries),
      settings: settings,
    );
  }

  @override
  Future<void> createHabit(HabitDraft draft) async {
    if (failSave) throw StateError('Local save failed. Try again.');
    writes++;
    habits.add(
      HabitView(
        id: nextId++,
        title: draft.title,
        category: draft.category,
        unit: draft.unit,
        dailyTarget: draft.dailyTarget,
        weeklyTarget: draft.weeklyTarget,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> updateHabit(int id, HabitDraft draft) async {
    writes++;
    final old = habits.firstWhere((h) => h.id == id);
    habits.removeWhere((h) => h.id == id);
    habits.add(
      HabitView(
        id: id,
        title: draft.title,
        category: draft.category,
        unit: draft.unit,
        dailyTarget: draft.dailyTarget,
        weeklyTarget: draft.weeklyTarget,
        createdAt: old.createdAt,
      ),
    );
  }

  @override
  Future<void> deleteHabit(int id) async {
    writes++;
    habits.removeWhere((h) => h.id == id);
    entries.removeWhere((c) => c.habitId == id);
  }

  @override
  Future<void> start(int habitId, DateTime day) async {
    if (entries.any((c) => c.habitId == habitId && sameDay(c.day, day))) return;
    writes++;
    entries.add(
      CheckInView(
        id: nextId++,
        habitId: habitId,
        day: day,
        progress: 0,
        status: CheckInStatus.started,
      ),
    );
  }

  @override
  Future<void> updateProgress(int habitId, DateTime day, int progress) async {
    final old = entries.firstWhere(
      (c) => c.habitId == habitId && sameDay(c.day, day),
    );
    writes++;
    entries.remove(old);
    entries.add(
      CheckInView(
        id: old.id,
        habitId: habitId,
        day: day,
        progress: progress,
        status: progress == 0
            ? CheckInStatus.started
            : CheckInStatus.inProgress,
      ),
    );
  }

  @override
  Future<void> finish(int habitId, DateTime day) async {
    final old = entries.firstWhere(
      (c) => c.habitId == habitId && sameDay(c.day, day),
    );
    writes++;
    entries.remove(old);
    entries.add(
      CheckInView(
        id: old.id,
        habitId: habitId,
        day: day,
        progress: old.progress,
        status: CheckInStatus.completed,
      ),
    );
  }

  @override
  Future<void> reset(int habitId, DateTime day) =>
      updateProgress(habitId, day, 0);
  @override
  Future<void> createCheckIn(CheckInDraft draft) async {
    writes++;
    entries.add(
      CheckInView(
        id: nextId++,
        habitId: draft.habitId,
        day: draft.day,
        progress: draft.progress,
        status: draft.status,
        note: draft.note,
      ),
    );
  }

  @override
  Future<void> updateCheckIn(int id, CheckInDraft draft) async {
    writes++;
    entries.removeWhere((c) => c.id == id);
    entries.add(
      CheckInView(
        id: id,
        habitId: draft.habitId,
        day: draft.day,
        progress: draft.progress,
        status: draft.status,
        note: draft.note,
      ),
    );
  }

  @override
  Future<void> deleteCheckIn(int id) async {
    writes++;
    entries.removeWhere((c) => c.id == id);
  }

  @override
  Future<void> saveSettings(SettingsView value) async {
    writes++;
    settings = value;
  }

  @override
  Future<GoalSuggestionView> suggestGoal(int habitId, DateTime today) async =>
      goal;
  @override
  Future<void> close() async {
    closed = true;
  }
}

Finder field(String label) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.labelText == label,
);

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> mount(WidgetTester tester, BloomGateway gateway) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(BloomApp(gateway: gateway));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'unavailable storage shows error and retry without fake records',
    (tester) async {
      await mount(tester, UiTestGateway()..failLoad = true);
      expect(find.text('Your habits could not be loaded'), findsOneWidget);
      expect(find.textContaining('Cannot open local database'), findsOneWidget);
      await tapVisible(tester, find.text('Try again'));
      expect(find.byType(HabitCard), findsNothing);
    },
  );

  testWidgets(
    'empty database validates create form and refreshes saved habit',
    (tester) async {
      final gateway = UiTestGateway();
      await mount(tester, gateway);
      expect(find.textContaining('No habits here yet'), findsOneWidget);
      await tapVisible(tester, find.text('New habit'));
      await tapVisible(tester, find.text('Save habit'));
      expect(find.text('Enter a value before saving.'), findsOneWidget);
      expect(gateway.writes, 0);
      await tester.enterText(field('Habit name'), 'Walk');
      await tester.enterText(field('Daily target'), '0');
      await tapVisible(tester, find.text('Save habit'));
      expect(
        find.text('Enter a whole number from 1 to 100000.'),
        findsOneWidget,
      );
      await tester.enterText(field('Daily target'), '15');
      await tapVisible(tester, find.text('Save habit'));
      expect(find.byType(HabitEditor), findsNothing);
      expect(find.text('Walk'), findsOneWidget);
      expect(gateway.habits.single.dailyTarget, 15);
    },
  );

  testWidgets('failed save retains form and actionable message', (
    tester,
  ) async {
    final gateway = UiTestGateway()..failSave = true;
    await mount(tester, gateway);
    await tapVisible(tester, find.text('New habit'));
    await tester.enterText(field('Habit name'), 'Read');
    await tapVisible(tester, find.text('Save habit'));
    expect(find.byType(HabitEditor), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
    expect(find.textContaining('Local save failed'), findsOneWidget);
    expect(gateway.writes, 0);
  });

  testWidgets('start progress finish and reset require explicit actions', (
    tester,
  ) async {
    final gateway = UiTestGateway();
    gateway.addHabit();
    await mount(tester, gateway);
    await tapVisible(tester, find.text('Read'));
    expect(find.byType(HabitDetail), findsOneWidget);
    await tapVisible(tester, find.text('Start today'));
    expect(gateway.entries.single.status, CheckInStatus.started);
    await tester.ensureVisible(find.byType(Slider));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Slider), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(gateway.entries.single.progress, 0);
    await tapVisible(tester, find.text('Finish for today'));
    expect(gateway.entries.single.status, CheckInStatus.completed);
    expect(gateway.entries.single.progress, 20);
    await tapVisible(tester, find.text('Reset today’s progress'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(gateway.entries.single.status, CheckInStatus.completed);
    await tapVisible(tester, find.text('Reset today’s progress'));
    await tester.tap(find.text('Reset today'));
    await tester.pumpAndSettle();
    expect(gateway.entries.single.progress, 0);
    expect(gateway.entries.single.status, CheckInStatus.started);
  });

  testWidgets('goal Apply only prefills; cancel never persists; Save does', (
    tester,
  ) async {
    final gateway = UiTestGateway();
    gateway.addHabit();
    await mount(tester, gateway);
    await tapVisible(tester, find.text('Read'));
    await tapVisible(tester, find.text('Apply'));
    expect(find.text('Weekly goal: 4 days'), findsOneWidget);
    expect(gateway.writes, 0);
    await tapVisible(tester, find.text('Cancel'));
    expect(gateway.habits.single.weeklyTarget, 3);
    await tapVisible(tester, find.text('Apply'));
    await tapVisible(tester, find.text('Save habit'));
    expect(gateway.habits.single.weeklyTarget, 4);
  });

  testWidgets('habit deletion warns cascade and cancellation preserves data', (
    tester,
  ) async {
    final gateway = UiTestGateway();
    final habit = gateway.addHabit();
    await gateway.start(habit.id, DateTime.now());
    await mount(tester, gateway);
    await tapVisible(tester, find.text('Read'));
    await tapVisible(tester, find.text('Delete habit and history'));
    expect(find.textContaining('ALL its saved check-ins'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(gateway.habits, hasLength(1));
    await tapVisible(tester, find.text('Delete habit and history'));
    await tester.tap(find.text('Delete all'));
    await tester.pumpAndSettle();
    expect(gateway.habits, isEmpty);
    expect(gateway.entries, isEmpty);
  });

  testWidgets(
    'duplicate check-in and out-of-range progress are rejected before writes',
    (tester) async {
      final gateway = UiTestGateway();
      final habit = gateway.addHabit();
      await gateway.start(habit.id, DateTime.now());
      final data = await gateway.load();
      await tester.pumpWidget(
        MaterialApp(
          home: CheckInEditor(gateway: gateway, snapshot: data),
        ),
      );
      await tester.pumpAndSettle();
      final writesBefore = gateway.writes;
      await tester.enterText(field('Progress (pages)'), '21');
      await tapVisible(tester, find.text('Save check-in'));
      expect(find.text('Enter a whole number from 0 to 20.'), findsOneWidget);
      await tester.enterText(field('Progress (pages)'), '0');
      await tapVisible(tester, find.text('Save check-in'));
      expect(find.textContaining('already has a check-in'), findsOneWidget);
      expect(gateway.writes, writesBefore);
    },
  );

  testWidgets('settings writes route through gateway and refresh values', (
    tester,
  ) async {
    final gateway = UiTestGateway();
    await mount(tester, gateway);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byTooltip('Increase default target'));
    expect(gateway.settings.defaultTarget, 21);
    await tapVisible(tester, find.text('Reduced motion'));
    expect(gateway.settings.reducedMotion, true);
    await tapVisible(tester, find.text('Start week on Monday'));
    expect(gateway.settings.weekStartsMonday, false);
  });

  testWidgets(
    'garden reflects completed saved records and history shows real filtered summary',
    (tester) async {
      final gateway = UiTestGateway();
      final habit = gateway.addHabit();
      await gateway.start(habit.id, DateTime.now());
      await gateway.updateProgress(habit.id, DateTime.now(), 20);
      await gateway.finish(habit.id, DateTime.now());
      await mount(tester, gateway);
      expect(find.text('Sprout · 1 saved completions'), findsOneWidget);
      expect(find.text('1 of 1 habits completed today'), findsOneWidget);
      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();
      expect(find.text('1 completed check-ins'), findsOneWidget);
      await tapVisible(tester, find.text('Correct or delete check-in'));
      await tester.enterText(field('Note (optional)'), 'Corrected note');
      await tapVisible(tester, find.text('Save check-in'));
      expect(gateway.entries.single.note, 'Corrected note');
      await tapVisible(tester, find.text('Correct or delete check-in'));
      await tapVisible(tester, find.text('Delete check-in'));
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(gateway.entries, isEmpty);
      expect(gateway.habits, hasLength(1));
    },
  );

  testWidgets(
    'portrait landscape and large text layouts have no framework errors',
    (tester) async {
      final gateway = UiTestGateway();
      gateway.addHabit();
      await mount(tester, gateway);
      for (final size in [const Size(390, 844), const Size(844, 390)]) {
        tester.view.physicalSize = size;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpAndSettle();
        for (final destination in ['Habits', 'Insights', 'Settings', 'Today']) {
          await tester.tap(find.text(destination).last);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(gateway.closed, true);
    },
  );
}
