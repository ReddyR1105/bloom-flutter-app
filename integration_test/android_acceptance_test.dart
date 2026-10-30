import 'package:bloom/data/bloom_repository.dart';
import 'package:bloom/integration/bloom_gateway.dart';
import 'package:bloom/main.dart' as app;
import 'package:bloom/ui/habit_detail.dart';
import 'package:bloom/ui/bloom_app.dart';
import 'package:bloom/ui/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Real Android plugins and the real app database/preferences, no fake gateway.
// Run only on dedicated test emulators. All entries are labeled test fixtures.
Finder field(String label) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.labelText == label,
);
Future<void> tap(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> waitFor(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 100 && finder.evaluate().isEmpty; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'real Android SQLite UI CRUD, activity, settings and helper integration',
    (tester) async {
      app.main();
      await tester.pumpAndSettle();
      final audit = await BloomRepository.open();
      try {
        // Idempotent test fixture cleanup; never deletes unrelated records.
        for (final habit in (await audit.load()).habits.where(
          (h) => h.title.startsWith('[TEST]'),
        )) {
          await audit.deleteHabit(habit.id);
        }
        await tester.tap(find.byTooltip('Refresh saved data'));
        await tester.pumpAndSettle();
        await tap(tester, find.text('New habit'));
        await tester.enterText(field('Habit name'), '[TEST] Read');
        await tester.enterText(field('Measurement unit'), 'pages');
        await tester.enterText(field('Daily target'), '20');
        await tap(tester, find.text('Save habit'));
        final habit = (await audit.load()).habits.singleWhere(
          (h) => h.title == '[TEST] Read',
        );
        expect(habit.dailyTarget, 20);
        await tap(tester, find.text('[TEST] Read'));
        expect(find.byType(HabitDetail), findsOneWidget);
        await waitFor(tester, find.textContaining('Not enough history yet'));
        await tap(tester, find.text('Not now'));
        await tap(tester, find.text('Start today'));
        await audit.start(
          habit.id,
          DateTime.now(),
        ); // resume must be idempotent
        expect(
          (await audit.load()).checkIns.where((c) => c.habitId == habit.id),
          hasLength(1),
        );
        await tester.ensureVisible(find.byType(Slider));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(Slider), const Offset(1000, 0));
        await tester.pumpAndSettle();
        expect(
          (await audit.load()).checkIns
              .singleWhere((c) => c.habitId == habit.id)
              .progress,
          0,
        );
        await tap(tester, find.text('Finish for today'));
        var entry = (await audit.load()).checkIns.singleWhere(
          (c) => c.habitId == habit.id,
        );
        expect(entry.status, CheckInStatus.completed);
        expect(entry.progress, 20);
        await tap(tester, find.text('Reset today’s progress'));
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(
          (await audit.getCheckIn(entry.id)).status,
          CheckInStatus.completed,
        );
        await tap(tester, find.text('Reset today’s progress'));
        await tester.tap(find.text('Reset today'));
        await tester.pumpAndSettle();
        expect((await audit.getCheckIn(entry.id)).progress, 0);
        await tester.ensureVisible(find.byType(Slider));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(Slider), const Offset(1000, 0));
        await tester.pumpAndSettle();
        await tap(tester, find.text('Save progress'));
        expect(
          (await audit.getCheckIn(entry.id)).status,
          CheckInStatus.inProgress,
        );
        await tap(tester, find.text('Finish for today'));
        await tap(tester, find.text('Edit habit'));
        await tester.enterText(field('Habit name'), '[TEST] Read 20 pages');
        await tap(tester, find.text('Save habit'));
        expect((await audit.getHabit(habit.id)).title, '[TEST] Read 20 pages');
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.textContaining('habits completed today'), findsOneWidget);
        expect(find.byType(Garden), findsOneWidget);
        await tester.tap(find.text('Insights'));
        await tester.pumpAndSettle();
        // History can include unrelated saved demonstration records.
        // Filter to this fixture before correcting the first visible entry.
        await tap(tester, find.byType(DropdownButtonFormField<int>));
        await tap(tester, find.text('[TEST] Read 20 pages').last);
        await tap(tester, find.text('Correct or delete check-in').first);
        await tester.enterText(
          field('Note (optional)'),
          'Android acceptance correction',
        );
        await tap(tester, find.text('Save check-in'));
        expect(
          (await audit.getCheckIn(entry.id)).note,
          'Android acceptance correction',
        );
        await tap(tester, find.text('Add a past check-in'));
        // Saved demo/user habits may precede this fixture in the dropdown.
        // Select the intended habit explicitly instead of relying on ordering.
        await tap(tester, find.byType(DropdownButtonFormField<int>));
        await tap(tester, find.text('[TEST] Read 20 pages').last);
        await tap(tester, find.text('Save check-in'));
        expect(find.textContaining('already has a check-in'), findsOneWidget);
        await tap(tester, find.text('Cancel'));
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();
        final beforeSettings = (await audit.load()).settings;
        await tap(tester, find.byTooltip('Increase default target'));
        await tap(tester, find.text('Reduced motion'));
        await tap(tester, find.text('Start week on Monday'));
        final settings = (await audit.load()).settings;
        expect(settings.defaultTarget, beforeSettings.defaultTarget + 1);
        expect(settings.reducedMotion, !beforeSettings.reducedMotion);
        expect(settings.weekStartsMonday, !beforeSettings.weekStartsMonday);
        // SQL validation really rejects excess progress and duplicate habit/day.
        await expectLater(
          audit.updateProgress(habit.id, DateTime.now(), 21),
          throwsArgumentError,
        );
        await expectLater(
          audit.createCheckIn(
            CheckInDraft(
              habitId: habit.id,
              day: DateTime.now(),
              progress: 0,
              status: CheckInStatus.started,
              note: 'duplicate',
            ),
          ),
          throwsA(isA<Exception>()),
        );
        await tester.tap(find.text('Habits'));
        await tester.pumpAndSettle();
        await tap(tester, find.text('[TEST] Read 20 pages'));
        await tap(tester, find.text('Correct today’s check-in'));
        await tap(tester, find.text('Delete check-in'));
        await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
        await tester.pumpAndSettle();
        expect(
          (await audit.load()).checkIns.where((c) => c.habitId == habit.id),
          isEmpty,
        );
        expect((await audit.getHabit(habit.id)).id, habit.id);
        await tap(tester, find.text('Start today'));
        await tap(tester, find.text('Delete habit and history'));
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect((await audit.getHabit(habit.id)).id, habit.id);
        await tap(tester, find.text('Delete habit and history'));
        await tester.tap(find.text('Delete all'));
        await tester.pumpAndSettle();
        expect(
          (await audit.load()).habits.where((h) => h.id == habit.id),
          isEmpty,
        );
        expect(
          (await audit.load()).checkIns.where((c) => c.habitId == habit.id),
          isEmpty,
        );
        // Leave one explicitly labeled test record/settings for the independent
        // host-side force-stop/relaunch/offline checks on the release APK.
        await audit.createHabit(
          const HabitDraft(
            title: '[TEST] Restart proof',
            category: 'Acceptance test',
            unit: 'pages',
            dailyTarget: 10,
            weeklyTarget: 3,
          ),
        );
        final persisted = (await audit.load()).habits.singleWhere(
          (h) => h.title == '[TEST] Restart proof',
        );
        await audit.start(persisted.id, DateTime.now());
        await audit.updateProgress(persisted.id, DateTime.now(), 10);
        await audit.finish(persisted.id, DateTime.now());
        await audit.saveSettings(
          const SettingsView(
            defaultTarget: 27,
            weekStartsMonday: false,
            reducedMotion: true,
          ),
        );
        await tester.tap(find.text('Today'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Refresh saved data'));
        await tester.pumpAndSettle();
        expect(find.text('[TEST] Restart proof'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await audit.close();
      }
    },
  );
  testWidgets('eligible real-SQLite helper Apply requires explicit Save', (
    tester,
  ) async {
    final today = localDay(DateTime.now());
    var clock = DateTime(today.year, today.month, today.day - 13);
    final repository = await BloomRepository.open(
      path: p.join(await getDatabasesPath(), 'bloom_helper_acceptance.db'),
      clock: () => clock,
    );
    for (final habit in (await repository.load()).habits.where(
      (h) => h.title == '[TEST] Helper fixture',
    )) {
      await repository.deleteHabit(habit.id);
    }
    await repository.createHabit(
      const HabitDraft(
        title: '[TEST] Helper fixture',
        category: 'Synthetic acceptance test',
        unit: 'pages',
        dailyTarget: 20,
        weeklyTarget: 3,
      ),
    );
    final habit = (await repository.load()).habits.singleWhere(
      (h) => h.title == '[TEST] Helper fixture',
    );
    clock = today;
    for (var offset = 0; offset < 14; offset++) {
      await repository.createCheckIn(
        CheckInDraft(
          habitId: habit.id,
          day: DateTime(today.year, today.month, today.day - offset),
          progress: offset < 8 ? 20 : 0,
          status: offset < 8 ? CheckInStatus.completed : CheckInStatus.started,
          note: 'Synthetic 14-day acceptance fixture',
        ),
      );
    }
    await tester.pumpWidget(BloomApp(gateway: repository));
    await tester.pumpAndSettle();
    await tap(tester, find.text('[TEST] Helper fixture'));
    await tap(tester, find.text('Apply'));
    expect(find.text('Weekly goal: 4 days'), findsOneWidget);
    expect((await repository.getHabit(habit.id)).weeklyTarget, 3);
    await tap(tester, find.text('Cancel'));
    expect((await repository.getHabit(habit.id)).weeklyTarget, 3);
    await tap(tester, find.text('Apply'));
    await tap(tester, find.text('Save habit'));
    expect((await repository.getHabit(habit.id)).weeklyTarget, 4);
    await repository.deleteHabit(habit.id);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
